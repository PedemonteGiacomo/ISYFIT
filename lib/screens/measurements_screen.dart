import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math' show min;

final Map<String, String> measurementTypeInfo = {
  'BIA':
      'BIA (Bioelectrical Impedance Analysis) helps estimate body composition, '
      'such as body fat and muscle mass, by sending a small electrical current.',
  'USArmy':
      'U.S. Army method uses circumferences (neck, waist, etc.) to estimate body fat.',
  'DEXA':
      'DEXA (Dual-Energy X-ray Absorptiometry) is an imaging test measuring bone density and body fat distribution.',
  'Plicometro':
      'A plicometro (skinfold caliper) measures skinfold thickness at selected sites to estimate total body fat.',
};

final Map<String, String> submetricInfo = {
  // BIA
  'weightInKg': 'Total body weight in kilograms, recorded during the BIA test.',
  'skeletalMuscleMassKg': 'Estimated lean (skeletal) muscle mass (kg).',
  'bodyFatKg': 'Estimated body fat mass (kg).',
  'bodyFatPercent': 'Percentage of total weight that is fat.',
  'BMI': 'BMI (Body Mass Index), ratio of weight to height (kg/m²).',
  'basalMetabolicRate': 'Estimated calories burned at rest over 24 hours.',
  'waistHipRatio': 'Ratio of waist circumference to hip circumference.',
  'visceralFatLevel': 'Approximate level of visceral (internal) fat.',
  'targetWeight': 'Planned or recommended target body weight (kg).',

  // US Army
  'neck': 'Neck circumference (cm).',
  'shoulders': 'Shoulders circumference (cm).',
  'chest': 'Chest circumference (cm).',
  'navel': 'Navel/girth around mid-abdomen (cm).',
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
};

class MeasurementsScreen extends StatefulWidget {
  final String clientUid;
  const MeasurementsScreen({Key? key, required this.clientUid}) : super(key: key);

  @override
  State<MeasurementsScreen> createState() => _MeasurementsScreenState();
}

class _MeasurementsScreenState extends State<MeasurementsScreen> {
  bool _isGraphMode = false;
  bool _showTable = false;

  /// Currently selected measurement type, submetric, and time range
  String _selectedMeasurementType = '';
  String _selectedSubmetric = '';
  final List<String> _timeRanges = ['All', '1M', '3M', '6M', '12M'];
  String _selectedTimeRange = 'All';

  // BIA
  final TextEditingController _biaWeightCtrl = TextEditingController();
  final TextEditingController _biaSkeletalMuscleMassCtrl = TextEditingController();
  final TextEditingController _biaBodyFatKgCtrl = TextEditingController();
  final TextEditingController _biaBodyFatPercentCtrl = TextEditingController();
  final TextEditingController _biaBMIctrl = TextEditingController();
  final TextEditingController _biaBasalMetabolicRateCtrl = TextEditingController();
  final TextEditingController _biaWaistHipRatioCtrl = TextEditingController();
  final TextEditingController _biaVisceralFatLevelCtrl = TextEditingController();
  final TextEditingController _biaTargetWeightCtrl = TextEditingController();

  // USArmy
  final TextEditingController _armyNeckCtrl = TextEditingController();
  final TextEditingController _armyShouldersCtrl = TextEditingController();
  final TextEditingController _armyChestCtrl = TextEditingController();
  final TextEditingController _armyNavelCtrl = TextEditingController();
  final TextEditingController _armyWaistCtrl = TextEditingController();
  final TextEditingController _armyGlutesCtrl = TextEditingController();
  final TextEditingController _armyRightArmCtrl = TextEditingController();
  final TextEditingController _armyLeftArmCtrl = TextEditingController();
  final TextEditingController _armyRightLegCtrl = TextEditingController();
  final TextEditingController _armyLeftLegCtrl = TextEditingController();

  // DEXA
  final TextEditingController _dexaBodyFatCtrl = TextEditingController();
  final TextEditingController _dexaBoneDensityCtrl = TextEditingController();

  // Plicometro
  final TextEditingController _plico1Ctrl = TextEditingController();
  final TextEditingController _plico2Ctrl = TextEditingController();

  /// The Firestore path: measurements/{clientUid}/records
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
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Text("Measurements - Loading...");
            }
            if (!snapshot.hasData || !snapshot.data!.exists) {
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
              const Text('Graph'),
              Switch(
                value: _isGraphMode,
                onChanged: (val) {
                  setState(() {
                    _isGraphMode = val;
                    _showTable = false;
                  });
                },
              ),
            ],
          ),
        ],
      ),
      body: _isGraphMode ? _buildGraphMode() : _buildInsertMode(),
    );
  }

  // ------------------------------------------------------------------------
  // INSERT MODE
  // ------------------------------------------------------------------------
  Widget _buildInsertMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          _buildMeasurementTypeSelection(),
          const SizedBox(height: 16),

          if (_selectedMeasurementType.isEmpty)
            _buildNoMeasurementSelectedUI(),

          if (_selectedMeasurementType.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Inserting data for: $_selectedMeasurementType',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.info_outline, color: Colors.blue),
                  onPressed: () {
                    final info = measurementTypeInfo[_selectedMeasurementType] ??
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

  /// A row with 4 big color-coded buttons for BIA, USArmy, DEXA, Plicometro
  Widget _buildMeasurementTypeSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildColoredTypeButton('BIA', Icons.biotech_sharp, Colors.indigo)),
        const SizedBox(width: 8),
        Expanded(child: _buildColoredTypeButton('USArmy', Icons.military_tech, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildColoredTypeButton('DEXA', Icons.my_library_books, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildColoredTypeButton('Plicometro', Icons.content_cut, Colors.redAccent)),
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
              'Choose a measurement type above to insert or view metrics for this client. '
              'Each measurement type focuses on different aspects (body composition, '
              'circumferences, body fat, etc.). Once a type is selected, a form to '
              'insert data will appear below.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementForm(String type) {
    switch (type) {
      case 'BIA':
        return Column(
          children: [
            _buildTextField(_biaWeightCtrl, 'Weight (kg)'),
            _buildTextField(_biaSkeletalMuscleMassCtrl, 'Skeletal Muscle Mass (kg)'),
            _buildTextField(_biaBodyFatKgCtrl, 'Body Fat (kg)'),
            _buildTextField(_biaBodyFatPercentCtrl, 'Body Fat (%)'),
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
        return Column(
          children: [
            _buildTextField(_plico1Ctrl, 'Pliche #1 (mm)'),
            _buildTextField(_plico2Ctrl, 'Pliche #2 (mm)'),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildTextField(TextEditingController ctrl, String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: ctrl,
              decoration: InputDecoration(
                labelText: label,
                border: const OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.info_outline, color: Colors.blue),
            onPressed: () {
              final subKey = _extractSubmetricKey(label);
              final info = submetricInfo[subKey] ?? 'No info available.';
              _showInfoDialog(context, label, info);
            },
          ),
        ],
      ),
    );
  }

  String _extractSubmetricKey(String label) {
    final clean = label.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
    if (clean.contains('weight') && clean.contains('kg')) return 'weightInKg';
    if (clean.contains('skeletalmusclemass')) return 'skeletalmusclemasskg';
    if (clean.contains('bodyfatkg')) return 'bodyfatkg';
    if (clean.contains('bodyfatpercent')) return 'bodyfatpercent';
    if (clean.contains('bmi')) return 'bmi';
    if (clean.contains('basalmetabolicrate')) return 'basalmetabolicrate';
    if (clean.contains('waisthipratio')) return 'waisthipratio';
    if (clean.contains('visceralfatlevel')) return 'visceralfatlevel';
    if (clean.contains('targetweight')) return 'targetweight';

    // USArmy
    if (clean.contains('neck')) return 'neck';
    if (clean.contains('shoulders')) return 'shoulders';
    if (clean.contains('chest')) return 'chest';
    if (clean.contains('navel')) return 'navel';
    if (clean.contains('waist')) return 'waist';
    if (clean.contains('glutes')) return 'glutes';
    if (clean.contains('rightarm')) return 'rightarm';
    if (clean.contains('leftarm')) return 'leftarm';
    if (clean.contains('rightleg')) return 'rightleg';
    if (clean.contains('leftleg')) return 'leftleg';

    // DEXA
    if (clean.contains('bodyfat') && clean.contains('dexa')) return 'bodyfat';
    if (clean.contains('bonedensity')) return 'bonedensity';

    // Plicometro
    if (clean.contains('pliche1')) return 'pliche1';
    if (clean.contains('pliche2')) return 'pliche2';

    return clean;
  }

  // ------------------------------------------------------------------------
  // GRAPH MODE
  // ------------------------------------------------------------------------
  Widget _buildGraphMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          if (_selectedMeasurementType.isEmpty)
            Card(
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
                      'Please select one of the measurements below to begin visualizing data.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey.shade800),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          _buildGraphTypeSelection(),

          if (_selectedMeasurementType.isNotEmpty) ...[
            const SizedBox(height: 16),
            // The chart
            _buildSubmetricSelection(_selectedMeasurementType),
            const SizedBox(height: 16),

            if (_selectedSubmetric.isEmpty)
              _buildNoSubmetricSelectedUI()
            else
              Container(
                height: 300,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.grey.shade300,
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    )
                  ],
                ),
                child: _buildChartWidget(),
              ),

            // Now the time range chips below the chart
            const SizedBox(height: 16),
            _buildTimeRangeSelector(),

            const SizedBox(height: 16),
            if (_selectedSubmetric.isNotEmpty)
              ElevatedButton(
                onPressed: () => setState(() => _showTable = !_showTable),
                child: Text(_showTable ? 'Hide Table' : 'Show All Data'),
              ),
            if (_showTable)
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: _buildDataTable(),
              ),
          ],
        ],
      ),
    );
  }

  Widget _buildGraphTypeSelection() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(child: _buildColoredGraphTypeButton('BIA', Icons.biotech_sharp, Colors.indigo)),
        const SizedBox(width: 8),
        Expanded(child: _buildColoredGraphTypeButton('USArmy', Icons.military_tech, Colors.green)),
        const SizedBox(width: 8),
        Expanded(child: _buildColoredGraphTypeButton('DEXA', Icons.my_library_books, Colors.orange)),
        const SizedBox(width: 8),
        Expanded(child: _buildColoredGraphTypeButton('Plicometro', Icons.content_cut, Colors.redAccent)),
      ],
    );
  }

  Widget _buildColoredGraphTypeButton(String type, IconData icon, Color color) {
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
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        setState(() {
          _selectedMeasurementType = type;
          _selectedSubmetric = '';
          _showTable = false;
        });
      },
    );
  }

  Widget _buildSubmetricSelection(String type) {
    final submetrics = _getSubmetricsFor(type);
    if (submetrics.isEmpty) return const SizedBox.shrink();

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: submetrics.map((sub) {
        final isSelected = (_selectedSubmetric == sub);
        return ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: () {
            setState(() {
              _selectedSubmetric = sub;
              _showTable = false;
            });
          },
          child: Text(
            sub,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNoSubmetricSelectedUI() {
    return Card(
      color: Colors.blueGrey.shade50,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 4,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Icon(Icons.info, color: Colors.blueGrey, size: 48),
            const SizedBox(height: 16),
            Text(
              'Select a submetric to visualize the chart. Each measurement type has unique submetrics.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey.shade800),
            ),
          ],
        ),
      ),
    );
  }

  List<String> _getSubmetricsFor(String type) {
    switch (type) {
      case 'BIA':
        return [
          'weightInKg',
          'skeletalMuscleMassKg',
          'bodyFatKg',
          'bodyFatPercent',
          'BMI',
          'basalMetabolicRate',
          'waistHipRatio',
          'visceralFatLevel',
          'targetWeight',
        ];
      case 'USArmy':
        return [
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
        ];
      default:
        return [];
    }
  }

  Widget _buildTimeRangeSelector() {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: _timeRanges.map((range) {
        final isSelected = (_selectedTimeRange == range);
        return ChoiceChip(
          label: Text(range),
          selected: isSelected,
          onSelected: (val) {
            if (val) {
              setState(() {
                _selectedTimeRange = range;
              });
            }
          },
        );
      }).toList(),
    );
  }

  /// Build the line chart
  Widget _buildChartWidget() {
    return FutureBuilder<QuerySnapshot>(
      future: _recordsCollection
          .where('type', isEqualTo: _selectedMeasurementType)
          .orderBy('timestamp', descending: false)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text('No data found for this type.'));
        }

        // Filter by time range
        List<QueryDocumentSnapshot> docs = snapshot.data!.docs;
        docs = _applyTimeRangeFilter(docs);
        if (docs.isEmpty) {
          return const Center(child: Text('No data in this date range.'));
        }

        // Convert each doc into a FlSpot with x = index, y = submetric
        final spots = <FlSpot>[];
        final dateStrings = <String>[];

        for (int i = 0; i < docs.length; i++) {
          final data = docs[i].data() as Map<String, dynamic>;
          final ts = (data['timestamp'] as Timestamp).toDate();

          final rawVal = data[_selectedSubmetric.toLowerCase()] ?? data[_selectedSubmetric];
          if (rawVal == null) continue;
          final val = double.tryParse(rawVal.toString());
          if (val == null) continue;

          spots.add(FlSpot(i.toDouble(), val));
          dateStrings.add(_formatDate(ts)); // "MM/dd"
        }

        if (spots.isEmpty) {
          return const Center(child: Text('No numeric data for this submetric.'));
        }

        double minX = spots.first.x, maxX = spots.first.x;
        double minY = spots.first.y, maxY = spots.first.y;
        for (final s in spots) {
          if (s.x < minX) minX = s.x;
          if (s.x > maxX) maxX = s.x;
          if (s.y < minY) minY = s.y;
          if (s.y > maxY) maxY = s.y;
        }
        if (maxX - minX == 0) {
          maxX = minX + 1;
        }
        if (maxY - minY == 0) {
          maxY = minY + 1;
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: LineChart(
            LineChartData(
              backgroundColor: Colors.white,
              minX: minX,
              maxX: maxX,
              minY: minY * 0.95,
              maxY: maxY * 1.05,
              lineTouchData: LineTouchData(
                touchTooltipData: LineTouchTooltipData(
                  fitInsideHorizontally: true,
                  fitInsideVertically: true,
                  getTooltipItems: (touchedSpots) {
                    return touchedSpots.map((ts) {
                      final idx = ts.spotIndex;
                      final dateStr =
                          (idx >= 0 && idx < dateStrings.length) ? dateStrings[idx] : '???';
                      return LineTooltipItem(
                        '$dateStr\n$_selectedSubmetric = ${ts.y}',
                        const TextStyle(color: Colors.black),
                      );
                    }).toList();
                  },
                  tooltipRoundedRadius: 8,
                ),
              ),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(showTitles: true, reservedSize: 40),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: 1,
                    getTitlesWidget: (value, meta) {
                      final idx = value.toInt();
                      if (idx < 0 || idx >= dateStrings.length) {
                        return const SizedBox.shrink();
                      }
                      return Text(dateStrings[idx], style: const TextStyle(fontSize: 10));
                    },
                  ),
                ),
              ),
              gridData: FlGridData(
                show: true,
                drawHorizontalLine: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (value) => FlLine(
                  color: Colors.grey.shade300,
                  strokeWidth: 1,
                ),
              ),
              borderData: FlBorderData(
                show: true,
                border: Border.all(color: Colors.grey.shade400),
              ),
              lineBarsData: [
                LineChartBarData(
                  spots: spots,
                  isCurved: true,
                  color: Colors.purpleAccent,
                  barWidth: 4,
                  belowBarData: BarAreaData(
                    show: true,
                    color: Colors.purpleAccent.withOpacity(0.15),
                  ),
                  dotData: FlDotData(
                    show: true,
                    getDotPainter: (spot, percent, barData, index) =>
                        FlDotCirclePainter(
                      radius: 5,
                      color: Colors.white,
                      strokeWidth: 3,
                      strokeColor: Colors.purpleAccent,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<QueryDocumentSnapshot> _applyTimeRangeFilter(List<QueryDocumentSnapshot> docs) {
    if (_selectedTimeRange == 'All') {
      return docs;
    }
    final now = DateTime.now();
    DateTime cutoff;
    switch (_selectedTimeRange) {
      case '1M':
        cutoff = DateTime(now.year, now.month - 1, now.day);
        break;
      case '3M':
        cutoff = DateTime(now.year, now.month - 3, now.day);
        break;
      case '6M':
        cutoff = DateTime(now.year, now.month - 6, now.day);
        break;
      case '12M':
        cutoff = DateTime(now.year - 1, now.month, now.day);
        break;
      default:
        return docs;
    }
    return docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final ts = (data['timestamp'] as Timestamp).toDate();
      return ts.isAfter(cutoff);
    }).toList();
  }

  String _formatDate(DateTime dt) {
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$mm/$dd';
  }

  // ------------------------------------------------------------------------
  // DATA TABLE
  // ------------------------------------------------------------------------
  Widget _buildDataTable() {
    return FutureBuilder<QuerySnapshot>(
      future: _recordsCollection
          .where('type', isEqualTo: _selectedMeasurementType)
          .orderBy('timestamp', descending: false)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text('No data found for this measurement type.');
        }

        var docs = snapshot.data!.docs;
        docs = _applyTimeRangeFilter(docs);
        if (docs.isEmpty) {
          return const Text('No data in this date range.');
        }

        final submetrics = _getSubmetricsFor(_selectedMeasurementType);
        final headers = ['Date'] + submetrics;
        if (submetrics.contains(_selectedSubmetric)) {
          headers.add('Diff');
        }

        double? prevVal;
        final rows = <List<String>>[];

        for (final doc in docs) {
          final data = doc.data() as Map<String, dynamic>;
          final ts = (data['timestamp'] as Timestamp).toDate();
          final dateStr = ts.toIso8601String().split('T').first;

          final rowValues = <String>[dateStr];
          for (var sub in submetrics) {
            final v = data[sub.toLowerCase()] ?? data[sub];
            rowValues.add(v?.toString() ?? '');
          }

          if (submetrics.contains(_selectedSubmetric)) {
            final raw = data[_selectedSubmetric.toLowerCase()] ?? data[_selectedSubmetric];
            final double? val = double.tryParse(raw?.toString() ?? '');
            String diffStr = '';
            if (val != null && prevVal != null) {
              final diff = val - prevVal!;
              diffStr = (diff > 0) ? '+${diff.toStringAsFixed(2)}'
                                   : diff.toStringAsFixed(2);
            }
            rowValues.add(diffStr);
            prevVal = val ?? prevVal;
          }

          rows.add(rowValues);
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: headers.map((h) => DataColumn(label: Text(h))).toList(),
            rows: rows.map((vals) {
              return DataRow(
                cells: vals.map((v) => DataCell(Text(v))).toList(),
              );
            }).toList(),
          ),
        );
      },
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
        dataToSave['weightinkg'] = _biaWeightCtrl.text;
        dataToSave['skeletalmusclemasskg'] = _biaSkeletalMuscleMassCtrl.text;
        dataToSave['bodyfatkg'] = _biaBodyFatKgCtrl.text;
        dataToSave['bodyfatpercent'] = _biaBodyFatPercentCtrl.text;
        dataToSave['bmi'] = _biaBMIctrl.text;
        dataToSave['basalmetabolicrate'] = _biaBasalMetabolicRateCtrl.text;
        dataToSave['waisthipratio'] = _biaWaistHipRatioCtrl.text;
        dataToSave['visceralfatlevel'] = _biaVisceralFatLevelCtrl.text;
        dataToSave['targetweight'] = _biaTargetWeightCtrl.text;
        break;

      case 'USArmy':
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
        break;
    }

    try {
      await _recordsCollection.add(dataToSave);
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
    _biaWeightCtrl.clear();
    _biaSkeletalMuscleMassCtrl.clear();
    _biaBodyFatKgCtrl.clear();
    _biaBodyFatPercentCtrl.clear();
    _biaBMIctrl.clear();
    _biaBasalMetabolicRateCtrl.clear();
    _biaWaistHipRatioCtrl.clear();
    _biaVisceralFatLevelCtrl.clear();
    _biaTargetWeightCtrl.clear();

    // USArmy
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
}
