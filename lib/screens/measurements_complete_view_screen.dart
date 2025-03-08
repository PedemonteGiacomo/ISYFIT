import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// A helper to get submetrics labels for each type (like you do in other screens).
Map<String, List<String>> allMeasurementFields = {
  'BIA': [
    'heightInCm',
    'weightInKg',
    'skeletalMuscleMassKg',
    'bodyFatKg',
    'BMI',
    'basalMetabolicRate',
    'waistHipRatio',
    'visceralFatLevel',
    'targetWeight',
  ],
  'USArmy': [
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
  ],
  'Plicometro': [
    'pliche1',
    'pliche2',
    'tricepsPlic',
    'subscapularPlic',
    'suprailiapplic',
    'thighPlic',
    'chestplic',
  ],
  // If you still store DEXA data or other, you can add them here:
  'DEXA': [
    'bodyFat',
    'boneDensity',
  ],
};

/// A single screen that aggregates *all* measurement docs
/// from "measurements/{clientUid}/records" and displays them:
/// 1) A body silhouette with *some* highlighted measures (like waist or arms).
/// 2) A full list or table grouping by measurement type and date.
class MeasurementsCompleteViewScreen extends StatefulWidget {
  final String clientUid;
  const MeasurementsCompleteViewScreen({Key? key, required this.clientUid})
      : super(key: key);

  @override
  State<MeasurementsCompleteViewScreen> createState() =>
      _MeasurementsCompleteViewScreenState();
}

class _MeasurementsCompleteViewScreenState
    extends State<MeasurementsCompleteViewScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = false;
  List<Map<String, dynamic>> _allRecords = [];

  @override
  void initState() {
    super.initState();
    _fetchAllRecords();
  }

  Future<void> _fetchAllRecords() async {
    setState(() => _isLoading = true);
    try {
      final querySnap = await FirebaseFirestore.instance
          .collection('measurements')
          .doc(widget.clientUid)
          .collection('records')
          .orderBy('timestamp', descending: false) // oldest -> newest
          .get();
      _allRecords =
          querySnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    } catch (e) {
      debugPrint('Error fetching all measurements: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// We can derive some "latest" measurement for certain submetrics
  /// to display on the silhouette overlay. For instance, waist, chest, arms, etc.
  String? _getLatestValue(String submetric) {
    // search from last doc to first doc for the first one that has submetric
    for (int i = _allRecords.length - 1; i >= 0; i--) {
      final doc = _allRecords[i];
      // submetrics in doc are often lowercased
      final val = doc[submetric.toLowerCase()] ?? doc[submetric];
      if (val != null) {
        return val.toString();
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allRecords.isEmpty) {
      return const Center(child: Text('No measurement data found.'));
    }

    // We'll display a ScrollView with:
    // 1) A "body silhouette" card highlighting some fields (like waist, chest, arms).
    // 2) A section with expansions by measurement type, listing each doc chronologically.

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            _buildBodySilhouetteCard(context),
            const SizedBox(height: 24),
            _buildAllTypesExpansion(context),
          ],
        ),
      ),
    );
  }

  /// 1) Body Silhouette Card
  Widget _buildBodySilhouetteCard(BuildContext context) {
    // E.g., we might want to highlight "waist" from USArmy or BIA
    // In your data model, "waist" might appear in USArmy or BIA?
    // We'll just attempt to read a few "common" measure keys:

    final waistVal = _getLatestValue('waist');
    final chestVal = _getLatestValue('chest');
    final rightArmVal = _getLatestValue('rightArm');
    final leftArmVal = _getLatestValue('leftArm');
    final weightVal = _getLatestValue('weightInKg');

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: SizedBox(
        height: 400,
        // We'll do a stack with an image, then Positioneds for label overlays
        child: Stack(
          children: [
            // 1) The background silhouette
            Positioned.fill(
              child: Opacity(
                opacity: 0.9,
                child: Image.asset(
                  'assets/images/silhouette.png',
                  fit: BoxFit.contain,
                ),
              ),
            ),
            // 2) Overlays: e.g. waist label
            if (waistVal != null)
              Positioned(
                left: 120,
                top: 220,
                child: _buildOverlayLabel('Waist: $waistVal cm'),
              ),
            if (chestVal != null)
              Positioned(
                left: 100,
                top: 160,
                child: _buildOverlayLabel('Chest: $chestVal cm'),
              ),
            if (rightArmVal != null)
              Positioned(
                right: 40,
                top: 180,
                child: _buildOverlayLabel('R-Arm: $rightArmVal cm'),
              ),
            if (leftArmVal != null)
              Positioned(
                left: 40,
                top: 180,
                child: _buildOverlayLabel('L-Arm: $leftArmVal cm'),
              ),
            if (weightVal != null)
              Positioned(
                left: 100,
                bottom: 20,
                child: _buildOverlayLabel('Weight: $weightVal kg'),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverlayLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Colors.black,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  /// 2) Show expansions grouping docs by type (BIA, USArmy, etc.)
  Widget _buildAllTypesExpansion(BuildContext context) {
    // We'll group each doc by its "type".
    // Also keep them in chronological order inside each type.
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (final doc in _allRecords) {
      final type = doc['type'] ?? 'Unknown';
      grouped.putIfAbsent(type, () => []).add(doc);
    }

    // Sort the docs inside each type by timestamp ascending
    for (final type in grouped.keys) {
      grouped[type]!.sort((a, b) {
        final tsA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final tsB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return tsA.compareTo(tsB);
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: grouped.keys.map((type) {
        return _buildTypeExpansionTile(type, grouped[type]!);
      }).toList(),
    );
  }

  Widget _buildTypeExpansionTile(String type, List<Map<String, dynamic>> docs) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ExpansionTile(
        title: Text(
          type,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: _buildTypeDataTable(type, docs),
          ),
        ],
      ),
    );
  }

  Widget _buildTypeDataTable(String type, List<Map<String, dynamic>> docs) {
    // columns: first is "Metric"
    // then for each doc, one column
    final columns = <DataColumn>[const DataColumn(label: Text('Metric'))];

    // We'll also gather the date/time from each doc to label columns
    final docDates = <String>[];
    for (final doc in docs) {
      final dt = (doc['timestamp'] as Timestamp?)?.toDate();
      final dateStr = (dt != null)
          ? '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}'
          : 'Unknown';
      docDates.add(dateStr);
      columns.add(DataColumn(label: Text(dateStr)));
    }

    final submetrics = allMeasurementFields[type] ?? [];

    // build rows for submetrics
    final rows = <DataRow>[];
    for (final sub in submetrics) {
      final cells = <DataCell>[];
      // First cell: sub name
      cells.add(DataCell(
          Text(sub, style: const TextStyle(fontWeight: FontWeight.bold))));
      // Then for each doc
      for (int i = 0; i < docs.length; i++) {
        final docData = docs[i];
        final val = docData[sub.toLowerCase()] ?? docData[sub];
        final displayVal = val?.toString() ?? '–';
        cells.add(DataCell(Text(displayVal)));
      }
      rows.add(DataRow(cells: cells));
    }

    return DataTable(
      columns: columns,
      rows: rows,
      columnSpacing: 20,
      dataRowHeight: 36,
      headingRowHeight: 36,
    );
  }
}
