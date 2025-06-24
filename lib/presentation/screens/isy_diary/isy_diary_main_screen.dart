import 'package:flutter/material.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/screens/base_screen.dart';

class IsyDiaryMainScreen extends StatelessWidget {
  const IsyDiaryMainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: GradientAppBar(
        title: 'IsyDiary',
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
      body: Center(
        child: Text(
          'IsyDiary\nWork in progress',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
      ),
    );
  }
}
