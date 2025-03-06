import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Info about different measurement types (no DEXA).
final Map<String, String> measurementTypeInfo = {
  'BIA': 'BIA (Bioelectrical Impedance Analysis).',
  'USArmy': 'U.S. Army formula using circumferences and height.',
  'Plicometro': 'Skinfold caliper measuring multiple sites.',
};

class MeasurementsInsertScreen extends StatefulWidget {
  // Optionally receive the clientUid here, if needed:
  final String? clientUid; 
  const MeasurementsInsertScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<MeasurementsInsertScreen> createState() => _MeasurementsInsertScreenState();
}

class _MeasurementsInsertScreenState extends State<MeasurementsInsertScreen>
    with AutomaticKeepAliveClientMixin {
  // By default, TabBarView rebuilds child widgets on tab switch, 
  // but wantKeepAlive => true helps keep state alive.

  @override
  bool get wantKeepAlive => true; 

  // The currently selected measurement
  String _selectedMeasurementType = '';

  // BIA
  final _biaHeightCtrl = TextEditingController();
  final _biaWeightCtrl = TextEditingController();
  final _biaSkeletalMuscleMassCtrl = TextEditingController();
  final _biaBodyFatKgCtrl = TextEditingController();
  final _biaBMICtrl = TextEditingController();
  final _biaBasalMetabolicRateCtrl = TextEditingController();
  final _biaWaistHipRatioCtrl = TextEditingController();
  final _biaVisceralFatLevelCtrl = TextEditingController();
  final _biaTargetWeightCtrl = TextEditingController();

  // USArmy
  final _armyHeightCtrl = TextEditingController();
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

  // Plicometro
  final _plico1Ctrl = TextEditingController();
  final _plico2Ctrl = TextEditingController();
  final _plicoTricepsCtrl = TextEditingController();
  final _plicoSubscapularCtrl = TextEditingController();
  final _plicoSuprailiacCtrl = TextEditingController();
  final _plicoThighCtrl = TextEditingController();
  final _plicoChestCtrl = TextEditingController();

  // Access your Firestore path
  CollectionReference get _recordsCollection {
    final cUid = widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('measurements')
        .doc(cUid)
        .collection('records');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Because we use AutomaticKeepAliveClientMixin
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildMeasurementTypeSelection(context),
          const SizedBox(height: 16),
          if (_selectedMeasurementType.isEmpty)
            _buildNoMeasurementSelectedUI()
          else
            _buildMeasurementForm(context),
        ],
      ),
    );
  }

  Widget _buildMeasurementTypeSelection(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _buildColoredTypeButton('BIA', Icons.biotech, Colors.indigo),
        _buildColoredTypeButton('USArmy', Icons.military_tech, Colors.green),
        _buildColoredTypeButton('Plicometro', Icons.content_cut, Colors.red),
      ],
    );
  }

  Widget _buildColoredTypeButton(String type, IconData icon, Color color) {
    final bool isSelected = (_selectedMeasurementType == type);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.7),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        type,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
              'Choose a measurement type above to insert data.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementForm(BuildContext context) {
    final info = measurementTypeInfo[_selectedMeasurementType] ?? '';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title + Info
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              '$_selectedMeasurementType Insert',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            IconButton(
              icon: const Icon(Icons.info_outline, color: Colors.blue),
              onPressed: () {
                _showInfoDialog(context, _selectedMeasurementType, info);
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        _buildFieldsByType(_selectedMeasurementType),
        const SizedBox(height: 16),
        ElevatedButton(
          onPressed: _saveMeasurementData,
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildFieldsByType(String type) {
    switch (type) {
      case 'BIA':
        return Column(
          children: [
            _buildTextField(_biaHeightCtrl, 'Height (cm)'),
            _buildTextField(_biaWeightCtrl, 'Weight (kg)'),
            _buildTextField(_biaSkeletalMuscleMassCtrl, 'Skeletal Muscle Mass (kg)'),
            _buildTextField(_biaBodyFatKgCtrl, 'Body Fat (kg)'),
            _buildTextField(_biaBMICtrl, 'BMI'),
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
      case 'Plicometro':
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

  Future<void> _saveMeasurementData() async {
    if (_selectedMeasurementType.isEmpty) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

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
        dataToSave['bmi'] = _biaBMICtrl.text;
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
        final newDocRef = _recordsCollection.doc();
        transaction.set(newDocRef, dataToSave);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Measurement saved successfully!')),
      );
      _clearAllFields();
      setState(() => _selectedMeasurementType = '');
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
    _biaBMICtrl.clear();
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
    // Plicometro
    _plico1Ctrl.clear();
    _plico2Ctrl.clear();
    _plicoTricepsCtrl.clear();
    _plicoSubscapularCtrl.clear();
    _plicoSuprailiacCtrl.clear();
    _plicoThighCtrl.clear();
    _plicoChestCtrl.clear();
  }

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
}
