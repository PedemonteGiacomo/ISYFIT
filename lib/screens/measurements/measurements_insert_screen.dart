import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:isyfit/widgets/measurement_type_tab_bar_widget.dart'; // <<-- Import the new widget

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
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final data = doc.data() ?? {};
    return data['gender'] ?? 'Unknown';
  }

  Future<double> _fetchAge() async {
    final uid = widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return 30;
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
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
      final denominator = (1.0324 -
          0.19077 * ln(waistCm - neckCm) +
          0.15456 * ln(heightCm));
      return numerator / denominator - 450.0;
    }
  }

  double _calcBodyFatPlic(double sumOfPlic, double age) {
    final density = 1.109380
        - 0.0008267 * sumOfPlic
        + 0.0000016 * sumOfPlic * sumOfPlic
        - 0.0002574 * age;
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Insert BIA Measurements",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildNumberField(_biaHeightCtrl, "Height (cm) *"),
          _buildNumberField(_biaWeightCtrl, "Weight (kg) *"),
          _buildNumberField(_biaSkeletalMuscleMassCtrl, "Skeletal Muscle Mass (kg)"),
          _buildNumberField(_biaBodyFatKgCtrl, "Body Fat (kg)"),
          _buildNumberField(_biaBMICtrl, "BMI (optional; can auto-compute)"),
          _buildNumberField(_biaBasalMetabolicRateCtrl, "Basal Metabolic Rate (kcal)"),
          _buildNumberField(_biaWaistHipRatioCtrl, "Waist-Hip Ratio"),
          _buildNumberField(_biaVisceralFatLevelCtrl, "Visceral Fat Level"),
          _buildNumberField(_biaTargetWeightCtrl, "Target Weight"),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onSaveBIA(gender, age),
            icon: const Icon(Icons.save),
            label: const Text("Save BIA"),
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
        'visceralFatLevel':
            double.tryParse(_biaVisceralFatLevelCtrl.text) ?? 0,
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("BIA inserted successfully.")),
      );
      _clearBIAFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const Text("Insert U.S. Army Measurements",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildNumberField(_armyHeightCtrl, "Height (cm) *"),
          _buildNumberField(_armyNeckCtrl, "Neck (cm) *"),
          _buildNumberField(_armyWaistCtrl, "Waist (cm) *"),
          if (isFemale) _buildNumberField(_armyHipsCtrl, "Hips (cm) (female) *"),
          _buildNumberField(_armyWristCtrl, "Wrist (cm) (morphology)"),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onSaveUSArmy(gender, age),
            icon: const Icon(Icons.save),
            label: const Text("Save U.S. Army"),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("U.S. Army inserted successfully.")),
      );
      _clearUSArmyFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
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
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Insert Plicometro Measurements",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          Row(
            children: [
              const Text("Sites (3-site method)"),
              IconButton(
                icon: const Icon(Icons.help_outline),
                onPressed: () {
                  setState(() => _showPlicHelp = !_showPlicHelp);
                },
              ),
            ],
          ),
          if (_showPlicHelp)
            Container(
              padding: const EdgeInsets.all(8),
              color: Colors.grey.shade200,
              child: Text(
                isMale
                    ? "Men usually measure: Chest, Abdomen, Thigh."
                    : "Women usually measure: Triceps, Suprailiac, Thigh.",
              ),
            ),
          const SizedBox(height: 8),
          if (isMale) ...[
            _buildNumberField(_plicChestCtrl, "Chest (mm)"),
            _buildNumberField(_plicAbdomenCtrl, "Abdomen (mm)"),
            _buildNumberField(_plicThighCtrl, "Thigh (mm)"),
          ] else ...[
            _buildNumberField(_plicTricepsCtrl, "Triceps (mm)"),
            _buildNumberField(_plicSuprailiacCtrl, "Suprailiac (mm)"),
            _buildNumberField(_plicThighCtrl, "Thigh (mm)"),
          ],
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _onSavePlic(gender, age),
            icon: const Icon(Icons.save),
            label: const Text("Save Plicometer"),
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Plicometro inserted successfully.")),
      );
      _clearPlicFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _clearPlicFields() {
    _plicChestCtrl.clear();
    _plicAbdomenCtrl.clear();
    _plicThighCtrl.clear();
    _plicTricepsCtrl.clear();
    _plicSuprailiacCtrl.clear();
  }

  Widget _buildNumberField(TextEditingController controller, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
