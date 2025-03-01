import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
// Import your custom theme:
import 'theme/app_theme.dart';

import 'firebase_options.dart';
import 'screens/login_screen.dart';
import 'screens/base_screen.dart';
import 'screens/medical_history/medical_questionnaire/questionnaire_screen.dart';
import 'screens/medical_history/medical_history_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
  );
  runApp(const IsyFitApp());
}

class IsyFitApp extends StatelessWidget {
  const IsyFitApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'IsyFit',
      // Here we call buildAppTheme from app_theme.dart:
      theme: buildAppTheme(isDark: false),
      // You could also specify:
      // darkTheme: buildAppTheme(isDark: true),
      // themeMode: ThemeMode.light, // or system

      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/base': (context) => const BaseScreen(),
        '/questionnaire': (context) => const QuestionnaireScreen(),
        '/medical_history_dashboard': (context) => const MedicalHistoryScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();

    Future.delayed(const Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => const AuthGate(),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.7;
    final double height = MediaQuery.of(context).size.height * 0.3;

    return Scaffold(
      backgroundColor: Colors.white, // or Theme.of(context).scaffoldBackgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/ISYFIT_LOGO.jpg',
              width: width,
              height: height,
            ),
            const SizedBox(height: 40),
            AnimatedTextKit(
              animatedTexts: [
                TypewriterAnimatedText(
                  'Fitness, in your pocket.',
                  textStyle: const TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue, // or use Theme.of(context).colorScheme.primary
                  ),
                  speed: const Duration(milliseconds: 100),
                ),
              ],
              isRepeatingAnimation: false,
            ),
          ],
        ),
      ),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasData) {
          return const BaseScreen();
        } else {
          return const LoginScreen();
        }
      },
    );
  }
}
