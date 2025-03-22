import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'package:isyfit/widgets/gradient_app_bar.dart';
import 'package:isyfit/widgets/gradient_button_for_final_submit_screen.dart';

class FinalSubmitScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? clientUid;

  const FinalSubmitScreen({
    Key? key,
    required this.data,
    this.clientUid,
  }) : super(key: key);

  @override
  _FinalSubmitScreenState createState() => _FinalSubmitScreenState();
}

class _FinalSubmitScreenState extends State<FinalSubmitScreen> {
  bool isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      // 1) Use your GradientAppBar
      appBar: GradientAppBar(
        title: 'isy-check - Anamnesis Data Insertion',
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
                      // ✅ Success Icon
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),

                      // ✅ Header Text
                      Text(
                        'Thank You!',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Text(
                        'You’ve successfully completed the questionnaire. '
                        'Please review your data and submit it.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ✅ Data Summary
                      _buildDataSummary(),
                      const SizedBox(height: 24),

                      // ✅ GradientButton for submission
                      GradientButtonFFSS(
                        label: isSubmitting ? 'Submitting...' : 'Submit',
                        // If submitting, show a small spinner icon. Otherwise, show send icon.
                        icon: isSubmitting ? Icons.hourglass_empty : Icons.send,
                        onPressed: isSubmitting ? null : _handleSubmit,
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

  /// 🔹 **Summary Data Display**
  Widget _buildDataSummary() {
    final entries = widget.data.entries.toList();
    final rows = <Widget>[];

    // We group them in pairs of 2 per row
    for (int i = 0; i < entries.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildDataCard(entries[i])),
            if (i + 1 < entries.length) const SizedBox(width: 16),
            if (i + 1 < entries.length)
              Expanded(child: _buildDataCard(entries[i + 1])),
          ],
        ),
      );
      rows.add(const SizedBox(height: 16));
    }

    return Column(children: rows);
  }

  /// 🔹 **Single Data Card**
  Widget _buildDataCard(MapEntry<String, dynamic> entry) {
    final theme = Theme.of(context);
    final keyLabel = entry.key;
    final val = entry.value is List
        ? (entry.value as List).join(', ')
        : entry.value.toString();

    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border.all(color: theme.colorScheme.primary.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            keyLabel,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            val,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// 🔹 **Handle Submission to Firebase**
  Future<void> _handleSubmit() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      // If this was PT-submitted for a client, we use their UID; otherwise, use the logged-in user’s UID
      final targetUid = widget.clientUid ?? user.uid;

      // Merge the data into the "medical_history/{targetUid}" doc
      await FirebaseFirestore.instance
          .collection('medical_history')
          .doc(targetUid)
          .set(widget.data, SetOptions(merge: true));

      // ✅ Show success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Data saved successfully!',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          backgroundColor: Colors.green,
        ),
      );

      // ✅ Go back to BaseScreen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BaseScreen()),
      );
    } catch (e) {
      // ❌ Show error
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error saving data: $e',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white,
                ),
          ),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }
}
