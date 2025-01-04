import 'package:flutter/material.dart';
import 'training_goals_screen.dart';

class SleepEnergyScreen extends StatefulWidget {
  final Map<String, dynamic> data;
  const SleepEnergyScreen({Key? key, required this.data}) : super(key: key);

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
    if (widget.data['sleep_time'] != null) {
      sleepTime = _parseTime(widget.data['sleep_time']);
    }
    if (widget.data['wake_time'] != null) {
      wakeTime = _parseTime(widget.data['wake_time']);
    }
    feelsEnergetic = widget.data['energetic'] == 'Yes';
    widget.data['energetic'] = 'No'; // Default value
  }

  TimeOfDay _parseTime(String time) {
    final parts = time.split(':');
    final hour = int.parse(parts[0]);
    final minute = int.parse(parts[1]);
    return TimeOfDay(hour: hour, minute: minute);
  }

  Future<void> _selectTime(BuildContext context, TimeOfDay? initialTime, Function(TimeOfDay) onTimeSelected) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: initialTime ?? TimeOfDay.now(),
    );
    if (picked != null) {
      onTimeSelected(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sleep and Energy'),
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
                  child: Column(
                    children: [
                      // Header Section
                      const Icon(Icons.nights_stay_outlined, size: 64, color: Colors.blue),
                      const SizedBox(height: 16),
                      Text(
                        'Sleep and Energy',
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Help us understand your sleep patterns and energy levels to optimize your plan.',
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                      const SizedBox(height: 24),

                      // Sleep Time Picker
                      _buildTimePicker(
                        context,
                        label: 'What time do you sleep?',
                        time: sleepTime,
                        icon: Icons.bedtime_outlined,
                        onTimeSelected: (time) {
                          setState(() {
                            sleepTime = time;
                            widget.data['sleep_time'] = '${time.hour}:${time.minute}';
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Wake Time Picker
                      _buildTimePicker(
                        context,
                        label: 'What time do you wake up?',
                        time: wakeTime,
                        icon: Icons.wb_sunny_outlined,
                        onTimeSelected: (time) {
                          setState(() {
                            wakeTime = time;
                            widget.data['wake_time'] = '${time.format(context)}';
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Energetic Toggle
                      _buildToggleOption(
                        label: 'Do you feel energetic upon waking up?',
                        value: feelsEnergetic,
                        icon: Icons.battery_charging_full_outlined,
                        onChanged: (value) {
                          setState(() {
                            feelsEnergetic = value;
                            widget.data['energetic'] = value ? 'Yes' : 'No';
                          });
                        },
                      ),
                      const SizedBox(height: 32),

                      // Next Button
                      SizedBox(
                        width: MediaQuery.of(context).size.width * 0.75, // 75% width button
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (sleepTime != null && wakeTime != null) {
                              if (!feelsEnergetic) {
                                widget.data['energetic'] = 'No';
                              }
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      TrainingGoalsScreen(data: widget.data),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please select your sleep and wake-up times.')),
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
    );
  }

  Widget _buildTimePicker(BuildContext context,
      {required String label, required TimeOfDay? time, required IconData icon, required Function(TimeOfDay) onTimeSelected}) {
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
            child: InkWell(
              onTap: () => _selectTime(context, time, onTimeSelected),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      time != null
                          ? '${time.format(context)}'
                          : label,
                      style: TextStyle(
                        fontSize: 14,
                        color: time != null ? Colors.black : Colors.grey,
                      ),
                    ),
                    const Icon(Icons.keyboard_arrow_down, color: Colors.grey),
                  ],
                ),
              ),
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
}
