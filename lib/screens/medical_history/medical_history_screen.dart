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

/// A helper function to parse and calculate the user’s age from a dateOfBirth string.
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

  /// If a PT is viewing, fetch that client’s minimal profile
  late Future<Map<String, dynamic>?> clientProfile;

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
      builder: (_) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
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

  Future<void> _deleteDocument(
      BuildContext context, Map<String, dynamic> doc) async {
    final uid = targetUid;
    if (uid == null) return;

    // Remove the PT-check here so both PT and clients can delete documents.
    // if (isPTView) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('PT cannot delete this document.')),
    //   );
    //   return;
    // }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Center(
        child: CircularProgressIndicator(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );

    try {
      final storageRef = FirebaseStorage.instance
          .ref('medical_documents/$uid/${doc['fileName']}');
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
    final extension = fileType.toLowerCase();

    if (extension == 'pdf' || extension == 'doc' || extension == 'docx') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PDFViewScreen(
            fileUrl: url,
            fileExtension: extension,
          ),
        ),
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

  /// ---------------------------------------
  /// DASHBOARD-STYLE UI BUILDERS
  /// ---------------------------------------

  Widget _buildDashboardHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // If PT is viewing, show the client’s name
          if (isPTView)
            FutureBuilder<Map<String, dynamic>?>(
              future: clientProfile,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                final profileData = snapshot.data;
                if (profileData == null) return const SizedBox();
                return Text(
                  '${profileData['name']} ${profileData['surname'] ?? ''} (${profileData['email']})',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                );
              },
            ),
          // else show "Your anamnesis" for the user
          if (!isPTView)
            Text(
              'Your Anamnesis',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
        ],
      ),
    );
  }

  /// PERSONAL INFO TAB
  Widget _buildPersonalInfoTab(Map<String, dynamic> data) {
    final name = data['name'] ?? 'N/A';
    final surname = data['surname'] ?? 'N/A';
    final phone = data['phone'] ?? 'N/A';
    final profession = data['profession'] ?? 'N/A';
    final height = data['height'] != null ? '${data['height']} cm' : 'N/A';
    final weight = data['weight'] != null ? '${data['weight']} kg' : 'N/A';
    final ageStr = data.containsKey('dateOfBirth')
        ? '${calculateAge(data['dateOfBirth'])} yrs'
        : 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Personal Details',
            icon: Icons.person_pin,
            children: [
              _buildDataLine(label: 'Name', value: name),
              _buildDataLine(label: 'Surname', value: surname),
              _buildDataLine(label: 'Age', value: ageStr),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Contact Details',
            icon: Icons.phone,
            children: [
              _buildDataLine(label: 'Phone', value: phone),
              _buildDataLine(label: 'Profession', value: profession),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Physical Stats',
            icon: Icons.accessibility,
            children: [
              _buildDataLine(label: 'Height', value: height),
              _buildDataLine(label: 'Weight', value: weight),
            ],
          ),
        ],
      ),
    );
  }

  /// LIFESTYLE TAB
  Widget _buildLifestyleTab(Map<String, dynamic> data) {
    final alcohol = data['alcohol'] ?? 'N/A';
    final alcoholDetails = data['alcohol_details'] ?? '';
    final smokes = data['smokes'] ?? 'N/A';
    final smokingDetails = data['smoking_details'] ?? '';
    final waterIntake = data['waterIntake'] ?? 'N/A';
    final sleepTime = data['sleep_time'] ?? 'N/A';
    final wakeTime = data['wake_time'] ?? 'N/A';
    final energetic = data['energetic'] ?? 'N/A';

    var breakfast = data['breakfast'] ?? 'N/A';
    if (breakfast == 'Yes' && data['breakfastDetails'] != null) {
      breakfast += ' (${data['breakfastDetails']})';
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Lifestyle & Habits',
            icon: Icons.local_drink,
            children: [
              _buildDataLine(label: 'Alcohol?', value: alcohol),
              if (alcoholDetails.isNotEmpty)
                _buildDataLine(label: 'Alcohol Details', value: alcoholDetails),
              _buildDataLine(label: 'Smokes?', value: smokes),
              if (smokingDetails.isNotEmpty)
                _buildDataLine(label: 'Smoking Details', value: smokingDetails),
              _buildDataLine(label: 'Water Intake', value: waterIntake),
              _buildDataLine(label: 'Breakfast', value: breakfast),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Sleep & Energy',
            icon: Icons.nights_stay,
            children: [
              _buildDataLine(label: 'Sleep Time', value: sleepTime),
              _buildDataLine(label: 'Wake Time', value: wakeTime),
              _buildDataLine(label: 'Feels Energetic?', value: energetic),
            ],
          ),
        ],
      ),
    );
  }

  /// TRAINING TAB
  Widget _buildTrainingTab(Map<String, dynamic> data) {
    final injuriesOrSurgery = data['injuriesOrSurgery'] ?? 'N/A';
    final injuriesOrSurgeryDetails = data['injuriesOrSurgeryDetails'] ?? 'N/A';
    final spineIssues = data['spineJointMuscleIssues'] ?? 'N/A';
    final spineDetails = data['spineJointMuscleIssuesDetails'] ?? 'N/A';
    final pathologies = data['pathologies'] ?? 'N/A';
    final pathologiesDetails = data['pathologiesDetails'] ?? 'N/A';
    final asthmatic = data['asthmatic'] ?? 'N/A';

    final sportsExperience = data['sportExperience'] ?? 'N/A';
    final otherPTExperience = data['otherPTExperience'] ?? 'N/A';
    final fixedShifts = data['fixedWorkShifts'] ?? 'N/A';
    final goals = data['goals'] ?? 'N/A';
    final gymExperience = data['gymExperience'] ?? 'N/A';

    final trainingDays = data['training_days'] is List
        ? (data['training_days'] as List).join(', ')
        : (data['training_days'] ?? 'N/A').toString();
    final preferredTime = data['preferredTime'] ?? 'N/A';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildSectionCard(
            title: 'Health & Injury History',
            icon: Icons.health_and_safety,
            children: [
              _buildDataLine(
                  label: 'Spine/Joint/Muscle Issues', value: spineIssues),
              if (spineIssues == 'Yes' && spineDetails != 'N/A')
                _buildDataLine(label: 'Details', value: spineDetails),
              _buildDataLine(
                  label: 'Injuries or Surgery', value: injuriesOrSurgery),
              if (injuriesOrSurgery == 'Yes' &&
                  injuriesOrSurgeryDetails != 'N/A')
                _buildDataLine(
                    label: 'Details', value: injuriesOrSurgeryDetails),
              _buildDataLine(label: 'Pathologies', value: pathologies),
              if (pathologies != 'N/A' && pathologiesDetails != 'N/A')
                _buildDataLine(
                    label: 'Pathologies Details', value: pathologiesDetails),
              _buildDataLine(label: 'Asthmatic Subject?', value: asthmatic),
            ],
          ),
          const SizedBox(height: 16),
          _buildSectionCard(
            title: 'Training Experience & Goals',
            icon: Icons.fitness_center,
            children: [
              _buildDataLine(
                  label: 'Sports Experience', value: sportsExperience),
              _buildDataLine(
                  label: 'Other PT Experience', value: otherPTExperience),
              _buildDataLine(label: 'Fixed Shifts?', value: fixedShifts),
              _buildDataLine(label: 'Gym Experience', value: gymExperience),
              _buildDataLine(label: 'Training Days', value: trainingDays),
              _buildDataLine(label: 'Preferred Time', value: preferredTime),
              _buildDataLine(label: 'Goals', value: goals),
            ],
          ),
        ],
      ),
    );
  }

  /// DOCUMENTS TAB
  Widget _buildDocumentsTab(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: medicalDocuments,
      builder: (context, snapshot) {
        final theme = Theme.of(context);
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(
              color: theme.colorScheme.primary,
            ),
          );
        }
        final docs = snapshot.data ?? [];
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'No documents uploaded yet.',
                    style: theme.textTheme.bodyLarge,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => _uploadFile(context),
                    icon: Icon(Icons.upload_file,
                        color: Theme.of(context).colorScheme.onPrimary),
                    label: Text('Upload Document',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary)),
                  ),
                ],
              ),
            ),
          );
        }

        final visibleDocs = showAllDocuments ? docs : docs.take(3).toList();
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Title + Upload button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Medical Documents',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  ElevatedButton.icon(
                      onPressed: () => _uploadFile(context),
                      icon: Icon(Icons.upload_file,
                          color: Theme.of(context).colorScheme.onPrimary),
                      label: Text('Upload',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.onPrimary))),
                ],
              ),
              const SizedBox(height: 16),
              // Documents list
              Expanded(
                child: ListView.builder(
                  itemCount: visibleDocs.length,
                  itemBuilder: (context, index) {
                    final doc = visibleDocs[index];
                    final icon = _getFileTypeIcon(doc['fileType'] ?? '');
                    final timestamp = doc['uploadedAt'] as Timestamp?;
                    final uploadDate = timestamp != null
                        ? DateFormat.yMMMd().format(timestamp.toDate())
                        : 'N/A';

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor:
                              theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(icon, color: theme.colorScheme.primary),
                        ),
                        title: Text(
                          doc['fileName'] ?? '',
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium,
                        ),
                        subtitle: Text(
                          'Uploaded on: $uploadDate',
                          style: theme.textTheme.bodySmall,
                        ),
                        trailing: Wrap(
                          spacing: 12,
                          children: [
                            IconButton(
                              icon: Icon(Icons.visibility,
                                  color: Colors.green.shade600),
                              onPressed: () => _viewDocument(
                                context,
                                doc['downloadUrl'] ?? '',
                                doc['fileType'] ?? '',
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete,
                                  color: theme.colorScheme.error),
                              onPressed: () => _deleteDocument(context, doc),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Show more / Show less toggle
              if (docs.length > 3)
                TextButton(
                  onPressed: () {
                    setState(() {
                      showAllDocuments = !showAllDocuments;
                    });
                  },
                  child: Text(
                    showAllDocuments
                        ? 'Show Less Documents'
                        : 'Show All Documents',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Helper card layout for sections
  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.surfaceVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: theme.colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.secondary,
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDataLine({required String label, required String value}) {
    final textTheme = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(value, style: textTheme.bodyMedium),
        ],
      ),
    );
  }

  /// If no medical history for the user (non-PT), show the questionnaire
  Widget _buildNoMedicalHistoryForUser() {
    return const QuestionnaireScreen();
  }

  /// If no medical history for PT’s client, show a simple message
  Widget _buildNoMedicalHistoryForPT(Map<String, dynamic>? profileData) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Expanded(
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 600),
                  child: Card(
                    elevation: 4,
                    color: theme.colorScheme.errorContainer.withOpacity(0.2),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.warning,
                            size: 48,
                            color: theme.colorScheme.error,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Medical Data Found',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: theme.colorScheme.error,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'This user has not yet provided any medical history.\n'
                            'You can fill out the questionnaire for them or ask the user to do it.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                          const SizedBox(height: 24),
                          ElevatedButton.icon(
                            icon: Icon(Icons.assignment_outlined,
                                color: Theme.of(context).colorScheme.onPrimary),
                            label: Text('Fill Questionnaire',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                            onPressed: () {
                              // Navigate to the questionnaire flow but pass the clientUid
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => QuestionnaireScreen(
                                    clientUid: widget.clientUid,
                                  ),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              foregroundColor: theme.colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton.icon(
                            icon: Icon(Icons.arrow_back,
                                color: Theme.of(context).colorScheme.onPrimary),
                            label: Text('Return to Clients',
                                style: TextStyle(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onPrimary)),
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.secondary,
                              foregroundColor: theme.colorScheme.onSecondary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
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
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    // If we are a PT viewing a client’s data:
    if (isPTView) {
      return FutureBuilder<Map<String, dynamic>?>(
        future: clientProfile,
        builder: (context, snapshotProfile) {
          if (snapshotProfile.connectionState == ConnectionState.waiting) {
            return Scaffold(
              appBar: AppBar(
                title: Text(
                  'Fit-Check',
                  style:
                      TextStyle(color: Theme.of(context).colorScheme.onPrimary),
                ),
                backgroundColor: Theme.of(context).primaryColor,
                centerTitle: true,
                iconTheme: IconThemeData(
                  color: Theme.of(context).colorScheme.onPrimary,
                ),
              ),
              body: Center(
                child: CircularProgressIndicator(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            );
          }
          final profileData = snapshotProfile.data;

          return FutureBuilder<Map<String, dynamic>?>(
            future: medicalHistory,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text('Fit-Check',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary)),
                    backgroundColor: Theme.of(context).primaryColor,
                    centerTitle: true,
                    iconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  body: Center(
                    child: CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                );
              }
              // If no medical data for this client
              if (!snapshot.hasData || snapshot.data == null) {
                return Scaffold(
                  appBar: AppBar(
                    title: Text('Fit-Check',
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary)),
                    backgroundColor: Theme.of(context).primaryColor,
                    centerTitle: true,
                    iconTheme: IconThemeData(
                      color: Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                  body: _buildNoMedicalHistoryForPT(profileData),
                );
              }
              final data = snapshot.data!;

              return Scaffold(
                appBar: AppBar(
                  title: Text('Fit-Check',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary)),
                  backgroundColor: Theme.of(context).primaryColor,
                  centerTitle: true,
                  iconTheme: IconThemeData(
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                ),
                body: Column(
                  children: [
                    _buildDashboardHeader(),
                    Expanded(
                      child: DefaultTabController(
                        length: 4,
                        child: Column(
                          children: [
                            TabBar(
                              labelColor: Theme.of(context).colorScheme.primary,
                              unselectedLabelColor: Colors.grey,
                              indicatorColor:
                                  Theme.of(context).colorScheme.primary,
                              tabs: const [
                                Tab(text: 'Personal Info'),
                                Tab(text: 'Lifestyle'),
                                Tab(text: 'Training'),
                                Tab(text: 'Documents'),
                              ],
                            ),
                            Expanded(
                              child: TabBarView(
                                children: [
                                  _buildPersonalInfoTab(data),
                                  _buildLifestyleTab(data),
                                  _buildTrainingTab(data),
                                  _buildDocumentsTab(context),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      );
    }

    // If we are viewing our own data
    return FutureBuilder<Map<String, dynamic>?>(
      future: medicalHistory,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Fit-Check',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary)),
              backgroundColor: Theme.of(context).primaryColor,
              centerTitle: true,
              iconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            body: Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          );
        }
        // If no data, show the questionnaire
        if (!snapshot.hasData || snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              title: Text('Fit-Check',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary)),
              backgroundColor: Theme.of(context).primaryColor,
              centerTitle: true,
              iconTheme: IconThemeData(
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
            body: _buildNoMedicalHistoryForUser(),
          );
        }
        final data = snapshot.data!;
        return Scaffold(
          appBar: AppBar(
            title: Text('Fit-Check',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
            backgroundColor: Theme.of(context).primaryColor,
            centerTitle: true,
            iconTheme: IconThemeData(
              color: Theme.of(context).colorScheme.onPrimary,
            ),
          ),
          body: Column(
            children: [
              _buildDashboardHeader(),
              Expanded(
                child: DefaultTabController(
                  length: 4,
                  child: Column(
                    children: [
                      TabBar(
                        labelColor: Theme.of(context).colorScheme.primary,
                        unselectedLabelColor: Colors.grey,
                        indicatorColor: Theme.of(context).colorScheme.primary,
                        tabs: const [
                          Tab(text: 'Personal Info'),
                          Tab(text: 'Lifestyle'),
                          Tab(text: 'Training'),
                          Tab(text: 'Documents'),
                        ],
                      ),
                      Expanded(
                        child: TabBarView(
                          children: [
                            _buildPersonalInfoTab(data),
                            _buildLifestyleTab(data),
                            _buildTrainingTab(data),
                            _buildDocumentsTab(context),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
