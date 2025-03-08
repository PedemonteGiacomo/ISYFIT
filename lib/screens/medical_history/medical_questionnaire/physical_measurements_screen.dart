import 'package:flutter/material.dart';
import 'lifestyle_screen.dart';

class PhysicalMeasurementsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? clientUid;

  const PhysicalMeasurementsScreen({
    Key? key,
    required this.data,
    this.clientUid,
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
    _heightController =
        TextEditingController(text: widget.data['height'] ?? '');
    _weightController =
        TextEditingController(text: widget.data['weight'] ?? '');
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
      // appBar: AppBar(
      //   title: const Text('Physical Measurements'),
      //   centerTitle: true,
      //   backgroundColor: theme.colorScheme.primary,
      // ),
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
                        // Header Section
                        Icon(Icons.straighten,
                            size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Physical Measurements',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Provide accurate details of your physical measurements to help us better understand your requirements.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form Fields
                        Row(
                          children: [
                            Expanded(
                              child: _buildTextInput(
                                'Height (cm)',
                                'Enter height',
                                Icons.height_outlined,
                                _heightController,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTextInput(
                                'Weight (kg)',
                                'Enter weight',
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
                                      clientUid: widget.clientUid,
                                    ),
                                  ),
                                );
                              }
                            },
                            icon: const Icon(Icons.arrow_forward,
                                color: Colors.white),
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

  /// Reusable **text input field** with icon and theme styling
  Widget _buildTextInput(
    String label,
    String hint,
    IconData icon,
    TextEditingController controller,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          decoration: InputDecoration(
            prefixIcon:
                Icon(icon, color: Theme.of(context).colorScheme.primary),
            hintText: hint,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12.0),
            ),
            filled: true,
            fillColor: Theme.of(context).colorScheme.surface,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
          validator: (value) =>
              value == null || value.isEmpty ? 'This field is required' : null,
        ),
      ],
    );
  }
}
