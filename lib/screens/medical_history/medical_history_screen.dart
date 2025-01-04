import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_pdfview/flutter_pdfview.dart';
import 'package:isyfit/screens/medical_history/pdf_view_screen.dart';
import 'package:isyfit/screens/medical_history/image_view_screen.dart';
import 'package:isyfit/screens/medical_questionnaire/questionnaire_screen.dart';
import 'package:isyfit/widgets/data_card.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;

class MedicalHistoryScreen extends StatefulWidget {
  const MedicalHistoryScreen({Key? key}) : super(key: key);

  @override
  _MedicalHistoryScreenState createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  late Future<Map<String, dynamic>?> medicalHistory;
  late Future<List<Map<String, dynamic>>> medicalDocuments;
  bool showAllDocuments = false;

  @override
  void initState() {
    super.initState();
    medicalHistory = _fetchMedicalHistory();
    medicalDocuments = _fetchDocuments();
  }

  Future<Map<String, dynamic>?> _fetchMedicalHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('medical_history')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  Future<List<Map<String, dynamic>>> _fetchDocuments() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    final querySnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medical_documents')
        .get();

    return querySnapshot.docs
        .map((doc) => {
              'fileName': doc['fileName'],
              'downloadUrl': doc['downloadUrl'],
              'fileType': doc['fileType'],
              'uploadedAt': doc['uploadedAt'],
            })
        .toList();
  }

  Future<void> _uploadFile(BuildContext context) async {
    try {
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
          const SnackBar(
              content: Text('Unable to read file. Please try again.')),
        );
        return;
      }

      // Show loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      final fileName = file.name;

      // Check if the file already exists in Firestore
      final existingFiles = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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

      final storageRef =
          FirebaseStorage.instance.ref('medical_documents/${user.uid}/$fileName');

      final uploadTask = storageRef.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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

  IconData _getFileTypeIcon(String? fileType) {
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

  Future<void> _deleteDocument(
      BuildContext context, Map<String, dynamic> doc) async {
    try {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      // Delete from Storage
      final storageRef = FirebaseStorage.instance
          .ref('medical_documents/${user.uid}/${doc['fileName']}');
      await storageRef.delete();

      // Delete from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
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

  Widget _buildDocumentsSection(BuildContext context) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: medicalDocuments,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text('No documents uploaded yet.'),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: () => _uploadFile(context),
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Document'),
                ),
              ],
            ),
          );
        }

        final documents = snapshot.data!;
        final visibleDocs =
            showAllDocuments ? documents : documents.take(3).toList();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Medical Documents',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: visibleDocs.length,
                itemBuilder: (context, index) {
                  final doc = visibleDocs[index];
                  final icon = _getFileTypeIcon(doc['fileType']);
                  return Card(
                    elevation: 2,
                    margin: const EdgeInsets.symmetric(vertical: 8.0),
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
                        'Uploaded on: '
                        '${(doc['uploadedAt'] as Timestamp).toDate().toString().split(' ')[0]}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: Wrap(
                        spacing: 12, // space between two icons
                        children: [
                          IconButton(
                            icon: const Icon(Icons.visibility,
                                color: Colors.green),
                            onPressed: () {
                              _viewDocument(
                                  context, doc['downloadUrl'], doc['fileType']);
                            },
                          ),
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
              if (documents.length > 3)
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
                  ),
                ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _uploadFile(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload More Documents'),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History Dashboard'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: medicalHistory,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const QuestionnaireScreen();
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Column(
              children: [
                // ----- Data Cards Section -----
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // 1st Row: Height / Weight
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: DataCard(
                              title: 'Height',
                              value: '${data['height']} cm',
                              icon: Icons.height,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: DataCard(
                              title: 'Weight',
                              value: '${data['weight']} kg',
                              icon: Icons.monitor_weight,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 2nd Row: Drinks Alcohol / Smokes
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

                      // 3rd Row: Sleep Time / Wake Time
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

                      // 4th Row: Goals / Training Days
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
                              value: (data['training_days'] as List).join(', '),
                              icon: Icons.calendar_today,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // 5th Row: Energetic
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
                const Divider(thickness: 1.5),
                const SizedBox(height: 16),

                // ----- Documents Section -----
                _buildDocumentsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }
}
