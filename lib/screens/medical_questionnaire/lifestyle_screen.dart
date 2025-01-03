import 'package:flutter/material.dart';
import 'sleep_energy_screen.dart';

class LifestyleScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const LifestyleScreen({Key? key, required this.data}) : super(key: key);

  @override
  _LifestyleScreenState createState() => _LifestyleScreenState();
}

class _LifestyleScreenState extends State<LifestyleScreen> {
  bool drinksAlcohol = false;
  bool smokes = false;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController alcoholDetailsController = TextEditingController();
  final TextEditingController smokingDetailsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    drinksAlcohol = widget.data['drinks_alcohol'] == 'Yes';
    smokes = widget.data['smokes'] == 'Yes';
    alcoholDetailsController.text = widget.data['alcohol_details'] ?? '';
    smokingDetailsController.text = widget.data['smoking_details'] ?? '';
  }

  @override
  void dispose() {
    alcoholDetailsController.dispose();
    smokingDetailsController.dispose();
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
                        // Header Section
                        const Icon(Icons.local_drink_outlined, size: 64, color: Colors.blue),
                        const SizedBox(height: 16),
                        Text(
                          'Lifestyle',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Provide details about your lifestyle habits to help us tailor the best plan for you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Do you drink alcohol?
                        _buildToggleOption(
                          label: 'Do you drink alcohol?',
                          value: drinksAlcohol,
                          icon: Icons.local_bar_outlined,
                          onChanged: (value) {
                            setState(() {
                              drinksAlcohol = value;
                              widget.data['alcohol'] = value ? 'Yes' : 'No';                             
                              if (!value) {
                                alcoholDetailsController.clear();
                                widget.data['alcohol_details'] = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Alcohol details
                        if (drinksAlcohol)
                          _buildTextInput(
                            'If yes, how much?',
                            'Enter details',
                            alcoholDetailsController,
                            (value) => widget.data['alcohol_details'] = value,
                          ),
                        const SizedBox(height: 24),

                        // Do you smoke?
                        _buildToggleOption(
                          label: 'Do you smoke?',
                          value: smokes,
                          icon: Icons.smoking_rooms_outlined,
                          onChanged: (value) {
                            setState(() {
                              smokes = value;
                              widget.data['smokes'] = value ? 'Yes' : 'No';
                              if (!value) {
                                smokingDetailsController.clear();
                                widget.data['smoking_details'] = null;
                              }
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Smoking details
                        if (smokes)
                          _buildTextInput(
                            'If yes, how much?',
                            'Enter details',
                            smokingDetailsController,
                            (value) => widget.data['smoking_details'] = value,
                          ),
                        const SizedBox(height: 32),

                        // Next Button
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.75, // 75% width button
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _formKey.currentState?.save();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SleepEnergyScreen(data: widget.data),
                                  ),
                                );
                              }
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
      ),
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
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
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 14),
                ),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTextInput(
    String label,
    String hint,
    TextEditingController controller,
    Function(String) onSaved,
  ) {
    return Row(
      children: [
        const Icon(Icons.edit_outlined, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  onSaved: (value) => onSaved(value ?? ''),
                  validator: (value) =>
                      value == null || value.isEmpty ? 'This field is required' : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
