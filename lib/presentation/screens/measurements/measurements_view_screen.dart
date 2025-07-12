import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// Import your reusable tab bar widget:
import 'package:isyfit/presentation/widgets/measurement_type_tab_bar_widget.dart';

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

      final querySnap =
          await collectionRef.orderBy('timestamp', descending: true).get();

      _allRecords = querySnap.docs
          .map((doc) => doc.data())
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
    final filtered =
        _allRecords.where((m) => m['type'] == measureType).toList();
    if (filtered.isEmpty) return [];
    // Already sorted descending in _fetchData, so the first 2 are the newest
    return filtered.take(2).toList();
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

                /// Modern floating action buttons
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FloatingActionButton(
                        heroTag: 'refreshFab',
                        onPressed: _fetchData,
                        backgroundColor: Theme.of(context).colorScheme.primary,
                        elevation: 8,
                        child: Icon(
                          Icons.refresh,
                          color: Theme.of(context).colorScheme.onPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the modern content for each tab with enhanced UX
  Widget _buildTabContent(String measureType) {
    final lastTwo = _getLastTwoRecords(measureType);
    if (lastTwo.isEmpty) {
      return _buildEmptyState(measureType);
    }

    final newestData = lastTwo[0];
    final secondNewestData = (lastTwo.length > 1) ? lastTwo[1] : null;
    
    // Generate comparison metrics for modern display
    final metrics = _generateComparisonMetrics(measureType, newestData, secondNewestData);
    
    // Count total records for this measurement type
    final totalRecords = _allRecords.where((m) => m['type'] == measureType).length;

    return CustomScrollView(
      slivers: [
        // Modern header section
        SliverToBoxAdapter(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: _buildModernHeader(measureType, totalRecords),
          ),
        ),

        // Quick insights summary
        SliverToBoxAdapter(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 400),
            child: _buildQuickInsights(metrics),
          ),
        ),

        // Modern comparison grid
        SliverToBoxAdapter(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 500),
            child: _buildModernComparisonGrid(metrics),
          ),
        ),

        // Bottom padding for FAB
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// Build empty state with better UX
  Widget _buildEmptyState(String measureType) {
    final Map<String, dynamic> typeInfo = {
      'BIA': {
        'icon': Icons.biotech,
        'color': Colors.green,
        'message': 'No BIA measurements recorded yet',
        'subtitle': 'Add your first bioelectrical impedance analysis',
      },
      'USArmy': {
        'icon': Icons.military_tech,
        'color': Colors.indigo,
        'message': 'No U.S. Army measurements recorded yet',
        'subtitle': 'Add your first circumference-based measurement',
      },
      'Plicometro': {
        'icon': Icons.straighten,
        'color': Colors.purple,
        'message': 'No Plicometer measurements recorded yet',
        'subtitle': 'Add your first skinfold measurement',
      },
    };

    final info = typeInfo[measureType] ?? typeInfo['BIA']!;

    return Center(
      child: Container(
        margin: const EdgeInsets.all(32),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    (info['color'] as Color).withOpacity(0.8),
                    info['color'] as Color,
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: (info['color'] as Color).withOpacity(0.3),
                    blurRadius: 15,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Icon(
                info['icon'],
                color: Colors.white,
                size: 48,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              info['message'],
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              info['subtitle'],
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Generate comparison metrics from data
  List<ComparisonMetric> _generateComparisonMetrics(
      String measureType, Map<String, dynamic> newest, Map<String, dynamic>? secondNewest) {
    final submetrics = getSubmetricsFor(measureType);
    final metrics = <ComparisonMetric>[];

    for (final sub in submetrics) {
      final metricInfo = prettyMetricLabels[sub] ?? {
        'label': sub,
        'icon': Icons.insights,
        'unit': '',
        'color': Colors.grey
      };

      final newValRaw = newest[sub] ?? newest[sub.toLowerCase()];
      final oldValRaw = (secondNewest == null)
          ? null
          : secondNewest[sub] ?? secondNewest[sub.toLowerCase()];

      final newVal = double.tryParse(newValRaw?.toString() ?? '');
      final oldVal = double.tryParse(oldValRaw?.toString() ?? '');
      
      final newValText = newVal != null 
          ? '${newVal.toStringAsFixed(1)}${metricInfo['unit']}'
          : 'N/A';
      final oldValText = oldVal != null 
          ? '${oldVal.toStringAsFixed(1)}${metricInfo['unit']}'
          : 'N/A';

      TrendDirection trend = TrendDirection.noData;
      if (newVal != null && oldVal != null) {
        final diff = newVal - oldVal;
        if (diff.abs() < 0.001) {
          trend = TrendDirection.stable;
        } else if (diff > 0) {
          trend = TrendDirection.up;
        } else {
          trend = TrendDirection.down;
        }
      }

      metrics.add(ComparisonMetric(
        name: sub,
        displayName: metricInfo['label'],
        newValue: newValText,
        oldValue: oldValText,
        trend: trend,
        icon: metricInfo['icon'],
        color: metricInfo['color'],
        unit: metricInfo['unit'],
      ));
    }

    return metrics;
  }

  /// Build modern comparison header
  Widget _buildModernHeader(String measureType, int recordCount) {
    final Map<String, dynamic> typeInfo = {
      'BIA': {
        'title': 'BIA Analysis',
        'subtitle': 'Bioelectrical Impedance',
        'icon': Icons.biotech,
        'gradient': [const Color(0xFF4CAF50), const Color(0xFF2E7D32)],
      },
      'USArmy': {
        'title': 'U.S. Army Method',
        'subtitle': 'Circumference-based Analysis',
        'icon': Icons.military_tech,
        'gradient': [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
      },
      'Plicometro': {
        'title': 'Plicometer Analysis',
        'subtitle': 'Skinfold Measurements',
        'icon': Icons.straighten,
        'gradient': [const Color(0xFF6A1B9A), const Color(0xFF8E24AA)],
      },
    };

    final info = typeInfo[measureType] ?? typeInfo['BIA']!;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: info['gradient'],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: (info['gradient'][0] as Color).withOpacity(0.4),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(20),
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
                child: Icon(info['icon'], color: Colors.white, size: 32),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      info['title'],
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      info['subtitle'],
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withOpacity(0.9),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.white.withOpacity(0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '$recordCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Records',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build modern comparison grid with uniform adaptive height
  Widget _buildModernComparisonGrid(List<ComparisonMetric> metrics) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Latest vs Previous',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate number of columns based on orientation
              final orientation = MediaQuery.of(context).orientation;
              final crossAxisCount = orientation == Orientation.landscape ? 3 : 2;
              
              // Create rows of cards with uniform height
              final List<Widget> rows = [];
              for (int i = 0; i < metrics.length; i += crossAxisCount) {
                final rowMetrics = metrics.sublist(
                  i, 
                  (i + crossAxisCount > metrics.length) ? metrics.length : i + crossAxisCount
                );
                
                rows.add(
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        for (int j = 0; j < rowMetrics.length; j++) ...[
                          Expanded(
                            child: _buildMetricComparisonCard(rowMetrics[j]),
                          ),
                          if (j < rowMetrics.length - 1) const SizedBox(width: 12),
                        ],
                        // Fill remaining space if row is not complete
                        if (rowMetrics.length < crossAxisCount) ...[
                          for (int k = rowMetrics.length; k < crossAxisCount; k++) ...[
                            const SizedBox(width: 12),
                            const Expanded(child: SizedBox()),
                          ],
                        ],
                      ],
                    ),
                  ),
                );
                
                if (i + crossAxisCount < metrics.length) {
                  rows.add(const SizedBox(height: 12));
                }
              }
              
              return Column(children: rows);
            },
          ),
        ],
      ),
    );
  }

  /// Build individual metric comparison card
  Widget _buildMetricComparisonCard(ComparisonMetric metric) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 5),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: metric.color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with icon and name
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [metric.color.withOpacity(0.8), metric.color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(metric.icon, color: Colors.white, size: 16),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    metric.displayName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: metric.color,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Current value (latest)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Latest',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  metric.newValue ?? 'N/A',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Comparison with trend
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Previous',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        metric.oldValue ?? 'N/A',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrendIndicator(metric.trend),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build trend indicator
  Widget _buildTrendIndicator(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.up:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.trending_up,
            color: Colors.red,
            size: 20,
          ),
        );
      case TrendDirection.down:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.trending_down,
            color: Colors.green,
            size: 20,
          ),
        );
      case TrendDirection.stable:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.trending_flat,
            color: Colors.grey,
            size: 20,
          ),
        );
      case TrendDirection.noData:
        return Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: Colors.blueGrey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.remove,
            color: Colors.blueGrey,
            size: 20,
          ),
        );
    }
  }

  /// Build quick insights summary
  Widget _buildQuickInsights(List<ComparisonMetric> metrics) {
    final improvements = metrics.where((m) => m.trend == TrendDirection.down).length;
    final increases = metrics.where((m) => m.trend == TrendDirection.up).length;
    final stable = metrics.where((m) => m.trend == TrendDirection.stable).length;

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.blue.shade50,
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.blue.withOpacity(0.2),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.1),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.blue.withOpacity(0.8), Colors.blue],
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.insights, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Text(
                  'Quick Insights',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.blue.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildInsightItem(
                    'Improvements',
                    improvements.toString(),
                    Icons.trending_down,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightItem(
                    'Increases',
                    increases.toString(),
                    Icons.trending_up,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInsightItem(
                    'Stable',
                    stable.toString(),
                    Icons.trending_flat,
                    Colors.grey,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build individual insight item
  Widget _buildInsightItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: color.withOpacity(0.8),
            ),
            textAlign: TextAlign.center,
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

/// Data model for comparison metrics
class ComparisonMetric {
  final String name;
  final String displayName;
  final String? newValue;
  final String? oldValue;
  final TrendDirection trend;
  final IconData icon;
  final Color color;
  final String? unit;

  ComparisonMetric({
    required this.name,
    required this.displayName,
    this.newValue,
    this.oldValue,
    required this.trend,
    required this.icon,
    required this.color,
    this.unit,
  });
}

/// Trend direction enum
enum TrendDirection { up, down, stable, noData }

/// Pretty labels for better UX
final Map<String, Map<String, dynamic>> prettyMetricLabels = {
  'heightInCm': {'label': 'Height', 'icon': Icons.height, 'unit': 'cm', 'color': Colors.blue},
  'weightInKg': {'label': 'Weight', 'icon': Icons.monitor_weight, 'unit': 'kg', 'color': Colors.green},
  'skeletalMuscleMassKg': {'label': 'Muscle Mass', 'icon': Icons.fitness_center, 'unit': 'kg', 'color': Colors.orange},
  'bodyFatKg': {'label': 'Body Fat', 'icon': Icons.water_drop, 'unit': 'kg', 'color': Colors.red},
  'BMI': {'label': 'BMI', 'icon': Icons.calculate, 'unit': '', 'color': Colors.purple},
  'basalMetabolicRate': {'label': 'BMR', 'icon': Icons.local_fire_department, 'unit': 'kcal', 'color': Colors.deepOrange},
  'waistHipRatio': {'label': 'Waist-Hip Ratio', 'icon': Icons.straighten, 'unit': '', 'color': Colors.teal},
  'visceralFatLevel': {'label': 'Visceral Fat', 'icon': Icons.favorite, 'unit': 'level', 'color': Colors.pink},
  'targetWeight': {'label': 'Target Weight', 'icon': Icons.flag, 'unit': 'kg', 'color': Colors.indigo},
  'isyScore': {'label': 'IsyScore', 'icon': Icons.star, 'unit': '/100', 'color': Colors.amber},
  'neck': {'label': 'Neck', 'icon': Icons.accessibility, 'unit': 'cm', 'color': Colors.cyan},
  'waist': {'label': 'Waist', 'icon': Icons.crop_free, 'unit': 'cm', 'color': Colors.purple},
  'hips': {'label': 'Hips', 'icon': Icons.crop_free, 'unit': 'cm', 'color': Colors.pink},
  'wrist': {'label': 'Wrist', 'icon': Icons.watch, 'unit': 'cm', 'color': Colors.orange},
  'usArmyBodyFatPercent': {'label': 'Army Body Fat', 'icon': Icons.military_tech, 'unit': '%', 'color': Colors.deepOrange},
  'morphology': {'label': 'Morphology', 'icon': Icons.analytics, 'unit': '', 'color': Colors.blueGrey},
  'idealWeight': {'label': 'Ideal Weight', 'icon': Icons.balance, 'unit': 'kg', 'color': Colors.lightGreen},
  'chestplic': {'label': 'Chest Fold', 'icon': Icons.straighten, 'unit': 'mm', 'color': Colors.red},
  'abdominalPlic': {'label': 'Abdomen Fold', 'icon': Icons.straighten, 'unit': 'mm', 'color': Colors.orange},
  'thighPlic': {'label': 'Thigh Fold', 'icon': Icons.straighten, 'unit': 'mm', 'color': Colors.blue},
  'tricepsPlic': {'label': 'Triceps Fold', 'icon': Icons.straighten, 'unit': 'mm', 'color': Colors.pink},
  'suprailiapplic': {'label': 'Suprailiac Fold', 'icon': Icons.straighten, 'unit': 'mm', 'color': Colors.purple},
  'plicBodyFatPercent': {'label': 'Plic Body Fat', 'icon': Icons.analytics, 'unit': '%', 'color': Colors.teal},
};
