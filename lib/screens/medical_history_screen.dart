import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'dart:typed_data';

class MedicalHistoryScreen extends StatelessWidget {
  const MedicalHistoryScreen({Key? key}) : super(key: key);

  Future<Map<String, dynamic>?> _fetchMedicalHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await FirebaseFirestore.instance
        .collection('medical_history')
        .doc(user.uid)
        .get();
    return doc.data();
  }

  Future<void> _uploadFile(BuildContext context) async {
    try {
      // Allow user to select a file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png', 'docx'],
      );

      if (result == null || result.files.isEmpty) {
        // User canceled the picker or no file was selected
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No file selected.')),
        );
        return;
      }

      final file = result.files.single;
      Uint8List? fileBytes = file.bytes;

      // Read file manually if `bytes` is null
      if (fileBytes == null && file.path != null) {
        final fileFromPath = File(file.path!);
        fileBytes = await fileFromPath.readAsBytes();
      }

      // Ensure file bytes are available
      if (fileBytes == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unable to read file. Please try again.')),
        );
        return;
      }

      // Show a loading dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      // Get the user's ID and prepare Firebase Storage reference
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not logged in.')),
        );
        return;
      }

      final fileName = file.name;
      final storageRef =
          FirebaseStorage.instance.ref('medical_documents/${user.uid}/$fileName');

      // Upload file to Firebase Storage
      final uploadTask = storageRef.putData(fileBytes);
      final snapshot = await uploadTask.whenComplete(() => null);
      final downloadUrl = await snapshot.ref.getDownloadURL();

      // Save file metadata to Firestore
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

      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('File uploaded successfully!')),
      );
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading file: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History Dashboard'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.upload_file),
            onPressed: () => _uploadFile(context),
          ),
        ],
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchMedicalHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(child: Text('No data available.'));
          }
          final data = snapshot.data!;
          return Padding(
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
          );
        },
      ),
    );
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
