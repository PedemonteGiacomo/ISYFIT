import 'package:flutter/material.dart';
import 'sleep_energy_screen.dart';

class LifestyleScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? clientUid; // <-- Add this

  const LifestyleScreen({
    Key? key,
    required this.data,
    this.clientUid, // <-- Accept in constructor
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

  final TextEditingController alcoholDetailsController = TextEditingController();
  final TextEditingController smokingDetailsController = TextEditingController();
  final TextEditingController waterIntakeController = TextEditingController();
  final TextEditingController spineJointMuscleDetailsController = TextEditingController();
  final TextEditingController injuriesOrSurgeryDetailsController = TextEditingController();
  final TextEditingController pathologiesDetailsController = TextEditingController();
  final TextEditingController breakfastDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    widget.data['alcohol'] = widget.data['alcohol'] ?? 'No';
    widget.data['smokes'] = widget.data['smokes'] ?? 'No';
    widget.data['fixedWorkShifts'] = widget.data['fixedWorkShifts'] ?? 'No';
    widget.data['waterIntake'] = widget.data['waterIntake'] ?? '';
    widget.data['spineJointMuscleIssues'] = widget.data['spineJointMuscleIssues'] ?? 'No';
    widget.data['injuriesOrSurgery'] = widget.data['injuriesOrSurgery'] ?? 'No';
    widget.data['pathologies'] = widget.data['pathologies'] ?? 'No';
    widget.data['asthmatic'] = widget.data['asthmatic'] ?? 'No';
    widget.data['breakfast'] = widget.data['breakfast'] ?? 'No';

    alcoholDetailsController.text = widget.data['alcohol_details'] ?? '';
    smokingDetailsController.text = widget.data['smoking_details'] ?? '';
    waterIntakeController.text = widget.data['waterIntake'];
    spineJointMuscleDetailsController.text = widget.data['spineJointMuscleIssuesDetails'] ?? '';
    injuriesOrSurgeryDetailsController.text = widget.data['injuriesOrSurgeryDetails'] ?? '';
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
        title: const Text('Lifestyle'),
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
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        const Icon(Icons.medical_services_outlined, size: 64, color: Colors.blue),
                        const SizedBox(height: 16),
                        Text(
                          'Lifestyle and Medical History',
                          style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Provide lifestyle and medical details to help us tailor the best plan for you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        _buildToggleOption(
                          label: 'Are your work shifts fixed?',
                          value: fixedWorkShifts,
                          icon: Icons.schedule_outlined,
                          onChanged: (value) {
                            setState(() {
                              fixedWorkShifts = value;
                              widget.data['fixedWorkShifts'] = value ? 'Yes' : 'No';
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
                            'If yes, how much?',
                            alcoholDetailsController,
                            (value) => widget.data['alcohol_details'] = value,
                          ),
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
                            'If yes, how much?',
                            smokingDetailsController,
                            (value) => widget.data['smoking_details'] = value,
                          ),
                        const SizedBox(height: 24),

                        _buildTextInput(
                          'How much water do you drink daily?',
                          waterIntakeController,
                          (value) => widget.data['waterIntake'] = value,
                        ),
                        const SizedBox(height: 24),

                        _buildToggleOption(
                          label: 'Do you have spine, joint, or muscle issues?',
                          value: spineJointMuscleIssues,
                          icon: Icons.accessibility_outlined,
                          onChanged: (value) {
                            setState(() {
                              spineJointMuscleIssues = value;
                              widget.data['spineJointMuscleIssues'] = value ? 'Yes' : 'No';
                              if (!value) spineJointMuscleDetailsController.clear();
                            });
                          },
                        ),
                        if (spineJointMuscleIssues)
                          _buildTextInput(
                            'Describe the issue:',
                            spineJointMuscleDetailsController,
                            (value) => widget.data['spineJointMuscleIssuesDetails'] = value,
                          ),
                        const SizedBox(height: 24),

                        _buildToggleOption(
                          label: 'Have you had any injuries or surgery?',
                          value: injuriesOrSurgery,
                          icon: Icons.healing_outlined,
                          onChanged: (value) {
                            setState(() {
                              injuriesOrSurgery = value;
                              widget.data['injuriesOrSurgery'] = value ? 'Yes' : 'No';
                              if (!value) injuriesOrSurgeryDetailsController.clear();
                            });
                          },
                        ),
                        if (injuriesOrSurgery)
                          _buildTextInput(
                            'Describe your injury/surgery:',
                            injuriesOrSurgeryDetailsController,
                            (value) => widget.data['injuriesOrSurgeryDetails'] = value,
                          ),
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
                          _buildTextInput(
                            'Describe the pathology:',
                            pathologiesDetailsController,
                            (value) => widget.data['pathologiesDetails'] = value,
                          ),
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

                        _buildToggleOption(
                          label: 'Do you have breakfast daily?',
                          value: widget.data['breakfast'] == 'Yes',
                          icon: Icons.breakfast_dining_outlined,
                          onChanged: (value) {
                            setState(() {
                              widget.data['breakfast'] = value ? 'Yes' : 'No';
                              if (!value) breakfastDetailsController.clear();
                            });
                          },
                        ),
                        if (widget.data['breakfast'] == 'Yes')
                          _buildTextInput(
                            'What do you have for breakfast?',
                            breakfastDetailsController,
                            (value) => widget.data['breakfastDetails'] = value,
                          ),
                        const SizedBox(height: 32),

                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => SleepEnergyScreen(
                                  data: widget.data,
                                  clientUid: widget.clientUid, // <-- pass forward
                                ),
                              ),
                            );
                          },
                          child: const Text('Next'),
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
      secondary: Icon(icon),
      onChanged: onChanged,
    );
  }

  Widget _buildTextInput(
    String label,
    TextEditingController controller,
    ValueChanged<String> onChanged,
  ) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      onChanged: onChanged,
    );
  }
}
