import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoCollectionTab extends StatefulWidget {
  final String clientUid;
  const PhotoCollectionTab({Key? key, required this.clientUid})
      : super(key: key);

  @override
  State<PhotoCollectionTab> createState() => _PhotoCollectionTabState();
}

class _PhotoCollectionTabState extends State<PhotoCollectionTab>
    with AutomaticKeepAliveClientMixin {
  late Future<QuerySnapshot> _photosFuture;

  /// Map Firestore categories to user-friendly labels
  final Map<String, String> _categoryLabels = {
    'frontale': 'Front',
    'posteriore': 'Back',
    'laterale sx': 'Lateral Left',
    'laterale dx': 'Lateral Right',
  };

  /// The order in which categories should appear
  final List<String> _categoryOrder = [
    'frontale',
    'posteriore',
    'laterale sx',
    'laterale dx',
  ];

  /// Track whether each category is expanded or collapsed (initially true).
  final Map<String, bool> _expandedStates = {
    'frontale': true,
    'posteriore': true,
    'laterale sx': true,
    'laterale dx': true,
  };

  /// Current number of columns for the grid (adjusted by slider)
  int _currentColumns = 4;

  /// Whether the floating slider is currently visible
  bool _showSlider = false;

  @override
  bool get wantKeepAlive => true; // preserve state when switching tabs

  @override
  void initState() {
    super.initState();
    _fetchPhotos();
  }

  void _fetchPhotos() {
    _photosFuture = FirebaseFirestore.instance
        .collection('clientPhotos')
        .doc(widget.clientUid)
        .collection('photos')
        .orderBy('uploadTimestamp', descending: true)
        .get();
  }

  Future<void> _refresh() async {
    setState(() {
      _fetchPhotos();
    });
  }

  /// Toggles the visibility of our floating slider
  void _toggleSlider() {
    setState(() {
      _showSlider = !_showSlider;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAlive

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // The actual gallery UI
          FutureBuilder<QuerySnapshot>(
            future: _photosFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No photos found.'));
              }

              // Group docs by category
              final allDocs = snapshot.data!.docs;
              final Map<String, List<QueryDocumentSnapshot>> categoryGroups = {
                'frontale': [],
                'posteriore': [],
                'laterale sx': [],
                'laterale dx': [],
              };

              for (var doc in allDocs) {
                final data = doc.data() as Map<String, dynamic>;
                final category = (data['category'] ?? 'unknown').toString();
                if (categoryGroups.containsKey(category)) {
                  categoryGroups[category]!.add(doc);
                }
              }

              // Build a scrollable column with 4 sections
              return SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                child: Column(
                  children: _categoryOrder.map((catKey) {
                    final catDocs = categoryGroups[catKey]!;
                    final catLabel = _categoryLabels[catKey] ?? 'Unknown';
                    return _buildCategorySection(catKey, catLabel, catDocs);
                  }).toList(),
                ),
              );
            },
          ),

          // A Column of FABs in bottom-right
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1) Refresh button
                FloatingActionButton(
                  heroTag: 'refreshPhotos',
                  onPressed: _refresh,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  child: Icon(Icons.refresh, color: Theme.of(context).colorScheme.onPrimary),
                ),
                const SizedBox(height: 10),
                // 2) Slider settings button
                FloatingActionButton(
                  heroTag: 'sliderColumns',
                  onPressed: _toggleSlider,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: const Icon(Icons.grid_on),
                ),
              ],
            ),
          ),

          // The floating slider widget (if visible)
          if (_showSlider)
            Positioned(
              // place it slightly above the second FAB
              bottom: 90, // adjust as needed
              right: 16,
              child: _buildFloatingSliderCard(context),
            ),
        ],
      ),
    );
  }

  /// Builds a "collapsible" Card for a single category
  Widget _buildCategorySection(
    String categoryKey,
    String categoryLabel,
    List<QueryDocumentSnapshot> docs,
  ) {
    final isExpanded = _expandedStates[categoryKey] ?? true;

    // If no photos in this category
    if (docs.isEmpty) {
      return Card(
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 2,
        child: _buildHeader(
          categoryKey: categoryKey,
          categoryLabel: '$categoryLabel (No Photos)',
          isExpanded: false,
          childBelow: const SizedBox(),
        ),
      );
    }

    // If we have photos
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        child: _buildHeader(
          categoryKey: categoryKey,
          categoryLabel: categoryLabel,
          isExpanded: isExpanded,
          childBelow: isExpanded ? _buildPhotoGrid(docs) : const SizedBox(),
        ),
      ),
    );
  }

  /// Builds the "header row" + the content below (photo grid, if expanded)
  Widget _buildHeader({
    required String categoryKey,
    required String categoryLabel,
    required bool isExpanded,
    required Widget childBelow,
  }) {
    // We'll create a gradient from the primary color to a slightly transparent version
    final primary = Theme.of(context).colorScheme.primary;
    final onPrimary = Theme.of(context).colorScheme.onPrimary;

    return Column(
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _expandedStates[categoryKey] = !isExpanded;
            });
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  primary,
                  primary.withOpacity(0.6),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(12),
                topRight: const Radius.circular(12),
                bottomLeft: Radius.circular(isExpanded ? 0 : 12),
                bottomRight: Radius.circular(isExpanded ? 0 : 12),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    categoryLabel,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: onPrimary,
                        ),
                  ),
                ),
                // Show a simple chevron that rotates
                AnimatedRotation(
                  duration: const Duration(milliseconds: 300),
                  turns: isExpanded ? 0.5 : 0.0, // rotate arrow 180 degrees
                  child: Icon(
                    Icons.keyboard_arrow_down,
                    color: onPrimary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Show the grid if expanded
        if (isExpanded) childBelow,
      ],
    );
  }

  /// A grid of photo thumbnails, sized by _currentColumns
  Widget _buildPhotoGrid(List<QueryDocumentSnapshot> docs) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        // Use _currentColumns to define the # of columns
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _currentColumns,
          crossAxisSpacing: 4,
          mainAxisSpacing: 4,
          // For squares, ratio = 1.0; or smaller if you want them more portrait
          childAspectRatio: 1.0,
        ),
        itemCount: docs.length,
        itemBuilder: (ctx, i) {
          final data = docs[i].data() as Map<String, dynamic>;
          final imageUrl = data['imageUrl'] ?? '';

          return ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Material(
              color: Colors.grey.shade200,
              child: Ink.image(
                image: NetworkImage(imageUrl),
                fit: BoxFit.cover,
                child: InkWell(
                  onTap: () => _showFullImage(imageUrl),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Show the tapped image in a dialog with zoom/pan
  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.black87,
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 4.0,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            loadingBuilder: (ctx, child, progress) {
              if (progress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            errorBuilder: (ctx, error, stack) {
              return const Center(
                child: Icon(Icons.error, color: Colors.red),
              );
            },
          ),
        ),
      ),
    );
  }

  /// Builds the small "floating card" that holds our slider
  Widget _buildFloatingSliderCard(BuildContext context) {
    return Card(
      elevation: 6,
      color: Colors.white.withOpacity(0.9),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: Container(
        width: 200, // adjust as desired
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Thumbnails: $_currentColumns',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Slider(
              value: _currentColumns.toDouble(),
              min: 2,
              max: 8,
              divisions: 6,
              label: '$_currentColumns',
              onChanged: (double newVal) {
                setState(() {
                  _currentColumns = newVal.toInt();
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
