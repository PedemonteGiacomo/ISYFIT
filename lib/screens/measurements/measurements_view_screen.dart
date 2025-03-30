import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// For convenience, a function returning submetrics for each type:
List<String> getSubmetricsFor(String type) {
  switch (type) {
    case 'BIA':
      return [
        'heightInCm',
        'weightInKg',
        'skeletalMuscleMassKg',
        'bodyFatKg',
        'BMI',
        'basalMetabolicRate',
        'waistHipRatio',
        'visceralFatLevel',
        'targetWeight',
        'isyScore',
      ];
    case 'USArmy':
      return [
        'heightInCm',
        'neck',
        'waist',
        'hips',
        'wrist',
        'usArmyBodyFatPercent',
        'morphology',
        'idealWeight',
        'isyScore',
      ];
    case 'Plicometro':
      return [
        'chestplic',
        'abdominalPlic',
        'thighPlic',
        'tricepsPlic',
        'suprailiapplic',
        'plicBodyFatPercent',
        'isyScore',
      ];
    default:
      return ['isyScore']; // fallback
  }
}

class MeasurementsViewScreen extends StatefulWidget {
  final String clientUid;
  const MeasurementsViewScreen({Key? key, required this.clientUid})
      : super(key: key);

  @override
  State<MeasurementsViewScreen> createState() => _MeasurementsViewScreenState();
}

class _MeasurementsViewScreenState extends State<MeasurementsViewScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedMeasurementType = '';

  void _navigateToFullHistory(BuildContext context, String measurementType) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FullHistoryScreen(
          clientUid: widget.clientUid,
          measurementType: measurementType,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildMeasurementTypeSelection(context),
            const SizedBox(height: 12),
            if (_selectedMeasurementType.isEmpty)
              _buildNoMeasurementSelectedUI()
            else
              _buildTwoLastMeasuresView(_selectedMeasurementType),
          ],
        ),
      ),
    );
  }

  Widget _buildMeasurementTypeSelection(BuildContext context) {
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
    final isSelected = (_selectedMeasurementType == type);
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      icon: Icon(icon, color: Colors.white),
      label: Text(
        type,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
      ),
      onPressed: () {
        setState(() => _selectedMeasurementType = type);
      },
    );
  }

  Widget _buildNoMeasurementSelectedUI() {
    return Center(
      child: Card(
        color: Colors.blueGrey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: const Padding(
          padding: EdgeInsets.all(24.0),
          child: Text(
            'Select a measurement type above to see the last 2 measures.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }

  Widget _buildTwoLastMeasuresView(String measurementType) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Center(child: Text("Not logged in."));
    }

    final collectionRef = FirebaseFirestore.instance
        .collection('measurements')
        .doc(widget.clientUid)
        .collection('records');

    return FutureBuilder<QuerySnapshot>(
      future: collectionRef
          .where('type', isEqualTo: measurementType)
          .orderBy('timestamp', descending: true)
          .limit(2)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Card(
            margin: const EdgeInsets.all(16),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No data found for $measurementType',
                style: TextStyle(color: Colors.blueGrey.shade800),
              ),
            ),
          );
        }

        final docs = snapshot.data!.docs;
        final newestData =
            docs.isNotEmpty ? docs[0].data() as Map<String, dynamic> : null;
        final secondNewestData =
            docs.length > 1 ? docs[1].data() as Map<String, dynamic> : null;

        return _buildSimplifiedTable(measurementType, newestData, secondNewestData);
      },
    );
  }

  Widget _buildSimplifiedTable(
      String type, Map<String, dynamic>? newDoc, Map<String, dynamic>? oldDoc) {
    final submetrics = getSubmetricsFor(type);
    if (newDoc == null) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Table heading
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '$type - Last 2 Measurements',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                // "View Full History" button
                ElevatedButton.icon(
                  onPressed: () => _navigateToFullHistory(context, type),
                  icon: Icon(Icons.history, color: Theme.of(context).colorScheme.onPrimary),
                  label: Text('Full History', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // The table listing each submetric
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: submetrics.map((sub) {
                    final newValRaw = newDoc[sub] ?? newDoc[sub.toLowerCase()];
                    final oldValRaw = oldDoc == null
                        ? null
                        : oldDoc[sub] ?? oldDoc[sub.toLowerCase()];
                    double? newVal = double.tryParse(newValRaw?.toString() ?? '');
                    double? oldVal = double.tryParse(oldValRaw?.toString() ?? '');
                    return _buildMetricRow(sub, newVal, oldVal);
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(String sub, double? newVal, double? oldVal) {
    Widget trendIcon = const Text('–');
    if (newVal != null && oldVal != null) {
      final diff = newVal - oldVal;
      if (diff.abs() < 0.001) {
        trendIcon = const Text('↔', style: TextStyle(color: Colors.grey, fontSize: 18));
      } else if (diff > 0) {
        trendIcon = Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_upward, color: Colors.red, size: 20),
            SizedBox(width: 4),
            Text('↑', style: TextStyle(color: Colors.red, fontSize: 18)),
          ],
        );
      } else {
        trendIcon = Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.arrow_downward, color: Colors.green, size: 20),
            SizedBox(width: 4),
            Text('↓', style: TextStyle(color: Colors.green, fontSize: 18)),
          ],
        );
      }
    }

    final newValText =
        (newVal == null) ? 'N/A' : newVal.toStringAsFixed(1);
    final oldValText =
        (oldVal == null) ? '—' : oldVal.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Text(
              sub,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            flex: 2,
            child: Text(newValText, textAlign: TextAlign.center),
          ),
          SizedBox(width: 40, child: Center(child: trendIcon)),
          Expanded(
            flex: 2,
            child: Text(oldValText, textAlign: TextAlign.center),
          ),
        ],
      ),
    );
  }
}

/// A separate route for Full History
class FullHistoryScreen extends StatelessWidget {
  final String clientUid;
  final String measurementType;

  const FullHistoryScreen({
    Key? key,
    required this.clientUid,
    required this.measurementType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final collectionRef = FirebaseFirestore.instance
        .collection('measurements')
        .doc(clientUid)
        .collection('records');

    return Scaffold(
      appBar: AppBar(
        title: Text('$measurementType - Full History'),
        centerTitle: true,
      ),
      body: FutureBuilder<QuerySnapshot>(
        future: collectionRef
            .where('type', isEqualTo: measurementType)
            .orderBy('timestamp', descending: false)
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(child: Text('No data for $measurementType'));
          }

          final docs = snapshot.data!.docs; // oldest -> newest
          final submetrics = getSubmetricsFor(measurementType);

          // Build columns
          final columns = <DataColumn>[
            const DataColumn(label: Text('Metric')),
          ];
          for (final doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final ts = (data['timestamp'] as Timestamp).toDate();
            columns.add(DataColumn(label: Text(_formatDate(ts))));
          }

          // Build rows
          final rows = <DataRow>[];
          for (final sub in submetrics) {
            final cells = <DataCell>[];
            // sub name
            cells.add(DataCell(Text(
              sub,
              style: const TextStyle(fontWeight: FontWeight.bold),
            )));
            // each doc
            for (final doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final rawVal = data[sub] ?? data[sub.toLowerCase()];
              final valStr = rawVal?.toString() ?? '—';
              cells.add(DataCell(Text(valStr)));
            }
            rows.add(DataRow(cells: cells));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(columns: columns, rows: rows),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    final dd = dt.day.toString().padLeft(2, '0');
    final mm = dt.month.toString().padLeft(2, '0');
    final yy = dt.year.toString().substring(2);
    return '$dd/$mm/$yy';
  }
}
