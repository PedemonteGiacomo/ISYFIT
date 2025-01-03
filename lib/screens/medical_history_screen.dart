import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_pdfview/flutter_pdfview.dart';
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

  Widget _buildDataCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12.0),
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
                    fontSize: 14.0,
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
                        'Uploaded on: ${(doc['uploadedAt'] as Timestamp).toDate().toString().split(' ')[0]}',
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

      final storageRef = FirebaseStorage.instance
          .ref('medical_documents/${user.uid}/${doc['fileName']}');
      await storageRef.delete();

      final querySnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('medical_documents')
          .where('fileName', isEqualTo: doc['fileName'])
          .get();

      for (final doc in querySnapshot.docs) {
        await doc.reference.delete();
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
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // First Row: Measurements
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

                      // Second Row: Lifestyle
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildDataCard(
                              title: 'Drinks Alcohol',
                              value: data['alcohol'] ?? 'N/A',
                              icon: Icons.local_drink,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _buildDataCard(
                              title: 'Smokes',
                              value: data['smokes'] ?? 'N/A',
                              icon: Icons.smoking_rooms,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Third Row: Sleep and Energy
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildDataCard(
                              title: 'Sleep Time',
                              value: data['sleep_time'] ?? 'N/A',
                              icon: Icons.nights_stay,
                              color: Colors.indigo,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _buildDataCard(
                              title: 'Wake Time',
                              value: data['wake_time'] ?? 'N/A',
                              icon: Icons.wb_sunny,
                              color: Colors.amber,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Fourth Row: Training Goals
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: _buildDataCard(
                              title: 'Goals',
                              value: data['goals'] ?? 'N/A',
                              icon: Icons.fitness_center,
                              color: Colors.purple,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            flex: 1,
                            child: _buildDataCard(
                              title: 'Training Days',
                              value: (data['training_days'] as List).join(', '),
                              icon: Icons.calendar_today,
                              color: Colors.teal,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Fifth Row: Energetic
                      Row(
                        children: [
                          Expanded(
                            flex: 1,
                            child: _buildDataCard(
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
                _buildDocumentsSection(context),
              ],
            ),
          );
        },
      ),
    );
  }
}

class PDFViewScreen extends StatefulWidget {
  final String pdfUrl;

  const PDFViewScreen({Key? key, required this.pdfUrl}) : super(key: key);

  @override
  _PDFViewScreenState createState() => _PDFViewScreenState();
}

class _PDFViewScreenState extends State<PDFViewScreen> {
  String? localFilePath;
  bool isLoading = true;
  int totalPages = 0;
  int currentPage = 0;
  bool showControls = false;

  late PDFViewController pdfController;

  @override
  void initState() {
    super.initState();
    _downloadAndLoadPDF();
  }

  Future<void> _downloadAndLoadPDF() async {
    try {
      final directory = await getTemporaryDirectory();
      final filePath = '${directory.path}/temp_pdf.pdf';

      final response = await http.get(Uri.parse(widget.pdfUrl));
      if (response.statusCode == 200) {
        final file = File(filePath);
        await file.writeAsBytes(response.bodyBytes);

        setState(() {
          localFilePath = filePath;
          isLoading = false;
        });
      } else {
        throw Exception('Failed to download PDF');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading PDF: $e')),
      );
    }
  }

  void _toggleControls() {
    setState(() {
      showControls = !showControls;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PDF Viewer'),
        actions: [
          if (!isLoading)
            GestureDetector(
              onTap: _toggleControls,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Text(
                    'Page ${currentPage + 1} of $totalPages',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Stack(
        children: [
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Container(
                  margin: const EdgeInsets.all(16), // Margin outside the border
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.grey, // Border color
                      width: 2, // Border width
                    ),
                    borderRadius: BorderRadius.circular(12), // Rounded corners
                  ),
                  padding:
                      const EdgeInsets.all(16), // Padding inside the border
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10), // Clipping corners
                    child: PDFView(
                      filePath: localFilePath!,
                      enableSwipe: true,
                      swipeHorizontal: true,
                      autoSpacing: true,
                      pageFling: true,
                      fitEachPage: true,
                      onRender: (pages) {
                        setState(() {
                          totalPages = pages!;
                        });
                      },
                      onViewCreated: (PDFViewController controller) {
                        pdfController = controller;
                      },
                      onPageChanged: (page, _) {
                        setState(() {
                          currentPage = page!;
                        });
                      },
                      onError: (error) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $error')),
                        );
                      },
                    ),
                  ),
                ),
          if (showControls) _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 20,
      left: 20,
      right: 20,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Go to page:',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
                SizedBox(
                  width: 100,
                  child: TextField(
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      hintText: 'Page',
                    ),
                    onSubmitted: (value) {
                      final page = int.tryParse(value);
                      if (page != null && page > 0 && page <= totalPages) {
                        pdfController.setPage(page - 1);
                        setState(() {
                          currentPage = page - 1;
                        });
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Invalid page number')),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    if (currentPage > 0) {
                      pdfController.setPage(currentPage - 1);
                      setState(() {
                        currentPage--;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Previous'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    if (currentPage < totalPages - 1) {
                      pdfController.setPage(currentPage + 1);
                      setState(() {
                        currentPage++;
                      });
                    }
                  },
                  icon: const Icon(Icons.arrow_forward),
                  label: const Text('Next'),
                ),
              ],
            ),
          ],
        ),
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
        child: Container(
          margin: const EdgeInsets.all(16), // Margin outside the border
          decoration: BoxDecoration(
            border: Border.all(
              color: Colors.grey, // Border color
              width: 2, // Border width
            ),
            borderRadius: BorderRadius.circular(12), // Rounded corners
            //boxShadow: [
            //   BoxShadow(
            //     color: Colors.black.withOpacity(0.2), // Shadow color
            //     blurRadius: 6, // Shadow blur radius
            //     offset: const Offset(0, 3), // Shadow offset
            //   ),
            // ],
          ),
          padding: const EdgeInsets.all(16), // Padding inside the border
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10), // Clipping corners
            child: Image.network(
              imageUrl,
              fit: BoxFit.contain, // Ensure the image fits well
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) {
                  return child; // Display image when fully loaded
                }
                return const Center(
                  child:
                      CircularProgressIndicator(), // Show a loader while the image is loading
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    'Failed to load image',
                    style: TextStyle(color: Colors.red, fontSize: 16),
                  ),
                ); // Display an error message if the image fails to load
              },
            ),
          ),
        ),
      ),
    );
  }
}
