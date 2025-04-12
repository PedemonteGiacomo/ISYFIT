import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Import your reusable tab bar widget:
import 'package:isyfit/widgets/measurement_type_tab_bar_widget.dart';

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
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  /// A TabController for the 3 measurement types
  late TabController _tabController;

  bool _isLoading = false;
  List<Map<String, dynamic>> _allRecords = [];

  @override
  void initState() {
    super.initState();
    // We have 3 tabs: BIA, USArmy, Plicometro
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final collectionRef = FirebaseFirestore.instance
          .collection('measurements')
          .doc(widget.clientUid)
          .collection('records');

      final querySnap = await collectionRef
          .orderBy('timestamp', descending: true)
          .get();

      _allRecords = querySnap.docs
          .map((doc) => doc.data() as Map<String, dynamic>)
          .toList();
    } catch (e) {
      debugPrint('Error fetching data in MeasurementsViewScreen: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Filter to get the last 2 records for a given measure type
  List<Map<String, dynamic>> _getLastTwoRecords(String measureType) {
    final filtered = _allRecords.where((m) => m['type'] == measureType).toList();
    if (filtered.isEmpty) return [];
    // Already sorted descending in _fetchData, so the first 2 are the newest
    return filtered.take(2).toList();
  }

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

    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_allRecords.isEmpty) {
      return const Center(child: Text('No measurement data found.'));
    }

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Column(
        children: [
          /// Our new measurement type tab bar
          MeasurementTypeTabBarWidget(tabController: _tabController),

          /// Each tab shows the "last 2 measures" for that measure type
          Expanded(
            child: Stack(
              children: [
                TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTabContent('BIA'),
                    _buildTabContent('USArmy'),
                    _buildTabContent('Plicometro'),
                  ],
                ),

                /// A floating action button in the bottom-right corner
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton(
              heroTag: 'refreshFab',
              onPressed: _fetchData,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the content for each tab:
  ///  - The "last two" measure records for the given measureType
  ///  - If none found, show "No data"
  Widget _buildTabContent(String measureType) {
    final lastTwo = _getLastTwoRecords(measureType);
    if (lastTwo.isEmpty) {
      return Center(child: Text('No data found for $measureType'));
    }

    final newestData = lastTwo[0];
    final secondNewestData = (lastTwo.length > 1) ? lastTwo[1] : null;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Table heading
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$measureType - Last 2 Measurements',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // ElevatedButton.icon(
              //   onPressed: () => _navigateToFullHistory(context, measureType),
              //   icon: Icon(Icons.history, color: Theme.of(context).colorScheme.onPrimary,),
              //   label: Text('Full History', style: TextStyle(color:  Theme.of(context).colorScheme.onPrimary),),
              // ),
            ],
          ),
          const SizedBox(height: 16),

          // The table listing each submetric
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildSimplifiedTable(measureType, newestData, secondNewestData),
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a mini-table for newest & secondNewest records
  Widget _buildSimplifiedTable(
    String measureType,
    Map<String, dynamic> newest,
    Map<String, dynamic>? secondNewest,
  ) {
    final submetrics = getSubmetricsFor(measureType);

    return Column(
      children: submetrics.map((sub) {
        final newValRaw = newest[sub] ?? newest[sub.toLowerCase()];
        final oldValRaw = (secondNewest == null)
            ? null
            : secondNewest[sub] ?? secondNewest[sub.toLowerCase()];

        final newVal = double.tryParse(newValRaw?.toString() ?? '');
        final oldVal = double.tryParse(oldValRaw?.toString() ?? '');
        final newValText = (newVal == null) ? 'N/A' : newVal.toStringAsFixed(1);
        final oldValText = (oldVal == null) ? '—' : oldVal.toStringAsFixed(1);

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
      }).toList(),
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
