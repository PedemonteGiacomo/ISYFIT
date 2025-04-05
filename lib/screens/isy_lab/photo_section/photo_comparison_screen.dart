import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoComparisonTab extends StatefulWidget {
  final String clientUid;
  const PhotoComparisonTab({Key? key, required this.clientUid}) : super(key: key);

  @override
  State<PhotoComparisonTab> createState() => _PhotoComparisonTabState();
}

class _PhotoComparisonTabState extends State<PhotoComparisonTab>
    with AutomaticKeepAliveClientMixin {
  List<Map<String, dynamic>> _photos = [];

  @override
  bool get wantKeepAlive => true; // keep state

  @override
  void initState() {
    super.initState();
    _loadPhotos();
  }

  Future<void> _loadPhotos() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('clientPhotos')
        .doc(widget.clientUid)
        .collection('photos')
        .orderBy('uploadTimestamp', descending: false)
        .get();
    final docs = snapshot.docs.map((d) => d.data() as Map<String, dynamic>).toList();
    setState(() {
      _photos = docs;
    });
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // keepAlive
    return Container(
      color: Colors.white,
      child: _photos.isEmpty
          ? const Center(child: Text('No photos to compare.'))
          : PageView.builder(
              itemCount: (_photos.length / 2).ceil(),
              itemBuilder: (ctx, index) {
                final firstIdx = index * 2;
                final secondIdx = firstIdx + 1;
                final firstPhoto = _photos[firstIdx];
                final secondPhoto = (secondIdx < _photos.length)
                    ? _photos[secondIdx]
                    : null;

                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      // left photo
                      Expanded(
                        child: _buildCompareCard(
                          firstPhoto['imageUrl'] ?? '',
                          firstPhoto['category'] ?? 'unknown',
                        ),
                      ),
                      const SizedBox(width: 10),
                      // right photo
                      Expanded(
                        child: (secondPhoto == null)
                            ? Container()
                            : _buildCompareCard(
                                secondPhoto['imageUrl'] ?? '',
                                secondPhoto['category'] ?? 'unknown',
                              ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildCompareCard(String imageUrl, String category) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (ctx, child, progress) {
                  if (progress == null) return child;
                  return const Center(child: CircularProgressIndicator());
                },
                errorBuilder: (ctx, error, stack) {
                  return const Center(child: Icon(Icons.error, color: Colors.red));
                },
              ),
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              color: Colors.black54,
              padding: const EdgeInsets.all(4),
              child: Text(
                category,
                style: const TextStyle(color: Colors.white),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
