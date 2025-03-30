import 'dart:math';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// A map containing short descriptions of each measurement type (optional).
final Map<String, String> measurementTypeInfo = {
  'BIA': 'BIA (Bioelectrical Impedance Analysis). This method uses electrical impedance...',
  'USArmy': 'U.S. Army formula using circumference + height to estimate bodyfat...',
  'Plicometro': 'Skinfold caliper on multiple sites (see your PDF for details).',
};

/// This can show an image for each type to help the user measure.
final Map<String, String> measurementTypeImage = {
  'BIA': 'assets/images/bia_info.png',
  'USArmy': 'assets/images/usarmy_info.png',
  'Plicometro': 'assets/images/plicometro_info.png',
};

class MeasurementsInsertScreen extends StatefulWidget {
  final String? clientUid;
  const MeasurementsInsertScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<MeasurementsInsertScreen> createState() =>
      _MeasurementsInsertScreenState();
}

class _MeasurementsInsertScreenState extends State<MeasurementsInsertScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedMeasurementType = '';

  // ---------------------------------------------------------------------------
  // BIA fields
  // ---------------------------------------------------------------------------
  final _biaHeightCtrl = TextEditingController(); // cm
  final _biaWeightCtrl = TextEditingController(); // kg
  final _biaSkeletalMuscleMassCtrl = TextEditingController(); 
  final _biaBodyFatKgCtrl = TextEditingController(); 
  final _biaBMICtrl = TextEditingController(); 
  final _biaBasalMetabolicRateCtrl = TextEditingController(); 
  final _biaWaistHipRatioCtrl = TextEditingController(); 
  final _biaVisceralFatLevelCtrl = TextEditingController(); 
  final _biaTargetWeightCtrl = TextEditingController(); 

  // ---------------------------------------------------------------------------
  // U.S. Army fields
  // ---------------------------------------------------------------------------
  final _armyHeightCtrl = TextEditingController(); // cm
  final _armyNeckCtrl = TextEditingController();   // cm
  final _armyWaistCtrl = TextEditingController();  // cm
  final _armyHipsCtrl = TextEditingController();   // cm (for female)
  final _armyWristCtrl = TextEditingController();  // morphology

  // ---------------------------------------------------------------------------
  // Plicometro fields (male/female sets)
  // ---------------------------------------------------------------------------
  final _plicChestCtrl = TextEditingController();       // mm (male)
  final _plicAbdomenCtrl = TextEditingController();     // mm (male)
  final _plicThighCtrl = TextEditingController();       // mm (male & female)
  final _plicTricepsCtrl = TextEditingController();     // mm (female)
  final _plicSuprailiacCtrl = TextEditingController();  // mm (female)

  bool _showPlicHelp = false;

  late Future<String> _genderFuture;
  late Future<double> _ageFuture;

  @override
  void initState() {
    super.initState();
    _genderFuture = _fetchGender();
    _ageFuture = _fetchAge();
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
    if (data['dateOfBirth'] == null) return 30; // fallback
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

  // ---------------------------------------------------------------------------
  // Helper formulas for bodyfat, BMI, etc. (same as your older code)
  // ---------------------------------------------------------------------------
  double _calcBodyFatPlic(double sumOfPlic, double age) {
    final density = 1.109380
        - 0.0008267 * sumOfPlic
        + 0.0000016 * sumOfPlic * sumOfPlic
        - 0.0002574 * age;
    return (495 / density) - 450;
  }

  double _calcBodyFatUSArmy({
    required String gender,
    required double heightCm,
    required double neckCm,
    required double waistCm,
    double? hipsCm,
  }) {
    final ln = log;
    if (gender.toLowerCase().startsWith('f')) {
      if (hipsCm == null) return 0;
      final numerator = 495.0;
      final denominator = (1.29579 -
          0.35004 * ln(waistCm + hipsCm - neckCm) +
          0.22100 * ln(heightCm));
      return numerator / denominator - 450.0;
    } else {
      final numerator = 495.0;
      final denominator = (1.0324 - 0.19077 * ln(waistCm - neckCm)
          + 0.15456 * ln(heightCm));
      return numerator / denominator - 450.0;
    }
  }

  double _computeBMI(double weightKg, double heightCm) {
    final heightM = heightCm / 100.0;
    if (heightM <= 0) return 0;
    return weightKg / (heightM * heightM);
  }

  String _classifyBMI(String gender, double bmi, double age) {
    // Very simplified approach
    if (bmi < 16) return 'Severely Underweight';
    if (bmi < 18.5) return 'Underweight';
    if (bmi < 25) return 'Normal';
    if (bmi < 30) return 'Overweight';
    return 'Obese';
  }

  String _classifyWHR(String gender, double whr, double age) {
    // Very simplified approach
    if (gender.toLowerCase().startsWith('m')) {
      if (whr < 0.94) return 'Low risk (Gynoid)';
      if (whr < 1.00) return 'Moderate risk (Intermediate)';
      return 'High risk (Android)';
    } else {
      if (whr < 0.78) return 'Low risk (Gynoid)';
      if (whr < 0.84) return 'Moderate risk (Intermediate)';
      return 'High risk (Android)';
    }
  }

  // Morphology
  String _classifyMorphology(String gender, double statureCm, double wristCm) {
    final ratio = statureCm / wristCm;
    if (gender.toLowerCase().startsWith('m')) {
      if (ratio > 10.4) return 'Longilineo';
      if (ratio >= 9.6) return 'Normolineo';
      return 'Brevilineo';
    } else {
      if (ratio > 10.9) return 'Longilinea';
      if (ratio >= 9.9) return 'Normolinea';
      return 'Brevilinea';
    }
  }

  double _computeIdealWeight(String gender, double statureM, double wristCm) {
    if (gender.toLowerCase().startsWith('m')) {
      if (wristCm > 20) {
        return 75 * statureM - 58.5;
      } else if (wristCm >= 16) {
        return 75 * statureM - 63.5;
      } else {
        return 75 * statureM - 69.0;
      }
    } else {
      // female
      if (wristCm > 18) {
        return 68 * statureM - 51.5;
      } else if (wristCm >= 14) {
        return 68 * statureM - 58.0;
      } else {
        return 68 * statureM - 61.0;
      }
    }
  }

  // ---------------------------------------------------------------------------
  // A mock "IsyScore" formula. Adjust to your real logic as needed.
  // Example: 100 points baseline, -0.5 * BMI difference from 22, - BF% ...
  // ---------------------------------------------------------------------------
  double _computeIsyScore({
    required double bmi,
    required double bodyFatPercent,
    required double age,
  }) {
    // This is purely an example formula.
    // You might do something more elaborate.
    double score = 100.0;
    // penalize if BMI strays from 22
    final diffFrom22 = (bmi - 22.0).abs();
    score -= diffFrom22 * 1.5;
    // penalize body fat
    score -= bodyFatPercent * 0.5;
    // slight penalty if older (just as example)
    if (age > 40) {
      score -= (age - 40) * 0.2;
    }
    // clamp
    if (score < 0) score = 0;
    if (score > 100) score = 100;
    return score;
  }

  // ---------------------------------------------------------------------------
  // UI
  // ---------------------------------------------------------------------------
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

        return Container(
          // decoration: BoxDecoration(
          //   gradient: LinearGradient(
          //     colors: [
          //       Colors.blueGrey.shade50,
          //       Colors.blueGrey.shade100,
          //     ],
          //     begin: Alignment.topLeft,
          //     end: Alignment.bottomRight,
          //   ),
          // ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildMeasurementTypeSelector(),
                const SizedBox(height: 16),
                if (_selectedMeasurementType.isEmpty)
                  _buildNoSelectionView()
                else
                  _buildFormFields(context, gender, age),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<Map<String, dynamic>> _loadGenderAge() async {
    final g = await _genderFuture;
    final a = await _ageFuture;
    return {'gender': g, 'age': a};
  }

  Widget _buildMeasurementTypeSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildTypeButton('BIA', Icons.biotech, Colors.indigo),
        _buildTypeButton('USArmy', Icons.military_tech, Colors.green),
        _buildTypeButton('Plicometro', Icons.content_cut, Colors.red),
      ],
    );
  }

  Widget _buildTypeButton(String type, IconData icon, Color color) {
    final bool isSelected = (_selectedMeasurementType == type);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.6),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        type,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () => setState(() => _selectedMeasurementType = type),
    );
  }

  Widget _buildNoSelectionView() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          "Select a measurement type above to begin.",
          style: TextStyle(color: Colors.grey.shade700),
        ),
      ),
    );
  }

  Widget _buildFormFields(BuildContext context, String gender, double age) {
    final description = measurementTypeInfo[_selectedMeasurementType] ?? '';
    final imagePath = measurementTypeImage[_selectedMeasurementType];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + info icon
        Row(
          children: [
            Text(
              '$_selectedMeasurementType Insert',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () {
                _showMeasurementInfoDialog(context, imagePath, description);
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Actual fields
        if (_selectedMeasurementType == 'BIA') _buildBIAFields(),
        if (_selectedMeasurementType == 'USArmy') _buildUSArmyFields(gender),
        if (_selectedMeasurementType == 'Plicometro')
          _buildPlicFields(gender, age),

        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: () => _onSavePressed(gender, age),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
          ),
          child: const Text("Save"),
        ),
      ],
    );
  }

  void _showMeasurementInfoDialog(
    BuildContext context,
    String? imagePath,
    String description,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(_selectedMeasurementType),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (imagePath != null)
                Image.asset(imagePath, fit: BoxFit.contain),
              const SizedBox(height: 16),
              Text(description),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Widget _buildBIAFields() {
    return Column(
      children: [
        _buildNumberField(_biaHeightCtrl, "Height (cm) *Obbligatorio"),
        _buildNumberField(_biaWeightCtrl, "Weight (kg) *Obbligatorio"),
        _buildNumberField(_biaSkeletalMuscleMassCtrl,
            "Skeletal Muscle Mass (kg) (facoltativo)"),
        _buildNumberField(_biaBodyFatKgCtrl, "Body Fat (kg) (facoltativo)"),
        _buildNumberField(_biaBMICtrl,
            "BMI (facoltativo, can auto-compute from Height & Weight)"),
        _buildNumberField(_biaBasalMetabolicRateCtrl, "BMR (kcal) (facoltativo)"),
        _buildNumberField(_biaWaistHipRatioCtrl, "Waist-Hip Ratio (facoltativo)"),
        _buildNumberField(_biaVisceralFatLevelCtrl, "Visceral Fat Level (facoltativo)"),
        _buildNumberField(_biaTargetWeightCtrl, "Target Weight (facoltativo)"),
      ],
    );
  }

  Widget _buildUSArmyFields(String gender) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildNumberField(_armyHeightCtrl, "Height (cm) *Obbligatorio"),
        _buildNumberField(_armyNeckCtrl,   "Neck (cm) *Obbligatorio"),
        _buildNumberField(_armyWaistCtrl,  "Waist (cm) *Obbligatorio"),
        if (gender.toLowerCase().startsWith('f'))
          _buildNumberField(_armyHipsCtrl, "Hips (cm) *Obbligatorio (female)"),
        _buildNumberField(_armyWristCtrl,
            "Wrist (cm) (facoltativo, for morphology)"),
      ],
    );
  }

  Widget _buildPlicFields(String gender, double age) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text("Plicometer sites:"),
            IconButton(
              icon: const Icon(Icons.help_outline),
              onPressed: () => setState(() => _showPlicHelp = !_showPlicHelp),
            ),
          ],
        ),
        if (_showPlicHelp)
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade200,
            child: Text(
              (gender.toLowerCase().startsWith('m'))
                  ? "For men: Chest, Abdomen, Thigh (obbligatori for standard 3-site)."
                  : "For women: Triceps, Suprailiac, Thigh (obbligatori for standard 3-site).",
            ),
          ),
        if (gender.toLowerCase().startsWith('m')) ...[
          _buildNumberField(_plicChestCtrl,      "Chest (mm) *Obbligatorio"),
          _buildNumberField(_plicAbdomenCtrl,    "Abdomen (mm) *Obbligatorio"),
          _buildNumberField(_plicThighCtrl,      "Thigh (mm) *Obbligatorio"),
        ] else ...[
          _buildNumberField(_plicTricepsCtrl,    "Triceps (mm) *Obbligatorio"),
          _buildNumberField(_plicSuprailiacCtrl, "Suprailiac (mm) *Obbligatorio"),
          _buildNumberField(_plicThighCtrl,      "Thigh (mm) *Obbligatorio"),
        ],
      ],
    );
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

  // ---------------------------------------------------------------------------
  // On Save
  // ---------------------------------------------------------------------------
  Future<void> _onSavePressed(String gender, double age) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final record = <String, dynamic>{
      'type': _selectedMeasurementType,
      'timestamp': Timestamp.now(),
      'ptId': user.uid,
    };

    double? finalBodyFatPercent; // for isyScore

    try {
      if (_selectedMeasurementType == 'BIA') {
        final h = double.tryParse(_biaHeightCtrl.text) ?? 0;
        final w = double.tryParse(_biaWeightCtrl.text) ?? 0;
        record['heightInCm']   = h;
        record['weightInKg']   = w;
        record['skeletalMuscleMassKg'] =
            double.tryParse(_biaSkeletalMuscleMassCtrl.text) ?? 0;
        record['bodyFatKg']    = double.tryParse(_biaBodyFatKgCtrl.text) ?? 0;

        // BMI can be typed in or computed
        final maybeBmi = double.tryParse(_biaBMICtrl.text);
        double computedBMI = maybeBmi ?? _computeBMI(w, h);
        record['BMI'] = computedBMI;
        finalBodyFatPercent = null; // BIA device might give you BF% or BF kg

        record['basalMetabolicRate'] =
            double.tryParse(_biaBasalMetabolicRateCtrl.text) ?? 0;
        final whr = double.tryParse(_biaWaistHipRatioCtrl.text) ?? 0;
        record['waistHipRatio'] = whr;
        record['visceralFatLevel'] =
            double.tryParse(_biaVisceralFatLevelCtrl.text) ?? 0;
        record['targetWeight'] =
            double.tryParse(_biaTargetWeightCtrl.text) ?? 0;

        // If you want, you could compute or store classification for BMI, etc.
        record['bmiCategory'] = _classifyBMI(gender, computedBMI, age);
        record['whrCategory'] = _classifyWHR(gender, whr, age);
      }

      else if (_selectedMeasurementType == 'USArmy') {
        final h = double.tryParse(_armyHeightCtrl.text) ?? 0;
        final n = double.tryParse(_armyNeckCtrl.text)   ?? 0;
        final w = double.tryParse(_armyWaistCtrl.text)  ?? 0;
        final hips = double.tryParse(_armyHipsCtrl.text) ?? 0;
        final wr   = double.tryParse(_armyWristCtrl.text)?? 0;

        record['heightInCm'] = h;
        record['neck']       = n;
        record['waist']      = w;
        if (gender.toLowerCase().startsWith('f')) {
          record['hips'] = hips;
        }
        record['wrist']      = wr;

        double bf = _calcBodyFatUSArmy(
          gender: gender,
          heightCm: h,
          neckCm: n,
          waistCm: w,
          hipsCm: (gender.toLowerCase().startsWith('f')) ? hips : null,
        );
        record['usArmyBodyFatPercent'] = bf;
        finalBodyFatPercent = bf;

        final morph = _classifyMorphology(gender, h, wr);
        record['morphology'] = morph;

        final idealW = _computeIdealWeight(gender, h/100, wr);
        record['idealWeight'] = idealW;
      }

      else if (_selectedMeasurementType == 'Plicometro') {
        if (gender.toLowerCase().startsWith('m')) {
          final chest   = double.tryParse(_plicChestCtrl.text)   ?? 0;
          final abd     = double.tryParse(_plicAbdomenCtrl.text) ?? 0;
          final thigh   = double.tryParse(_plicThighCtrl.text)   ?? 0;
          record['chestplic']   = chest;
          record['abdominalPlic'] = abd;
          record['thighPlic']   = thigh;
          final sum = chest + abd + thigh;
          final plicBF = _calcBodyFatPlic(sum, age);
          record['plicBodyFatPercent'] = plicBF;
          finalBodyFatPercent = plicBF;
        } else {
          final tri   = double.tryParse(_plicTricepsCtrl.text)    ?? 0;
          final sup   = double.tryParse(_plicSuprailiacCtrl.text) ?? 0;
          final th    = double.tryParse(_plicThighCtrl.text)      ?? 0;
          record['tricepsPlic']    = tri;
          record['suprailiapplic'] = sup;
          record['thighPlic']      = th;
          final sum = tri + sup + th;
          final plicBF = _calcBodyFatPlic(sum, age);
          record['plicBodyFatPercent'] = plicBF;
          finalBodyFatPercent = plicBF;
        }
      }

      // --- Compute a mock BMI if possible for the isyScore formula ---
      double computedBMI = 0;
      if (_selectedMeasurementType == 'BIA') {
        computedBMI = record['BMI'] ?? 0;
      } else if (_selectedMeasurementType == 'USArmy') {
        final double? h = record['heightInCm'];
        if (h != null && h > 0) {
          // guess weight? user might not have it. We'll skip or do an assumption
          // If you want more accurate, you'd store weight from a different doc
          computedBMI = 25.0; 
        }
      } else if (_selectedMeasurementType == 'Plicometro') {
        // same problem: we might not have weight in plic. We'll skip or guess
        computedBMI = 25.0;
      }

      final double bfPercent = finalBodyFatPercent ?? 20.0;
      double isyScore = _computeIsyScore(
        bmi: computedBMI,
        bodyFatPercent: bfPercent,
        age: age,
      );
      record['isyScore'] = isyScore;

      await _recordsCollection.add(record);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Measurements saved successfully!")),
      );

      _clearFields();
      setState(() => _selectedMeasurementType = '');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  void _clearFields() {
    // BIA
    _biaHeightCtrl.clear();
    _biaWeightCtrl.clear();
    _biaSkeletalMuscleMassCtrl.clear();
    _biaBodyFatKgCtrl.clear();
    _biaBMICtrl.clear();
    _biaBasalMetabolicRateCtrl.clear();
    _biaWaistHipRatioCtrl.clear();
    _biaVisceralFatLevelCtrl.clear();
    _biaTargetWeightCtrl.clear();

    // US Army
    _armyHeightCtrl.clear();
    _armyNeckCtrl.clear();
    _armyWaistCtrl.clear();
    _armyHipsCtrl.clear();
    _armyWristCtrl.clear();

    // Plic
    _plicChestCtrl.clear();
    _plicAbdomenCtrl.clear();
    _plicThighCtrl.clear();
    _plicTricepsCtrl.clear();
    _plicSuprailiacCtrl.clear();
  }
}
