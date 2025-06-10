import 'dart:async';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:flutter_stripe/flutter_stripe.dart'; // 👈 nuovo import
import 'package:app_links/app_links.dart';

import 'firebase_options.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/screens/login_screen.dart';
import 'presentation/screens/base_screen.dart';
import 'presentation/screens/medical_history/medical_questionnaire/questionnaire_screen.dart';
import 'presentation/screens/medical_history/anamnesis_screen.dart';
import 'presentation/theme/app_theme.dart';
import 'domain/providers/auth_provider.dart';

final GlobalKey<NavigatorState> _navKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ───────────── Stripe ─────────────
  Stripe.publishableKey =
      'pk_live_51RSHw2KbTQJ1x1Amjm7cYUtVeEyxJTRWqtY173xJa6fGpsPgLcJQ1BFCvPt90S1sU0mtIft2M3Igj9kSSUpx5kal00OZmMNkJf'; // 👉  sostituisci con la tua key
  await Stripe.instance.applySettings();

  // ───────────── Firebase ───────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
  );

  runApp(const ProviderScope(child: IsyFitApp()));
}

/// APP ROOT ­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­­
class IsyFitApp extends StatefulWidget {
  const IsyFitApp({Key? key}) : super(key: key);
  @override
  State<IsyFitApp> createState() => _IsyFitAppState();
}

class _IsyFitAppState extends State<IsyFitApp> {
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSub;

  @override
  void initState() {
    super.initState();

    _appLinks = AppLinks();

    // app lanciata da link “a freddo”
    _appLinks.getInitialLink().then((uri) {
      if (uri != null) _routeFromUri(uri);
    });

    // link ricevuti con app già aperta
    _linkSub = _appLinks.uriLinkStream.listen(
      (uri) => _routeFromUri(uri),
      onError: (_) {}, // ignora errori di parsing
    );
  }

  void _routeFromUri(Uri uri) {
    switch (uri.host) {
      case 'success': // isyfit://success
        _navKey.currentState?.pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const BaseScreen()),
          (_) => false,
        );
        break;
      case 'cancel': // isyfit://cancel
        final ctx = _navKey.currentContext;
        if (ctx != null) {
          ScaffoldMessenger.of(ctx).showSnackBar(
            const SnackBar(content: Text('Pagamento annullato')),
          );
        }
        break;
      default:
        // altri link → nessuna azione
        break;
    }
  }

  @override
  void dispose() {
    _linkSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'IsyFit',
      theme: buildAppTheme(isDark: false),
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

/// SPLASH -----------------------------------------------------------------
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
        MaterialPageRoute(builder: (_) => const AuthGate()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width * .7;
    final h = MediaQuery.of(context).size.height * .3;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Image.asset('assets/images/ISYFIT_LOGO.jpg', width: w, height: h),
          const SizedBox(height: 40),
          AnimatedTextKit(
            isRepeatingAnimation: false,
            animatedTexts: [
              TypewriterAnimatedText(
                'Fitness, in your pocket.',
                textStyle: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.blue),
                speed: const Duration(milliseconds: 100),
              ),
            ],
          ),
        ]),
      ),
    );
  }
}

/// AUTH GATE --------------------------------------------------------------
class AuthGate extends ConsumerWidget {
  const AuthGate({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    return authState.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => const LoginScreen(),
      data: (user) => user != null ? const BaseScreen() : const LoginScreen(),
    );
  }
}
