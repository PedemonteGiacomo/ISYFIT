import 'package:flutter/material.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'package:isyfit/widgets/gradient_app_bar.dart';
import 'package:isyfit/widgets/gradient_button.dart';
import 'training_goals_screen.dart';

class SleepEnergyScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  final String? clientUid;

  const SleepEnergyScreen({
    Key? key,
    required this.data,
    this.clientUid,
  }) : super(key: key);

  @override
  _SleepEnergyScreenState createState() => _SleepEnergyScreenState();
}

class _SleepEnergyScreenState extends State<SleepEnergyScreen> {
  TimeOfDay? sleepTime;
  TimeOfDay? wakeTime;
  bool feelsEnergetic = false;

  @override
  void initState() {
    super.initState();
    sleepTime = _parseTime(widget.data['sleep_time']);
    wakeTime = _parseTime(widget.data['wake_time']);
    feelsEnergetic = (widget.data['energetic'] == 'Yes');
  }

  TimeOfDay? _parseTime(String? time) {
    if (time == null) return null;
    final parts = time.split(':');
    if (parts.length == 2) {
      final hour = int.tryParse(parts[0]) ?? 0;
      final minute = int.tryParse(parts[1]) ?? 0;
      return TimeOfDay(hour: hour, minute: minute);
    }
    return null;
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay? initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  void _goNext() {
    if (sleepTime == null || wakeTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your sleep and wake-up times.'),
        ),
      );
      return;
    }
    // Save to data
    widget.data['sleep_time'] = '${sleepTime!.hour}:${sleepTime!.minute}';
    widget.data['wake_time'] = '${wakeTime!.hour}:${wakeTime!.minute}';
    widget.data['energetic'] = feelsEnergetic ? 'Yes' : 'No';

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TrainingGoalsScreen(
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
      // 1) Use GradientAppBar
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
                  borderRadius: BorderRadius.circular(16.0),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Icon(Icons.nights_stay_outlined,
                          size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Sleep & Energy',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us understand your sleep patterns and energy levels to refine your plan.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Sleep Time
                      _buildTimePicker(
                        context,
                        label: 'What time do you usually go to sleep?',
                        time: sleepTime,
                        icon: Icons.bedtime_outlined,
                        onTimeSelected: (time) {
                          setState(() {
                            sleepTime = time;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Wake Time
                      _buildTimePicker(
                        context,
                        label: 'What time do you usually wake up?',
                        time: wakeTime,
                        icon: Icons.wb_sunny_outlined,
                        onTimeSelected: (time) {
                          setState(() {
                            wakeTime = time;
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Feels Energetic toggle
                      _buildToggleOption(
                        label: 'Do you feel energetic upon waking?',
                        value: feelsEnergetic,
                        icon: Icons.battery_charging_full_outlined,
                        onChanged: (value) {
                          setState(() {
                            feelsEnergetic = value;
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // 2) Use GradientButton for Next
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

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            )),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: InkWell(
            onTap: () => _selectTime(context, time, onTimeSelected),
            child: Row(
              children: [
                Icon(icon, color: theme.colorScheme.primary, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12.0),
                    child: Text(
                      time != null
                          ? time.format(context)
                          : 'Tap to select time',
                      style: TextStyle(
                        fontSize: 14,
                        color: time != null ? Colors.black : Colors.grey,
                      ),
                    ),
                  ),
                ),
                const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            )),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.all(8.0),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8.0),
          ),
          child: Row(
            children: [
              Icon(icon, color: theme.colorScheme.primary, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(label, style: const TextStyle(fontSize: 14)),
              ),
              Switch(
                value: value,
                onChanged: onChanged,
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
