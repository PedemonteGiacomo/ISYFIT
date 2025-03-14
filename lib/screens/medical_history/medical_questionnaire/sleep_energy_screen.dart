import 'package:flutter/material.dart';
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
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  Future<void> _selectTime(
    BuildContext context,
    TimeOfDay? initialTime,
    Function(TimeOfDay) onTimeSelected,
  ) async {
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
        backgroundColor: theme.colorScheme.primary,
        title: Text('Sleep & Energy',
            style: TextStyle(color: Theme.of(context).colorScheme.onPrimary)),
        centerTitle: true,
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
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
                        style: theme.textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Help us understand your sleep patterns and energy levels.',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.7),
                        ),
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
                            widget.data['sleep_time'] =
                                '${time.hour}:${time.minute}';
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
                            widget.data['wake_time'] =
                                '${time.hour}:${time.minute}';
                          });
                        },
                      ),
                      const SizedBox(height: 24),

                      // Energetic Toggle
                      _buildToggleOption(
                        label: 'Do you feel energetic when you wake up?',
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
                        width: MediaQuery.of(context).size.width * 0.75,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            if (sleepTime == null || wakeTime == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      'Please select your sleep and wake-up times.'),
                                  backgroundColor:
                                      theme.colorScheme.errorContainer,
                                ),
                              );
                              return;
                            }
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => TrainingGoalsScreen(
                                  data: widget.data,
                                  clientUid: widget.clientUid,
                                ),
                              ),
                            );
                          },
                          icon: Icon(Icons.arrow_forward,
                              color: Theme.of(context).colorScheme.onPrimary),
                          label: Text('Next',
                              style: TextStyle(
                                  color:
                                      Theme.of(context).colorScheme.onPrimary)),
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

  Widget _buildTimePicker(
    BuildContext context, {
    required String label,
    required TimeOfDay? time,
    required IconData icon,
    required Function(TimeOfDay) onTimeSelected,
  }) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
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
                      time != null ? time.format(context) : label,
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
        Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
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
                Text(label, style: const TextStyle(fontSize: 14)),
                Switch(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
