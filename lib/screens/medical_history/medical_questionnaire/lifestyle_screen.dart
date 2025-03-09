import 'package:flutter/material.dart';
import 'sleep_energy_screen.dart';

class LifestyleScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? clientUid;

  const LifestyleScreen({
    Key? key,
    required this.data,
    this.clientUid,
  }) : super(key: key);

  @override
  _LifestyleScreenState createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  bool drinksAlcohol = false;
  bool smokes = false;
  bool fixedWorkShifts = false;
  bool spineJointMuscleIssues = false;
  bool injuriesOrSurgery = false;
  bool pathologies = false;
  bool asthmatic = false;

  final _formKey = GlobalKey<FormState>();

  final TextEditingController alcoholDetailsController =
      TextEditingController();
  final TextEditingController smokingDetailsController =
      TextEditingController();
  final TextEditingController waterIntakeController = TextEditingController();
  final TextEditingController spineJointMuscleDetailsController =
      TextEditingController();
  final TextEditingController injuriesOrSurgeryDetailsController =
      TextEditingController();
  final TextEditingController pathologiesDetailsController =
      TextEditingController();
  final TextEditingController breakfastDetailsController =
      TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.data['alcohol'] ??= 'No';
    widget.data['smokes'] ??= 'No';
    widget.data['fixedWorkShifts'] ??= 'No';
    widget.data['waterIntake'] ??= '';
    widget.data['spineJointMuscleIssues'] ??= 'No';
    widget.data['injuriesOrSurgery'] ??= 'No';
    widget.data['pathologies'] ??= 'No';
    widget.data['asthmatic'] ??= 'No';
    widget.data['breakfast'] ??= 'No';

    alcoholDetailsController.text = widget.data['alcohol_details'] ?? '';
    smokingDetailsController.text = widget.data['smoking_details'] ?? '';
    waterIntakeController.text = widget.data['waterIntake'];
    spineJointMuscleDetailsController.text =
        widget.data['spineJointMuscleIssuesDetails'] ?? '';
    injuriesOrSurgeryDetailsController.text =
        widget.data['injuriesOrSurgeryDetails'] ?? '';
    pathologiesDetailsController.text = widget.data['pathologiesDetails'] ?? '';
    breakfastDetailsController.text = widget.data['breakfastDetails'] ?? '';
  }

  @override
  void dispose() {
    alcoholDetailsController.dispose();
    smokingDetailsController.dispose();
    waterIntakeController.dispose();
    spineJointMuscleDetailsController.dispose();
    injuriesOrSurgeryDetailsController.dispose();
    pathologiesDetailsController.dispose();
    breakfastDetailsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('Lifestyle',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Icon(Icons.medical_services_outlined,
                            size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Lifestyle and Medical History',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Provide lifestyle and medical details to help us tailor the best plan for you.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _buildToggleOption(
                          label: 'Are your work shifts fixed?',
                          value: fixedWorkShifts,
                          icon: Icons.schedule_outlined,
                          onChanged: (value) {
                            setState(() {
                              fixedWorkShifts = value;
                              widget.data['fixedWorkShifts'] =
                                  value ? 'Yes' : 'No';
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        _buildToggleOption(
                          label: 'Do you drink alcohol?',
                          value: drinksAlcohol,
                          icon: Icons.local_bar_outlined,
                          onChanged: (value) {
                            setState(() {
                              drinksAlcohol = value;
                              widget.data['alcohol'] = value ? 'Yes' : 'No';
                              if (!value) alcoholDetailsController.clear();
                            });
                          },
                        ),
                        if (drinksAlcohol)
                          _buildTextInput(
                              'If yes, how much?', alcoholDetailsController),
                        const SizedBox(height: 24),
                        _buildToggleOption(
                          label: 'Do you smoke?',
                          value: smokes,
                          icon: Icons.smoking_rooms_outlined,
                          onChanged: (value) {
                            setState(() {
                              smokes = value;
                              widget.data['smokes'] = value ? 'Yes' : 'No';
                              if (!value) smokingDetailsController.clear();
                            });
                          },
                        ),
                        if (smokes)
                          _buildTextInput(
                              'If yes, how much?', smokingDetailsController),
                        const SizedBox(height: 24),
                        _buildTextInput('How much water do you drink daily?',
                            waterIntakeController),
                        const SizedBox(height: 24),
                        _buildToggleOption(
                          label: 'Do you have spine, joint, or muscle issues?',
                          value: spineJointMuscleIssues,
                          icon: Icons.accessibility_outlined,
                          onChanged: (value) {
                            setState(() {
                              spineJointMuscleIssues = value;
                              widget.data['spineJointMuscleIssues'] =
                                  value ? 'Yes' : 'No';
                              if (!value)
                                spineJointMuscleDetailsController.clear();
                            });
                          },
                        ),
                        if (spineJointMuscleIssues)
                          _buildTextInput('Describe the issue:',
                              spineJointMuscleDetailsController),
                        const SizedBox(height: 24),
                        _buildToggleOption(
                          label: 'Have you had any injuries or surgery?',
                          value: injuriesOrSurgery,
                          icon: Icons.healing_outlined,
                          onChanged: (value) {
                            setState(() {
                              injuriesOrSurgery = value;
                              widget.data['injuriesOrSurgery'] =
                                  value ? 'Yes' : 'No';
                              if (!value)
                                injuriesOrSurgeryDetailsController.clear();
                            });
                          },
                        ),
                        if (injuriesOrSurgery)
                          _buildTextInput('Describe your injury/surgery:',
                              injuriesOrSurgeryDetailsController),
                        const SizedBox(height: 24),
                        _buildToggleOption(
                          label: 'Do you have any pathologies?',
                          value: pathologies,
                          icon: Icons.local_hospital_outlined,
                          onChanged: (value) {
                            setState(() {
                              pathologies = value;
                              widget.data['pathologies'] = value ? 'Yes' : 'No';
                              if (!value) pathologiesDetailsController.clear();
                            });
                          },
                        ),
                        if (pathologies)
                          _buildTextInput('Describe the pathology:',
                              pathologiesDetailsController),
                        const SizedBox(height: 24),
                        _buildToggleOption(
                          label: 'Are you asthmatic?',
                          value: asthmatic,
                          icon: Icons.air_outlined,
                          onChanged: (value) {
                            setState(() {
                              asthmatic = value;
                              widget.data['asthmatic'] = value ? 'Yes' : 'No';
                            });
                          },
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SleepEnergyScreen(
                                  data: widget.data,
                                  clientUid: widget.clientUid,
                                ),
                              ),
                            );
                          },
                          child: Text(
                            'Next',
                            style: TextStyle(
                                color: Theme.of(context).colorScheme.onPrimary),
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
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool value,
    required IconData icon,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      title: Text(label),
      value: value,
      secondary: Icon(icon, color: Theme.of(context).colorScheme.primary),
      onChanged: onChanged,
    );
  }

  Widget _buildTextInput(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration:
          InputDecoration(labelText: label, border: const OutlineInputBorder()),
    );
  }
}
