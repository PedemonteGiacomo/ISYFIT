import 'package:flutter/cupertino.dart'; // for CupertinoPicker
import 'package:flutter/material.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'package:isyfit/widgets/gradient_app_bar.dart';
import 'package:isyfit/widgets/gradient_button.dart';
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
  // Default to 170 cm, 70 kg if not found in widget.data
  int _selectedHeight = 170;
  int _selectedWeight = 70;

  @override
  void initState() {
    super.initState();
    if (widget.data['height'] != null && widget.data['height'] != '') {
      final int? parsed = int.tryParse(widget.data['height']);
      if (parsed != null) _selectedHeight = parsed;
    }
    if (widget.data['weight'] != null && widget.data['weight'] != '') {
      final int? parsed = int.tryParse(widget.data['weight']);
      if (parsed != null) _selectedWeight = parsed;
    }
  }

  // Launch a bottom sheet with CupertinoPicker for height or weight
  Future<void> _showPicker({
    required String title,
    required int minValue,
    required int maxValue,
    required int currentValue,
    required ValueChanged<int> onSelected,
  }) async {
    await showModalBottomSheet(
      // So we can manually control width, we do:
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // show our custom shape fully
      context: context,
      builder: (BuildContext ctx) {
        // Use an Align + ConstrainedBox (or SizedBox) to limit the width
        return Align(
          alignment: Alignment.bottomCenter,
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: 400, // <<-- ADJUST THIS as needed
              maxHeight: 320, // enough for the header + picker
            ),
            child: Container(
              // Round top corners
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // A small header row with a "Done" button
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Theme.of(context)
                          .colorScheme
                          .primary
                          .withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(),
                          child: Text(
                            'Done',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  Expanded(
                    child: CupertinoPicker(
                      backgroundColor: Colors.white,
                      scrollController: FixedExtentScrollController(
                        initialItem: currentValue - minValue,
                      ),
                      itemExtent: 40,
                      magnification: 1.2,
                      useMagnifier: true,
                      onSelectedItemChanged: (index) {
                        final val = minValue + index;
                        onSelected(val);
                      },
                      children: List.generate(maxValue - minValue + 1, (index) {
                        final val = minValue + index;
                        return Center(
                          child: Text(
                            '$val',
                            style: const TextStyle(fontSize: 18),
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onNext() {
    widget.data['height'] = '$_selectedHeight';
    widget.data['weight'] = '$_selectedWeight';
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

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: GradientAppBar(
        title: 'IsyCheck - Anamnesis Data Insertion',
        actions: [
          IconButton(
            icon: Icon(Icons.home, color: theme.colorScheme.onPrimary),
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
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      // Header Section
                      Icon(Icons.straighten,
                          size: 64, color: theme.colorScheme.primary),
                      const SizedBox(height: 16),
                      Text(
                        'Physical Measurements',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
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

                      // Height
                      _buildMeasurementRow(
                        label: 'Height (cm)',
                        currentValue: _selectedHeight,
                        displayIcon: Icons.swap_vert_rounded,
                        onTap: () => _showPicker(
                          title: 'Select Your Height (cm)',
                          minValue: 80,
                          maxValue: 250,
                          currentValue: _selectedHeight,
                          onSelected: (val) =>
                              setState(() => _selectedHeight = val),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Weight
                      _buildMeasurementRow(
                        label: 'Weight (kg)',
                        currentValue: _selectedWeight,
                        displayIcon: Icons.monitor_weight_outlined,
                        onTap: () => _showPicker(
                          title: 'Select Your Weight (kg)',
                          minValue: 30,
                          maxValue: 200,
                          currentValue: _selectedWeight,
                          onSelected: (val) =>
                              setState(() => _selectedWeight = val),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // Next
                      GradientButton(
                        label: 'Next',
                        icon: Icons.arrow_forward,
                        onPressed: _onNext,
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

  Widget _buildMeasurementRow({
    required String label,
    required int currentValue,
    required IconData displayIcon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                Icon(displayIcon, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$currentValue',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w500,
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
}
