import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PhotoCollectionTab extends StatefulWidget {
  final String clientUid;
  const PhotoCollectionTab({Key? key, required this.clientUid}) : super(key: key);

  @override
  State<PhotoCollectionTab> createState() => _PhotoCollectionTabState();
}

class _PhotoCollectionTabState extends State<PhotoCollectionTab>
    with AutomaticKeepAliveClientMixin {
  late Future<QuerySnapshot> _photosFuture;

  @override
  bool get wantKeepAlive => true; // keep state if desired

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

  @override
  Widget build(BuildContext context) {
    super.build(context); // for keepAlive
    return Container(
      color: Colors.white, // White background
      child: Stack(
        children: [
          FutureBuilder<QuerySnapshot>(
            future: _photosFuture,
            builder: (ctx, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(child: Text('No photos found.'));
              }

              final docs = snapshot.data!.docs;
              return GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, // or 3, etc.
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: docs.length,
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final imageUrl = data['imageUrl'] ?? '';
                  final category = data['category'] ?? 'Unknown';
                  return GestureDetector(
                    onTap: () {
                      // Could show a larger view or do something else
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          // Photo
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
                                  return const Center(
                                      child: Icon(Icons.error, color: Colors.red));
                                },
                              ),
                            ),
                          ),
                          // Category label
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
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
                    ),
                  );
                },
              );
            },
          ),

          // Refresh FAB
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton(
              heroTag: 'refreshPhotos',
              onPressed: _refresh,
              child: const Icon(Icons.refresh),
            ),
          ),
        ],
      ),
    );
  }
}
