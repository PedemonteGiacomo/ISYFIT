import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/app_snackbars.dart';
import '../../theme/app_gradients.dart';

import 'package:isyfit/presentation/widgets/measurement_type_tab_bar_widget.dart'; // <<-- Import the new widget

/// This is the Insert screen. We'll show a 3-tab approach:
/// Tab 0: BIA form fields
/// Tab 1: USArmy form fields
/// Tab 2: Plicometro form fields
///
/// Each tab can have its own "Save" button (or you can unify them).
class MeasurementsInsertScreen extends StatefulWidget {
  final String? clientUid;
  const MeasurementsInsertScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<MeasurementsInsertScreen> createState() =>
      _MeasurementsInsertScreenState();
}

class _MeasurementsInsertScreenState extends State<MeasurementsInsertScreen>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  late TabController _tabController;

  // BIA fields
  final _biaHeightCtrl = TextEditingController();
  final _biaWeightCtrl = TextEditingController();
  final _biaSkeletalMuscleMassCtrl = TextEditingController();
  final _biaBodyFatKgCtrl = TextEditingController();
  final _biaBMICtrl = TextEditingController();
  final _biaBasalMetabolicRateCtrl = TextEditingController();
  final _biaWaistHipRatioCtrl = TextEditingController();
  final _biaVisceralFatLevelCtrl = TextEditingController();
  final _biaTargetWeightCtrl = TextEditingController();

  // USArmy fields
  final _armyHeightCtrl = TextEditingController();
  final _armyNeckCtrl = TextEditingController();
  final _armyWaistCtrl = TextEditingController();
  final _armyHipsCtrl = TextEditingController();
  final _armyWristCtrl = TextEditingController();

  // Plicometro fields
  final _plicChestCtrl = TextEditingController();
  final _plicAbdomenCtrl = TextEditingController();
  final _plicThighCtrl = TextEditingController();
  final _plicTricepsCtrl = TextEditingController();
  final _plicSuprailiacCtrl = TextEditingController();
  bool _showPlicHelp = false;

  late Future<String> _genderFuture;
  late Future<double> _ageFuture;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _genderFuture = _fetchGender();
    _ageFuture = _fetchAge();
  }

  @override
  void dispose() {
    _tabController.dispose();
    // Also dispose controllers if you want
    super.dispose();
  }

  Future<String> _fetchGender() async {
    final uid = widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 'Unknown';
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    return data['gender'] ?? 'Unknown';
  }

  Future<double> _fetchAge() async {
    final uid = widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 30;
    final doc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    if (data['dateOfBirth'] == null) return 30;
    final dob = DateTime.tryParse(data['dateOfBirth']);
    if (dob == null) return 30;
    final now = DateTime.now();
    int age = now.year - dob.year;
    if ((now.month < dob.month) ||
        (now.month == dob.month && now.day < dob.day)) {
      age--;
    }
    return age.toDouble();
  }

  CollectionReference get _recordsCollection {
    final cUid = widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('measurements')
        .doc(cUid)
        .collection('records');
  }

  // Example formula methods below...
  double _calcBodyFatUSArmy({
    required String gender,
    required double heightCm,
    required double neckCm,
    required double waistCm,
    double? hipsCm,
  }) {
    final ln = math.log;
    if (gender.toLowerCase().startsWith('f')) {
      if (hipsCm == null) return 0;
      final numerator = 495.0;
      final denominator = (1.29579 -
          0.35004 * ln(waistCm + hipsCm - neckCm) +
          0.22100 * ln(heightCm));
      return numerator / denominator - 450.0;
    } else {
      final numerator = 495.0;
      final denominator =
          (1.0324 - 0.19077 * ln(waistCm - neckCm) + 0.15456 * ln(heightCm));
      return numerator / denominator - 450.0;
    }
  }

  double _calcBodyFatPlic(double sumOfPlic, double age) {
    final density = 1.109380 -
        0.0008267 * sumOfPlic +
        0.0000016 * sumOfPlic * sumOfPlic -
        0.0002574 * age;
    return (495 / density) - 450;
  }

  double _computeBMI(double weightKg, double heightCm) {
    final hM = heightCm / 100.0;
    if (hM <= 0) return 0;
    return weightKg / (hM * hM);
  }

  double _computeIsyScore({
    required double bmi,
    required double bodyFatPercent,
    required double age,
  }) {
    double score = 100.0;
    final diffFrom22 = (bmi - 22.0).abs();
    score -= diffFrom22 * 1.5;
    score -= bodyFatPercent * 0.5;
    if (age > 40) {
      score -= (age - 40) * 0.2;
    }
    if (score < 0) score = 0;
    if (score > 100) score = 100;
    return score;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return FutureBuilder<Map<String, dynamic>>(
      future: _loadGenderAge(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final info = snap.data ?? {};
        final gender = info['gender'] as String? ?? 'Unknown';
        final age = info['age'] as double? ?? 30.0;

        // Now we have gender & age. We'll show the tab bar + 3 tab views
        return Column(
          children: [
            // The new tab bar widget:
            MeasurementTypeTabBarWidget(tabController: _tabController),

            // The 3 TabBarView children:
            Expanded(
              child: Container(
                color: Theme.of(context).colorScheme.surface, // White background from theme
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // BIA form
                    _buildBIAForm(context, gender, age),
                    // USArmy form
                    _buildUSArmyForm(context, gender, age),
                    // Plicometro form
                    _buildPlicForm(context, gender, age),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadGenderAge() async {
    final g = await _genderFuture;
    final a = await _ageFuture;
    return {'gender': g, 'age': a};
  }

  // ---------------------------------------------------------------------------
  //  BIA Tab
  // ---------------------------------------------------------------------------
  Widget _buildBIAForm(BuildContext context, String gender, double age) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
          children: [
            // Hero Header with Modern Glassmorphism Effect
            Container(
              decoration: BoxDecoration(
                gradient: AppGradients.primary(Theme.of(context)),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.biotech, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "BIA Analysis",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Bioelectrical Impedance Analysis",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Modern Floating Cards with Advanced Styling
            _buildAdvancedSectionCard(
              title: "Physical Metrics",
              icon: Icons.straighten,
              iconColor: const Color(0xFF4CAF50),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildAdvancedNumberField(
                        _biaHeightCtrl, 
                        "Height", 
                        icon: Icons.height, 
                        suffixText: "cm",
                        gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
                      )
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildAdvancedNumberField(
                        _biaWeightCtrl, 
                        "Weight", 
                        icon: Icons.monitor_weight, 
                        suffixText: "kg",
                        gradientColors: [Colors.green.shade400, Colors.green.shade600],
                      )
                    ),
                  ],
                ),
                _buildAdvancedNumberField(
                  _biaBMICtrl, 
                  "BMI (auto-calculated)", 
                  icon: Icons.calculate, 
                  suffixText: "kg/m²",
                  gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
                ),
              ],
            ),

            _buildAdvancedSectionCard(
              title: "Body Composition",
              icon: Icons.accessibility_new,
              iconColor: const Color(0xFFFF9800),
              children: [
                _buildAdvancedNumberField(
                  _biaSkeletalMuscleMassCtrl, 
                  "Skeletal Muscle Mass", 
                  icon: Icons.fitness_center, 
                  suffixText: "kg",
                  gradientColors: [Colors.red.shade400, Colors.red.shade600],
                ),
                _buildAdvancedNumberField(
                  _biaBodyFatKgCtrl, 
                  "Body Fat Mass", 
                  icon: Icons.water_drop, 
                  suffixText: "kg",
                  gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
                _buildAdvancedNumberField(
                  _biaVisceralFatLevelCtrl, 
                  "Visceral Fat Level", 
                  icon: Icons.favorite, 
                  suffixText: "level",
                  gradientColors: [Colors.pink.shade400, Colors.pink.shade600],
                ),
              ],
            ),

            _buildAdvancedSectionCard(
              title: "Metabolic & Goals",
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFF44336),
              children: [
                _buildAdvancedNumberField(
                  _biaBasalMetabolicRateCtrl, 
                  "Basal Metabolic Rate", 
                  icon: Icons.local_fire_department, 
                  suffixText: "kcal",
                  gradientColors: [Colors.deepOrange.shade400, Colors.deepOrange.shade600],
                ),
                _buildAdvancedNumberField(
                  _biaWaistHipRatioCtrl, 
                  "Waist-Hip Ratio", 
                  icon: Icons.straighten, 
                  suffixText: "ratio",
                  gradientColors: [Colors.teal.shade400, Colors.teal.shade600],
                ),
                _buildAdvancedNumberField(
                  _biaTargetWeightCtrl, 
                  "Target Weight", 
                  icon: Icons.flag, 
                  suffixText: "kg",
                  gradientColors: [Colors.indigo.shade400, Colors.indigo.shade600],
                ),
              ],
            ),

            const SizedBox(height: 32),
            
            // Ultra-Modern Save Button with Advanced Effects
            _buildUltraModernSaveButton(
              onPressed: () => _onSaveBIA(gender, age),
              label: "Save BIA Analysis",
              icon: Icons.save,
            ),
          ],
        ),
    );
  }

  Future<void> _onSaveBIA(String gender, double age) async {
    try {
      final h = double.tryParse(_biaHeightCtrl.text) ?? 0;
      final w = double.tryParse(_biaWeightCtrl.text) ?? 0;
      final record = <String, dynamic>{
        'type': 'BIA',
        'timestamp': Timestamp.now(),
        'ptId': FirebaseAuth.instance.currentUser?.uid,
        'heightInCm': h,
        'weightInKg': w,
        'skeletalMuscleMassKg':
            double.tryParse(_biaSkeletalMuscleMassCtrl.text) ?? 0,
        'bodyFatKg': double.tryParse(_biaBodyFatKgCtrl.text) ?? 0,
        'basalMetabolicRate':
            double.tryParse(_biaBasalMetabolicRateCtrl.text) ?? 0,
        'waistHipRatio': double.tryParse(_biaWaistHipRatioCtrl.text) ?? 0,
        'visceralFatLevel': double.tryParse(_biaVisceralFatLevelCtrl.text) ?? 0,
        'targetWeight': double.tryParse(_biaTargetWeightCtrl.text) ?? 0,
      };

      // BMI
      double typedBMI = double.tryParse(_biaBMICtrl.text) ?? 0;
      if (typedBMI == 0) {
        typedBMI = _computeBMI(w, h);
      }
      record['BMI'] = typedBMI;

      // For example, compute isyScore from BMI + a guessed BF% if you want
      // If BIA device provides BF% separately, do that. Or skip.
      double guessedBFPercent = 20.0; // or from bodyFatKg
      double isyScore = _computeIsyScore(
        bmi: typedBMI,
        bodyFatPercent: guessedBFPercent,
        age: age,
      );
      record['isyScore'] = isyScore;

      await _recordsCollection.add(record);

      showSuccessSnackBar(context, "BIA inserted successfully.");
      _clearBIAFields();
    } catch (e) {
      showErrorSnackBar(context, "Error: $e");
    }
  }

  void _clearBIAFields() {
    _biaHeightCtrl.clear();
    _biaWeightCtrl.clear();
    _biaSkeletalMuscleMassCtrl.clear();
    _biaBodyFatKgCtrl.clear();
    _biaBMICtrl.clear();
    _biaBasalMetabolicRateCtrl.clear();
    _biaWaistHipRatioCtrl.clear();
    _biaVisceralFatLevelCtrl.clear();
    _biaTargetWeightCtrl.clear();
  }

  // ---------------------------------------------------------------------------
  // USArmy Tab
  // ---------------------------------------------------------------------------
  Widget _buildUSArmyForm(BuildContext context, String gender, double age) {
    final isFemale = gender.toLowerCase().startsWith('f');
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
          children: [
            // Hero Header with Military Theme
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF1B5E20),
                    const Color(0xFF2E7D32),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1B5E20).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.military_tech, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "U.S. Army Method",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Circumference-based body fat calculation",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Advanced Sections
            _buildAdvancedSectionCard(
              title: "Basic Measurements",
              icon: Icons.straighten,
              iconColor: const Color(0xFF2196F3),
              children: [
                _buildAdvancedNumberField(
                  _armyHeightCtrl, 
                  "Height", 
                  icon: Icons.height, 
                  suffixText: "cm",
                  gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
                ),
                _buildAdvancedNumberField(
                  _armyNeckCtrl, 
                  "Neck Circumference", 
                  icon: Icons.accessibility, 
                  suffixText: "cm",
                  gradientColors: [Colors.cyan.shade400, Colors.cyan.shade600],
                ),
              ],
            ),

            _buildAdvancedSectionCard(
              title: isFemale ? "Body Circumferences (Female)" : "Body Circumferences (Male)",
              icon: Icons.straighten,
              iconColor: isFemale ? const Color(0xFFE91E63) : const Color(0xFF3F51B5),
              children: [
                _buildAdvancedNumberField(
                  _armyWaistCtrl, 
                  "Waist Circumference", 
                  icon: Icons.crop_free, 
                  suffixText: "cm",
                  gradientColors: isFemale 
                    ? [Colors.pink.shade400, Colors.pink.shade600]
                    : [Colors.indigo.shade400, Colors.indigo.shade600],
                ),
                if (isFemale)
                  _buildAdvancedNumberField(
                    _armyHipsCtrl, 
                    "Hip Circumference", 
                    icon: Icons.crop_free, 
                    suffixText: "cm",
                    gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
                  ),
              ],
            ),

            _buildAdvancedSectionCard(
              title: "Morphological Analysis",
              icon: Icons.analytics,
              iconColor: const Color(0xFFFF9800),
              children: [
                _buildAdvancedNumberField(
                  _armyWristCtrl, 
                  "Wrist Circumference", 
                  icon: Icons.watch, 
                  suffixText: "cm",
                  gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                ),
              ],
            ),

            const SizedBox(height: 32),
            
            _buildUltraModernSaveButton(
              onPressed: () => _onSaveUSArmy(gender, age),
              label: "Save U.S. Army Analysis",
              icon: Icons.save,
            ),
          ],
        ),
    );
  }

  Future<void> _onSaveUSArmy(String gender, double age) async {
    try {
      final h = double.tryParse(_armyHeightCtrl.text) ?? 0;
      final n = double.tryParse(_armyNeckCtrl.text) ?? 0;
      final w = double.tryParse(_armyWaistCtrl.text) ?? 0;
      final hips = double.tryParse(_armyHipsCtrl.text) ?? 0;
      final wr = double.tryParse(_armyWristCtrl.text) ?? 0;

      final bf = _calcBodyFatUSArmy(
        gender: gender,
        heightCm: h,
        neckCm: n,
        waistCm: w,
        hipsCm: (gender.toLowerCase().startsWith('f')) ? hips : null,
      );

      final record = <String, dynamic>{
        'type': 'USArmy',
        'timestamp': Timestamp.now(),
        'ptId': FirebaseAuth.instance.currentUser?.uid,
        'heightInCm': h,
        'neck': n,
        'waist': w,
        if (gender.toLowerCase().startsWith('f')) 'hips': hips,
        'wrist': wr,
        'usArmyBodyFatPercent': bf,
        // etc. Possibly morphology or idealWeight
      };

      // Example isyScore
      double guessedBMI = 25.0; // we don't have weight?
      double isyScore = _computeIsyScore(
        bmi: guessedBMI,
        bodyFatPercent: bf,
        age: age,
      );
      record['isyScore'] = isyScore;

      await _recordsCollection.add(record);

      showSuccessSnackBar(context, "U.S. Army inserted successfully.");
      _clearUSArmyFields();
    } catch (e) {
      showErrorSnackBar(context, "Error: $e");
    }
  }

  void _clearUSArmyFields() {
    _armyHeightCtrl.clear();
    _armyNeckCtrl.clear();
    _armyWaistCtrl.clear();
    _armyHipsCtrl.clear();
    _armyWristCtrl.clear();
  }

  // ---------------------------------------------------------------------------
  // Plicometro Tab
  // ---------------------------------------------------------------------------
  Widget _buildPlicForm(BuildContext context, String gender, double age) {
    final isMale = gender.toLowerCase().startsWith('m');
    return SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Header with Scientific Theme
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6A1B9A),
                    const Color(0xFF8E24AA),
                  ],
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6A1B9A).withOpacity(0.4),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.1),
                        Colors.white.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.white.withOpacity(0.3)),
                        ),
                        child: const Icon(Icons.straighten, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Plicometer Analysis",
                              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Skinfold thickness measurements",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.white.withOpacity(0.9),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Interactive Method Info Card
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    Colors.white.withOpacity(0.95),
                    Colors.white.withOpacity(0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  width: 1,
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      setState(() => _showPlicHelp = !_showPlicHelp);
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      Theme.of(context).colorScheme.primary,
                                      Theme.of(context).colorScheme.primary.withOpacity(0.7),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                      blurRadius: 8,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: const Icon(Icons.info_outline, color: Colors.white, size: 20),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  isMale
                                      ? "3-Site Method (Male): Chest, Abdomen, Thigh"
                                      : "3-Site Method (Female): Triceps, Suprailiac, Thigh",
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    color: Theme.of(context).colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                              AnimatedRotation(
                                turns: _showPlicHelp ? 0.5 : 0,
                                duration: const Duration(milliseconds: 300),
                                child: Icon(
                                  Icons.expand_more,
                                  color: Theme.of(context).colorScheme.primary,
                                  size: 24,
                                ),
                              ),
                            ],
                          ),
                          AnimatedSize(
                            duration: const Duration(milliseconds: 300),
                            child: _showPlicHelp
                                ? Column(
                                    children: [
                                      const SizedBox(height: 20),
                                      Container(
                                        padding: const EdgeInsets.all(16),
                                        decoration: BoxDecoration(
                                          color: Theme.of(context).colorScheme.primary.withOpacity(0.05),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(
                                            color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                                          ),
                                        ),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "📏 Measurement Guide:",
                                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                                fontWeight: FontWeight.bold,
                                                color: Theme.of(context).colorScheme.primary,
                                              ),
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              isMale
                                                  ? "• Chest: Diagonal fold halfway between nipple and shoulder crease\n"
                                                      "• Abdomen: Vertical fold 2cm to the right of the umbilicus\n"
                                                      "• Thigh: Vertical fold on the front of the thigh midway between hip and knee"
                                                  : "• Triceps: Vertical fold on the back of the upper arm\n"
                                                      "• Suprailiac: Diagonal fold above the crest of the ilium\n"
                                                      "• Thigh: Vertical fold on the front of the thigh midway between hip and knee",
                                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                color: Theme.of(context).colorScheme.primary,
                                                height: 1.6,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Measurements Section
            _buildAdvancedSectionCard(
              title: isMale ? "Male Sites (3-Point Method)" : "Female Sites (3-Point Method)",
              icon: Icons.straighten,
              iconColor: isMale ? const Color(0xFF1976D2) : const Color(0xFFE91E63),
              children: [
                if (isMale) ...[
                  _buildAdvancedNumberField(
                    _plicChestCtrl, 
                    "Chest", 
                    icon: Icons.favorite, 
                    suffixText: "mm",
                    gradientColors: [Colors.red.shade400, Colors.red.shade600],
                  ),
                  _buildAdvancedNumberField(
                    _plicAbdomenCtrl, 
                    "Abdomen", 
                    icon: Icons.crop_free, 
                    suffixText: "mm",
                    gradientColors: [Colors.orange.shade400, Colors.orange.shade600],
                  ),
                  _buildAdvancedNumberField(
                    _plicThighCtrl, 
                    "Thigh", 
                    icon: Icons.accessibility, 
                    suffixText: "mm",
                    gradientColors: [Colors.blue.shade400, Colors.blue.shade600],
                  ),
                ] else ...[
                  _buildAdvancedNumberField(
                    _plicTricepsCtrl, 
                    "Triceps", 
                    icon: Icons.fitness_center, 
                    suffixText: "mm",
                    gradientColors: [Colors.pink.shade400, Colors.pink.shade600],
                  ),
                  _buildAdvancedNumberField(
                    _plicSuprailiacCtrl, 
                    "Suprailiac", 
                    icon: Icons.crop_free, 
                    suffixText: "mm",
                    gradientColors: [Colors.purple.shade400, Colors.purple.shade600],
                  ),
                  _buildAdvancedNumberField(
                    _plicThighCtrl, 
                    "Thigh", 
                    icon: Icons.accessibility, 
                    suffixText: "mm",
                    gradientColors: [Colors.indigo.shade400, Colors.indigo.shade600],
                  ),
                ],
              ],
            ),

            const SizedBox(height: 32),
            
            _buildUltraModernSaveButton(
              onPressed: () => _onSavePlic(gender, age),
              label: "Save Plicometer Analysis",
              icon: Icons.save,
            ),
          ],
        ),
    );
  }

  Future<void> _onSavePlic(String gender, double age) async {
    try {
      final isMale = gender.toLowerCase().startsWith('m');
      double bf = 0;
      final record = <String, dynamic>{
        'type': 'Plicometro',
        'timestamp': Timestamp.now(),
        'ptId': FirebaseAuth.instance.currentUser?.uid,
      };

      if (isMale) {
        final chest = double.tryParse(_plicChestCtrl.text) ?? 0;
        final abd = double.tryParse(_plicAbdomenCtrl.text) ?? 0;
        final thigh = double.tryParse(_plicThighCtrl.text) ?? 0;
        record['chestplic'] = chest;
        record['abdominalPlic'] = abd;
        record['thighPlic'] = thigh;

        final sum = chest + abd + thigh;
        bf = _calcBodyFatPlic(sum, age);
        record['plicBodyFatPercent'] = bf;
      } else {
        final tri = double.tryParse(_plicTricepsCtrl.text) ?? 0;
        final sup = double.tryParse(_plicSuprailiacCtrl.text) ?? 0;
        final th = double.tryParse(_plicThighCtrl.text) ?? 0;
        record['tricepsPlic'] = tri;
        record['suprailiapplic'] = sup;
        record['thighPlic'] = th;

        final sum = tri + sup + th;
        bf = _calcBodyFatPlic(sum, age);
        record['plicBodyFatPercent'] = bf;
      }

      // Example isyScore
      double guessedBMI = 25.0;
      double isyScore = _computeIsyScore(
        bmi: guessedBMI,
        bodyFatPercent: bf,
        age: age,
      );
      record['isyScore'] = isyScore;

      await _recordsCollection.add(record);

      showSuccessSnackBar(context, "Plicometro inserted successfully.");
      _clearPlicFields();
    } catch (e) {
      showErrorSnackBar(context, "Error: $e");
    }
  }

  void _clearPlicFields() {
    _plicChestCtrl.clear();
    _plicAbdomenCtrl.clear();
    _plicThighCtrl.clear();
    _plicTricepsCtrl.clear();
    _plicSuprailiacCtrl.clear();
  }

  /// Advanced Section Card with Modern Glassmorphism Design
  Widget _buildAdvancedSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
    Color? iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white.withOpacity(0.7),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.8),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.white.withOpacity(0.3),
              width: 1.5,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            iconColor?.withOpacity(0.8) ?? Theme.of(context).colorScheme.primary.withOpacity(0.8),
                            iconColor ?? Theme.of(context).colorScheme.primary,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: (iconColor ?? Theme.of(context).colorScheme.primary).withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...children,
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Ultra-Modern Number Field with Gradient Accents
  Widget _buildAdvancedNumberField(
    TextEditingController controller, 
    String label, {
    IconData? icon, 
    String? suffixText,
    List<Color>? gradientColors,
  }) {
    final colors = gradientColors ?? [
      Theme.of(context).colorScheme.primary,
      Theme.of(context).colorScheme.primary.withOpacity(0.7),
    ];
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [
              colors.first.withOpacity(0.05),
              colors.last.withOpacity(0.02),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: colors.first.withOpacity(0.2),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: colors.first.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: TextFormField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            fontWeight: FontWeight.w500,
          ),
          decoration: InputDecoration(
            labelText: label,
            prefixIcon: icon != null 
              ? Container(
                  margin: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: colors),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, color: Colors.white, size: 20),
                )
              : null,
            suffixText: suffixText,
            suffixStyle: TextStyle(
              color: colors.first,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: colors.first, width: 2),
            ),
            filled: false,
            labelStyle: TextStyle(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          ),
        ),
      ),
    );
  }

  /// Ultra-Modern Save Button with Advanced Animation Effects
  Widget _buildUltraModernSaveButton({
    required VoidCallback onPressed,
    required String label,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 10),
            spreadRadius: 2,
          ),
          BoxShadow(
            color: Colors.white.withOpacity(0.9),
            blurRadius: 20,
            offset: const Offset(0, -5),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          decoration: BoxDecoration(
            gradient: AppGradients.primary(Theme.of(context)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onPressed,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.1),
                      Colors.transparent,
                      Colors.black.withOpacity(0.05),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
