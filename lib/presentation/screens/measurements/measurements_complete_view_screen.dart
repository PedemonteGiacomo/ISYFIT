import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// PDF imports
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

// FL Chart import
import 'package:fl_chart/fl_chart.dart';

// Import the new reusable widget
import 'package:isyfit/presentation/widgets/measurement_type_tab_bar_widget.dart';

/// We skip 'targetWeight' from displayed cards, but it's in the data model if needed.
final Map<String, List<String>> allMeasurementFields = {
  'BIA': [
    'heightInCm',
    'weightInKg',
    'skeletalMuscleMassKg',
    'bodyFatKg',
    'BMI',
    'basalMetabolicRate',
    'waistHipRatio',
    'visceralFatLevel',
    // 'targetWeight',
    'isyScore',
  ],
  'USArmy': [
    'heightInCm',
    'neck',
    'waist',
    'hips',
    'wrist',
    'usArmyBodyFatPercent',
    'morphology',
    'idealWeight',
    // 'targetWeight',
    'isyScore',
  ],
  'Plicometro': [
    'chestplic',
    'abdominalPlic',
    'thighPlic',
    'tricepsPlic',
    'suprailiapplic',
    'plicBodyFatPercent',
    // 'targetWeight',
    'isyScore',
  ],
};

/// A user-friendly label map so that e.g. "bodyFatKg" => "Body Fat (kg)".
final Map<String, String> prettyLabels = {
  'heightInCm': 'Height (cm)',
  'weightInKg': 'Weight (kg)',
  'skeletalMuscleMassKg': 'Skeletal Muscle Mass (kg)',
  'bodyFatKg': 'Body Fat (kg)',
  'BMI': 'BMI',
  'basalMetabolicRate': 'Basal Metabolic Rate',
  'waistHipRatio': 'Waist-Hip Ratio',
  'visceralFatLevel': 'Visceral Fat Level',
  'targetWeight': 'Target Weight',
  'isyScore': 'IsyScore',
  'neck': 'Neck (cm)',
  'waist': 'Waist (cm)',
  'hips': 'Hips (cm)',
  'wrist': 'Wrist (cm)',
  'usArmyBodyFatPercent': 'Army BF (%)',
  'morphology': 'Morphology',
  'idealWeight': 'Ideal Weight',
  'chestplic': 'Chest Plic (mm)',
  'abdominalPlic': 'Abdomen Plic (mm)',
  'thighPlic': 'Thigh Plic (mm)',
  'tricepsPlic': 'Triceps Plic (mm)',
  'suprailiapplic': 'Suprailiac Plic (mm)',
  'plicBodyFatPercent': 'Plic BF (%)',
};

/// A data model for chart points
class ChartData {
  final DateTime date;
  final double value;
  ChartData(this.date, this.value);
}

/// KPI Card data model
class KPIData {
  final String label;
  final String value;
  final String? trend; // '+2.1', '-0.5', null
  final Color color;
  final IconData icon;
  final bool isPositiveTrend;

  KPIData({
    required this.label,
    required this.value,
    this.trend,
    required this.color,
    required this.icon,
    this.isPositiveTrend = true,
  });
}

/// Chart series data model
class ChartSeriesData {
  final String name;
  final List<ChartData> data;
  final Color color;
  final bool isVisible;

  ChartSeriesData({
    required this.name,
    required this.data,
    required this.color,
    this.isVisible = true,
  });
}

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
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  @override
  bool get wantKeepAlive => true;

  bool _isLoading = false;
  List<Map<String, dynamic>> _allRecords = [];

  /// We'll build a 3-tab layout: BIA, USArmy, Plicometro
  late TabController _tabController;

  /// Dashboard state
  bool _isExpanded = true; // For collapsible sections on mobile
  
  /// Chart series visibility state
  Map<String, bool> _seriesVisibility = {
    'weightInKg': true,
    'bodyFatKg': false,
    'skeletalMuscleMassKg': false,
    'BMI': false,
    'usArmyBodyFatPercent': false,
    'plicBodyFatPercent': false,
  };

  @override
  void initState() {
    super.initState();
    // Initialize our TabController for the 3 measurement types
    _tabController = TabController(length: 3, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    try {
      final querySnap = await FirebaseFirestore.instance
          .collection('measurements')
          .doc(widget.clientUid)
          .collection('records')
          .orderBy('timestamp', descending: false)
          .get();
      _allRecords = querySnap.docs.map((d) => d.data()).toList();
    } catch (e) {
      debugPrint('Error fetching data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Return docs for a measure type
  List<Map<String, dynamic>> _getRecordsFor(String measureType) {
    return _allRecords.where((doc) => doc['type'] == measureType).toList();
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
          // Our new reusable tab bar with no extra margin
          MeasurementTypeTabBarWidget(tabController: _tabController),

          // TabBarView for the 3 measurement types
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
                // FABs positioned in two rows at bottom-right
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          FloatingActionButton(
                            heroTag: 'refreshFab',
                            onPressed: _fetchData,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            child: Icon(
                              Icons.refresh,
                              color: Theme.of(context).colorScheme.onPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FloatingActionButton.extended(
                            heroTag: 'pdf',
                            onPressed: _generatePdfReport,
                            backgroundColor:
                                Theme.of(context).colorScheme.primary,
                            label: Text("Export PDF",
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                            icon: Icon(Icons.picture_as_pdf,
                                color: Theme.of(context).colorScheme.onPrimary),
                          ),
                        ],
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

  /// Modern dashboard tab content with hero cards, interactive charts, and responsive design
  Widget _buildTabContent(String measureType) {
    final docs = _getRecordsFor(measureType);
    if (docs.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.insights_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No $measureType data available',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start by adding some measurements',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    // Sort docs ascending by timestamp
    docs.sort((a, b) {
      final tsA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final tsB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return tsA.compareTo(tsB);
    });

    return CustomScrollView(
      slivers: [
        // Hero Cards Section
        SliverToBoxAdapter(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: _buildHeroCardsSection(measureType, docs),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // Chart Series Toggle
        SliverToBoxAdapter(
          child: _buildChartSeriesToggle(measureType),
        ),

        // Multi-Series Interactive Chart
        SliverToBoxAdapter(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: _buildMultiSeriesChart(measureType, docs),
          ),
        ),

        // IsyScore Section
        SliverToBoxAdapter(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            child: _buildModernIsyScoreSection(docs),
          ),
        ),

        // Expandable Data Table Section
        SliverToBoxAdapter(
          child: _buildExpandableDataSection(measureType, docs),
        ),

        // Bottom padding for FABs
        const SliverToBoxAdapter(child: SizedBox(height: 100)),
      ],
    );
  }

  /// Modern IsyScore section with better styling
  Widget _buildModernIsyScoreSection(List<Map<String, dynamic>> docs) {
    final scoreDocs = docs.where((d) => d['isyScore'] != null).toList();
    if (scoreDocs.isEmpty) return const SizedBox.shrink();
    
    scoreDocs.sort((a, b) {
      final tsA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final tsB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return tsA.compareTo(tsB);
    });

    final latestDoc = scoreDocs.last;
    final valDouble = double.tryParse(latestDoc['isyScore']?.toString() ?? '0');
    final displayVal = valDouble?.toStringAsFixed(1) ?? 'N/A';
    
    // Enhanced color coding with more granular levels
    Color primaryColor = Colors.blueGrey.shade800;
    Color backgroundColor = Colors.blueGrey.shade50;
    String level = 'Unknown';
    
    if (valDouble != null) {
      if (valDouble < 30) {
        primaryColor = Colors.red.shade600;
        backgroundColor = Colors.red.shade50;
        level = 'Needs Improvement';
      } else if (valDouble < 50) {
        primaryColor = Colors.orange.shade600;
        backgroundColor = Colors.orange.shade50;
        level = 'Below Average';
      } else if (valDouble < 70) {
        primaryColor = Colors.amber.shade600;
        backgroundColor = Colors.amber.shade50;
        level = 'Average';
      } else if (valDouble < 85) {
        primaryColor = Colors.lightGreen.shade600;
        backgroundColor = Colors.lightGreen.shade50;
        level = 'Good';
      } else {
        primaryColor = Colors.green.shade600;
        backgroundColor = Colors.green.shade50;
        level = 'Excellent';
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 2,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showSubmetricChartPopup(context, 'isyScore', docs),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: [
                  backgroundColor,
                  Colors.white,
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
                    gradient: LinearGradient(
                      colors: [primaryColor.withOpacity(0.8), primaryColor],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.star, color: Colors.white, size: 28),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'IsyScore',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        level,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: primaryColor.withOpacity(0.8),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      displayVal,
                      style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: primaryColor.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '/100',
                        style: TextStyle(
                          color: primaryColor.withOpacity(0.7),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 12),
                Icon(
                  Icons.chevron_right,
                  color: primaryColor.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Expandable data table section with improved UX
  Widget _buildExpandableDataSection(String measureType, List<Map<String, dynamic>> docs) {
    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ExpansionTile(
        initiallyExpanded: _isExpanded,
        onExpansionChanged: (expanded) {
          setState(() {
            _isExpanded = expanded;
          });
        },
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary.withOpacity(0.8),
                Theme.of(context).colorScheme.primary,
              ],
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(Icons.table_chart, color: Colors.white, size: 20),
        ),
        title: Text(
          'Detailed Data Table',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text('${docs.length} measurements recorded'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildTypeDataTable(measureType, docs),
          ),
        ],
      ),
    );
  }

  /// Build a modern DataTable with enhanced styling
  Widget _buildTypeDataTable(String measureType, List<Map<String, dynamic>> docs) {
    final submetrics = allMeasurementFields[measureType] ?? [];
    
    // Build columns => first is "Metric", then one col per doc
    final dtStrings = <String>[];
    for (final doc in docs) {
      final dt = (doc['timestamp'] as Timestamp?)?.toDate();
      if (dt != null) {
        dtStrings.add(
          '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}',
        );
      } else {
        dtStrings.add('Unknown');
      }
    }

    final columns = <DataColumn>[
      DataColumn(
        label: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'Metric',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
      ),
    ];
    
    for (final dtStr in dtStrings) {
      columns.add(
        DataColumn(
          label: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              dtStr,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ),
        ),
      );
    }

    final rows = <DataRow>[];
    for (int metricIndex = 0; metricIndex < submetrics.length; metricIndex++) {
      final sub = submetrics[metricIndex];
      final label = prettyLabels[sub] ?? sub;
      final cells = <DataCell>[];
      
      // Metric name cell with icon
      cells.add(
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _chooseIconForSubmetric(sub),
                  size: 16,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    label,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      // Data cells
      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final val = doc[sub] ?? doc[sub.toLowerCase()];
        final displayValue = val?.toString() ?? '–';
        
        cells.add(
          DataCell(
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                displayValue,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: displayValue == '–' 
                    ? Theme.of(context).colorScheme.onSurface.withOpacity(0.5)
                    : Theme.of(context).colorScheme.onSurface,
                  fontWeight: displayValue == '–' ? FontWeight.normal : FontWeight.w500,
                ),
              ),
            ),
          ),
        );
      }
      
      rows.add(
        DataRow(
          cells: cells,
          color: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (metricIndex.isEven) {
                return Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3);
              }
              return null;
            },
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: DataTable(
            columns: columns,
            rows: rows,
            columnSpacing: 24,
            dataRowHeight: 56,
            headingRowHeight: 60,
            dividerThickness: 1,
            headingRowColor: MaterialStateProperty.all(
              Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
            ),
            border: TableBorder.all(
              color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  /// Show a popup line chart for a submetric
  void _showSubmetricChartPopup(
    BuildContext context,
    String sub,
    List<Map<String, dynamic>> docs,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(prettyLabels[sub] ?? sub),
        content: SizedBox(
          width: MediaQuery.of(context).size.width * 0.9,
          child: _buildLineChartForSub(docs, sub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          )
        ],
      ),
    );
  }

  /// Build a line chart for sub across docs
  Widget _buildLineChartForSub(List<Map<String, dynamic>> docs, String sub) {
    final List<ChartData> chartData = [];
    for (final doc in docs) {
      final dt = (doc['timestamp'] as Timestamp?)?.toDate();
      if (dt == null) continue;
      final rawVal = doc[sub] ?? doc[sub.toLowerCase()];
      final val = double.tryParse(rawVal?.toString() ?? '');
      if (val == null) continue;
      chartData.add(ChartData(dt, val));
    }

    if (chartData.length < 2) {
      return const Text('Not enough data for this submetric chart.');
    }

    chartData.sort((a, b) => a.date.compareTo(b.date));
    final spots = <FlSpot>[];
    for (int i = 0; i < chartData.length; i++) {
      spots.add(FlSpot(i.toDouble(), chartData[i].value));
    }
    final xLabels = <int, String>{};
    for (int i = 0; i < chartData.length; i++) {
      final d = chartData[i].date;
      xLabels[i] =
          '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}';
    }

    return SizedBox(
      height: 300,
      child: LineChart(
        LineChartData(
          lineTouchData: LineTouchData(
            enabled: true,
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((spot) {
                  final xVal = spot.x.toInt();
                  final yVal = spot.y;
                  final dateString = xLabels[xVal] ?? 'N/A';
                  return LineTooltipItem(
                    '$dateString\n$yVal',
                    const TextStyle(color: Colors.white),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(show: true),
          borderData: FlBorderData(
            show: true,
            border: const Border(
              left: BorderSide(color: Colors.black54),
              bottom: BorderSide(color: Colors.black54),
              top: BorderSide(color: Colors.transparent),
              right: BorderSide(color: Colors.transparent),
            ),
          ),
          titlesData: FlTitlesData(
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                interval: 1,
                getTitlesWidget: (value, meta) {
                  final label = xLabels[value.toInt()] ?? '';
                  return Text(label, style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 40,
                getTitlesWidget: (value, meta) {
                  return Text(value.toStringAsFixed(1),
                      style: const TextStyle(fontSize: 10));
                },
              ),
            ),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              barWidth: 3,
              color: Colors.blueAccent,
              dotData: FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  IconData _chooseIconForSubmetric(String sub) {
    if (sub.toLowerCase().contains('height')) return Icons.height;
    if (sub.toLowerCase().contains('weight'))
      return Icons.monitor_weight_outlined;
    if (sub.toLowerCase().contains('score')) return Icons.star;
    if (sub.toLowerCase().contains('waist')) return Icons.accessibility_new;
    if (sub.toLowerCase().contains('hips')) return Icons.accessibility;
    if (sub.toLowerCase().contains('fat')) return Icons.fitness_center;
    if (sub.toLowerCase().contains('bmi')) return Icons.monitor_heart;
    return Icons.insights;
  }

  /// Generate KPI data for hero cards based on measurement type
  List<KPIData> _generateKPIData(String measureType, List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) return [];
    
    docs.sort((a, b) {
      final tsA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final tsB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return tsA.compareTo(tsB);
    });

    final latest = docs.last;
    final previous = docs.length > 1 ? docs[docs.length - 2] : null;

    List<KPIData> kpis = [];

    switch (measureType) {
      case 'BIA':
        // Weight
        final weight = double.tryParse(latest['weightInKg']?.toString() ?? '0') ?? 0;
        final prevWeight = previous != null ? (double.tryParse(previous['weightInKg']?.toString() ?? '0') ?? 0) : 0;
        final weightTrend = previous != null ? (weight - prevWeight).toStringAsFixed(1) : null;
        kpis.add(KPIData(
          label: 'Weight',
          value: '${weight.toStringAsFixed(1)} kg',
          trend: weightTrend != null ? '${weightTrend.startsWith('-') ? '' : '+'}$weightTrend kg' : null,
          color: Colors.blue,
          icon: Icons.monitor_weight,
          isPositiveTrend: (weight - prevWeight) <= 0, // For weight, losing is positive
        ));

        // Body Fat
        final bodyFat = double.tryParse(latest['bodyFatKg']?.toString() ?? '0') ?? 0;
        final prevBodyFat = previous != null ? (double.tryParse(previous['bodyFatKg']?.toString() ?? '0') ?? 0) : 0;
        final bodyFatTrend = previous != null ? (bodyFat - prevBodyFat).toStringAsFixed(1) : null;
        kpis.add(KPIData(
          label: 'Body Fat',
          value: '${bodyFat.toStringAsFixed(1)} kg',
          trend: bodyFatTrend != null ? '${bodyFatTrend.startsWith('-') ? '' : '+'}$bodyFatTrend kg' : null,
          color: Colors.orange,
          icon: Icons.water_drop,
          isPositiveTrend: (bodyFat - prevBodyFat) <= 0,
        ));

        // Skeletal Muscle Mass
        final smm = double.tryParse(latest['skeletalMuscleMassKg']?.toString() ?? '0') ?? 0;
        final prevSMM = previous != null ? (double.tryParse(previous['skeletalMuscleMassKg']?.toString() ?? '0') ?? 0) : 0;
        final smmTrend = previous != null ? (smm - prevSMM).toStringAsFixed(1) : null;
        kpis.add(KPIData(
          label: 'Muscle Mass',
          value: '${smm.toStringAsFixed(1)} kg',
          trend: smmTrend != null ? '${smmTrend.startsWith('-') ? '' : '+'}$smmTrend kg' : null,
          color: Colors.green,
          icon: Icons.fitness_center,
          isPositiveTrend: (smm - prevSMM) >= 0,
        ));
        break;

      case 'USArmy':
        // Army Body Fat %
        final armyBF = double.tryParse(latest['usArmyBodyFatPercent']?.toString() ?? '0') ?? 0;
        final prevArmyBF = previous != null ? (double.tryParse(previous['usArmyBodyFatPercent']?.toString() ?? '0') ?? 0) : 0;
        final armyBFTrend = previous != null ? (armyBF - prevArmyBF).toStringAsFixed(1) : null;
        kpis.add(KPIData(
          label: 'Body Fat %',
          value: '${armyBF.toStringAsFixed(1)}%',
          trend: armyBFTrend != null ? '${armyBFTrend.startsWith('-') ? '' : '+'}$armyBFTrend%' : null,
          color: Colors.deepOrange,
          icon: Icons.military_tech,
          isPositiveTrend: (armyBF - prevArmyBF) <= 0,
        ));

        // Height (stable metric)
        final height = double.tryParse(latest['heightInCm']?.toString() ?? '0') ?? 0;
        kpis.add(KPIData(
          label: 'Height',
          value: '${height.toStringAsFixed(0)} cm',
          trend: null,
          color: Colors.indigo,
          icon: Icons.height,
        ));

        // Waist
        final waist = double.tryParse(latest['waist']?.toString() ?? '0') ?? 0;
        final prevWaist = previous != null ? (double.tryParse(previous['waist']?.toString() ?? '0') ?? 0) : 0;
        final waistTrend = previous != null ? (waist - prevWaist).toStringAsFixed(1) : null;
        kpis.add(KPIData(
          label: 'Waist',
          value: '${waist.toStringAsFixed(1)} cm',
          trend: waistTrend != null ? '${waistTrend.startsWith('-') ? '' : '+'}$waistTrend cm' : null,
          color: Colors.purple,
          icon: Icons.crop_free,
          isPositiveTrend: (waist - prevWaist) <= 0,
        ));
        break;

      case 'Plicometro':
        // Plic Body Fat %
        final plicBF = double.tryParse(latest['plicBodyFatPercent']?.toString() ?? '0') ?? 0;
        final prevPlicBF = previous != null ? (double.tryParse(previous['plicBodyFatPercent']?.toString() ?? '0') ?? 0) : 0;
        final plicBFTrend = previous != null ? (plicBF - prevPlicBF).toStringAsFixed(1) : null;
        kpis.add(KPIData(
          label: 'Body Fat %',
          value: '${plicBF.toStringAsFixed(1)}%',
          trend: plicBFTrend != null ? '${plicBFTrend.startsWith('-') ? '' : '+'}$plicBFTrend%' : null,
          color: Colors.teal,
          icon: Icons.straighten,
          isPositiveTrend: (plicBF - prevPlicBF) <= 0,
        ));

        // Chest Plic (for male) or Triceps (for female)
        final chest = double.tryParse(latest['chestplic']?.toString() ?? '0') ?? 0;
        final triceps = double.tryParse(latest['tricepsPlic']?.toString() ?? '0') ?? 0;
        final mainPlic = chest > 0 ? chest : triceps;
        final mainPlicLabel = chest > 0 ? 'Chest' : 'Triceps';
        kpis.add(KPIData(
          label: '$mainPlicLabel Fold',
          value: '${mainPlic.toStringAsFixed(1)} mm',
          trend: null,
          color: Colors.pink,
          icon: Icons.straighten,
        ));

        // Sum of folds
        final thigh = double.tryParse(latest['thighPlic']?.toString() ?? '0') ?? 0;
        final abdominal = double.tryParse(latest['abdominalPlic']?.toString() ?? '0') ?? 0;
        final suprailiac = double.tryParse(latest['suprailiapplic']?.toString() ?? '0') ?? 0;
        final totalFolds = mainPlic + thigh + (chest > 0 ? abdominal : suprailiac);
        kpis.add(KPIData(
          label: 'Total Folds',
          value: '${totalFolds.toStringAsFixed(1)} mm',
          trend: null,
          color: Colors.deepPurple,
          icon: Icons.analytics,
        ));
        break;
    }

    return kpis;
  }

  /// Build modern hero cards section
  Widget _buildHeroCardsSection(String measureType, List<Map<String, dynamic>> docs) {
    final kpis = _generateKPIData(measureType, docs);
    if (kpis.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(
            'Key Metrics',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ),
        Container(
          height: 120,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: kpis.length,
            separatorBuilder: (context, index) => const SizedBox(width: 12),
            itemBuilder: (context, index) => _buildKPICard(kpis[index]),
          ),
        ),
      ],
    );
  }

  /// Build individual KPI card with modern design
  Widget _buildKPICard(KPIData kpi) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
        border: Border.all(
          color: kpi.color.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [kpi.color.withOpacity(0.8), kpi.color],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(kpi.icon, color: Colors.white, size: 18),
                ),
                if (kpi.trend != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: kpi.isPositiveTrend ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          kpi.isPositiveTrend ? Icons.trending_up : Icons.trending_down,
                          color: kpi.isPositiveTrend ? Colors.green : Colors.red,
                          size: 12,
                        ),
                        const SizedBox(width: 2),
                        Text(
                          kpi.trend!.replaceAll('+', '').replaceAll('-', ''),
                          style: TextStyle(
                            color: kpi.isPositiveTrend ? Colors.green : Colors.red,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              kpi.label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              kpi.value,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: kpi.color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Build chart series toggle chips
  Widget _buildChartSeriesToggle(String measureType) {
    final availableSeries = <String, String>{};
    switch (measureType) {
      case 'BIA':
        availableSeries.addAll({
          'weightInKg': 'Weight',
          'bodyFatKg': 'Body Fat',
          'skeletalMuscleMassKg': 'Muscle Mass',
          'BMI': 'BMI',
        });
        break;
      case 'USArmy':
        availableSeries.addAll({
          'usArmyBodyFatPercent': 'Body Fat %',
          'waist': 'Waist',
          'neck': 'Neck',
        });
        break;
      case 'Plicometro':
        availableSeries.addAll({
          'plicBodyFatPercent': 'Body Fat %',
          'chestplic': 'Chest',
          'thighPlic': 'Thigh',
        });
        break;
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Chart Series',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: availableSeries.entries.map((entry) {
              final isSelected = _seriesVisibility[entry.key] ?? false;
              return FilterChip(
                selected: isSelected,
                label: Text(entry.value),
                onSelected: (selected) {
                  setState(() {
                    _seriesVisibility[entry.key] = selected;
                  });
                },
                selectedColor: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                checkmarkColor: Theme.of(context).colorScheme.primary,
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  /// Build modern interactive chart with multiple series
  Widget _buildMultiSeriesChart(String measureType, List<Map<String, dynamic>> docs) {
    final visibleSeries = _seriesVisibility.entries
        .where((entry) => entry.value)
        .map((entry) => entry.key)
        .toList();

    if (visibleSeries.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Column(
            children: [
              Icon(Icons.show_chart, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Select chart series to display',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Trends Overview',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: _buildMultiLineChart(visibleSeries, docs),
            ),
          ],
        ),
      ),
    );
  }

  /// Build the actual multi-line chart
  Widget _buildMultiLineChart(List<String> series, List<Map<String, dynamic>> docs) {
    if (docs.isEmpty) return const Center(child: Text('No data available'));

    docs.sort((a, b) {
      final tsA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final tsB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return tsA.compareTo(tsB);
    });

    final colors = [Colors.blue, Colors.green, Colors.orange, Colors.purple, Colors.red, Colors.teal];
    final lineBarsData = <LineChartBarData>[];

    for (int seriesIndex = 0; seriesIndex < series.length; seriesIndex++) {
      final seriesKey = series[seriesIndex];
      final spots = <FlSpot>[];
      
      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final rawVal = doc[seriesKey] ?? doc[seriesKey.toLowerCase()];
        final val = double.tryParse(rawVal?.toString() ?? '');
        if (val != null) {
          spots.add(FlSpot(i.toDouble(), val));
        }
      }

      if (spots.isNotEmpty) {
        lineBarsData.add(
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colors[seriesIndex % colors.length],
            barWidth: 3,
            dotData: FlDotData(show: true),
            belowBarData: BarAreaData(
              show: true,
              color: colors[seriesIndex % colors.length].withOpacity(0.1),
            ),
          ),
        );
      }
    }

    final xLabels = <int, String>{};
    for (int i = 0; i < docs.length; i++) {
      final dt = (docs[i]['timestamp'] as Timestamp?)?.toDate();
      if (dt != null) {
        xLabels[i] = '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}';
      }
    }

    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          enabled: true,
          touchTooltipData: LineTouchTooltipData(
            getTooltipItems: (touchedSpots) {
              return touchedSpots.map((spot) {
                final seriesIndex = lineBarsData.indexWhere((line) => line.spots.contains(spot));
                final seriesName = seriesIndex != -1 ? series[seriesIndex] : 'Unknown';
                final xVal = spot.x.toInt();
                final yVal = spot.y;
                final dateString = xLabels[xVal] ?? 'N/A';
                return LineTooltipItem(
                  '$dateString\n${prettyLabels[seriesName] ?? seriesName}\n${yVal.toStringAsFixed(1)}',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              }).toList();
            },
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: true,
          horizontalInterval: 1,
          verticalInterval: 1,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: Colors.grey.withOpacity(0.2),
              strokeWidth: 1,
            );
          },
        ),
        borderData: FlBorderData(
          show: true,
          border: Border.all(color: Colors.grey.withOpacity(0.3)),
        ),
        titlesData: FlTitlesData(
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: math.max(1, docs.length / 5).floor().toDouble(),
              getTitlesWidget: (value, meta) {
                final label = xLabels[value.toInt()] ?? '';
                return Text(label, style: const TextStyle(fontSize: 10));
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 50,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 10),
                );
              },
            ),
          ),
          rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
        ),
        lineBarsData: lineBarsData,
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // PDF generation (unchanged)
  // ---------------------------------------------------------------------------
  Future<void> _generatePdfReport() async {
    final pdf = pw.Document();
    final Map<String, List<Map<String, dynamic>>> grouped = {};

    // Group docs by type
    for (final doc in _allRecords) {
      final type = doc['type'] ?? 'Unknown';
      grouped.putIfAbsent(type, () => []).add(doc);
    }
    // Sort them ascending
    grouped.forEach((type, list) {
      list.sort((a, b) {
        final tsA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
        final tsB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
        return tsA.compareTo(tsB);
      });
    });

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) {
          final widgets = <pw.Widget>[];

          // Title page
          widgets.add(
            pw.Center(
              child: pw.Text(
                'Measurement Report',
                style:
                    pw.TextStyle(fontSize: 28, fontWeight: pw.FontWeight.bold),
              ),
            ),
          );
          widgets.add(pw.Divider(thickness: 2));
          widgets.add(pw.SizedBox(height: 10));

          // For each measure type, build a table
          grouped.forEach((type, docs) {
            widgets.add(
              pw.Text(
                type,
                style:
                    pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              ),
            );
            widgets.add(pw.SizedBox(height: 8));

            final submetrics = allMeasurementFields[type] ?? [];
            final headers = <pw.Widget>[
              pw.Text('Metric',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            ];

            // Each doc => date
            final dateStrings = <String>[];
            for (final doc in docs) {
              final dt = (doc['timestamp'] as Timestamp?)?.toDate();
              if (dt != null) {
                dateStrings.add(
                    '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}');
              } else {
                dateStrings.add('Unknown');
              }
            }
            for (final ds in dateStrings) {
              headers.add(pw.Text(ds,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold)));
            }

            final tableRows = <List<pw.Widget>>[];
            for (final sub in submetrics) {
              final rowCells = <pw.Widget>[];
              final label = prettyLabels[sub] ?? sub;
              final isIsy = (sub == 'isyScore');
              final subStyle = isIsy
                  ? pw.TextStyle(
                      fontWeight: pw.FontWeight.bold, color: PdfColors.purple)
                  : pw.TextStyle(fontWeight: pw.FontWeight.bold);
              rowCells.add(pw.Text(label, style: subStyle));

              for (int i = 0; i < docs.length; i++) {
                final val = docs[i][sub] ?? docs[i][sub.toLowerCase()];
                final valStyle = isIsy
                    ? pw.TextStyle(color: PdfColors.purple)
                    : const pw.TextStyle();
                rowCells.add(pw.Text(val?.toString() ?? '–', style: valStyle));
              }
              tableRows.add(rowCells);
            }

            widgets.add(
              pw.Table(
                border: pw.TableBorder.all(width: 0.5),
                children: [
                  pw.TableRow(
                    children: headers.map((h) {
                      return pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: h,
                      );
                    }).toList(),
                  ),
                  ...tableRows.map((rowCells) => pw.TableRow(
                        children: rowCells.map((cell) {
                          return pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: cell,
                          );
                        }).toList(),
                      )),
                ],
              ),
            );

            widgets.add(pw.SizedBox(height: 20));
          });

          return widgets;
        },
      ),
    );

    // Let user pick how to save/print PDF
    await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
