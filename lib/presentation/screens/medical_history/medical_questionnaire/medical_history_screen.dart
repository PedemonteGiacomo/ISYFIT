import 'package:flutter/material.dart';
import 'package:isyfit/presentation/screens/base_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/widgets/gradient_button.dart';
import 'sleep_energy_screen.dart';

/// Example model for icon-labeled choice
class _IconChoice {
  final String label;
  final IconData icon;
  const _IconChoice(this.label, this.icon);
}

class MedicalHistoryScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? clientUid;

  const MedicalHistoryScreen({
    Key? key,
    required this.data,
    this.clientUid,
  }) : super(key: key);

  @override
  _MedicalHistoryScreenState createState() => _MedicalHistoryScreenState();
}

class _MedicalHistoryScreenState extends State<MedicalHistoryScreen> {
  final _formKey = GlobalKey<FormState>();

  bool spineJointMuscleIssues = false;
  bool injuriesOrSurgery = false;
  bool pathologies = false;
  bool asthmatic = false;

  // Single-choice icons for muscle issues
  final List<_IconChoice> _muscleIssueOptions = [
    _IconChoice('Neck', Icons.account_box_outlined),
    _IconChoice('Lower Back', Icons.chair_alt_outlined),
    _IconChoice('Knees', Icons.directions_walk_outlined),
    _IconChoice('Shoulders', Icons.accessibility),
    _IconChoice('Other', Icons.help_outline),
  ];
  String? _selectedMuscleIssue;
  final TextEditingController otherMuscleIssueController =
      TextEditingController();

  // Single-choice icons for injuries
  final List<_IconChoice> _injuryOptions = [
    _IconChoice('Ankle', Icons.directions_run),
    _IconChoice('Knee', Icons.directions_walk_outlined),
    _IconChoice('Shoulder', Icons.accessibility),
    _IconChoice('Back', Icons.chair),
    _IconChoice('Other', Icons.help_outline),
  ];
  String? _selectedInjury;
  final TextEditingController otherInjuryController = TextEditingController();

  // Pathologies => multi-select chips
  final List<String> _pathologyOptions = [
    'Diabetes',
    'Hypertension',
    'Cardiac',
    'Other'
  ];
  final List<String> _selectedPathologies = [];
  final TextEditingController otherPathologyController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    // Initialize if missing
    widget.data['spineJointMuscleIssues'] ??= 'No';
    widget.data['injuriesOrSurgery'] ??= 'No';
    widget.data['pathologies'] ??= 'No';
    widget.data['asthmatic'] ??= 'No';

    spineJointMuscleIssues = (widget.data['spineJointMuscleIssues'] == 'Yes');
    injuriesOrSurgery = (widget.data['injuriesOrSurgery'] == 'Yes');
    pathologies = (widget.data['pathologies'] == 'Yes');
    asthmatic = (widget.data['asthmatic'] == 'Yes');

    // If user had typed details for muscle issues or injuries before, parse them if you'd like.
    // We'll do a basic approach: if it matches one of our labels, set it; else "Other".
    if (spineJointMuscleIssues) {
      final oldDetail = widget.data['spineJointMuscleIssuesDetails'] ?? '';
      // If oldDetail is in the list of muscleIssue labels, pick it. Otherwise "Other"
      if (_muscleIssueOptions.any((o) => o.label == oldDetail)) {
        _selectedMuscleIssue = oldDetail;
      } else if (oldDetail.isNotEmpty) {
        _selectedMuscleIssue = 'Other';
        otherMuscleIssueController.text = oldDetail;
      }
    }

    if (injuriesOrSurgery) {
      final oldInj = widget.data['injuriesOrSurgeryDetails'] ?? '';
      if (_injuryOptions.any((o) => o.label == oldInj)) {
        _selectedInjury = oldInj;
      } else if (oldInj.isNotEmpty) {
        _selectedInjury = 'Other';
        otherInjuryController.text = oldInj;
      }
    }

    // If pathologies => parse them from a string if you want. We'll do a basic approach:
    // E.g. user stored "Hypertension, Other - some detail"
    // We'll skip that advanced parse for simplicity, but you can if you'd like.
  }

  @override
  void dispose() {
    otherMuscleIssueController.dispose();
    otherInjuryController.dispose();
    otherPathologyController.dispose();
    super.dispose();
  }

  // Proceed to Sleep/Energy screen
  void _goToNextScreen() {
    // Convert toggles to Yes/No
    widget.data['spineJointMuscleIssues'] =
        spineJointMuscleIssues ? 'Yes' : 'No';
    widget.data['injuriesOrSurgery'] = injuriesOrSurgery ? 'Yes' : 'No';
    widget.data['pathologies'] = pathologies ? 'Yes' : 'No';
    widget.data['asthmatic'] = asthmatic ? 'Yes' : 'No';

    // If spineJointMuscleIssues => store chosen or typed
    if (!spineJointMuscleIssues) {
      _selectedMuscleIssue = null;
      otherMuscleIssueController.clear();
      widget.data['spineJointMuscleIssuesDetails'] = '';
    } else {
      if (_selectedMuscleIssue == 'Other') {
        widget.data['spineJointMuscleIssuesDetails'] =
            otherMuscleIssueController.text.trim();
      } else {
        widget.data['spineJointMuscleIssuesDetails'] =
            _selectedMuscleIssue ?? '';
      }
    }

    // If injuries => store chosen or typed
    if (!injuriesOrSurgery) {
      _selectedInjury = null;
      otherInjuryController.clear();
      widget.data['injuriesOrSurgeryDetails'] = '';
    } else {
      if (_selectedInjury == 'Other') {
        widget.data['injuriesOrSurgeryDetails'] =
            otherInjuryController.text.trim();
      } else {
        widget.data['injuriesOrSurgeryDetails'] = _selectedInjury ?? '';
      }
    }

    // If pathologies => store multi-select
    if (!pathologies) {
      _selectedPathologies.clear();
      otherPathologyController.clear();
      widget.data['pathologiesDetails'] = '';
    } else {
      // We'll store them as a comma-labeled string
      String finalPathologies = _selectedPathologies.join(', ');
      // If "Other" is in there, we append the typed text
      if (_selectedPathologies.contains('Other') &&
          otherPathologyController.text.trim().isNotEmpty) {
        finalPathologies += ' - ' + otherPathologyController.text.trim();
      }
      widget.data['pathologiesDetails'] = finalPathologies;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SleepEnergyScreen(
          data: widget.data,
          clientUid: widget.clientUid,
        ),
      ),
    );
  }

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
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Icon + Title
                        Icon(
                          Icons.medical_services_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Medical History',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Let us know about any injuries or conditions so we can keep you safe and supported.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 1) Spine/Joint/Muscle Issues
                        _buildSwitchOption(
                          label: 'Do you have spine, joint, or muscle issues?',
                          value: spineJointMuscleIssues,
                          icon: Icons.accessibility_new_outlined,
                          onChanged: (v) =>
                              setState(() => spineJointMuscleIssues = v),
                        ),
                        if (spineJointMuscleIssues) _buildMuscleIssueIcons(),
                        if (spineJointMuscleIssues &&
                            _selectedMuscleIssue == 'Other')
                          _buildMuscleIssueOtherField(),
                        const SizedBox(height: 16),

                        // 2) Injuries or Surgery
                        _buildSwitchOption(
                          label: 'Have you had any injuries or surgery?',
                          value: injuriesOrSurgery,
                          icon: Icons.healing_outlined,
                          onChanged: (v) =>
                              setState(() => injuriesOrSurgery = v),
                        ),
                        if (injuriesOrSurgery) _buildInjuryIcons(),
                        if (injuriesOrSurgery && _selectedInjury == 'Other')
                          _buildInjuryOtherField(),
                        const SizedBox(height: 16),

                        // 3) Pathologies
                        _buildSwitchOption(
                          label: 'Do you have any pathologies?',
                          value: pathologies,
                          icon: Icons.local_hospital_outlined,
                          onChanged: (v) => setState(() => pathologies = v),
                        ),
                        if (pathologies) _buildPathologyMultiSelect(),
                        const SizedBox(height: 16),

                        // 4) Asthmatic
                        _buildSwitchOption(
                          label: 'Are you asthmatic?',
                          value: asthmatic,
                          icon: Icons.air_outlined,
                          onChanged: (v) => setState(() => asthmatic = v),
                        ),
                        const SizedBox(height: 32),

                        // Next Button
                        GradientButton(
                          label: 'Next',
                          icon: Icons.arrow_forward,
                          onPressed: _goToNextScreen,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Reusable switch-based question
  Widget _buildSwitchOption({
    required String label,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    final theme = Theme.of(context);
    return SwitchListTile(
      title: Text(label),
      value: value,
      secondary: Icon(icon, color: theme.colorScheme.primary),
      onChanged: onChanged,
      activeColor: theme.colorScheme.primary,
    );
  }

  // ------------------------- SPINE/JOINT/MUSCLE SECTION -------------------------
  Widget _buildMuscleIssueIcons() {
    final theme = Theme.of(context);
    // Replacing old drop-down with icons
    final List<_IconChoice> muscleIssueChoices = [
      _IconChoice('Neck', Icons.accessibility_new),
      _IconChoice('Lower Back', Icons.chair_alt_outlined),
      _IconChoice('Knees', Icons.directions_walk_outlined),
      _IconChoice('Shoulders', Icons.accessibility),
      _IconChoice('Other', Icons.help_outline),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select your main issue:', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: muscleIssueChoices.map((choice) {
                final bool isSelected = (_selectedMuscleIssue == choice.label);
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () =>
                        setState(() => _selectedMuscleIssue = choice.label),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            choice.icon,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            choice.label,
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // If "Other" => show text field
  Widget _buildMuscleIssueOtherField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: otherMuscleIssueController,
        decoration: InputDecoration(
          labelText: 'Describe your issue',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  // ------------------------- INJURIES OR SURGERY SECTION -------------------------
  Widget _buildInjuryIcons() {
    final theme = Theme.of(context);
    final List<_IconChoice> injuryChoices = [
      _IconChoice('Ankle', Icons.directions_run),
      _IconChoice('Knee', Icons.run_circle_outlined),
      _IconChoice('Shoulder', Icons.accessible_forward),
      _IconChoice('Back', Icons.chair),
      _IconChoice('Other', Icons.help_outline),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select your injury/surgery:',
              style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: injuryChoices.map((choice) {
                final bool isSelected = (_selectedInjury == choice.label);
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedInjury = choice.label),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? theme.colorScheme.primary.withOpacity(0.2)
                            : theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isSelected
                              ? theme.colorScheme.primary
                              : Colors.grey.shade300,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            choice.icon,
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            choice.label,
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.black,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // If "Other" => show text field
  Widget _buildInjuryOtherField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: otherInjuryController,
        decoration: InputDecoration(
          labelText: 'Describe your injury/surgery',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  // ------------------------- PATHOLOGIES MULTI-SELECT -------------------------
  Widget _buildPathologyMultiSelect() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Select your pathologies:', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _pathologyOptions.map((option) {
              final isSelected = _selectedPathologies.contains(option);
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  setState(() {
                    if (selected) {
                      _selectedPathologies.add(option);
                    } else {
                      _selectedPathologies.remove(option);
                    }
                  });
                },
                selectedColor: theme.colorScheme.primary.withOpacity(0.2),
              );
            }).toList(),
          ),
          // If "Other" is selected among them, show text field
          if (_selectedPathologies.contains('Other'))
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextFormField(
                controller: otherPathologyController,
                decoration: InputDecoration(
                  labelText: 'Describe your pathology',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
