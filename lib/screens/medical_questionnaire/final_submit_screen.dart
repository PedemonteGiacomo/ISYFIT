import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isyfit/screens/base_screen.dart';

class FinalSubmitScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const FinalSubmitScreen({Key? key, required this.data}) : super(key: key);

  @override
  _FinalSubmitScreenState createState() => _FinalSubmitScreenState();
}

class _FinalSubmitScreenState extends State<FinalSubmitScreen> {
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Finalize'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      // Header Section
                      const Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: Colors.green,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Thank You!',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'You’ve successfully completed the questionnaire. Please review your data and submit it.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Summary of Data in Rows of Two
                      _buildDataSummary(),
                      const SizedBox(height: 24),

                      // Submit Button
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: ElevatedButton.icon(
                          onPressed: isSubmitting ? null : _handleSubmit,
                          icon: isSubmitting
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(Icons.send, color: Colors.white),
                          label: Text(
                            isSubmitting ? 'Submitting...' : 'Submit',
                            style: const TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Colors.green,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
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
    );
  }

  Widget _buildDataSummary() {
    List<Widget> rows = [];
    List<MapEntry<String, dynamic>> entries = widget.data.entries.toList();

    for (int i = 0; i < entries.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(
              child: _buildDataCard(entries[i]),
            ),
            if (i + 1 < entries.length)
              const SizedBox(width: 16), // Space between cards
            if (i + 1 < entries.length)
              Expanded(
                child: _buildDataCard(entries[i + 1]),
              ),
          ],
        ),
      );
      rows.add(const SizedBox(height: 16)); // Space between rows
    }

    return Column(
      children: rows,
    );
  }

  Widget _buildDataCard(MapEntry<String, dynamic> entry) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            entry.key,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            entry.value is List
                ? (entry.value as List).join(', ')
                : entry.value.toString(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleSubmit() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      await FirebaseFirestore.instance
          .collection('medical_history')
          .doc(user.uid)
          .set(widget.data);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Data saved successfully!'), backgroundColor: Colors.green,),
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => Scaffold(
        body: const BaseScreen(),
        // bottomNavigationBar: navbar.NavigationBar(
        //   currentIndex: 1,
        //   onIndexChanged: (index) {
        //     // Handle navigation based on the index
        //   },
        // ),
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving data: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }
}
