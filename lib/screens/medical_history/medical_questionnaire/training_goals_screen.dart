import 'package:flutter/material.dart';
import 'final_submit_screen.dart';

class TrainingGoalsScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? clientUid;

  const TrainingGoalsScreen({
    Key? key,
    required this.data,
    this.clientUid,
  }) : super(key: key);

  @override
  _TrainingGoalsScreenState createState() => _TrainingGoalsScreenState();
}

class _TrainingGoalsScreenState extends State<TrainingGoalsScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<String> selectedDays = [];

  final TextEditingController goalsController = TextEditingController();
  final TextEditingController sportExpController = TextEditingController();
  final TextEditingController gymExpController = TextEditingController();
  final TextEditingController otherPTExpController = TextEditingController();
  final TextEditingController preferredTimeController = TextEditingController();

  int timesPerWeek = 3;

  @override
  void initState() {
    super.initState();
    goalsController.text = widget.data['goals'] ?? '';
    selectedDays.addAll(widget.data['training_days'] ?? []);
    sportExpController.text = widget.data['sportExperience'] ?? '';
    gymExpController.text = widget.data['gymExperience'] ?? '';
    otherPTExpController.text = widget.data['otherPTExperience'] ?? '';
    preferredTimeController.text = widget.data['preferredTime'] ?? '';
    timesPerWeek = widget.data['timesPerWeek'] ?? 3;
  }

  @override
  void dispose() {
    goalsController.dispose();
    sportExpController.dispose();
    gymExpController.dispose();
    otherPTExpController.dispose();
    preferredTimeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: theme.primaryColor,
        title: Text('Training & Goals',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
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
                        Icon(Icons.fitness_center_outlined,
                            size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Training & Goals',
                          style: theme.textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Define your training goals and additional details to help us plan the best program for you.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),

                        _buildTextInput(
                          'Sports Experience',
                          'Professional, amateur, casual?',
                          sportExpController,
                          (value) => widget.data['sportExperience'] = value,
                        ),
                        const SizedBox(height: 16),

                        _buildTextInput(
                          'Gym Experience',
                          'Have you trained with weights before?',
                          gymExpController,
                          (value) => widget.data['gymExperience'] = value,
                        ),
                        const SizedBox(height: 16),

                        _buildTextInput(
                          'Previous Personal Trainers',
                          'How was your experience?',
                          otherPTExpController,
                          (value) => widget.data['otherPTExperience'] = value,
                        ),
                        const SizedBox(height: 16),

                        _buildTimesPerWeekDropdown(),
                        const SizedBox(height: 24),

                        _buildTextInput(
                          'What are your training goals?',
                          'E.g., fitness, strength, hypertrophy',
                          goalsController,
                          (value) => widget.data['goals'] = value,
                        ),
                        const SizedBox(height: 16),

                        _buildToggleButtonGroup(
                          label: 'Preferred Training Days',
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
                        const SizedBox(height: 16),

                        _buildTextInput(
                          'Preferred Training Time',
                          'Morning, afternoon, or evening?',
                          preferredTimeController,
                          (value) => widget.data['preferredTime'] = value,
                        ),
                        const SizedBox(height: 32),

                        // Next Button
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.75,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? false) {
                                widget.data['timesPerWeek'] = timesPerWeek;

                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FinalSubmitScreen(
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

  Widget _buildTextInput(
    String label,
    String hint,
    TextEditingController controller,
    Function(String) onSaved,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(Icons.edit_outlined,
            color: Theme.of(context).colorScheme.primary, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: TextFormField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onSaved: (value) => onSaved(value ?? ''),
            validator: (value) => value == null || value.isEmpty
                ? 'This field is required'
                : null,
            minLines: 1,
            maxLines: 3,
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
        Text(label,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
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
                  selected
                      ? selectedValues.add(option)
                      : selectedValues.remove(option);
                  onChanged(selectedValues);
                });
              },
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected
                    ? Theme.of(context).colorScheme.primary
                    : Colors.black,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildTimesPerWeekDropdown() {
    return Row(
      children: [
        Icon(Icons.calendar_month,
            color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        const Text('How many times per week?'),
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: timesPerWeek,
          items: List.generate(7, (i) => i + 1)
              .map((count) =>
                  DropdownMenuItem(value: count, child: Text('$count')))
              .toList(),
          onChanged: (val) {
            setState(() {
              timesPerWeek = val ?? 3;
            });
          },
        ),
      ],
    );
  }
}
