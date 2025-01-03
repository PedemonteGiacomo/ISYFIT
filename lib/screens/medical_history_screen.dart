import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/screens/medical_questionnaire/questionnaire_screen.dart';

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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Medical History Dashboard'),
        centerTitle: true,
      ),
      body: FutureBuilder<Map<String, dynamic>?>(
        future: _fetchMedicalHistory(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return const QuestionnaireScreen();
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
                        value: data['drinks_alcohol'] ?? 'N/A',
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
