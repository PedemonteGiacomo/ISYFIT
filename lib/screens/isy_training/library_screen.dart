import 'package:flutter/material.dart';

class LibraryScreen extends StatelessWidget {
  final String? clientUid;
  const LibraryScreen({Key? key, this.clientUid}) : super(key: key);

  //TODO: implement the clientUid logic here to separate the PT view of the client's library
  
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
