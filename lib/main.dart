import 'dart:async';
import 'dart:math' as math;
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
import 'data/services/notification_service.dart';

// Using the globalNavigatorKey from notification_service.dart
final GlobalKey<NavigatorState> _navKey = globalNavigatorKey;
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ───────────── Stripe ─────────────
  Stripe.publishableKey =
      'pk_live_51RSHw2KbTQJ1x1Amjm7cYUtVeEyxJTRWqtY173xJa6fGpsPgLcJQ1BFCvPt90S1sU0mtIft2M3Igj9kSSUpx5kal00OZmMNkJf'; // 👉  sostituisci con la tua key
  Stripe.publishableKey =
      'pk_live_51RSHw2KbTQJ1x1Amjm7cYUtVeEyxJTRWqtY173xJa6fGpsPgLcJQ1BFCvPt90S1sU0mtIft2M3Igj9kSSUpx5kal00OZmMNkJf'; // 👉  sostituisci con la tua key
  await Stripe.instance.applySettings();

  // ───────────── Firebase ───────────
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await FirebaseAppCheck.instance.activate(
    appleProvider: AppleProvider.debug,
    androidProvider: AndroidProvider.debug,
  );
  await NotificationService.instance.init();

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

  // TODO: Verificare la necessità di fare redirect in questo modo, nel codice ci sono widget che direttamente ne restituiscono altri, senza passare per le route.
  // Per esempio, in BaseScreen viene restituito direttamente il widget HomeScreen.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navKey,
      title: 'IsyFit',
      theme: buildAppTheme(isDark: false),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => LoginScreen(),
        '/base': (context) => const BaseScreen(),
        '/questionnaire': (context) => const QuestionnaireScreen(),
        '/medical_history_dashboard': (context) => const MedicalHistoryScreen(),
      },
    );
  }
}

/// SPLASH -----------------------------------------------------------------
///
/// * Dopo 4 s abilita lo swipe.
/// * Il contenuto del Splash segue il dito in tempo reale.
/// * Finché l'opacità bianca è > 0 mostra solo uno sfondo neutro, poi rivela
///   gradualmente la schermata reale sottostante (AuthGate).
class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with TickerProviderStateMixin {
  // ---------- Animazione del suggerimento "UP SWIPE" ----------
  late final AnimationController _hintCtrl; // bounce
  late final Animation<Offset> _hintAnim;

  // ---------- Slide dell'intero Splash ----------
  late final AnimationController
      _slideCtrl; // 0 → fermo, 1 → fuori dallo schermo
  late final Animation<Offset> _slideAnim;

  bool _canSwipe = false; // attivo dopo 4 s
  double _dragStartY = 0; // memorizza partenza gesto
  static const _distanceThreshold = 0.30; // 30 % altezza schermo
  bool _splashFinished = false; // quando true l'overlay viene nascosto

  @override
  void initState() {
    super.initState();

    // ---------- Controller bounce del logo suggerimento ----------
    _hintCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _hintAnim = Tween<Offset>(begin: const Offset(0, .15), end: Offset.zero)
        .animate(CurvedAnimation(parent: _hintCtrl, curve: Curves.easeInOut));

    // ---------- Controller slide Splash ----------
    _slideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _slideAnim = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -1))
        .animate(CurvedAnimation(parent: _slideCtrl, curve: Curves.easeOut));

    // Dopo 4 s abilita swipe e avvia anim bounce logo
    Future.delayed(const Duration(seconds: 4), () {
      if (!mounted) return;
      setState(() => _canSwipe = true);
      _hintCtrl.repeat(reverse: true);
    });
  }

  @override
  void dispose() {
    _hintCtrl.dispose();
    _slideCtrl.dispose();
    super.dispose();
  }

  // ------------------------------------------------------------
  // BUILD
  // ------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Schermata reale sottostante (non interagibile finché splash ≠ 1)
          const AuthGate(),

          if (!_splashFinished) ...[
            // Overlay bianco che svanisce gradualmente — evita "sbirciatine" sgradevoli
            AnimatedBuilder(
              animation: _slideCtrl,
              builder: (_, __) {
                final opacity = (1 - _slideCtrl.value).clamp(0.0, 1.0);
                return IgnorePointer(
                  ignoring: true,
                  child: Opacity(
                    opacity: opacity,
                    child: Container(color: Colors.white),
                  ),
                );
              },
            ),

            // Splash che scorre via
            SlideTransition(
              position: _slideAnim,
              child: GestureDetector(
                // START
                onVerticalDragStart: (details) =>
                    _dragStartY = details.globalPosition.dy,

                // UPDATE — segue il dito
                onVerticalDragUpdate: (details) {
                  if (!_canSwipe) return;
                  final delta = (_dragStartY - details.globalPosition.dy)
                      .clamp(0.0, screenHeight);
                  _slideCtrl.value = delta / screenHeight;
                },

                // END — decide se chiudere o tornare indietro
                onVerticalDragEnd: (details) {
                  if (!_canSwipe) return;

                  final shouldClose = _slideCtrl.value > _distanceThreshold ||
                      (details.primaryVelocity != null &&
                          details.primaryVelocity! < -700);

                  if (shouldClose) {
                    _finishSplash();
                  } else {
                    _slideCtrl.reverse(); // torna giù
                  }
                },
                child: _buildSplashUI(context),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ------------------------------------------------------------
  // Completa lo splash (animazione fino a 1 e poi navigazione)
  // ------------------------------------------------------------
  void _finishSplash() {
    _hintCtrl.stop();
    _slideCtrl
        .animateTo(1, duration: const Duration(milliseconds: 200))
        .then((_) {
      if (mounted) {
        setState(() => _splashFinished = true);
      }
    });
  }

  // ------------------------------------------------------------
  // UI vera e propria separata per pulizia
  // ------------------------------------------------------------
  Widget _buildSplashUI(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final baseDim = math.min(size.width, size.height);

    return Stack(
      children: [
        // ------------- LOGO + PAYOFF -------------
        Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: baseDim * .5, // scale with the smallest side
                child: Image.asset(
                  'assets/images/ISYFIT_LOGO_new-removebg-resized.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),
              AnimatedTextKit(
                isRepeatingAnimation: false,
                animatedTexts: [
                  TypewriterAnimatedText(
                    'Fitness, in your pocket.',
                    textStyle: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.blue,
                    ),
                    speed: const Duration(milliseconds: 100),
                  ),
                ],
              ),
            ],
          ),
        ),

        // ------------- LOGO "UP SWIPE" RIMBALZANTE -------------
        if (_canSwipe && _slideCtrl.value < 0.05)
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 32),
              child: SlideTransition(
                position: _hintAnim,
                child: Image.asset(
                  'assets/images/swipe_up-removebg.png',
                  width: baseDim * .35,
                ),
              ),
            ),
          ),
      ],
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
      error: (_, __) => LoginScreen(),
      data: (user) => user != null ? const BaseScreen() : LoginScreen(),
    );
  }
}
