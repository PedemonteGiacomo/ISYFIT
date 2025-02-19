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
  final TextEditingController sportExpController = TextEditingController();
  final TextEditingController gymExpController = TextEditingController();
  final TextEditingController otherPTExpController = TextEditingController();
  final TextEditingController preferredTimeController = TextEditingController();

  int timesPerWeek = 3; // or default 2, etc.

  @override
  void initState() {
    super.initState();
    // existing
    goalsController.text = widget.data['goals'] ?? '';
    selectedDays.addAll(widget.data['training_days'] ?? []);

    // new
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
                          'Define your training goals and additional details to help us plan the best program for you.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                        const SizedBox(height: 24),

                        // 1) Esperienze sportive dilettantistiche/professionistiche
                        _buildTextInput(
                          'Esperienze sportive?',
                          'Dilettantistiche, professionistiche, etc.',
                          sportExpController,
                          (value) => widget.data['sportExperience'] = value,
                        ),
                        const SizedBox(height: 16),

                        // 2) Hai già esperienza in sala pesi?
                        _buildTextInput(
                          'Esperienza sala pesi?',
                          'Se sì, quanto tempo fa e per quanto?',
                          gymExpController,
                          (value) => widget.data['gymExperience'] = value,
                        ),
                        const SizedBox(height: 16),

                        // 3) Esperienza con altri PT?
                        _buildTextInput(
                          'Altri Personal Trainer in passato?',
                          'Come ti sei trovato?',
                          otherPTExpController,
                          (value) => widget.data['otherPTExperience'] = value,
                        ),
                        const SizedBox(height: 16),

                        // 4) Quante volte a settimana?
                        _buildTimesPerWeekDropdown(),
                        const SizedBox(height: 24),

                        // 5) Goals
                        _buildTextInput(
                          'What are your training goals?',
                          'E.g., fitness, strength, hypertrophy, etc.',
                          goalsController,
                          (value) => widget.data['goals'] = value,
                        ),
                        const SizedBox(height: 16),

                        // 6) Preferred Training Days
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
                        const SizedBox(height: 16),

                        // 7) Orario preferito
                        _buildTextInput(
                          'Orario preferito',
                          'Mattina? Pomeriggio? Sera?',
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
                                _formKey.currentState?.save();
                                // Save the timesPerWeek also
                                widget.data['timesPerWeek'] = timesPerWeek;

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

  Widget _buildTextInput(
    String label,
    String hint,
    TextEditingController controller,
    Function(String) onSaved,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(label,
                    style: const TextStyle(fontSize: 12, color: Colors.grey)),
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
                  minLines: 1,
                  maxLines: 3,
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
                color: isSelected ? Colors.blue : Colors.black,
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
        const Icon(Icons.calendar_month, color: Colors.blue),
        const SizedBox(width: 12),
        const Text('Quante volte a settimana?'),
        const SizedBox(width: 16),
        DropdownButton<int>(
          value: timesPerWeek,
          items: [1, 2, 3, 4, 5, 6, 7].map((count) {
            return DropdownMenuItem<int>(
              value: count,
              child: Text('$count'),
            );
          }).toList(),
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
