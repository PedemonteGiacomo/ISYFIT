import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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

class PhotoInsertTab extends StatefulWidget {
  final String clientUid;

  const PhotoInsertTab({
    Key? key,
    required this.clientUid,
  }) : super(key: key);

  @override
  State<PhotoInsertTab> createState() => _PhotoInsertTabState();
}

class _PhotoInsertTabState extends State<PhotoInsertTab>
    with AutomaticKeepAliveClientMixin {
  late Future<DocumentSnapshot<Map<String, dynamic>>> _userFuture;
  late List<PoseCategory> _poses;

  /// Stores the image File for each pose category (if selected)
  final Map<String, File?> _selectedImages = {};

  /// Tracks whether we are currently uploading an image for each pose
  final Map<String, bool> _isUploading = {};

  /// Which category is selected in portrait mode (only one card is shown)
  String? _selectedCategory;

  @override
  bool get wantKeepAlive => true; // preserve tab state

  @override
  void initState() {
    super.initState();
    // Fetch the user doc for gender, etc.
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(widget.clientUid)
        .get();
  }

  List<PoseCategory> _buildPosesForGender(String gender) {
    final lowerGender = gender.toLowerCase();
    final isMale = lowerGender.contains('male');
    if (isMale) {
      // Ordered: Front, Back, Left, Right
      return [
        PoseCategory(
          key: 'frontale',
          displayName: 'Front',
          assetPlaceholder: 'assets/images/man_silhouette_front.jpg',
        ),
        PoseCategory(
          key: 'posteriore',
          displayName: 'Back',
          assetPlaceholder: 'assets/images/man_silhouette_back.jpg',
        ),
        PoseCategory(
          key: 'laterale sx',
          displayName: 'Left',
          assetPlaceholder: 'assets/images/man_silhouette_lateral_left.jpg',
        ),
        PoseCategory(
          key: 'laterale dx',
          displayName: 'Right',
          assetPlaceholder: 'assets/images/man_silhouette_lateral_right.jpg',
        ),
      ];
    } else {
      // Assume female
      return [
        PoseCategory(
          key: 'frontale',
          displayName: 'Front',
          assetPlaceholder: 'assets/images/woman_silhouette_front.jpg',
        ),
        PoseCategory(
          key: 'posteriore',
          displayName: 'Back',
          assetPlaceholder: 'assets/images/woman_silhouette_back.jpg',
        ),
        PoseCategory(
          key: 'laterale sx',
          displayName: 'Left',
          assetPlaceholder: 'assets/images/woman_silhouette_lateral_left.jpg',
        ),
        PoseCategory(
          key: 'laterale dx',
          displayName: 'Right',
          assetPlaceholder: 'assets/images/woman_silhouette_lateral_right.jpg',
        ),
      ];
    }
  }

  Future<void> _pickImage(String poseKey, ImageSource source) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: source);
    if (pickedFile == null) return; // user cancelled

    setState(() {
      _selectedImages[poseKey] = File(pickedFile.path);
    });
  }

  Future<void> _uploadPhoto(String poseKey) async {
    final file = _selectedImages[poseKey];
    if (file == null) return;
    setState(() => _isUploading[poseKey] = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in.');

      final fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storagePath = 'clientPhotos/${widget.clientUid}/$fileName';
      final storageRef = FirebaseStorage.instance.ref().child(storagePath);
      await storageRef.putFile(file);
      final downloadUrl = await storageRef.getDownloadURL();

      final photosCollection = FirebaseFirestore.instance
          .collection('clientPhotos')
          .doc(widget.clientUid)
          .collection('photos');
      await photosCollection.add({
        'category': poseKey,
        'imageUrl': downloadUrl,
        'uploadedBy': user.uid,
        'uploadTimestamp': Timestamp.now(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Photo uploaded successfully for $poseKey'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error uploading photo: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isUploading[poseKey] = false);
    }
  }

  /// Builds the single upload card for a pose, used in portrait mode.
  Widget _buildPoseCard(BuildContext context, PoseCategory pose) {
    final selectedFile = _selectedImages[pose.key];
    final isUploading = _isUploading[pose.key] == true;
    final theme = Theme.of(context);

    // We expand the card's height in portrait so it fills the screen more.
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;
    final cardHeight = isPortrait
        ? MediaQuery.of(context).size.height * 0.75 // bigger fraction for more vertical fill
        : 450.0; // fixed in landscape

    // Make the image region a bigger fraction so there's less empty space
    final imageRegionHeight = isPortrait
        ? cardHeight * 0.60  // 60% of the card
        : cardHeight * 0.40;

    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: SizedBox(
        height: cardHeight,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Pose label
              Text(
                pose.displayName,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Image region
              SizedBox(
                height: imageRegionHeight,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: selectedFile == null
                      ? Image.asset(pose.assetPlaceholder, fit: BoxFit.contain)
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(selectedFile, fit: BoxFit.cover),
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // Row of camera & gallery icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: const Icon(Icons.camera_alt),
                    onPressed: () => _pickImage(pose.key, ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: () => _pickImage(pose.key, ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Upload button or placeholder text
              Expanded(
                child: Center(
                  child: selectedFile != null
                      ? isUploading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                              ),
                              icon: Icon(Icons.cloud_upload, color: theme.colorScheme.onPrimary),
                              label: Text('Upload', style: TextStyle(color: theme.colorScheme.onPrimary)),
                              onPressed: () => _uploadPhoto(pose.key),
                            )
                      : Text(
                          'Take a picture or select it from the gallery',
                          style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds the row of category buttons shown in portrait mode.
  Widget _buildCategorySelectorRow(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SizedBox(
        height: 120,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var cat in _poses)
              Expanded(
                child: _CategoryCardWidget(
                  data: cat,
                  // If you prefer a per-category male/female logic,
                  // you might pass a separate param. Currently it's the same placeholder.
                  isSelected: (_selectedCategory == cat.key),
                  onTap: () {
                    setState(() {
                      if (_selectedCategory == cat.key) {
                        _selectedCategory = null;
                      } else {
                        _selectedCategory = cat.key;
                      }
                    });
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: FutureBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        future: _userFuture,
        builder: (ctx, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text('Client not found.'));
          }

          final userData = snapshot.data!.data();
          final gender = userData?['gender'] ?? 'Male';
          _poses = _buildPosesForGender(gender);

          final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  'Select Which Photo to Insert',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Tap the camera icon to shoot or the gallery icon to upload for the selected view.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // If portrait: show the row of category buttons, then one card for the selected category
                if (isPortrait)
                  Column(
                    children: [
                      _buildCategorySelectorRow(context),
                      const SizedBox(height: 16),
                      if (_selectedCategory != null)
                        _buildPoseCard(
                          context,
                          _poses.firstWhere(
                            (p) => p.key == _selectedCategory,
                            orElse: () => _poses.first,
                          ),
                        )
                      else
                        const Padding(
                          padding: EdgeInsets.all(8.0),
                          child: Text('Select a category to upload a photo.'),
                        ),
                    ],
                  )

                // If landscape: show all 4 cards in a grid
                else
                  GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9,
                    children: _poses
                        .map((pose) => _buildPoseCard(context, pose))
                        .toList(),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A card widget that displays a category silhouette and label.
/// Used in the top row (portrait mode) for the user to pick which category
/// they want to work with.
class _CategoryCardWidget extends StatelessWidget {
  final PoseCategory data;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryCardWidget({
    Key? key,
    required this.data,
    required this.isSelected,
    required this.onTap,
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
              Image.asset(data.assetPlaceholder, height: 70),
              Text(
                data.displayName,
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
