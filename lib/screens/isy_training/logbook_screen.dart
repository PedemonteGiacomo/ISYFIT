import 'package:flutter/material.dart';

class LogbookScreen extends StatelessWidget {
  const LogbookScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with your actual logbook implementation.
    return Center(
      child: Text(
        "Logbook\n(Visualizzazione & interactive card for weight, RPE, etc.)",
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
