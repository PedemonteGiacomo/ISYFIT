import 'package:flutter/material.dart';
import 'final_submit_screen.dart';

class TrainingGoalsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const TrainingGoalsScreen({Key? key, required this.data}) : super(key: key);

  @override
  _TrainingGoalsScreenState createState() => _TrainingGoalsScreenState();
}

class _TrainingGoalsScreenState extends State<TrainingGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> selectedDays = [];
  final TextEditingController goalsController = TextEditingController();

  @override
  void initState() {
    super.initState();
    goalsController.text = widget.data['goals'] ?? '';
    selectedDays.addAll(widget.data['training_days'] ?? []);
  }

  @override
  void dispose() {
    goalsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Training and Goals'),
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
                        const Icon(Icons.fitness_center_outlined,
                            size: 64, color: Colors.blue),
                        const SizedBox(height: 16),
                        Text(
                          'Training and Goals',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Define your training goals and preferred workout days to help us plan the best program for you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // Training Goals
                        _buildTextInput(
                          'What are your training goals?',
                          'Describe your goals (e.g., fitness, strength, etc.)',
                          goalsController,
                          (value) => widget.data['goals'] = value,
                        ),
                        const SizedBox(height: 24),

                        // Preferred Training Days
                        _buildToggleButtonGroup(
                          label: 'Preferred training days',
                          options: [
                            'Monday',
                            'Tuesday',
                            'Wednesday',
                            'Thursday',
                            'Friday',
                            'Saturday',
                            'Sunday'
                          ],
                          selectedValues: selectedDays,
                          onChanged: (values) =>
                              widget.data['training_days'] = values,
                        ),
                        const SizedBox(height: 32),

                        // Next Button
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                _formKey.currentState?.save();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        FinalSubmitScreen(data: widget.data),
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

  Widget _buildTextInput(String label, String hint, TextEditingController controller,
      Function(String) onSaved) {
    return Row(
      children: [
        const Icon(Icons.edit_outlined, color: Colors.blue, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            padding:
                const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
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
                    contentPadding:
                        const EdgeInsets.symmetric(vertical: 8.0),
                  ),
                  onSaved: (value) => onSaved(value ?? ''),
                  validator: (value) => value == null || value.isEmpty
                      ? 'This field is required'
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleButtonGroup({
    required String label,
    required List<String> options,
    required List<String> selectedValues,
    required Function(List<String>) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8.0,
          children: options.map((option) {
            final isSelected = selectedValues.contains(option);
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  if (selected) {
                    selectedValues.add(option);
                  } else {
                    selectedValues.remove(option);
                  }
                  onChanged(selectedValues);
                });
              },
              selectedColor: Colors.blue.shade100,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                  color: isSelected ? Colors.blue : Colors.black),
            );
          }).toList(),
        ),
      ],
    );
  }
}
