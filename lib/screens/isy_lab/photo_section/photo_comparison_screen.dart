import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

enum CompareMode {
  sideBySide,
  slidingOverlay,
}

class PhotoComparisonTab extends StatefulWidget {
  final String clientUid;
  const PhotoComparisonTab({Key? key, required this.clientUid})
      : super(key: key);

  @override
  State<PhotoComparisonTab> createState() => _PhotoComparisonTabState();
}

/// A helper model for the 4 “poses” or categories
class PoseCategory {
  final String key;            
  final String displayName;    
  final String assetPlaceholder;

  PoseCategory({
    required this.key,
    required this.displayName,
    required this.assetPlaceholder,
  });
}

class _PhotoComparisonTabState extends State<PhotoComparisonTab>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  // All photos from Firestore
  List<Map<String, dynamic>> _allPhotos = [];

  // Category silhouettes (kept for completeness)
  final List<_CategoryCardData> _categories = [
    _CategoryCardData(
      key: 'frontale',
      label: 'Front',
      assetPathMale: 'assets/images/man_silhouette_front.jpg',
      assetPathFemale: 'assets/images/woman_silhouette_front.jpg',
    ),
    _CategoryCardData(
      key: 'posteriore',
      label: 'Back',
      assetPathMale: 'assets/images/man_silhouette_back.jpg',
      assetPathFemale: 'assets/images/woman_silhouette_back.jpg',
    ),
    _CategoryCardData(
      key: 'laterale sx',
      label: 'Left',
      assetPathMale: 'assets/images/man_silhouette_lateral_left.jpg',
      assetPathFemale: 'assets/images/woman_silhouette_lateral_left.jpg',
    ),
    _CategoryCardData(
      key: 'laterale dx',
      label: 'Right',
      assetPathMale: 'assets/images/man_silhouette_lateral_right.jpg',
      assetPathFemale: 'assets/images/woman_silhouette_lateral_right.jpg',
    ),
  ];

  // Chosen category (if needed)
  String? _selectedCategory;
  String _gender = 'Male';

  // Filter & compare modes
  DateTime? _startDateFilter;
  bool _showFilterPanel = false;
  CompareMode _compareMode = CompareMode.sideBySide;

  // The two photos to compare: older and newer
  Map<String, dynamic>? _olderPhoto;
  Map<String, dynamic>? _newerPhoto;

  @override
  void initState() {
    super.initState();
    _loadGenderAndPhotos();
  }

  Future<void> _loadGenderAndPhotos() async {
    await _loadGender();
    await _loadAllPhotos();
  }

  Future<void> _loadGender() async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientUid)
        .get();
    if (doc.exists) {
      final data = doc.data();
      if (data != null && data.containsKey('gender')) {
        _gender = data['gender'].toString();
      }
    }
    setState(() {});
  }

  Future<void> _loadAllPhotos() async {
    final snap = await FirebaseFirestore.instance
        .collection('clientPhotos')
        .doc(widget.clientUid)
        .collection('photos')
        .orderBy('uploadTimestamp', descending: false)
        .get();

    final docs = snap.docs.map((d) {
      final dData = d.data();
      dData['docId'] = d.id;
      return dData;
    }).toList();

    setState(() {
      _allPhotos = docs
          .map((map) => {
                ...map,
                'uploadDate': (map['uploadTimestamp'] is Timestamp)
                    ? (map['uploadTimestamp'] as Timestamp).toDate()
                    : null,
              })
          .toList();
    });
  }

  List<Map<String, dynamic>> get _filteredPhotos {
    if (_selectedCategory == null) return [];
    final cat = _selectedCategory!;
    final subset = _allPhotos.where((p) => p['category'] == cat).toList();
    if (_startDateFilter != null) {
      subset.removeWhere((p) {
        final dt = p['uploadDate'] as DateTime?;
        if (dt == null) return true;
        return dt.isBefore(_startDateFilter!);
      });
    }
    return subset;
  }

  void _quickSetFilter(Duration dur) {
    final now = DateTime.now();
    setState(() {
      _startDateFilter = now.subtract(dur);
    });
  }

  void _clearFilter() {
    setState(() {
      _startDateFilter = null;
    });
  }

  void _toggleFilterPanel() {
    setState(() {
      _showFilterPanel = !_showFilterPanel;
    });
  }

  Future<void> _refreshPhotos() async {
    await _loadAllPhotos();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: FloatingActionButton(
        onPressed: _refreshPhotos,
        tooltip: 'Refresh Photos',
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        child: const Icon(Icons.refresh),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 16),
            _buildCategoryRow(context),
            if (_showFilterPanel) ...[
              const SizedBox(height: 2),
              _buildFilterPanel(context),
              const SizedBox(height: 2),
            ],
            if (!_showFilterPanel) const SizedBox(height: 12),
            _buildCompareModeToggles(context),
            const SizedBox(height: 16),
            _buildThumbnailRow(),
            const SizedBox(height: 20),
            if (_olderPhoto != null && _newerPhoto != null)
              _buildComparisonArea(context)
            else
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'Select two images from the same category for comparison.',
                  style: TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Category Row ---
  Widget _buildCategoryRow(BuildContext context) {
    final filterBgColor = _showFilterPanel
        ? Theme.of(context).colorScheme.primary
        : Colors.transparent;
    final filterIconColor = _showFilterPanel
        ? Theme.of(context).colorScheme.onPrimary
        : Colors.black54;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var cat in _categories)
              Expanded(
                child: _CategoryCardWidget(
                  data: cat,
                  isMale: _gender.toLowerCase().contains('male'),
                  isSelected: (_selectedCategory == cat.key),
                  onTap: () {
                    setState(() {
                      if (_selectedCategory == cat.key) {
                        _selectedCategory = null;
                        _olderPhoto = null;
                        _newerPhoto = null;
                      } else {
                        _selectedCategory = cat.key;
                        _olderPhoto = null;
                        _newerPhoto = null;
                      }
                    });
                  },
                ),
              ),
            Container(
              decoration: BoxDecoration(
                color: filterBgColor,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: Icon(Icons.filter_list, color: filterIconColor),
                onPressed: _toggleFilterPanel,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Filter Panel ---
  Widget _buildFilterPanel(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
      child: Container(
        padding: const EdgeInsets.only(left: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                ElevatedButton(
                  onPressed: () => _quickSetFilter(const Duration(days: 7)),
                  child: const Text('Last Week'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: () => _quickSetFilter(const Duration(days: 30)),
                  child: const Text('Last Month'),
                ),
                const SizedBox(width: 8),
                OutlinedButton(
                  onPressed: _clearFilter,
                  child: const Text('Clear'),
                ),
              ],
            ),
            if (_startDateFilter != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Filtering since ${DateFormat.yMMMd().format(_startDateFilter!)}',
                  style: const TextStyle(fontSize: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // --- Compare Mode Toggles ---
  Widget _buildCompareModeToggles(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildModeButton(
            mode: CompareMode.sideBySide,
            icon: Icons.view_week,
            label: 'Side-by-Side',
          ),
          const SizedBox(width: 8),
          _buildModeButton(
            mode: CompareMode.slidingOverlay,
            icon: Icons.view_carousel,
            label: 'Overlay',
          ),
        ],
      ),
    );
  }

  Widget _buildModeButton({
    required CompareMode mode,
    required IconData icon,
    required String label,
  }) {
    final isSel = (_compareMode == mode);
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _compareMode = mode),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSel
                ? Theme.of(context).colorScheme.primary
                : Colors.grey.shade300,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSel
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.black54,
              ),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: isSel
                      ? Theme.of(context).colorScheme.onPrimary
                      : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- Thumbnail Row ---
  Widget _buildThumbnailRow() {
    if (_selectedCategory == null) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'Select a category above.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    final photos = _filteredPhotos;
    if (photos.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text(
          'No photos found for this category/filter.',
          style: TextStyle(color: Colors.grey),
        ),
      );
    }
    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: photos.length,
        itemBuilder: (ctx, i) {
          final p = photos[i];
          final imageUrl = p['imageUrl'] ?? '';
          final dt = p['uploadDate'] as DateTime?;
          final dateStr = (dt != null) ? DateFormat('yyyy-MM-dd').format(dt) : '';
          final isOlder = (_olderPhoto == p);
          final isNewer = (_newerPhoto == p);
          return GestureDetector(
            onTap: () => _selectPhoto(p),
            child: Container(
              width: 100,
              height: 100,
              margin: const EdgeInsets.only(right: 8),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrl,
                      width: 100,
                      height: 100,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    left: 2,
                    top: 2,
                    child: Container(
                      color: Colors.black54,
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      child: Text(
                        dateStr,
                        style: const TextStyle(fontSize: 9, color: Colors.white),
                      ),
                    ),
                  ),
                  if (isOlder || isNewer)
                    Positioned.fill(
                      child: Container(
                        color: Colors.black54,
                        alignment: Alignment.center,
                        child: Text(
                          isOlder ? 'Older' : 'Newer',
                          style: const TextStyle(color: Colors.white, fontSize: 11),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _selectPhoto(Map<String, dynamic> p) {
    if (_olderPhoto == null) {
      setState(() => _olderPhoto = p);
      return;
    }
    if (_newerPhoto == null) {
      final olderTime = _olderPhoto?['uploadDate'] as DateTime?;
      final thisTime = p['uploadDate'] as DateTime?;
      if (olderTime != null &&
          thisTime != null &&
          thisTime.isBefore(olderTime)) {
        setState(() {
          _newerPhoto = _olderPhoto;
          _olderPhoto = p;
        });
      } else {
        setState(() {
          _newerPhoto = p;
        });
      }
      return;
    }
    setState(() {
      _olderPhoto = p;
      _newerPhoto = null;
    });
  }

  // --- Comparison Area ---
  Widget _buildComparisonArea(BuildContext context) {
    if (_compareMode == CompareMode.sideBySide) {
      return _buildSideBySideCards(context);
    } else {
      return _buildOverlayCard(context);
    }
  }

  Widget _buildSideBySideCards(BuildContext context) {
    final older = _olderPhoto!;
    final newer = _newerPhoto!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          Expanded(child: _buildOneComparisonCard(older, isOlder: true)),
          const SizedBox(width: 16),
          Expanded(child: _buildOneComparisonCard(newer, isOlder: false)),
        ],
      ),
    );
  }

  Widget _buildOverlayCard(BuildContext context) {
    final older = _olderPhoto!;
    final newer = _newerPhoto!;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 3,
          child: Container(
            width: 500,
            height: MediaQuery.of(context).size.height * 0.62,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white, // White background for clarity.
            ),
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildCompareImage(older['imageUrl']),
                ),
                // Updated sliding overlay with a larger hit area and visible swipe hint.
                Positioned.fill(
                  child: _SlidingOverlay(newerImageUrl: newer['imageUrl']),
                ),
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.black54,
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Older: ${_fmt(older)}',
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            'Newer: ${_fmt(newer)}',
                            style: const TextStyle(color: Colors.white),
                            textAlign: TextAlign.right,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOneComparisonCard(Map<String, dynamic> photo,
      {required bool isOlder}) {
    final imageUrl = photo['imageUrl'] ?? '';
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.62,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
        ),
        child: Stack(
          children: [
            Positioned.fill(child: _buildCompareImage(imageUrl)),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black54,
                padding: const EdgeInsets.all(4),
                child: Text(
                  '${isOlder ? "Older" : "Newer"}: ${_fmt(photo)}',
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompareImage(String url) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        loadingBuilder: (ctx, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (ctx, error, stack) {
          return const Center(child: Icon(Icons.error, color: Colors.red));
        },
      ),
    );
  }

  String _fmt(Map<String, dynamic> photo) {
    final dt = photo['uploadDate'] as DateTime?;
    if (dt == null) return '???';
    return DateFormat('yyyy-MM-dd').format(dt);
  }
}

/// Data model for category card info.
class _CategoryCardData {
  final String key;
  final String label;
  final String assetPathMale;
  final String assetPathFemale;

  _CategoryCardData({
    required this.key,
    required this.label,
    required this.assetPathMale,
    required this.assetPathFemale,
  });
}

/// Category card widget with gradient if selected.
/// Here the text is aligned at the bottom.
class _CategoryCardWidget extends StatelessWidget {
  final _CategoryCardData data;
  final bool isSelected;
  final VoidCallback onTap;
  final bool isMale;

  const _CategoryCardWidget({
    Key? key,
    required this.data,
    required this.isSelected,
    required this.onTap,
    required this.isMale,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cardDecoration = isSelected
        ? BoxDecoration(
            gradient: LinearGradient(
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          )
        : BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
          );
    final textColor = isSelected
        ? theme.colorScheme.onPrimary
        : Colors.black87;
    return GestureDetector(
      onTap: onTap,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        elevation: 3,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: Colors.transparent,
        child: Container(
          decoration: cardDecoration,
          padding: const EdgeInsets.all(8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Image.asset(isMale ? data.assetPathMale : data.assetPathFemale, height: 70),
              Text(
                data.label,
                style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sliding overlay widget with improved hit area and visible swipe hint.
class _SlidingOverlay extends StatefulWidget {
  final String newerImageUrl;
  const _SlidingOverlay({Key? key, required this.newerImageUrl})
      : super(key: key);

  @override
  State<_SlidingOverlay> createState() => _SlidingOverlayState();
}

class _SlidingOverlayState extends State<_SlidingOverlay> {
  double _overlayFraction = 0.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (ctx, constraints) {
        final totalWidth = constraints.maxWidth;
        final overlayWidth = totalWidth * _overlayFraction;
        return GestureDetector(
          onHorizontalDragUpdate: (details) {
            setState(() {
              // Adjust sensitivity by dividing by a factor (0.3 makes it require more drag distance)
              _overlayFraction -= details.primaryDelta! / (totalWidth * 0.3);
              if (_overlayFraction < 0) _overlayFraction = 0;
              if (_overlayFraction > 1) _overlayFraction = 1;
            });
          },
          child: Stack(
            children: [
              // The new image anchored to the right.
              Positioned(
                right: 0,
                top: 0,
                bottom: 0,
                width: overlayWidth,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    widget.newerImageUrl,
                    fit: BoxFit.cover,
                    loadingBuilder: (ctx, child, prog) {
                      if (prog == null) return child;
                      return const Center(child: CircularProgressIndicator());
                    },
                    errorBuilder: (ctx, error, stack) {
                      return const Center(child: Icon(Icons.error, color: Colors.red));
                    },
                  ),
                ),
              ),
              // A larger sliding handle area with an icon and a visible hint.
              Positioned(
                right: overlayWidth - 20,
                top: 0,
                bottom: 0,
                width: 40, // Increase the hit area
                child: Container(
                  color: Colors.transparent,
                  alignment: Alignment.center,
                  child: _overlayFraction < 0.1
                      ? const Text(
                          'Swipe',
                          style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                        )
                      : const Icon(Icons.drag_handle, color: Colors.white70, size: 24),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
