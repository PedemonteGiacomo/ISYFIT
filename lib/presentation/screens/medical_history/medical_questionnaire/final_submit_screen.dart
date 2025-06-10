import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:isyfit/presentation/screens/base_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/widgets/gradient_button_for_final_submit_screen.dart';

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

  /// A map to rename keys to more user-friendly labels.
  /// Extend or modify this as needed for your own keys.
  static const Map<String, String> niceKeyLabels = {
    "name": "Name",
    "surname": "Surname",
    "phone": "Phone",
    "dateOfBirth": "Date of Birth",
    "role": "Role",
    "height": "Height",
    "weight": "Weight",
    "alcohol": "Alcohol?",
    "alcohol_details": "Alcohol Frequency",
    "smokes": "Smokes?",
    "smoking_details": "Smoking Details",
    "fixedWorkShifts": "Fixed Work Shifts?",
    "waterIntake": "Water Intake (L)",
    "breakfast": "Breakfast?",
    "breakfastDetails": "Breakfast Details",
    "spineJointMuscleIssues": "Spine Joint Muscle Issues?",
    "spineJointMuscleIssuesDetails": "Spine/Joint/Muscle Issues Details",
    "injuriesOrSurgery": "Injuries/Surgery?",
    "injuriesOrSurgeryDetails": "Injuries/Surgery Details",
    "pathologies": "Pathologies?",
    "pathologiesDetails": "Pathologies Details",
    "asthmatic": "Asthmatic?",
    "sleep_time": "Sleep Time",
    "wake_time": "Wake Time",
    "energetic": "Feels Energetic?",
    "sportExperience": "Sports Experience",
    "gymExperience": "Gym Experience",
    "otherPTExperience": "Previous PT Experience",
    "timesPerWeek": "Times Per Week",
    "goals": "Training Goals",
    // If "training_goals_list" is a duplicate, we just won't display it at all
    "training_goals_list": "SKIP_DISPLAY",
    "training_days": "Preferred Training Days",
    "preferredTime": "Preferred Time",
  };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                      // Success Icon
                      Icon(
                        Icons.check_circle_outline,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(height: 16),

                      // Header Text
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

                      // Data Summary
                      _buildDataSummary(),
                      const SizedBox(height: 24),

                      // Submit GradientButton
                      GradientButtonFFSS(
                        label: isSubmitting ? 'Submitting...' : 'Submit',
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

  /// Builds the full summary of data, grouping them in pairs of 2
  Widget _buildDataSummary() {
    // Filter out "training_goals_list" since it's duplicated by "goals"
    final filteredMap = widget.data.entries
        .where((e) => e.key != "training_goals_list") // skip this key
        .toList();

    final rows = <Widget>[];

    // group in pairs
    for (int i = 0; i < filteredMap.length; i += 2) {
      rows.add(
        Row(
          children: [
            Expanded(child: _buildDataCard(filteredMap[i])),
            if (i + 1 < filteredMap.length) const SizedBox(width: 16),
            if (i + 1 < filteredMap.length)
              Expanded(child: _buildDataCard(filteredMap[i + 1])),
          ],
        ),
      );
      rows.add(const SizedBox(height: 16));
    }

    return Column(children: rows);
  }

  /// Single Data Card – show "Not specified" if blank.
  /// Also rename the key using niceKeyLabels if possible.
  Widget _buildDataCard(MapEntry<String, dynamic> entry) {
    final theme = Theme.of(context);

    // Convert Lists to comma-separated
    final rawValue = entry.value is List
        ? (entry.value as List).join(', ')
        : entry.value?.toString() ?? '';

    final displayValue = rawValue.trim().isEmpty ? 'Not specified' : rawValue;

    final keyLabel = niceKeyLabels[entry.key] ?? _keyToReadable(entry.key);

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
            displayValue,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Fallback method if not found in the map: just do a naive "title case"
  /// for something like "spineJointMuscleIssues" -> "Spine Joint Muscle Issues"
  /// or "sleep_time" -> "Sleep Time"
  String _keyToReadable(String originalKey) {
    // handle snake_case -> replace '_' with space
    final spaced = originalKey.replaceAll('_', ' ');

    // handle minimal camelCase splitting (very naive approach)
    // e.g. "spineJointMuscleIssues" -> "spine Joint Muscle Issues"
    final withCamelSplit = spaced.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );
    // Now uppercase the first letter of each word
    // e.g. "spine Joint muscle Issues" -> "Spine Joint Muscle Issues"
    return withCamelSplit
        .split(' ')
        .map((word) => word.isEmpty
            ? ''
            : word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  /// Submits the data to Firestore
  Future<void> _handleSubmit() async {
    setState(() {
      isSubmitting = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not logged in');
      }

      final targetUid = widget.clientUid ?? user.uid;

      await FirebaseFirestore.instance
          .collection('medical_history')
          .doc(targetUid)
          .set(widget.data, SetOptions(merge: true));

      // Show success
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

      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const BaseScreen()),
      );
    } catch (e) {
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
