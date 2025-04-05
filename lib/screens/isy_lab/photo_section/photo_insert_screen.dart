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

  final Map<String, File?> _selectedImages = {};
  final Map<String, bool> _isUploading = {};

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
      // Ordered: Front, Back, Lateral Left, Lateral Right
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
          displayName: 'Lateral Left',
          assetPlaceholder: 'assets/images/man_silhouette_lateral_left.jpg',
        ),
        PoseCategory(
          key: 'laterale dx',
          displayName: 'Lateral Right',
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
          displayName: 'Lateral Left',
          assetPlaceholder: 'assets/images/woman_silhouette_lateral_left.jpg',
        ),
        PoseCategory(
          key: 'laterale dx',
          displayName: 'Lateral Right',
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

  /// Single function to build each card so we can reuse it in either layout
  Widget _buildPoseCard(BuildContext context, PoseCategory pose) {
    final selectedFile = _selectedImages[pose.key];
    final isUploading = _isUploading[pose.key] == true;

    // Colors for the upload button from the app theme
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    final primary = Theme.of(context).colorScheme.primary;

    // Define a fixed total height for each card so they align.
    const double cardHeight = 320;

    return Card(
      margin: const EdgeInsets.all(8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: SizedBox(
        height: cardHeight, // ensure all cards have the same total height
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            // We'll align everything to the top to keep the
            // heights consistent regardless of content differences.
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                pose.displayName,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              // Keep the image region a fixed height so it doesn't resize the card
              SizedBox(
                height: 160,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: selectedFile == null
                      ? Image.asset(
                          pose.assetPlaceholder,
                          fit: BoxFit.contain,
                        )
                      : ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.file(
                            selectedFile,
                            fit: BoxFit.cover,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // Row with camera & gallery icons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  IconButton(
                    icon: Icon(Icons.camera_alt),
                    onPressed: () => _pickImage(pose.key, ImageSource.camera),
                  ),
                  IconButton(
                    icon: const Icon(Icons.photo_library),
                    onPressed: () => _pickImage(pose.key, ImageSource.gallery),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Show upload button if there's a file selected, otherwise placeholder text.
              Expanded(
                child: Center(
                  child: selectedFile != null
                      ? isUploading
                          ? const CircularProgressIndicator()
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primary,
                                foregroundColor: onPrimary,
                              ),
                              icon: Icon(Icons.cloud_upload, color: Theme.of(context).colorScheme.onPrimary,),
                              label: Text('Upload', style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
                              onPressed: () => _uploadPhoto(pose.key),
                            )
                      : Text(
                          'Take a picture or select it from the gallery',
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                color: Colors.grey[600],
                              ),
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // for AutomaticKeepAliveClientMixin

    final orientation = MediaQuery.of(context).orientation;
    final isPortrait = orientation == Orientation.portrait;

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
                  'Tap the camera icon to shoot or the gallery icon to upload for each view.',
                  style: Theme.of(context).textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),

                // 1) If portrait => 2x2 grid
                // 2) If landscape => Row with 4 expanded children
                if (isPortrait)
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
                  )
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: _poses
                        .map((pose) => Expanded(
                              child: _buildPoseCard(context, pose),
                            ))
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
