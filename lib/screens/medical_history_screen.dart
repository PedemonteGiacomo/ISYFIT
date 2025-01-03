import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';

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

      // Check if a file with the same name already exists
      final existingFiles = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medical_documents')
          .where('fileName', isEqualTo: fileName)
          .get();

      if (existingFiles.docs.isNotEmpty) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('File "$fileName" already exists.')),
        );
        return;
      }

      final storageRef = FirebaseStorage.instance
          .ref('medical_documents/${user.uid}/$fileName');

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

      // Refresh the documents
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
    try {
      // Show loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      // Delete the document from Firebase Storage
      final storageRef = FirebaseStorage.instance
          .ref('medical_documents/${user.uid}/${doc['fileName']}');
      await storageRef.delete();

      // Delete the document metadata from Firestore
      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medical_documents')
          .where('fileName', isEqualTo: doc['fileName'])
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
      }

      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Document deleted successfully!')),
      );

      // Refresh the documents
      setState(() {
        medicalDocuments = _fetchDocuments();
      });
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting document: $e')),
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
          return Column(
            children: [
              const Text('No documents uploaded yet.'),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _uploadFile(context),
                icon: const Icon(Icons.upload_file),
                label: const Text('Upload Document'),
              ),
            ],
          );
        }

        final documents = snapshot.data!;
        final visibleDocs = showAllDocuments ? documents : documents.take(3).toList();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Medical Documents',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            ...visibleDocs.map((doc) => ListTile(
                  leading: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _deleteDocument(context, doc);
                    },
                  ),
                  title: Text(doc['fileName']),
                  subtitle: Text('Uploaded at: ${doc['uploadedAt'].toDate()}'),
                  trailing: IconButton(
                    icon: const Icon(Icons.visibility),
                    onPressed: () {
                      _viewDocument(context, doc['downloadUrl'], doc['fileType']);
                    },
                  ),
                )),
            if (documents.length > 3)
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
            ElevatedButton.icon(
              onPressed: () => _uploadFile(context),
              icon: const Icon(Icons.upload_file),
              label: const Text('Upload More Documents'),
            ),
          ],
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
            return const Center(child: Text('No data available.'));
          }
          final data = snapshot.data!;
          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  ..._buildMedicalHistorySections(data),
                  const Divider(thickness: 1.5),
                  const SizedBox(height: 16),
                  _buildDocumentsSection(context),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildMedicalHistorySections(Map<String, dynamic> data) {
    return [
      Row(
        children: [
          Expanded(
            flex: 2,
            child: _buildDataCard(
              title: 'Height',
              value: '${data['height']} cm',
              icon: Icons.height,
              color: Colors.blue,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            flex: 1,
            child: _buildDataCard(
              title: 'Weight',
              value: '${data['weight']} kg',
              icon: Icons.monitor_weight,
              color: Colors.green,
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
    ];
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

  Widget _buildDataCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16.0),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class PDFViewScreen extends StatelessWidget {
  final String pdfUrl;

  const PDFViewScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document View'),
      ),
      body: PDFView(
        filePath: pdfUrl,
      ),
    );
  }
}

class ImageViewScreen extends StatelessWidget {
  final String imageUrl;

  const ImageViewScreen({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Document View'),
      ),
      body: Center(
        child: Image.network(imageUrl),
      ),
    );
  }
}
