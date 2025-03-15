import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  const LibraryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Replace with your actual exercise list.
    return Center(
      child: Text(
        "Exercise Library",
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
