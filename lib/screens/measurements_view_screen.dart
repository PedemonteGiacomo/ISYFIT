import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

class MeasurementsViewScreen extends StatefulWidget {
  final String? clientUid;
  const MeasurementsViewScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<MeasurementsViewScreen> createState() => _MeasurementsViewScreenState();
}

class _MeasurementsViewScreenState extends State<MeasurementsViewScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  String _selectedMeasurementType = '';

  CollectionReference get _recordsCollection {
    final cUid = widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('measurements')
        .doc(cUid)
        .collection('records');
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // Because keepAlive
    return Column(
      children: [
        const SizedBox(height: 12),
        _buildMeasurementTypeSelection(context),
        const SizedBox(height: 12),
        Expanded(
          child: _selectedMeasurementType.isEmpty
              ? _buildNoMeasurementSelectedUI()
              : _buildComparisonTable(_selectedMeasurementType),
        ),
      ],
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
    return Center(
      child: Card(
        color: Colors.blueGrey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info, color: Colors.blueGrey, size: 48),
              const SizedBox(height: 16),
              Text(
                'Select a measurement type above to view/compare data.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey.shade800),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonTable(String measurementType) {
    return FutureBuilder<QuerySnapshot>(
      future: _recordsCollection
          .where('type', isEqualTo: measurementType)
          .orderBy('timestamp', descending: false)
          .get(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildNoDataCard(measurementType);
        }

        final docs = snapshot.data!.docs; // oldest -> newest
        final reversedDocs = docs.reversed.toList(); // newest -> oldest
        final submetrics = getSubmetricsFor(measurementType);

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

        // newest Data
        final newestData = reversedDocs.isNotEmpty
            ? reversedDocs[0].data() as Map<String, dynamic>
            : null;
        final secondNewestData = reversedDocs.length > 1
            ? reversedDocs[1].data() as Map<String, dynamic>
            : null;

        // Build rows
        final rows = <DataRow>[];
        for (final sub in submetrics) {
          final cells = <DataCell>[];
          // Sub name
          cells.add(DataCell(
              Text(sub, style: const TextStyle(fontWeight: FontWeight.bold))));
          // Trend
          cells.add(DataCell(_buildTrendIcon(sub, newestData, secondNewestData)));
          // Each doc
          for (final doc in reversedDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final rawVal = data[sub.toLowerCase()] ?? data[sub];
            final valStr = rawVal?.toString() ?? '—';
            cells.add(DataCell(Text(valStr)));
          }
          rows.add(DataRow(cells: cells));
        }

        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns,
            rows: rows,
          ),
        );
      },
    );
  }

  Widget _buildTrendIcon(
    String sub,
    Map<String, dynamic>? newData,
    Map<String, dynamic>? oldData,
  ) {
    if (newData == null || oldData == null) {
      return const Text('–');
    }
    final newValRaw = newData[sub.toLowerCase()] ?? newData[sub];
    final oldValRaw = oldData[sub.toLowerCase()] ?? oldData[sub];
    if (newValRaw == null || oldValRaw == null) {
      return const Text('–');
    }
    final newVal = double.tryParse(newValRaw.toString());
    final oldVal = double.tryParse(oldValRaw.toString());
    if (newVal == null || oldVal == null) {
      return const Text('–');
    }

    final diff = newVal - oldVal;
    if (diff.abs() < 0.01) {
      return const Text('↔', style: TextStyle(color: Colors.grey));
    } else if (diff > 0) {
      return const Icon(Icons.arrow_upward, color: Colors.red, size: 18);
    } else {
      return const Icon(Icons.arrow_downward, color: Colors.green, size: 18);
    }
  }

  Widget _buildNoDataCard(String type) {
    return Center(
      child: Card(
        color: Colors.blueGrey.shade50,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 4,
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.info, color: Colors.blueGrey, size: 48),
              const SizedBox(height: 16),
              Text(
                'No measurements found for $type.',
                style: TextStyle(color: Colors.blueGrey.shade800),
              ),
            ],
          ),
        ),
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
