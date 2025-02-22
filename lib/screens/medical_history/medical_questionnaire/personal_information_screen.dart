import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'physical_measurements_screen.dart';

class PersonalInformationScreen extends StatefulWidget {
  final String? clientUid; // <-- Add this

  const PersonalInformationScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  _PersonalInformationScreenState createState() =>
      _PersonalInformationScreenState();
}

class _PersonalInformationScreenState extends State<PersonalInformationScreen> {
  String? name;
  String? surname;
  String? email;
  String? phone;
  String? dateOfBirth;
  String? role;
  String? profession;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// If clientUid != null, load the data for that user. Otherwise, load current user’s data.
  Future<void> _loadUserData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final userIdToLoad = widget.clientUid ?? user?.uid; 
      if (userIdToLoad != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userIdToLoad)
            .get();
        final data = userDoc.data();

        setState(() {
          email = data?['email'];
          name = data?['name'];
          surname = data?['surname'];
          phone = data?['phone'];
          dateOfBirth = data?['dateOfBirth'];
          role = data?['role'];
          profession = data?['profession'];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (e) {
      setState(() => isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Information'),
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
                      const Icon(Icons.person, size: 64, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Personal Information',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This section displays personal details as stored in the system.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Form Fields
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldWithIcon(
                              'Name',
                              name ?? 'N/A',
                              Icons.badge_outlined,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFieldWithIcon(
                              'Surname',
                              surname ?? 'N/A',
                              Icons.person_outline,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldWithIcon(
                              'Email',
                              email ?? 'N/A',
                              Icons.email_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldWithIcon(
                              'Phone',
                              phone ?? 'N/A',
                              Icons.phone_outlined,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _buildFieldWithIcon(
                              'Date of Birth',
                              dateOfBirth ?? 'N/A',
                              Icons.calendar_today,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _buildFieldWithIcon(
                              'Role',
                              role ?? 'N/A',
                              role == 'PT' ? Icons.medical_services : Icons.person,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Row(
                      //   children: [
                      //     Expanded(
                      //       child: _buildFieldWithIcon(
                      //         'Profession',
                      //         profession ?? 'N/A',
                      //         Icons.work_outline,
                      //       ),
                      //     ),
                      //   ],
                      // ),

                      const SizedBox(height: 32),
                      // Next Button -> Pass clientUid forward
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.5,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PhysicalMeasurementsScreen(
                                  data: {
                                    'name': name,
                                    'surname': surname,
                                    'email': email,
                                    'phone': phone,
                                    'dateOfBirth': dateOfBirth,
                                    'role': role,
                                    // 'profession': profession,
                                  },
                                  clientUid: widget.clientUid, // Pass forward
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.arrow_forward, color: Colors.white),
                          label: const Text('Next'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: theme.primaryColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            foregroundColor: Colors.white,
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

  Widget _buildFieldWithIcon(String label, String value, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
