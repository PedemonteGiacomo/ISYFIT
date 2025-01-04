import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:isyfit/screens/login_screen.dart';
import 'package:isyfit/screens/medical_history/pdf_view_screen.dart';
import 'package:isyfit/screens/medical_history/image_view_screen.dart';
import 'package:isyfit/widgets/data_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart'; // For date formatting if needed

// Suppose this is your questionnaire screen:
import 'package:isyfit/screens/medical_history/medical_questionnaire/questionnaire_screen.dart';

/// Helper function to calculate age from a date string
int calculateAge(String? dateOfBirth) {
  if (dateOfBirth == null) return 0;
  try {
    final dob = DateTime.parse(dateOfBirth);
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  } catch (e) {
    return 0;
  }
}

class MedicalHistoryScreen extends StatefulWidget {
  /// If `clientUid` is non-null, we load that client’s data (PT perspective).
  /// If `clientUid` is null, we load the currently logged-in user’s data.
  final String? clientUid;

  const MedicalHistoryScreen({
    Key? key,
    this.clientUid,
  }) : super(key: key);

  @override
  _MedicalHistoryScreenState createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  /// Future for the medical_history doc
  late Future<Map<String, dynamic>?> medicalHistory;

  /// Future for the list of medical_documents
  late Future<List<Map<String, dynamic>>> medicalDocuments;

  /// If a PT is viewing a client, we also fetch that client’s name+email
  late Future<Map<String, dynamic>?> clientProfile;

  // For controlling the scroll
  final ScrollController _scrollController = ScrollController();

  // Tracks whether to show the down arrow icon
  bool _showArrow = true;

  // Whether to show all documents or just 3
  bool showAllDocuments = false;

  /// True if this is a PT viewing someone else's data (clientUid != null)
  bool get isPTView => widget.clientUid != null;

  @override
  void initState() {
    super.initState();
    medicalHistory = _fetchMedicalHistory();
    medicalDocuments = _fetchDocuments();
    if (isPTView) {
      clientProfile = _fetchClientProfile();
    }
  }

  /// Returns `widget.clientUid` if provided, else the current user's UID
  String? get targetUid {
    if (widget.clientUid != null) {
      return widget.clientUid;
    }
    final user = FirebaseAuth.instance.currentUser;
    return user?.uid;
  }

  /// Fetch the medical_history doc for the target user
  Future<Map<String, dynamic>?> _fetchMedicalHistory() async {
    final uid = targetUid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('medical_history')
        .doc(uid)
        .get();
    return doc.data();
  }

  /// Fetch the `medical_documents` for the target user
  Future<List<Map<String, dynamic>>> _fetchDocuments() async {
    final uid = targetUid;
    if (uid == null) return [];
    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('medical_documents')
        .get();

    return querySnapshot.docs.map((doc) {
      return {
        'fileName': doc['fileName'],
        'downloadUrl': doc['downloadUrl'],
        'fileType': doc['fileType'],
        'uploadedAt': doc['uploadedAt'],
      };
    }).toList();
  }

  /// If PT is viewing a client, fetch that client's name and email
  Future<Map<String, dynamic>?> _fetchClientProfile() async {
    final uid = targetUid;
    if (uid == null) return null;
    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .get();
    return docSnap.data();
  }

  /// Upload a file if this is the user themself or if you want to allow a PT
  Future<void> _uploadFile(BuildContext context) async {
    try {
      final uid = targetUid;
      if (uid == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No target user found.')),
        );
        return;
      }

      // If a PT is viewing, decide if you want to allow uploading for them.
      // if (isPTView) {
      //   // block or allow
      // }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
      );

      if (result == null || result.files.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected.')),
        );
        return;
      }

      final file = result.files.single;
      Uint8List? fileBytes = file.bytes;

      // If user picks a file from path, read it
      if (fileBytes == null && file.path != null) {
        final fileFromPath = File(file.path!);
        fileBytes = await fileFromPath.readAsBytes();
      }

      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read file. Please try again.')),
        );
        return;
      }

      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final fileName = file.name;

      // Check if file already exists in Firestore
      final existingFiles = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medical_documents')
          .where('fileName', isEqualTo: fileName)
          .get();

      if (existingFiles.docs.isNotEmpty) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File "$fileName" already exists.')),
        );
        return;
      }

      // Upload to Firebase Storage
      final storageRef = FirebaseStorage.instance.ref('medical_documents/$uid/$fileName');
      final uploadTask = storageRef.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Add doc in "users/{uid}/medical_documents"
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medical_documents')
          .add({
        'fileName': fileName,
        'downloadUrl': downloadUrl,
        'fileType': file.extension,
        'uploadedAt': Timestamp.now(),
      });

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully!')),
      );

      // Refresh docs
      setState(() {
        medicalDocuments = _fetchDocuments();
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    }
  }

  /// Decide if you want to hide the delete icon if isPTView == true
  Future<void> _deleteDocument(BuildContext context, Map<String, dynamic> doc) async {
    try {
      final uid = targetUid;
      if (uid == null) return;

      // If PT is viewing, do not allow delete
      if (isPTView) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PT cannot delete this document.')),
        );
        return;
      }

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Delete from Storage
      final storageRef = FirebaseStorage.instance.ref('medical_documents/$uid/${doc['fileName']}');
      await storageRef.delete();

      // Delete from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('medical_documents')
          .where('fileName', isEqualTo: doc['fileName'])
          .get();

      for (final document in querySnapshot.docs) {
        await document.reference.delete();
      }

      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted successfully!')),
      );

      setState(() {
        medicalDocuments = _fetchDocuments();
      });
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
      );
    }
  }

  /// View a document (PDF or Image)
  void _viewDocument(BuildContext context, String url, String fileType) {
    if (fileType == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PDFViewScreen(pdfUrl: url),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ImageViewScreen(imageUrl: url),
        ),
      );
    }
  }

  /// Get the appropriate icon for the file type
  IconData _getFileTypeIcon(String fileType) {
    switch (fileType) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'jpg':
      case 'jpeg':
      case 'png':
        return Icons.image;
      case 'docx':
        return Icons.description;
      default:
        return Icons.insert_drive_file;
    }
  }

  /// Build a small header with the client’s name/email if PT is viewing
  Widget _buildClientHeader(BuildContext context, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown Name';
    final email = data['email'] ?? 'No Email';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(
          color: Colors.deepPurple.shade100,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: Colors.deepPurple.shade100,
            child: const Icon(Icons.person, color: Colors.white),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple.shade700,
                      ),
                ),
                const SizedBox(height: 4),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.deepPurple.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds the documents section with a "card" style, or says "No docs" if empty
  Widget _buildDocumentsSection(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: medicalDocuments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Container(
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(
                color: Colors.blueGrey.withOpacity(0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header: Icon + "Medical Documents"
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blueGrey.withOpacity(0.2),
                      child: Icon(
                        Icons.folder_special,
                        color: Colors.blueGrey.shade700,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Medical Documents',
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                if (!snapshot.hasData || snapshot.data!.isEmpty) ...[
                  const Text(
                    'No documents uploaded yet.',
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 16),
                  // Possibly block a PT from uploading
                  // if (isPTView) no button, else show
                  ElevatedButton.icon(
                    onPressed: () => _uploadFile(context),
                    icon: const Icon(Icons.upload_file),
                    label: const Text('Upload Document'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                        vertical: 12.0,
                        horizontal: 16.0,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                  ),
                ] else ...[
                  // Documents exist
                  _buildDocumentsList(context, snapshot.data!),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDocumentsList(BuildContext context, List<Map<String, dynamic>> docs) {
    final visibleDocs = showAllDocuments ? docs : docs.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: visibleDocs.length,
          itemBuilder: (context, index) {
            final doc = visibleDocs[index];
            final icon = _getFileTypeIcon(doc['fileType']);
            final uploadDate = (doc['uploadedAt'] as Timestamp?)
                    ?.toDate()
                    .toString()
                    .split(' ')[0] ??
                'N/A';

            // If isPTView => hide delete
            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(icon, color: Colors.blue),
                ),
                title: Text(
                  doc['fileName'],
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text(
                  'Uploaded on: $uploadDate',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: Wrap(
                  spacing: 12, // space between icons
                  children: [
                    // Everyone can view
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.green),
                      onPressed: () {
                        _viewDocument(context, doc['downloadUrl'], doc['fileType']);
                      },
                    ),
                    // Only show "delete" if not PT
                    if (!isPTView)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () {
                          _deleteDocument(context, doc);
                        },
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        // "Show All" or "Show Less"
        if (docs.length > 3)
          TextButton(
            onPressed: () {
              setState(() {
                showAllDocuments = !showAllDocuments;
              });
            },
            child: Text(
              showAllDocuments ? 'Show Less Documents' : 'Show All Documents',
            ),
          ),
        const SizedBox(height: 16),

        // Possibly block a PT from uploading more
        ElevatedButton.icon(
          onPressed: () {
            _uploadFile(context);
          },
          icon: const Icon(Icons.upload_file),
          label: const Text('Upload More Documents'),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(
              vertical: 12.0,
              horizontal: 16.0,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
          ),
        ),
      ],
    );
  }

  /// If no medical_history data:
  /// - If isPTView => show "No Medical Data Found" with "Return to Clients"
  /// - Else => show "Introducing card" with "Start Questionnaire"
  Widget _buildNoMedicalHistoryCard() {
    // If it's the PT, we do the old card with "Return to Clients"
    if (isPTView) {
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                color: Colors.orange.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.warning, size: 48, color: Colors.orange.shade600),
                      const SizedBox(height: 16),
                      Text(
                        'No Medical Data Found',
                        style: TextStyle(
                          color: Colors.orange.shade800,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This user has not yet provided any medical history.\n'
                        'Please check back later, or ask the user to fill out their details.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('Return to Clients'),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      // If it's the user themself => show the "Introducing card" with "Start Questionnaire"
      return Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 600),
              child: Card(
                elevation: 4,
                color: Colors.blue.shade50,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.help_outline, size: 48, color: Colors.blue.shade600),
                      const SizedBox(height: 16),
                      Text(
                        'No Medical Data Found',
                        style: TextStyle(
                          color: Colors.blue.shade800,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'It looks like you haven\'t filled in your medical questionnaire yet.\n'
                        'Tap below to start it now and record your medical history.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.black87),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.question_answer),
                        label: const Text('Start Questionnaire'),
                        onPressed: () {
                          // Navigate to your questionnaire screen
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const QuestionnaireScreen(),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade800,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool doProfile = isPTView;
    final User? user = FirebaseAuth.instance.currentUser;

    // Return LoginScreen if no user is logged in
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History Dashboard'),
        centerTitle: true,
      ),
      body: doProfile
          ? FutureBuilder<Map<String, dynamic>?>(
              future: clientProfile,
              builder: (context, snapshotProfile) {
                if (snapshotProfile.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final profileData = snapshotProfile.data;

                return FutureBuilder<Map<String, dynamic>?>(
                  future: medicalHistory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData || snapshot.data == null) {
                      // No medical history doc for PT view
                      return Column(
                        children: [
                          if (profileData != null)
                            _buildClientHeader(context, profileData),
                          Expanded(child: _buildNoMedicalHistoryCard()),
                        ],
                      );
                    }

                    final data = snapshot.data!;
                    return Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollUpdateNotification) {
                              if (notification.metrics.pixels > 50 && _showArrow) {
                                setState(() {
                                  _showArrow = false;
                                });
                              }
                              if (notification.metrics.pixels <= 50 && !_showArrow) {
                                setState(() {
                                  _showArrow = true;
                                });
                              }
                            }
                            return true;
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              children: [
                                if (profileData != null)
                                  _buildClientHeader(context, profileData),
                                // Data Cards
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      // Age / Height / Weight
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Age',
                                              value: data.containsKey('dateOfBirth')
                                                  ? '${calculateAge(data['dateOfBirth'])} yrs'
                                                  : 'N/A',
                                              icon: Icons.calendar_today,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Height',
                                              value: data['height'] != null
                                                  ? '${data['height']} cm'
                                                  : 'N/A',
                                              icon: Icons.height,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Weight',
                                              value: data['weight'] != null
                                                  ? '${data['weight']} kg'
                                                  : 'N/A',
                                              icon: Icons.monitor_weight,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Drinks Alcohol / Smokes
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Drinks Alcohol',
                                              value: data['alcohol'] ?? 'N/A',
                                              icon: Icons.local_drink,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Smokes',
                                              value: data['smokes'] ?? 'N/A',
                                              icon: Icons.smoking_rooms,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Sleep Time / Wake Time
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Sleep Time',
                                              value: data['sleep_time'] ?? 'N/A',
                                              icon: Icons.nights_stay,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Wake Time',
                                              value: data['wake_time'] ?? 'N/A',
                                              icon: Icons.wb_sunny,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Goals / Training Days
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: DataCard(
                                              title: 'Goals',
                                              value: data['goals'] ?? 'N/A',
                                              icon: Icons.fitness_center,
                                              color: Colors.purple,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Training Days',
                                              value: data['training_days'] != null
                                                  ? (data['training_days'] as List).join(', ')
                                                  : 'N/A',
                                              icon: Icons.calendar_today,
                                              color: Colors.teal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // Energetic
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Energetic',
                                              value: data['energetic'] ?? 'N/A',
                                              icon: Icons.battery_charging_full,
                                              color: Colors.yellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Documents
                                _buildDocumentsSection(context),
                              ],
                            ),
                          ),
                        ),
                        if (_showArrow)
                          const Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _AnimatedDownArrow(),
                            ),
                          ),
                      ],
                    );
                  },
                );
              },
            )
          : // If it's the user's own data
              FutureBuilder<Map<String, dynamic>?>(
                  future: medicalHistory,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data == null) {
                      // Show introducing card with "Start Questionnaire"
                      return _buildNoMedicalHistoryCard();
                    }
                    final data = snapshot.data!;
                    return Stack(
                      children: [
                        NotificationListener<ScrollNotification>(
                          onNotification: (notification) {
                            if (notification is ScrollUpdateNotification) {
                              if (notification.metrics.pixels > 50 && _showArrow) {
                                setState(() {
                                  _showArrow = false;
                                });
                              }
                              if (notification.metrics.pixels <= 50 && !_showArrow) {
                                setState(() {
                                  _showArrow = true;
                                });
                              }
                            }
                            return true;
                          },
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    children: [
                                      // 1) Age / Height / Weight
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Age',
                                              value: data.containsKey('dateOfBirth')
                                                  ? '${calculateAge(data['dateOfBirth'])} yrs'
                                                  : 'N/A',
                                              icon: Icons.calendar_today,
                                              color: Colors.blueGrey,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Height',
                                              value: data['height'] != null
                                                  ? '${data['height']} cm'
                                                  : 'N/A',
                                              icon: Icons.height,
                                              color: Colors.blue,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Weight',
                                              value: data['weight'] != null
                                                  ? '${data['weight']} kg'
                                                  : 'N/A',
                                              icon: Icons.monitor_weight,
                                              color: Colors.green,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // 2) Drinks Alcohol / Smokes
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Drinks Alcohol',
                                              value: data['alcohol'] ?? 'N/A',
                                              icon: Icons.local_drink,
                                              color: Colors.orange,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Smokes',
                                              value: data['smokes'] ?? 'N/A',
                                              icon: Icons.smoking_rooms,
                                              color: Colors.red,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // 3) Sleep Time / Wake Time
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Sleep Time',
                                              value: data['sleep_time'] ?? 'N/A',
                                              icon: Icons.nights_stay,
                                              color: Colors.indigo,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Wake Time',
                                              value: data['wake_time'] ?? 'N/A',
                                              icon: Icons.wb_sunny,
                                              color: Colors.amber,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // 4) Goals / Training Days
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 2,
                                            child: DataCard(
                                              title: 'Goals',
                                              value: data['goals'] ?? 'N/A',
                                              icon: Icons.fitness_center,
                                              color: Colors.purple,
                                            ),
                                          ),
                                          const SizedBox(width: 16),
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Training Days',
                                              value: data['training_days'] != null
                                                  ? (data['training_days'] as List).join(', ')
                                                  : 'N/A',
                                              icon: Icons.calendar_today,
                                              color: Colors.teal,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 16),
                                      // 5) Energetic
                                      Row(
                                        children: [
                                          Expanded(
                                            flex: 1,
                                            child: DataCard(
                                              title: 'Energetic',
                                              value: data['energetic'] ?? 'N/A',
                                              icon: Icons.battery_charging_full,
                                              color: Colors.yellow,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 32),
                                // Documents
                                _buildDocumentsSection(context),
                              ],
                            ),
                          ),
                        ),
                        if (_showArrow)
                          const Positioned(
                            bottom: 16,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: _AnimatedDownArrow(),
                            ),
                          ),
                      ],
                    );
                  },
                ),
    );
  }
}

/// A small widget that bounces the arrow up/down
class _AnimatedDownArrow extends StatefulWidget {
  const _AnimatedDownArrow({Key? key}) : super(key: key);

  @override
  __AnimatedDownArrowState createState() => __AnimatedDownArrowState();
}

class __AnimatedDownArrowState extends State<_AnimatedDownArrow>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    )..repeat(reverse: true); // up and down
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Transform.translate(
          offset: Offset(0, _animation.value),
          child: const Icon(
            Icons.arrow_downward,
            color: Colors.grey,
            size: 32,
          ),
        );
      },
    );
  }
}
