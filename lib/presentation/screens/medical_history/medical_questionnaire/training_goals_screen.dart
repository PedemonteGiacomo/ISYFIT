import 'package:flutter/material.dart';
import 'package:isyfit/presentation/screens/base_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/widgets/gradient_button.dart';
import 'final_submit_screen.dart';

/// Simple model for icon-labeled choice
class _IconChoice {
  final String label;
  final IconData icon;
  const _IconChoice(this.label, this.icon);
}

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
  // Sports Exp
  final List<_IconChoice> _sportsExpOptions = [
    _IconChoice('Professional', Icons.star_rate_rounded),
    _IconChoice('Amateur', Icons.sports_volleyball),
    _IconChoice('Casual', Icons.emoji_people_outlined),
    _IconChoice('None', Icons.not_interested),
  ];
  String? _selectedSportsExp;

  // Gym Exp
  final List<_IconChoice> _gymExpOptions = [
    _IconChoice('Beginner', Icons.self_improvement_outlined),
    _IconChoice('Intermediate', Icons.directions_run_rounded),
    _IconChoice('Advanced', Icons.fitness_center),
    _IconChoice('None', Icons.not_interested),
  ];
  String? _selectedGymExp;

  // PT Experience
  bool hadPTBefore = false;
  final List<_IconChoice> _ptExpOptions = [
    _IconChoice('Great', Icons.thumb_up),
    _IconChoice('Good', Icons.sentiment_satisfied_alt),
    _IconChoice('Okay', Icons.sentiment_neutral),
    _IconChoice('Poor', Icons.sentiment_dissatisfied),
  ];
  String? _ptExperienceFeedback;

  // Times per week
  int timesPerWeek = 3;

  // Goals: multi-select
  final List<String> goalsOptions = [
    'Lose Weight',
    'Build Muscle',
    'Improve Cardio',
    'Sports Performance',
  ];
  final List<String> selectedGoals = [];

  // Preferred training days
  final List<String> daysOfWeek = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];
  final List<String> selectedDays = [];

  // Preferred training time
  final List<_IconChoice> _timeOptions = [
    _IconChoice('Morning', Icons.wb_sunny_outlined),
    _IconChoice('Afternoon', Icons.cloud_outlined),
    _IconChoice('Evening', Icons.nights_stay_outlined),
    _IconChoice('Flexible', Icons.access_time_filled),
  ];
  String? _selectedTimePref;

  @override
  void initState() {
    super.initState();
    // Populate from data map if existing
    _selectedSportsExp = widget.data['sportExperience'] as String?;
    _selectedGymExp = widget.data['gymExperience'] as String?;
    hadPTBefore = (widget.data['otherPTExperience'] != null &&
        (widget.data['otherPTExperience'] as String).isNotEmpty);
    _ptExperienceFeedback =
        hadPTBefore ? widget.data['otherPTExperience'] as String? : null;

    timesPerWeek = widget.data['timesPerWeek'] ?? 3;

    if (widget.data['training_goals_list'] is List) {
      selectedGoals.addAll(widget.data['training_goals_list'].cast<String>());
    }
    if (widget.data['training_days'] is List) {
      selectedDays.addAll(widget.data['training_days'].cast<String>());
    }
    _selectedTimePref = widget.data['preferredTime'] as String?;
  }

  void _goNext() {
    // Minimal validations
    if (_selectedSportsExp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your sports experience.')),
      );
      return;
    }
    if (_selectedGymExp == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gym experience.')),
      );
      return;
    }
    if (hadPTBefore && _ptExperienceFeedback == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select how your PT experience was.')),
      );
      return;
    }
    if (selectedGoals.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select at least one goal.')),
      );
      return;
    }
    if (_selectedTimePref == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please select a preferred training time.')),
      );
      return;
    }

    // Store data
    widget.data['sportExperience'] = _selectedSportsExp;
    widget.data['gymExperience'] = _selectedGymExp;
    if (hadPTBefore) {
      widget.data['otherPTExperience'] = _ptExperienceFeedback ?? '';
    } else {
      widget.data['otherPTExperience'] = '';
    }
    widget.data['timesPerWeek'] = timesPerWeek;
    widget.data['training_goals_list'] = selectedGoals;
    widget.data['goals'] = selectedGoals.join(', ');
    widget.data['training_days'] = selectedDays;
    widget.data['preferredTime'] = _selectedTimePref;

    // Navigate
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FinalSubmitScreen(
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
              padding: const EdgeInsets.all(16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.fitness_center_outlined,
                          size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Training & Goals',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Choose your experiences and preferences for a personalized program.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sports Experience
                      _buildSingleRowIconChoices(
                        title: 'Sports Experience',
                        choices: _sportsExpOptions,
                        selectedValue: _selectedSportsExp,
                        onSelected: (val) =>
                            setState(() => _selectedSportsExp = val),
                      ),
                      const SizedBox(height: 16),

                      // Gym Experience
                      _buildSingleRowIconChoices(
                        title: 'Gym Experience',
                        choices: _gymExpOptions,
                        selectedValue: _selectedGymExp,
                        onSelected: (val) =>
                            setState(() => _selectedGymExp = val),
                      ),
                      const SizedBox(height: 16),

                      // PT Experience
                      _buildPTExperienceSection(),
                      const SizedBox(height: 16),

                      // Times per week
                      _buildTimesPerWeekRow(),
                      const SizedBox(height: 16),

                      // Goals: single row, multi-select
                      _buildSingleRowMultiSelect(
                        title: 'Training Goals',
                        options: goalsOptions,
                        selectedValues: selectedGoals,
                        onSelectChanged: (option, isSelected) {
                          setState(() {
                            if (isSelected) {
                              selectedGoals.add(option);
                            } else {
                              selectedGoals.remove(option);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Preferred days: single row, multi-select
                      _buildSingleRowMultiSelect(
                        title: 'Preferred Training Days',
                        options: daysOfWeek,
                        selectedValues: selectedDays,
                        onSelectChanged: (day, isSelected) {
                          setState(() {
                            if (isSelected) {
                              selectedDays.add(day);
                            } else {
                              selectedDays.remove(day);
                            }
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Preferred time
                      _buildSingleRowIconChoices(
                        title: 'Preferred Training Time',
                        choices: _timeOptions,
                        selectedValue: _selectedTimePref,
                        onSelected: (val) =>
                            setState(() => _selectedTimePref = val),
                      ),
                      const SizedBox(height: 32),

                      // Next button
                      GradientButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        onPressed: _goNext,
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

  /// Single-row icon-labeled choices for a single selection
  Widget _buildSingleRowIconChoices({
    required String title,
    required List<_IconChoice> choices,
    required String? selectedValue,
    required ValueChanged<String> onSelected,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Force single horizontal row with horizontal scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: choices.map((choice) {
              final bool isSelected = (selectedValue == choice.label);
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: InkWell(
                  onTap: () => onSelected(choice.label),
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
    );
  }

  /// Single-row multi-select (chips) with horizontal scrolling
  Widget _buildSingleRowMultiSelect({
    required String title,
    required List<String> options,
    required List<String> selectedValues,
    required void Function(String option, bool isSelected) onSelectChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: theme.textTheme.bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),

        // Single row scroll
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: options.map((option) {
              final isSelected = selectedValues.contains(option);
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(option),
                  selected: isSelected,
                  onSelected: (sel) => onSelectChanged(option, sel),
                  selectedColor: theme.colorScheme.primary.withOpacity(0.2),
                  labelStyle: TextStyle(
                    color:
                        isSelected ? theme.colorScheme.primary : Colors.black,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPTExperienceSection() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Previous Personal Trainer Experience',
          style:
              theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        SwitchListTile(
          contentPadding: EdgeInsets.zero, // Remove default padding
          title: const Text('Have you worked with a PT before?'),
          value: hadPTBefore,
          onChanged: (val) {
            setState(() {
              hadPTBefore = val;
              if (!val) _ptExperienceFeedback = null;
            });
          },
        ),
        if (hadPTBefore)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 8),
              Text('How was your experience?'),
              const SizedBox(height: 8),

              // Single row
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: _ptExpOptions.map((option) {
                    final bool isSelected =
                        (_ptExperienceFeedback == option.label);
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: InkWell(
                        onTap: () => setState(
                            () => _ptExperienceFeedback = option.label),
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
                                option.icon,
                                color: isSelected
                                    ? theme.colorScheme.primary
                                    : Colors.grey,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                option.label,
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
      ],
    );
  }

  Widget _buildTimesPerWeekRow() {
    final theme = Theme.of(context);
    return Row(
      children: [
        Icon(Icons.calendar_month, color: theme.colorScheme.primary),
        const SizedBox(width: 12),
        Text(
          'How many times per week?',
          style: theme.textTheme.bodyMedium,
        ),
        const Spacer(),
        // Row of numeric boxes (1..7) horizontally
        Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(7, (index) => index + 1).map((count) {
            final bool selected = (timesPerWeek == count);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: InkWell(
                onTap: () => setState(() => timesPerWeek = count),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: selected
                        ? theme.colorScheme.primary.withOpacity(0.2)
                        : theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? theme.colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                  ),
                  child: Text('$count'),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
