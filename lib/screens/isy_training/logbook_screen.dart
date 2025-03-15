import 'package:flutter/material.dart';

class LogbookScreen extends StatelessWidget {
  final String? clientUid;
  const LogbookScreen({Key? key, this.clientUid}) : super(key: key);

  //TODO: implement the clientUid logic here to separate the PT view of the client's logbook
  
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
