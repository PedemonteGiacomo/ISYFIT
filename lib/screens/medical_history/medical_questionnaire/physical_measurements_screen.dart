import 'package:flutter/material.dart';
import 'lifestyle_screen.dart';

class PhysicalMeasurementsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? clientUid; // <-- Add this

  const PhysicalMeasurementsScreen({
    Key? key,
    required this.data,
    this.clientUid, // <-- Accept it in constructor
  }) : super(key: key);

  @override
  _PhysicalMeasurementsScreenState createState() =>
      _PhysicalMeasurementsScreenState();
}

class _PhysicalMeasurementsScreenState
    extends State<PhysicalMeasurementsScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  @override
  void initState() {
    super.initState();
    _heightController = TextEditingController(text: widget.data['height'] ?? '');
    _weightController = TextEditingController(text: widget.data['weight'] ?? '');
  }

  @override
  void dispose() {
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Physical Measurements'),
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
                        const Icon(Icons.straighten, size: 64, color: Colors.blue),
                        const SizedBox(height: 16),
                        Text(
                          'Physical Measurements',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Provide accurate details of your physical measurements to help us better understand your requirements.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextInput(
                                'Height',
                                'Enter height (cm)',
                                Icons.height_outlined,
                                _heightController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextInput(
                                'Weight',
                                'Enter weight (kg)',
                                Icons.monitor_weight_outlined,
                                _weightController,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),

                        // Next Button
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                widget.data['height'] = _heightController.text;
                                widget.data['weight'] = _weightController.text;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => LifestyleScreen(
                                      data: widget.data,
                                      clientUid: widget.clientUid, // <-- pass forward
                                    ),
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

  Widget _buildTextInput(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Row(
      children: [
        Icon(icon, color: Colors.blue, size: 24),
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
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                TextFormField(
                  controller: controller,
                  decoration: InputDecoration(
                    hintText: hint,
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 8.0),
                  ),
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
