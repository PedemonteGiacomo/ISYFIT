import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/presentation/screens/base_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/widgets/gradient_button.dart'; // <-- Import your new widget
import 'physical_measurements_screen.dart';

class PersonalInformationScreen extends StatefulWidget {
  final String? clientUid;

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
  String? dateOfBirth; // raw date string
  String? role;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  /// Load user data from Firestore based on clientUid (if provided) or the logged-in user.
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

  /// Helper to calculate age from the dateOfBirth string
  int? _calculateAge(String? dateOfBirth) {
    if (dateOfBirth == null) return null;
    try {
      final dob = DateTime.parse(dateOfBirth);
      final now = DateTime.now();
      int age = now.year - dob.year;
      if (now.month < dob.month ||
          (now.month == dob.month && now.day < dob.day)) {
        age--;
      }
      return age;
    } catch (_) {
      return null;
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

    // Convert dateOfBirth to age
    final age = _calculateAge(dateOfBirth);

    return Scaffold(
      appBar: GradientAppBar(
        title: 'IsyCheck - Anamnesis Data Insertion',
        actions: [
          IconButton(
            icon: Icon(Icons.home,
                color: Theme.of(context).colorScheme.onPrimary),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BaseScreen()),
              );
            },
          ),
        ],
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Header
                      Icon(Icons.person,
                          size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Personal Information',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'This section displays personal details as stored in the system.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Each field is a vertical block
                      _buildFieldWithIcon(
                          'Name', name ?? 'N/A', Icons.badge_outlined),
                      _buildFieldWithIcon(
                          'Surname', surname ?? 'N/A', Icons.person_outline),
                      _buildFieldWithIcon(
                          'Email', email ?? 'N/A', Icons.email_outlined),
                      _buildFieldWithIcon(
                          'Phone', phone ?? 'N/A', Icons.phone_outlined),

                      // Age instead of dateOfBirth
                      _buildFieldWithIcon(
                        'Age',
                        age == null ? 'N/A' : '$age years',
                        Icons.cake_outlined,
                      ),

                      // Role
                      _buildFieldWithIcon(
                        'Role',
                        role ?? 'N/A',
                        role == 'PT' ? Icons.medical_services : Icons.person,
                      ),

                      const SizedBox(height: 32),

                      // Use the custom GradientButton here
                      GradientButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
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
                                },
                                clientUid: widget.clientUid,
                              ),
                            ),
                          );
                        },
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

  /// Reusable field with an icon
  Widget _buildFieldWithIcon(String label, String value, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                border: Border.all(color: theme.dividerColor),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
