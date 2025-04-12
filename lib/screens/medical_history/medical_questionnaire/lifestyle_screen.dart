import 'package:flutter/material.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'package:isyfit/widgets/gradient_app_bar.dart';
import 'package:isyfit/widgets/gradient_button.dart';
import 'medical_history_screen.dart';

/// Example model for icon-labeled choice
class _IconChoice {
  final String label;
  final IconData icon;
  const _IconChoice(this.label, this.icon);
}

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
  final _formKey = GlobalKey<FormState>();

  bool drinksAlcohol = false;
  bool smokes = false;
  bool fixedWorkShifts = false;

  // Water intake from 0 to 5 liters
  double _waterIntakeLiters = 2.0;

  // If user toggles "Yes" for alcohol, pick from an icon-labeled row
  String? _selectedAlcoholFreq;
  final TextEditingController _alcoholOtherController = TextEditingController();

  // Smoking details: user picks daily amount from slider
  double _cigarettesPerDay = 0;

  // --------------------------- Breakfast Additions ---------------------------
  bool eatsBreakfast = false;
  String? _selectedBreakfastChoice;
  final TextEditingController _breakfastOtherController = TextEditingController();

  final List<_IconChoice> _breakfastOptions = [
    _IconChoice('Light (coffee + pastry)', Icons.coffee),
    _IconChoice('Standard (cereal/toast)', Icons.breakfast_dining),
    _IconChoice('Hearty (eggs, bacon)', Icons.local_dining),
    _IconChoice('Other', Icons.help_outline),
  ];

  /// Icon-labeled choices for alcohol frequency
  final List<_IconChoice> _alcoholFrequencyOptions = [
    _IconChoice('Occasional', Icons.hourglass_bottom),
    _IconChoice('1-2 drinks/day', Icons.wine_bar),
    _IconChoice('3+ drinks/day', Icons.local_bar),
    _IconChoice('Other', Icons.help_outline),
  ];

  @override
  void initState() {
    super.initState();

    // 1) Initialize toggles from widget.data if they exist
    widget.data['alcohol'] ??= 'No';
    widget.data['smokes'] ??= 'No';
    widget.data['fixedWorkShifts'] ??= 'No';
    widget.data['waterIntake'] ??= '';
    widget.data['breakfast'] ??= 'No';
    widget.data['breakfastDetails'] ??= '';
    widget.data['alcohol_details'] ??= '';

    // Convert "Yes"/"No" to booleans
    drinksAlcohol   = (widget.data['alcohol'] == 'Yes');
    smokes          = (widget.data['smokes'] == 'Yes');
    fixedWorkShifts = (widget.data['fixedWorkShifts'] == 'Yes');

    // Breakfast
    eatsBreakfast   = (widget.data['breakfast'] == 'Yes');

    // If there's a numeric water intake, parse it
    if (widget.data['waterIntake'] != null &&
        widget.data['waterIntake']!.isNotEmpty) {
      final parsed = double.tryParse(widget.data['waterIntake']!);
      if (parsed != null && parsed >= 0 && parsed <= 5) {
        _waterIntakeLiters = parsed;
      }
    }

    // If user had chosen an alcohol detail previously
    if (drinksAlcohol) {
      final oldAlcohol = widget.data['alcohol_details'] ?? '';
      // If it matches one of our labels, pick it. Else "Other"
      if (_alcoholFrequencyOptions.any((o) => o.label == oldAlcohol)) {
        _selectedAlcoholFreq = oldAlcohol;
      } else if (oldAlcohol.isNotEmpty) {
        _selectedAlcoholFreq = 'Other';
        _alcoholOtherController.text = oldAlcohol;
      }
    }

    // If user had chosen a breakfast detail previously:
    if (eatsBreakfast) {
      final oldDetails = widget.data['breakfastDetails'] ?? '';
      if (_breakfastOptions.any((o) => o.label == oldDetails)) {
        _selectedBreakfastChoice = oldDetails;
      } else if (oldDetails.isNotEmpty) {
        _selectedBreakfastChoice = 'Other';
        _breakfastOtherController.text = oldDetails;
      }
    }
  }

  @override
  void dispose() {
    _alcoholOtherController.dispose();
    _breakfastOtherController.dispose();
    super.dispose();
  }

  // Save and navigate to medical screen
  void _goToNextScreen() {
    // Convert toggles to "Yes"/"No"
    widget.data['alcohol']       = drinksAlcohol ? 'Yes' : 'No';
    widget.data['smokes']        = smokes ? 'Yes' : 'No';
    widget.data['fixedWorkShifts'] = fixedWorkShifts ? 'Yes' : 'No';

    // Water intake
    widget.data['waterIntake'] = _waterIntakeLiters.toStringAsFixed(1);

    // Alcohol details
    if (drinksAlcohol && _selectedAlcoholFreq != null) {
      if (_selectedAlcoholFreq == 'Other') {
        widget.data['alcohol_details'] = _alcoholOtherController.text.trim();
      } else {
        widget.data['alcohol_details'] = _selectedAlcoholFreq;
      }
    } else {
      widget.data['alcohol_details'] = '';
    }

    // Smoking details
    if (smokes) {
      widget.data['smoking_details'] = _cigarettesPerDay.toStringAsFixed(1);
    } else {
      widget.data['smoking_details'] = '';
    }

    // Breakfast
    widget.data['breakfast'] = eatsBreakfast ? 'Yes' : 'No';
    if (eatsBreakfast && _selectedBreakfastChoice != null) {
      if (_selectedBreakfastChoice == 'Other') {
        widget.data['breakfastDetails'] =
            _breakfastOtherController.text.trim();
      } else {
        widget.data['breakfastDetails'] = _selectedBreakfastChoice;
      }
    } else {
      widget.data['breakfastDetails'] = '';
    }

    // Go next
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MedicalHistoryScreen(
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
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Header
                        Icon(Icons.local_drink_outlined,
                            size: 64, color: theme.colorScheme.primary),
                        const SizedBox(height: 16),
                        Text(
                          'Lifestyle Details',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your daily habits help us tailor a plan that suits your routine.',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 24),

                        // 1) Work Shifts
                        _buildSwitchOption(
                          label: 'Are your work shifts fixed?',
                          value: fixedWorkShifts,
                          icon: Icons.schedule_outlined,
                          onChanged: (v) => setState(() => fixedWorkShifts = v),
                        ),
                        const SizedBox(height: 16),

                        // 2) Alcohol
                        _buildSwitchOption(
                          label: 'Do you drink alcohol?',
                          value: drinksAlcohol,
                          icon: Icons.local_bar_outlined,
                          onChanged: (v) => setState(() => drinksAlcohol = v),
                        ),
                        if (drinksAlcohol) _buildAlcoholIconRow(),
                        if (drinksAlcohol && _selectedAlcoholFreq == 'Other')
                          _buildAlcoholOtherField(),
                        const SizedBox(height: 16),

                        // 3) Smoking
                        _buildSwitchOption(
                          label: 'Do you smoke?',
                          value: smokes,
                          icon: Icons.smoking_rooms_outlined,
                          onChanged: (v) => setState(() => smokes = v),
                        ),
                        if (smokes) _buildSmokingSlider(),
                        const SizedBox(height: 16),

                        // 4) Water intake slider
                        _buildWaterSlider(),
                        const SizedBox(height: 16),

                        // -------------------- 5) Breakfast Q  --------------------
                        _buildSwitchOption(
                          label: 'Do you usually eat breakfast?',
                          value: eatsBreakfast,
                          icon: Icons.free_breakfast_outlined,
                          onChanged: (v) => setState(() => eatsBreakfast = v),
                        ),
                        if (eatsBreakfast) _buildBreakfastIconRow(),
                        if (eatsBreakfast && _selectedBreakfastChoice == 'Other')
                          _buildBreakfastOtherField(),
                        const SizedBox(height: 32),

                        // Next button
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

  // Reusable switch
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

  // Replaces the old dropdown with a single-row icon-labeled approach
  Widget _buildAlcoholIconRow() {
    final theme = Theme.of(context);
    // These replicate your old text-based options + "Other"
    final List<_IconChoice> alcoholChoices = [
      _IconChoice('Occasional', Icons.hourglass_bottom),
      _IconChoice('1-2 drinks/day', Icons.wine_bar),
      _IconChoice('3+ drinks/day', Icons.local_bar),
      _IconChoice('Other', Icons.help_outline),
    ];

    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('How often/how much?', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: alcoholChoices.map((choice) {
                final bool isSelected = (_selectedAlcoholFreq == choice.label);
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedAlcoholFreq = choice.label),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            color: isSelected ? theme.colorScheme.primary : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            choice.label,
                            style: TextStyle(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : Colors.black,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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
  Widget _buildAlcoholOtherField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: _alcoholOtherController,
        decoration: InputDecoration(
          labelText: 'Describe your drinking frequency',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }

  // Smoking slider from 0..20 cigs/day
  Widget _buildSmokingSlider() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Cigarettes per day', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Slider(
          value: _cigarettesPerDay,
          min: 0,
          max: 20,
          divisions: 20,
          label: '${_cigarettesPerDay.round()} cigs/day',
          activeColor: theme.colorScheme.primary,
          onChanged: (val) {
            setState(() => _cigarettesPerDay = val);
          },
        ),
      ],
    );
  }

  // Water slider 0..5 liters
  Widget _buildWaterSlider() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Daily Water Intake (liters)', style: theme.textTheme.labelLarge),
        const SizedBox(height: 6),
        Slider(
          value: _waterIntakeLiters,
          min: 0,
          max: 5,
          divisions: 25, // step of 0.2 liters if you want
          label: '${_waterIntakeLiters.toStringAsFixed(1)} L',
          activeColor: theme.colorScheme.primary,
          onChanged: (val) {
            setState(() => _waterIntakeLiters = val);
          },
        ),
      ],
    );
  }

  // ---------------------- Breakfast details with single-row icons ----------------------
  Widget _buildBreakfastIconRow() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('What kind of breakfast?', style: theme.textTheme.labelLarge),
          const SizedBox(height: 6),

          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _breakfastOptions.map((option) {
                final bool isSelected = (_selectedBreakfastChoice == option.label);
                return Padding(
                  padding: const EdgeInsets.only(right: 12.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedBreakfastChoice = option.label),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
                            color: isSelected ? theme.colorScheme.primary : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            option.label,
                            style: TextStyle(
                              color: isSelected ? theme.colorScheme.primary : Colors.black,
                              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
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

  // If "Other" is selected for breakfast => show text field
  Widget _buildBreakfastOtherField() {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: TextFormField(
        controller: _breakfastOtherController,
        decoration: InputDecoration(
          labelText: 'Describe your breakfast',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          filled: true,
          fillColor: theme.colorScheme.surface,
        ),
      ),
    );
  }
}
