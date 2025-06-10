import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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
      _allRecords =
          querySnap.docs.map((d) => d.data() as Map<String, dynamic>).toList();
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

  /// For each measure type tab:
  /// 1) A "featured" line chart
  /// 2) A horizontal wrap row of submetric cards (excluding isyScore, targetWeight)
  /// 3) The IsyScore row if present
  /// 4) The data table with all historical data
  Widget _buildTabContent(String measureType) {
    final docs = _getRecordsFor(measureType);
    if (docs.isEmpty) {
      return const Center(child: Text('No data.'));
    }

    // Sort docs ascending by timestamp
    docs.sort((a, b) {
      final tsA = (a['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      final tsB = (b['timestamp'] as Timestamp?)?.toDate() ?? DateTime(1970);
      return tsA.compareTo(tsB);
    });

    final chartWidget = _buildFeaturedChart(measureType, docs);

    final allSubs = allMeasurementFields[measureType] ?? [];
    final cardSubs =
        allSubs.where((s) => s != 'isyScore' && s != 'targetWeight').toList();
    final cardsRow = _buildMeasurementCardsRow(cardSubs, docs);

    final isyScorePresent =
        allSubs.contains('isyScore') && docs.any((d) => d['isyScore'] != null);
    final isyScoreRow =
        isyScorePresent ? _buildIsyScoreRow(docs) : const SizedBox.shrink();

    final dataTable = _buildTypeDataTable(measureType, docs);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          chartWidget,
          const SizedBox(height: 24),
          cardsRow,
          const SizedBox(height: 16),
          isyScoreRow,
          const SizedBox(height: 24),
          dataTable,
        ],
      ),
    );
  }

  /// The "featured" submetric line chart for each measure type
  Widget _buildFeaturedChart(
      String measureType, List<Map<String, dynamic>> docs) {
    final Map<String, String> featured = {
      'BIA': 'weightInKg',
      'USArmy': 'usArmyBodyFatPercent',
      'Plicometro': 'plicBodyFatPercent',
    };
    final sub = featured[measureType];
    if (sub == null) return const SizedBox.shrink();

    // Gather sub's data
    final List<ChartData> chartData = [];
    for (final doc in docs) {
      final dt = (doc['timestamp'] as Timestamp?)?.toDate();
      if (dt == null) continue;
      final rawVal = doc[sub] ?? doc[sub.toLowerCase()];
      final val = double.tryParse(rawVal?.toString() ?? '');
      if (val != null) chartData.add(ChartData(dt, val));
    }
    if (chartData.length < 2) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text('Not enough data for $sub to display a chart.'),
        ),
      );
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

    final subLabel = prettyLabels[sub] ?? sub;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text('$subLabel Trend',
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            SizedBox(
              height: 240,
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
                          return Text(label,
                              style: const TextStyle(fontSize: 10));
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
                    rightTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles:
                        AxisTitles(sideTitles: SideTitles(showTitles: false)),
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
            ),
          ],
        ),
      ),
    );
  }

  /// Build a row/wrap of submetric cards, sized bigger
  Widget _buildMeasurementCardsRow(
      List<String> submetrics, List<Map<String, dynamic>> docs) {
    final cards =
        submetrics.map((sub) => _buildSubmetricCard(sub, docs)).toList();

    // We'll place them in a Wrap, so if there's not enough horizontal space,
    // they automatically flow to a new line.
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: cards,
    );
  }

  /// A single submetric card with larger size (e.g., 110×110).
  Widget _buildSubmetricCard(String sub, List<Map<String, dynamic>> docs) {
    final label = prettyLabels[sub] ?? sub;
    final latestVal = _getLatestValueForSubmetric(docs, sub) ?? 'N/A';
    final icon = _chooseIconForSubmetric(sub);

    return GestureDetector(
      onTap: () => _showSubmetricChartPopup(context, sub, docs),
      child: Container(
        width: 110,
        height: 110,
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 3)],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: Colors.blueGrey.shade800),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              latestVal.toString(),
              style: const TextStyle(fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  /// The isyScore row (one wide card) if isyScore is present
  Widget _buildIsyScoreRow(List<Map<String, dynamic>> docs) {
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
    // color code
    Color color = Colors.blueGrey.shade800;
    if (valDouble != null) {
      if (valDouble < 40)
        color = Colors.redAccent;
      else if (valDouble < 70)
        color = Colors.orange;
      else
        color = Colors.green;
    }

    return GestureDetector(
      onTap: () => _showSubmetricChartPopup(context, 'isyScore', docs),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.star, color: color, size: 20),
            const SizedBox(width: 8),
            Text('IsyScore',
                style: TextStyle(
                    fontWeight: FontWeight.bold, color: color, fontSize: 14)),
            const SizedBox(width: 16),
            Text(displayVal,
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold, color: color)),
          ],
        ),
      ),
    );
  }

  /// Build a DataTable with all historical data for the measure type
  Widget _buildTypeDataTable(
      String measureType, List<Map<String, dynamic>> docs) {
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
      const DataColumn(
          label: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
    ];
    for (final dtStr in dtStrings) {
      columns.add(DataColumn(label: Text(dtStr)));
    }

    final rows = <DataRow>[];
    for (final sub in submetrics) {
      final label = prettyLabels[sub] ?? sub;
      final cells = <DataCell>[];
      cells.add(DataCell(
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold))));

      for (int i = 0; i < docs.length; i++) {
        final doc = docs[i];
        final val = doc[sub] ?? doc[sub.toLowerCase()];
        cells.add(DataCell(Text(val?.toString() ?? '–')));
      }
      rows.add(DataRow(cells: cells));
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          columns: columns,
          rows: rows,
          columnSpacing: 20,
          dataRowHeight: 36,
          headingRowHeight: 36,
          dividerThickness: 1,
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

  /// Returns the latest value for sub in docs
  dynamic _getLatestValueForSubmetric(
      List<Map<String, dynamic>> docs, String sub) {
    for (int i = docs.length - 1; i >= 0; i--) {
      final doc = docs[i];
      if (doc.containsKey(sub)) {
        return doc[sub];
      }
    }
    return null;
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
