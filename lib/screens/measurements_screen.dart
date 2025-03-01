import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// For each measurement type, we show an info tooltip or description
final Map<String, String> measurementTypeInfo = {
  'BIA': 'BIA (Bioelectrical Impedance Analysis) helps estimate body composition, '
      'such as body fat and muscle mass, by sending a small electrical current.',
  'USArmy':
      'U.S. Army method uses circumferences (neck, waist, etc.) and height (in cm) to estimate body fat.',
  'DEXA':
      'DEXA (Dual-Energy X-ray Absorptiometry) is an imaging test measuring bone density and body fat distribution.',
  'Plicometro':
      'A plicometro (skinfold caliper) measures multiple skinfold sites (triceps, subscapular, etc.) to estimate total body fat.',
};

/// Submetric definitions & short descriptions
final Map<String, String> submetricInfo = {
  // BIA
  'heightInCm': 'Height in centimeters (needed if you want to compute BMI).',
  'weightInKg': 'Total body weight in kilograms (BIA).',
  'skeletalMuscleMassKg': 'Estimated lean (skeletal) muscle mass (kg).',
  'bodyFatKg': 'Estimated body fat mass (kg).',
  // 'bodyFatPercent': 'Percentage of total weight that is fat (if directly measured).',
  'BMI': 'BMI (Body Mass Index), ratio of weight to height (kg/m²).',
  'basalMetabolicRate':
      'Estimated calories burned at rest over 24 hours (kcal).',
  'waistHipRatio': 'Ratio of waist circumference to hip circumference.',
  'visceralFatLevel': 'Approximate level of visceral (internal) fat.',
  'targetWeight': 'Recommended target body weight (kg).',

  // US Army
  'heightInCm': 'Height in centimeters (needed for Army formula).',
  'neck': 'Neck circumference (cm).',
  'shoulders': 'Shoulders circumference (cm).',
  'chest': 'Chest circumference (cm).',
  'navel': 'Navel (mid-abdomen) circumference (cm).',
  'waist': 'Waist circumference (cm).',
  'glutes': 'Glutes/hip circumference (cm).',
  'rightArm': 'Right arm circumference (cm).',
  'leftArm': 'Left arm circumference (cm).',
  'rightLeg': 'Right leg circumference (cm).',
  'leftLeg': 'Left leg circumference (cm).',

  // DEXA
  'bodyFat': 'Body fat (%) from DEXA scan.',
  'boneDensity': 'Bone density measurement from the DEXA scan.',

  // Plicometro
  'pliche1': 'First skinfold thickness measurement (mm).',
  'pliche2': 'Second skinfold thickness measurement (mm).',
  'tricepsPlic': 'Triceps skinfold thickness (mm).',
  'subscapularPlic': 'Subscapular skinfold thickness (mm).',
  'suprailiacPlic': 'Suprailiac skinfold thickness (mm).',
  'thighPlic': 'Thigh skinfold thickness (mm).',
  'chestPlic': 'Chest skinfold thickness (mm).',
};

class MeasurementsScreen extends StatefulWidget {
  final String clientUid;
  const MeasurementsScreen({Key? key, required this.clientUid})
      : super(key: key);

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  /// Toggle: Insert vs Compare mode
  bool _isComparisonMode = false;

  /// Currently selected measurement type
  String _selectedMeasurementType = '';

  // BIA
  final _biaHeightCtrl = TextEditingController(); // If needed for BMI
  final _biaWeightCtrl = TextEditingController();
  final _biaSkeletalMuscleMassCtrl = TextEditingController();
  final _biaBodyFatKgCtrl = TextEditingController();
  // final _biaBodyFatPercentCtrl = TextEditingController();
  final _biaBMIctrl = TextEditingController();
  final _biaBasalMetabolicRateCtrl = TextEditingController();
  final _biaWaistHipRatioCtrl = TextEditingController();
  final _biaVisceralFatLevelCtrl = TextEditingController();
  final _biaTargetWeightCtrl = TextEditingController();

  // USArmy
  final _armyHeightCtrl = TextEditingController(); // Required for BF% formula
  final _armyNeckCtrl = TextEditingController();
  final _armyShouldersCtrl = TextEditingController();
  final _armyChestCtrl = TextEditingController();
  final _armyNavelCtrl = TextEditingController();
  final _armyWaistCtrl = TextEditingController();
  final _armyGlutesCtrl = TextEditingController();
  final _armyRightArmCtrl = TextEditingController();
  final _armyLeftArmCtrl = TextEditingController();
  final _armyRightLegCtrl = TextEditingController();
  final _armyLeftLegCtrl = TextEditingController();

  // DEXA
  final _dexaBodyFatCtrl = TextEditingController();
  final _dexaBoneDensityCtrl = TextEditingController();

  // Plicometro
  final _plico1Ctrl = TextEditingController();
  final _plico2Ctrl = TextEditingController();
  final _plicoTricepsCtrl = TextEditingController();
  final _plicoSubscapularCtrl = TextEditingController();
  final _plicoSuprailiacCtrl = TextEditingController();
  final _plicoThighCtrl = TextEditingController();
  final _plicoChestCtrl = TextEditingController();

  /// measurements/{clientUid}/records
  CollectionReference get _recordsCollection => FirebaseFirestore.instance
      .collection('measurements')
      .doc(widget.clientUid)
      .collection('records');

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(widget.clientUid)
              .get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData ||
                snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Measurements - Loading...");
            }
            if (!snapshot.data!.exists) {
              return Text("Measurements - ${widget.clientUid}");
            }
            final userDoc = snapshot.data!;
            final data = userDoc.data() as Map<String, dynamic>;
            final userName = data['name'] ?? 'Unknown';
            final userSurname = data['surname'] ?? 'Unknown';
            final userEmail = data['email'] ?? 'Unknown';
            return Text("Measurements - $userName $userSurname - $userEmail");
          },
        ),
        actions: [
          Row(
            children: [
              Text(_isComparisonMode ? 'Compare' : 'Insert'),
              Switch(
                value: _isComparisonMode,
                onChanged: (val) {
                  setState(() {
                    _isComparisonMode = val;
                    _selectedMeasurementType = '';
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: _isComparisonMode ? _buildComparisonMode() : _buildInsertMode(),
    );
  }

  // ------------------------------------------------------------------------
  // 1) INSERT MODE
  // ------------------------------------------------------------------------
  Widget _buildInsertMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildMeasurementTypeSelection(),
          const SizedBox(height: 16),
          if (_selectedMeasurementType.isEmpty) _buildNoMeasurementSelectedUI(),
          if (_selectedMeasurementType.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Inserting data for: $_selectedMeasurementType',
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () {
                    final info =
                        measurementTypeInfo[_selectedMeasurementType] ??
                            'No info available.';
                    _showInfoDialog(context, _selectedMeasurementType, info);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            _buildMeasurementForm(_selectedMeasurementType),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _saveMeasurementData,
              child: const Text('Save'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMeasurementTypeSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
            child: _buildColoredTypeButton(
                'BIA', Icons.biotech_sharp, Colors.indigo)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildColoredTypeButton(
                'USArmy', Icons.military_tech, Colors.green)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildColoredTypeButton(
                'DEXA', Icons.my_library_books, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildColoredTypeButton(
                'Plicometro', Icons.content_cut, Colors.redAccent)),
      ],
    );
  }

  Widget _buildColoredTypeButton(String type, IconData icon, Color color) {
    final bool isSelected = (_selectedMeasurementType == type);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        type,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        setState(() {
          _selectedMeasurementType = type;
        });
      },
    );
  }

  Widget _buildNoMeasurementSelectedUI() {
    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.info, color: Colors.blueGrey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Choose a measurement type above to insert or view metrics for this client. '
              'Each measurement type focuses on different aspects. Once a type is selected, '
              'a form to insert data will appear below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the insertion form for each measurement type
  Widget _buildMeasurementForm(String type) {
    switch (type) {
      case 'BIA':
        return Column(
          children: [
            _buildTextField(_biaHeightCtrl, 'Height (cm) *optional for BMI'),
            _buildTextField(_biaWeightCtrl, 'Weight (kg)'),
            _buildTextField(
                _biaSkeletalMuscleMassCtrl, 'Skeletal Muscle Mass (kg)'),
            _buildTextField(_biaBodyFatKgCtrl, 'Body Fat (kg)'),
            // _buildTextField(_biaBodyFatPercentCtrl, 'Body Fat (%)'),
            _buildTextField(_biaBMIctrl, 'BMI'),
            _buildTextField(_biaBasalMetabolicRateCtrl, 'Basal Metabolic Rate'),
            _buildTextField(_biaWaistHipRatioCtrl, 'Waist-Hip Ratio'),
            _buildTextField(_biaVisceralFatLevelCtrl, 'Visceral Fat Level'),
            _buildTextField(_biaTargetWeightCtrl, 'Target Weight'),
          ],
        );

      case 'USArmy':
        return Column(
          children: [
            _buildTextField(_armyHeightCtrl, 'Height (cm)'),
            _buildTextField(_armyNeckCtrl, 'Neck (cm)'),
            _buildTextField(_armyShouldersCtrl, 'Shoulders (cm)'),
            _buildTextField(_armyChestCtrl, 'Chest (cm)'),
            _buildTextField(_armyNavelCtrl, 'Navel (cm)'),
            _buildTextField(_armyWaistCtrl, 'Waist (cm)'),
            _buildTextField(_armyGlutesCtrl, 'Glutes (cm)'),
            _buildTextField(_armyRightArmCtrl, 'Right Arm (cm)'),
            _buildTextField(_armyLeftArmCtrl, 'Left Arm (cm)'),
            _buildTextField(_armyRightLegCtrl, 'Right Leg (cm)'),
            _buildTextField(_armyLeftLegCtrl, 'Left Leg (cm)'),
          ],
        );

      case 'DEXA':
        return Column(
          children: [
            _buildTextField(_dexaBodyFatCtrl, 'Body Fat (%)'),
            _buildTextField(_dexaBoneDensityCtrl, 'Bone Density'),
          ],
        );

      case 'Plicometro':
        // Standard: pliche1, pliche2 + extended sites
        return Column(
          children: [
            _buildTextField(_plico1Ctrl, 'Pliche #1 (mm)'),
            _buildTextField(_plico2Ctrl, 'Pliche #2 (mm)'),
            _buildTextField(_plicoTricepsCtrl, 'Triceps (mm)'),
            _buildTextField(_plicoSubscapularCtrl, 'Subscapular (mm)'),
            _buildTextField(_plicoSuprailiacCtrl, 'Suprailiac (mm)'),
            _buildTextField(_plicoThighCtrl, 'Thigh (mm)'),
            _buildTextField(_plicoChestCtrl, 'Chest (mm)'),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: TextField(
        controller: ctrl,
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
        ),
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // 2) COMPARISON (TABLE) MODE
  // ------------------------------------------------------------------------
  Widget _buildComparisonMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildComparisonTypeSelection(),
          const SizedBox(height: 16),
          if (_selectedMeasurementType.isEmpty)
            _buildNoMeasurementSelectedUI()
          else
            // Instead of stacking BF card above the table, we fetch docs ourselves:
            FutureBuilder<QuerySnapshot>(
              future: _recordsCollection
                  .where('type', isEqualTo: _selectedMeasurementType)
                  .orderBy('timestamp', descending: false)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  // No data => fill the row with the no-data card
                  return _buildNoDataCard(_selectedMeasurementType);
                }

                final docs = snapshot.data!.docs;
                // newest is docs.last
                final newestData = docs.last.data() as Map<String, dynamic>;
                final secondNewestData = docs.length > 1
                    ? docs[docs.length - 2].data() as Map<String, dynamic>
                    : null;

                // Build the BF% Card
                final bfCard = BFPercentageCard(
                  measurementType: _selectedMeasurementType,
                  latestData: newestData,
                  previousData: secondNewestData,
                );

                // Build the table
                final table = _buildComparisonTableWithDocs(
                  _selectedMeasurementType,
                  docs,
                );

                return LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 600;
                    if (isNarrow) {
                      // For narrow screens, stack BF card on top of table with a top margin
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: bfCard,
                          ),
                          const SizedBox(height: 16),
                          table,
                        ],
                      );
                    } else {
                      // For wide screens, place BF card to the left with a top margin
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(top: 12.0),
                            child: SizedBox(width: 280, child: bfCard),
                          ),
                          const SizedBox(width: 16),
                          Expanded(child: table),
                        ],
                      );
                    }
                  },
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildComparisonTypeSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
            child: _buildCompareTypeButton(
                'BIA', Icons.biotech_sharp, Colors.indigo)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildCompareTypeButton(
                'USArmy', Icons.military_tech, Colors.green)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildCompareTypeButton(
                'DEXA', Icons.my_library_books, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(
            child: _buildCompareTypeButton(
                'Plicometro', Icons.content_cut, Colors.redAccent)),
      ],
    );
  }

  Widget _buildCompareTypeButton(String type, IconData icon, Color color) {
    final bool isSelected = (_selectedMeasurementType == type);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        type,
        style:
            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        setState(() {
          _selectedMeasurementType = type;
        });
      },
    );
  }

  // Build the actual data table with docs
  Widget _buildComparisonTableWithDocs(
      String type, List<QueryDocumentSnapshot> docs) {
    // oldest -> newest
    final reversedDocs = docs.reversed.toList(); // newest -> oldest
    final newDocData = reversedDocs.isNotEmpty
        ? reversedDocs[0].data() as Map<String, dynamic>
        : null;
    final oldDocData = reversedDocs.length > 1
        ? reversedDocs[1].data() as Map<String, dynamic>
        : null;

    final submetrics = _getSubmetricsFor(type);

    // Build columns
    final columns = <DataColumn>[
      const DataColumn(label: Text('Measurement')),
      const DataColumn(label: Text('Trend')),
    ];
    for (final doc in reversedDocs) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = (data['timestamp'] as Timestamp).toDate();
      columns.add(DataColumn(label: Text(_formatDate(ts))));
    }

    // Build rows
    final rows = <DataRow>[];
    for (final sub in submetrics) {
      final cells = <DataCell>[];
      // sub name
      cells.add(DataCell(
          Text(sub, style: const TextStyle(fontWeight: FontWeight.bold))));
      // trend
      cells.add(DataCell(_buildTrendIcon(sub, newDocData, oldDocData)));
      // each doc
      for (final doc in reversedDocs) {
        final data = doc.data() as Map<String, dynamic>;
        final rawVal = data[sub.toLowerCase()] ?? data[sub];
        final valStr = rawVal?.toString() ?? '—';
        cells.add(DataCell(Text(valStr)));
      }
      rows.add(DataRow(cells: cells));
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: SizedBox(
        width: double.infinity,
        child: Card(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SingleChildScrollView(
              scrollDirection: Axis.vertical,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width - 32,
                ),
                child: DataTable(
                  columnSpacing: 24,
                  columns: columns,
                  rows: rows,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNoDataCard(String type) {
    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.info, color: Colors.blueGrey, size: 48),
            const SizedBox(height: 16),
            Text(
              'No data found for $type yet.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------------------
  // SAVE MEASUREMENT DATA
  // ------------------------------------------------------------------------
  Future<void> _saveMeasurementData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_selectedMeasurementType.isEmpty) return;

    final dataToSave = <String, dynamic>{
      'type': _selectedMeasurementType,
      'timestamp': Timestamp.now(),
      'ptId': user.uid,
    };

    switch (_selectedMeasurementType) {
      case 'BIA':
        dataToSave['heightincm'] = _biaHeightCtrl.text;
        dataToSave['weightinkg'] = _biaWeightCtrl.text;
        dataToSave['skeletalmusclemasskg'] = _biaSkeletalMuscleMassCtrl.text;
        dataToSave['bodyfatkg'] = _biaBodyFatKgCtrl.text;
        // dataToSave['bodyfatpercent'] = _biaBodyFatPercentCtrl.text;
        dataToSave['bmi'] = _biaBMIctrl.text;
        dataToSave['basalmetabolicrate'] = _biaBasalMetabolicRateCtrl.text;
        dataToSave['waisthipratio'] = _biaWaistHipRatioCtrl.text;
        dataToSave['visceralfatlevel'] = _biaVisceralFatLevelCtrl.text;
        dataToSave['targetweight'] = _biaTargetWeightCtrl.text;
        break;

      case 'USArmy':
        dataToSave['heightincm'] = _armyHeightCtrl.text;
        dataToSave['neck'] = _armyNeckCtrl.text;
        dataToSave['shoulders'] = _armyShouldersCtrl.text;
        dataToSave['chest'] = _armyChestCtrl.text;
        dataToSave['navel'] = _armyNavelCtrl.text;
        dataToSave['waist'] = _armyWaistCtrl.text;
        dataToSave['glutes'] = _armyGlutesCtrl.text;
        dataToSave['rightarm'] = _armyRightArmCtrl.text;
        dataToSave['leftarm'] = _armyLeftArmCtrl.text;
        dataToSave['rightleg'] = _armyRightLegCtrl.text;
        dataToSave['leftleg'] = _armyLeftLegCtrl.text;
        break;

      case 'DEXA':
        dataToSave['bodyfat'] = _dexaBodyFatCtrl.text;
        dataToSave['bonedensity'] = _dexaBoneDensityCtrl.text;
        break;

      case 'Plicometro':
        dataToSave['pliche1'] = _plico1Ctrl.text;
        dataToSave['pliche2'] = _plico2Ctrl.text;
        dataToSave['tricepsplic'] = _plicoTricepsCtrl.text;
        dataToSave['subscapularplic'] = _plicoSubscapularCtrl.text;
        dataToSave['suprailiapplic'] = _plicoSuprailiacCtrl.text;
        dataToSave['thighplic'] = _plicoThighCtrl.text;
        dataToSave['chestplic'] = _plicoChestCtrl.text;
        break;
    }

    try {
      await FirebaseFirestore.instance.runTransaction((transaction) async {
        // Add doc in a transaction for extra safety if desired
        final newDocRef = _recordsCollection.doc();
        transaction.set(newDocRef, dataToSave);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Measurement saved successfully!')),
      );
      _clearAllFields();
      setState(() {
        _selectedMeasurementType = '';
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving: $e')),
      );
    }
  }

  void _clearAllFields() {
    // BIA
    _biaHeightCtrl.clear();
    _biaWeightCtrl.clear();
    _biaSkeletalMuscleMassCtrl.clear();
    _biaBodyFatKgCtrl.clear();
    // _biaBodyFatPercentCtrl.clear();
    _biaBMIctrl.clear();
    _biaBasalMetabolicRateCtrl.clear();
    _biaWaistHipRatioCtrl.clear();
    _biaVisceralFatLevelCtrl.clear();
    _biaTargetWeightCtrl.clear();

    // USArmy
    _armyHeightCtrl.clear();
    _armyNeckCtrl.clear();
    _armyShouldersCtrl.clear();
    _armyChestCtrl.clear();
    _armyNavelCtrl.clear();
    _armyWaistCtrl.clear();
    _armyGlutesCtrl.clear();
    _armyRightArmCtrl.clear();
    _armyLeftArmCtrl.clear();
    _armyRightLegCtrl.clear();
    _armyLeftLegCtrl.clear();

    // DEXA
    _dexaBodyFatCtrl.clear();
    _dexaBoneDensityCtrl.clear();

    // Plicometro
    _plico1Ctrl.clear();
    _plico2Ctrl.clear();
    _plicoTricepsCtrl.clear();
    _plicoSubscapularCtrl.clear();
    _plicoSuprailiacCtrl.clear();
    _plicoThighCtrl.clear();
    _plicoChestCtrl.clear();
  }

  // ------------------------------------------------------------------------
  // INFO DIALOG
  // ------------------------------------------------------------------------
  void _showInfoDialog(BuildContext context, String title, String content) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(content),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // ------------------------------------------------------------------------
  // HELPER METHODS
  // ------------------------------------------------------------------------
  /// Return submetrics for each measurement type
  List<String> _getSubmetricsFor(String type) {
    switch (type) {
      case 'BIA':
        return [
          'heightInCm',
          'weightInKg',
          'skeletalMuscleMassKg',
          'bodyFatKg',
          // 'bodyFatPercent',
          'BMI',
          'basalMetabolicRate',
          'waistHipRatio',
          'visceralFatLevel',
          'targetWeight',
        ];
      case 'USArmy':
        return [
          'heightInCm',
          'neck',
          'shoulders',
          'chest',
          'navel',
          'waist',
          'glutes',
          'rightArm',
          'leftArm',
          'rightLeg',
          'leftLeg',
        ];
      case 'DEXA':
        return [
          'bodyFat',
          'boneDensity',
        ];
      case 'Plicometro':
        return [
          'pliche1',
          'pliche2',
          'tricepsPlic',
          'subscapularPlic',
          'suprailiapplic',
          'thighPlic',
          'chestplic',
        ];
      default:
        return [];
    }
  }

  /// Format date as dd/MM/yy
  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString().substring(2);
    return '$dd/$mm/$yy';
  }

  /// Trend icon for comparison
  Widget _buildTrendIcon(
      String sub, Map<String, dynamic>? newDoc, Map<String, dynamic>? oldDoc) {
    if (newDoc == null) {
      return const Text('–');
    }
    final newValRaw = newDoc[sub.toLowerCase()] ?? newDoc[sub];
    if (newValRaw == null) {
      return const Text('–');
    }
    final newVal = double.tryParse(newValRaw.toString());
    if (newVal == null) {
      return const Text('–');
    }
    if (oldDoc == null) {
      return const Text('–');
    }
    final oldValRaw = oldDoc[sub.toLowerCase()] ?? oldDoc[sub];
    if (oldValRaw == null) {
      return const Text('–');
    }
    final oldVal = double.tryParse(oldValRaw.toString());
    if (oldVal == null) {
      return const Text('–');
    }
    final diff = newVal - oldVal;
    if (diff > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.arrow_upward, color: Colors.red, size: 18),
          SizedBox(width: 2),
          Text('↑', style: TextStyle(color: Colors.red)),
        ],
      );
    } else if (diff < 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.arrow_downward, color: Colors.green, size: 18),
          SizedBox(width: 2),
          Text('↓', style: TextStyle(color: Colors.green)),
        ],
      );
    } else {
      return const Text('↔', style: TextStyle(color: Colors.grey));
    }
  }
}

/// A reusable card that calculates and displays BF% plus an arrow trend
class BFPercentageCard extends StatelessWidget {
  final String measurementType;
  final Map<String, dynamic> latestData;
  final Map<String, dynamic>? previousData;

  const BFPercentageCard({
    Key? key,
    required this.measurementType,
    required this.latestData,
    this.previousData,
  }) : super(key: key);

  // Calculate BF% for the newest data
  double? get currentBF => _calculateBF(measurementType, latestData);
  // Calculate BF% for the previous data
  double? get previousBF => previousData != null
      ? _calculateBF(measurementType, previousData!)
      : null;

  /// Compute BF% for each method:
  double? _calculateBF(String method, Map<String, dynamic> data) {
    switch (method) {
      case 'BIA':
        final w = double.tryParse(data['weightinkg']?.toString() ?? '');
        final bfKg = double.tryParse(data['bodyfatkg']?.toString() ?? '');
        if (w != null && w > 0 && bfKg != null) {
          return (bfKg / w) * 100;
        }
        // // Alternatively, if 'bodyFatPercent' is directly measured
        // final directBF = double.tryParse(data['bodyfatpercent']?.toString() ?? '');
        // if (directBF != null) {
        //   return directBF;
        // }
        break;
      case 'USArmy':
        // Simplified formula: BF% = 86.010 * log10(waist - neck) - 70.041 * log10(heightInCm) + 36.76
        final height = double.tryParse(data['heightincm']?.toString() ?? '');
        final waist = double.tryParse(data['waist']?.toString() ?? '');
        final neck = double.tryParse(data['neck']?.toString() ?? '');
        if (height != null &&
            height > 0 &&
            waist != null &&
            neck != null &&
            (waist - neck) > 0) {
          return 86.010 * (log(waist - neck) / log(10)) -
              70.041 * (log(height) / log(10)) +
              36.76;
        }
        break;
      case 'DEXA':
        final bf = double.tryParse(data['bodyfat']?.toString() ?? '');
        return bf;
      case 'Plicometro':
        // Combine pliche1, pliche2, plus optional tricepsPlic, etc.
        double sum = 0;
        int count = 0;
        for (final key in [
          'pliche1',
          'pliche2',
          'tricepsplic',
          'subscapularplic',
          'suprailiapplic',
          'thighplic',
          'chestplic'
        ]) {
          final val = double.tryParse(data[key]?.toString() ?? '');
          if (val != null && val > 0) {
            sum += val;
            count++;
          }
        }
        if (count > 0) {
          final avg = sum / count;
          // Placeholder formula: BF% = avg * 0.4
          return avg * 0.4;
        }
        break;
    }
    return null; // Couldn’t calculate
  }

  Widget _buildTrendIcon() {
    final curr = currentBF;
    final prev = previousBF;
    if (curr == null || prev == null) {
      return const Text('–',
          style: TextStyle(fontSize: 18, color: Colors.grey));
    }
    final diff = curr - prev;
    if (diff.abs() < 0.1) {
      return const Text('↔',
          style: TextStyle(fontSize: 18, color: Colors.grey));
    } else if (diff > 0) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.arrow_upward, color: Colors.red, size: 20),
          SizedBox(width: 4),
          Text('↑', style: TextStyle(color: Colors.red, fontSize: 18)),
        ],
      );
    } else {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.arrow_downward, color: Colors.green, size: 20),
          SizedBox(width: 4),
          Text('↓', style: TextStyle(color: Colors.green, fontSize: 18)),
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bf = currentBF;
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$measurementType Body Fat %',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: Colors.blueAccent.shade100,
                shape: BoxShape.circle,
              ),
              alignment: Alignment.center,
              child: bf != null
                  ? Text('${bf.toStringAsFixed(1)}%',
                      style: const TextStyle(
                          fontSize: 24, fontWeight: FontWeight.bold))
                  : const Text('N/A',
                      style:
                          TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 12),
            Text('Trend vs previous:', style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 8),
            _buildTrendIcon(),
          ],
        ),
      ),
    );
  }
}
