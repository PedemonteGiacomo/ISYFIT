import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_core/firebase_core.dart';
import 'package:intl/intl.dart';

import 'package:isyfit/screens/login_screen.dart';
import 'package:isyfit/screens/medical_history/pdf_view_screen.dart';
import 'package:isyfit/screens/medical_history/image_view_screen.dart';
import 'package:isyfit/screens/medical_history/medical_questionnaire/questionnaire_screen.dart';
import 'package:isyfit/widgets/data_card.dart';

/// A helper function to parse and calculate the user’s age from a dateOfBirth string.
int calculateAge(String? dateOfBirth) {
  if (dateOfBirth == null) return 0;
  try {
    final dob = DateTime.parse(dateOfBirth);
    final today = DateTime.now();
    int age = today.year - dob.year;
    if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age;
  } catch (e) {
    return 0;
  }
}

class MedicalHistoryScreen extends StatefulWidget {
  /// If [clientUid] is non-null, a PT is viewing a client’s medical data.
  /// If [clientUid] is null, we load the current logged-in user’s data.
  final String? clientUid;

  const MedicalHistoryScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  _MedicalHistoryScreenState createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  /// The main medical_history doc for the target user
  late Future<Map<String, dynamic>?> medicalHistory;

  /// A list of uploaded documents (PDFs/images) for the user
  late Future<List<Map<String, dynamic>>> medicalDocuments;

  /// If a PT is viewing a client, fetch that client’s minimal profile
  late Future<Map<String, dynamic>?> clientProfile;

  final ScrollController _scrollController = ScrollController();
  bool _showArrow = true;
  bool showAllDocuments = false;

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

  /// If PT is viewing, use [clientUid], else the current user’s uid
  String? get targetUid {
    if (widget.clientUid != null) return widget.clientUid;
    return FirebaseAuth.instance.currentUser?.uid;
  }

  Future<Map<String, dynamic>?> _fetchMedicalHistory() async {
    final uid = targetUid;
    if (uid == null) return null;
    final doc = await FirebaseFirestore.instance
        .collection('medical_history')
        .doc(uid)
        .get();
    return doc.data();
  }

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

  Future<Map<String, dynamic>?> _fetchClientProfile() async {
    final uid = targetUid;
    if (uid == null) return null;
    final docSnap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    return docSnap.data();
  }

  Future<void> _uploadFile(BuildContext context) async {
    final uid = targetUid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No target user found.')),
      );
      return;
    }

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

    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final fileName = file.name;
      // Check if file already exists
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
      final storageRef =
          FirebaseStorage.instance.ref('medical_documents/$uid/$fileName');
      await storageRef.putData(fileBytes);
      final downloadUrl = await storageRef.getDownloadURL();

      // Add doc in Firestore
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

      // Refresh
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

  Future<void> _deleteDocument(BuildContext context, Map<String, dynamic> doc) async {
    final uid = targetUid;
    if (uid == null) return;

    if (isPTView) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('PT cannot delete this document.')),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final storageRef =
          FirebaseStorage.instance.ref('medical_documents/$uid/${doc['fileName']}');
      await storageRef.delete();

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

  void _viewDocument(BuildContext context, String url, String fileType) {
    if (fileType == 'pdf') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => PDFViewScreen(pdfUrl: url)),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => ImageViewScreen(imageUrl: url)),
      );
    }
  }

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

  Widget _buildClientHeader(BuildContext context, Map<String, dynamic> data) {
    final name = data['name'] ?? 'Unknown Name';
    final email = data['email'] ?? 'No Email';
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.deepPurple.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.deepPurple.shade100, width: 1),
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
                  style: TextStyle(fontSize: 14, color: Colors.deepPurple.shade400),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentsSection(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: medicalDocuments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.blueGrey.withOpacity(0.05),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.blueGrey.withOpacity(0.2), width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title
                Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: Colors.blueGrey.withOpacity(0.2),
                      child: Icon(Icons.folder_special, color: Colors.blueGrey.shade700),
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
                  const Text('No documents uploaded yet.', style: TextStyle(fontSize: 16)),
                  const SizedBox(height: 16),
                  if (!isPTView)
                    ElevatedButton.icon(
                      onPressed: () => _uploadFile(context),
                      icon: const Icon(Icons.upload_file),
                      label: const Text('Upload Document'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                ] else ...[
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
            final icon = _getFileTypeIcon(doc['fileType'] ?? '');
            final timestamp = doc['uploadedAt'] as Timestamp?;
            final uploadDate = timestamp != null
                ? DateFormat.yMMMd().format(timestamp.toDate())
                : 'N/A';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: Icon(icon, color: Colors.blue),
                ),
                title: Text(
                  doc['fileName'] ?? '',
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 14),
                ),
                subtitle: Text('Uploaded on: $uploadDate', style: const TextStyle(fontSize: 12)),
                trailing: Wrap(
                  spacing: 12,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.visibility, color: Colors.green),
                      onPressed: () => _viewDocument(context,
                          doc['downloadUrl'] ?? '', doc['fileType'] ?? ''),
                    ),
                    if (!isPTView)
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteDocument(context, doc),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
        if (docs.length > 3)
          TextButton(
            onPressed: () {
              setState(() {
                showAllDocuments = !showAllDocuments;
              });
            },
            child: Text(showAllDocuments ? 'Show Less Documents' : 'Show All Documents'),
          ),
        const SizedBox(height: 16),
        if (!isPTView)
          ElevatedButton.icon(
            onPressed: () => _uploadFile(context),
            icon: const Icon(Icons.upload_file),
            label: const Text('Upload More Documents'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
      ],
    );
  }

  Widget _buildNoMedicalHistoryForUser() {
    // Just go to the questionnaire
    return const QuestionnaireScreen();
  }

  Widget _buildNoMedicalHistoryForPT() {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Card(
              elevation: 4,
              color: Colors.orange.shade50,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Container(
                padding: const EdgeInsets.all(24),
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
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange.shade800,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

  /// Reusable method to create a bold sub-header within the content
  Widget _buildSectionHeader(String title, IconData icon, {Color? color}) {
    final effectiveColor = color ?? Colors.blueGrey;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Row(
        children: [
          Icon(icon, color: effectiveColor, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              color: effectiveColor,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// A small grouping for displaying a single piece of data
  Widget _buildDataLine({
    required String label,
    required String value,
    IconData? icon,
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, color: color ?? Colors.blueGrey, size: 18),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Text(value),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your Anamnesis'),
        centerTitle: true,
      ),
      body: isPTView
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
                      return Column(
                        children: [
                          if (profileData != null)
                            _buildClientHeader(context, profileData),
                          Expanded(child: _buildNoMedicalHistoryForPT()),
                        ],
                      );
                    }
                    final data = snapshot.data!;
                    return _buildMainContent(data, profileData);
                  },
                );
              },
            )
          : FutureBuilder<Map<String, dynamic>?>(
              future: medicalHistory,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data == null) {
                  // If no data, go to the questionnaire
                  return const QuestionnaireScreen();
                }
                final data = snapshot.data!;
                return _buildMainContent(data, null);
              },
            ),
    );
  }

  /// The main method for building the entire "medical history" layout
  Widget _buildMainContent(Map<String, dynamic> data, Map<String, dynamic>? profileData) {
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
                if (isPTView && profileData != null)
                  _buildClientHeader(context, profileData),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildAllDataSections(context, data),
                ),
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
            child: Center(child: _AnimatedDownArrow()),
          ),
      ],
    );
  }

  /// Build all data sections in a single column: personal info, measures, etc.
  Widget _buildAllDataSections(BuildContext context, Map<String, dynamic> data) {
    final ageStr = data.containsKey('dateOfBirth')
        ? '${calculateAge(data['dateOfBirth'])} yrs'
        : 'N/A';
    final profession = data['profession'] ?? 'N/A';
    final phone = data['phone'] ?? 'N/A';
    final injuriesOrSurgery = data['injuriesOrSurgery'] ?? 'N/A';
    final injuriesOrSurgeryDetails = data['injuriesOrSurgeryDetails'] ?? 'N/A';
    final spineJointMuscleIssues = data['spineJointMuscleIssues'] ?? 'N/A';
    final spineJointMuscleDetails = data['spineJointMuscleIssuesDetails'] ?? 'N/A';
    final pathologies = data['pathologies'] ?? 'N/A';
    final pathologiesDetails = data['pathologiesDetails'] ?? 'N/A';
    final asthmatic = data['asthmatic'] ?? 'N/A';
    final water = data['waterIntake'] ?? 'N/A';
    final breakfast = data['breakfast'] ?? 'N/A';
    final trainingDays = data['training_days'] is List
        ? (data['training_days'] as List).join(', ')
        : (data['training_days'] ?? 'N/A').toString();
    final sportsExperience = data['sportExperience'] ?? 'N/A';
    final ptExperience = data['otherPTExperience'] ?? 'N/A';
    final fixedShifts = data['fixedWorkShifts'] ?? 'N/A'; // yes or no
    final gymExperience = data['gymExperience'] ?? 'N/A';
    final preferredTime = data['preferredTime'] ?? 'N/A';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          /// SECTION: Personal Info
          _buildSectionHeader('Personal Info', Icons.person_pin, color: Colors.blueGrey),
          _buildDataLine(
            label: 'Name',
            value: data['name'] ?? 'N/A',
            icon: Icons.person,
            color: Colors.blueGrey,
          ),
          _buildDataLine(
            label: 'Surname',
            value: data['surname'] ?? 'N/A',
            icon: Icons.person_outline,
            color: Colors.blueGrey,
          ),
          _buildDataLine(
            label: 'Age',
            value: ageStr,
            icon: Icons.cake,
            color: Colors.blueGrey,
          ),
          _buildDataLine(
            label: 'Phone',
            value: phone,
            icon: Icons.phone,
            color: Colors.blueGrey,
          ),
          _buildDataLine(
            label: 'Profession',
            value: profession,
            icon: Icons.work_outline,
            color: Colors.blueGrey,
          ),

          /// SECTION: Physical Measurements
          _buildSectionHeader('Physical Measurements', Icons.straighten, color: Colors.blue),
          _buildDataLine(
            label: 'Height',
            value: data['height'] != null ? '${data['height']} cm' : 'N/A',
            icon: Icons.height_outlined,
            color: Colors.blue,
          ),
          _buildDataLine(
            label: 'Weight',
            value: data['weight'] != null ? '${data['weight']} kg' : 'N/A',
            icon: Icons.monitor_weight_outlined,
            color: Colors.blue,
          ),

          /// SECTION: Lifestyle & Sleep
          _buildSectionHeader('Lifestyle & Sleep', Icons.local_drink, color: Colors.orange),
          _buildDataLine(
            label: 'Alcohol?',
            value: data['alcohol'] ?? 'N/A',
            icon: Icons.local_bar_outlined,
            color: Colors.orange,
          ),
          if (data['alcohol_details'] != null && data['alcohol_details'].toString().isNotEmpty)
            _buildDataLine(
              label: 'Alcohol Details',
              value: data['alcohol_details'] ?? '',
              icon: Icons.details_outlined,
              color: Colors.orange,
            ),
          _buildDataLine(
            label: 'Smokes?',
            value: data['smokes'] ?? 'N/A',
            icon: Icons.smoking_rooms_outlined,
            color: Colors.red,
          ),
          if (data['smoking_details'] != null && data['smoking_details'].toString().isNotEmpty)
            _buildDataLine(
              label: 'Smoking Details',
              value: data['smoking_details'] ?? '',
              icon: Icons.description_outlined,
              color: Colors.red,
            ),
          _buildDataLine(
            label: 'Water Intake',
            value: water,
            icon: Icons.water_drop_outlined,
            color: Colors.lightBlue,
          ),
          _buildDataLine(
            label: 'Sleep Time',
            value: data['sleep_time'] ?? 'N/A',
            icon: Icons.nights_stay_outlined,
            color: Colors.indigo,
          ),
          _buildDataLine(
            label: 'Wake Time',
            value: data['wake_time'] ?? 'N/A',
            icon: Icons.wb_sunny_outlined,
            color: Colors.amber,
          ),
          _buildDataLine(
            label: 'Feels Energetic?',
            value: data['energetic'] ?? 'N/A',
            icon: Icons.battery_charging_full_outlined,
            color: Colors.yellow[700],
          ),
          _buildDataLine(
            label: 'Breakfast (typical)',
            value: breakfast,
            icon: Icons.free_breakfast_outlined,
            color: Colors.brown[300],
          ),

          /// SECTION: Health & Injury History
          _buildSectionHeader('Health & Injury History', Icons.health_and_safety, color: Colors.redAccent),
          _buildDataLine(
            label: 'Spine, Joint, or Muscle Issues',
            value: spineJointMuscleIssues,
            icon: Icons.accessibility_new_outlined,
            color: Colors.redAccent,
          ),
          _buildDataLine(
            label: 'Any Injuries or Surgery',
            value: injuriesOrSurgery,
            icon: Icons.local_hospital_outlined,
            color: Colors.redAccent,
          ),
          if (injuriesOrSurgery == 'Yes' && injuriesOrSurgeryDetails != 'N/A')
            _buildDataLine(
              label: 'Injuries/Surgery Details',
              value: injuriesOrSurgeryDetails,
              icon: Icons.details_outlined,
              color: Colors.redAccent,
            ),
          _buildDataLine(
            label: 'Any Pathologies',
            value: pathologies,
            icon: Icons.warning_amber_outlined,
            color: Colors.redAccent,
          ),
          if (pathologies != 'N/A' && pathologiesDetails != 'N/A')
            _buildDataLine(
              label: 'Pathologies Details',
              value: pathologiesDetails,
              icon: Icons.details_outlined,
              color: Colors.redAccent,
            ),
          _buildDataLine(
            label: 'Asthmatic Subject?',
            value: asthmatic,
            icon: Icons.air_outlined,
            color: Colors.redAccent,
          ),

          /// SECTION: Training Experience & Goals
          _buildSectionHeader('Training Experience & Goals', Icons.fitness_center, color: Colors.purple),
          _buildDataLine(
            label: 'Sports Experience',
            value: sportsExperience,
            icon: Icons.sports_soccer_outlined,
            color: Colors.purple,
          ),
          _buildDataLine(
            label: 'Past Personal Trainer Exp.',
            value: ptExperience,
            icon: Icons.person_pin_outlined,
            color: Colors.purple,
          ),
          _buildDataLine(
            label: 'Fixed Shifts at Work?',
            value: fixedShifts,
            icon: Icons.schedule_outlined,
            color: Colors.deepPurpleAccent,
          ),
          _buildDataLine(
            label: 'Goals',
            value: data['goals'] ?? 'N/A',
            icon: Icons.flag_outlined,
            color: Colors.purple,
          ),
          _buildDataLine(
            label: 'Training Days',
            value: trainingDays,
            icon: Icons.calendar_today_outlined,
            color: Colors.teal,
          ),
        ],
      ),
    );
  }
}

/// A small widget that bounces the arrow up/down if user hasn’t scrolled yet
class _AnimatedDownArrow extends StatefulWidget {
  const _AnimatedDownArrow();

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
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0, end: 10).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
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
          child: const Icon(Icons.arrow_downward, color: Colors.grey, size: 32),
        );
      },
    );
  }
}
