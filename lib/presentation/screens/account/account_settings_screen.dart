import 'package:flutter/material.dart';

class AccountSettingsScreen extends StatelessWidget {
  const AccountSettingsScreen({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        "Settings Screen",
        style: Theme.of(context).textTheme.headlineSmall,
      ),
    );
  }
}
