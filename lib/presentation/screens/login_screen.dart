import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import 'package:isyfit/presentation/screens/base_screen.dart';
import 'registration/registration_screen.dart';
import '../../domain/utils/firebase_error_translator.dart';

class LoginScreen extends StatefulWidget {
  final AuthRepository authRepository;

  LoginScreen({Key? key, AuthRepository? authRepository})
      : authRepository = authRepository ?? AuthRepository(),
        super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;
  bool _forgotMode = false;

  Future<void> _login() async {
    setState(() {
      _isLoading = true;
    });

    try {
      await widget.authRepository.signIn(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (!mounted) return;
      // Navigate to BaseScreen on success:
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BaseScreen()),
      );
    } on FirebaseAuthException catch (e) {
      final msg = FirebaseErrorTranslator.fromException(e);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } catch (e) {
      final msg = FirebaseErrorTranslator.fromException(e as Exception);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _sendReset() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await widget.authRepository.sendPasswordReset(
        _emailController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Email di reset inviata. Controlla la tua casella.'),
        ),
      );
      setState(() => _forgotMode = false);
    } on FirebaseAuthException catch (e) {
      final msg = FirebaseErrorTranslator.fromException(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isPortrait =
                MediaQuery.of(context).orientation == Orientation.portrait;
            final widthFactor = isPortrait ? 0.8 : 0.6;
            final cardWidth = (constraints.maxWidth * widthFactor)
                .clamp(isPortrait ? 280.0 : 320.0, 500.0);

            return Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 12, // card più "alta" visivamente
                  shadowColor: theme.shadowColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30.0),
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: cardWidth,
                      minHeight: isPortrait
                          ? constraints.maxHeight * 0.35
                          : constraints.maxHeight * 0.40,
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment
                            .center, // elementi centrati verticalmente
                        crossAxisAlignment: CrossAxisAlignment
                            .center, // elementi centrati orizzontalmente
                        children: [
                          // Logo (rimane a sinistra per mantenere il branding)
                          Align(
                            alignment: Alignment.center,
                            child: Image.asset(
                              'assets/images/ISYFIT_LOGO_new-removebg-resized.png',
                              height: 100,
                              width: 222,
                              fit: BoxFit.contain,
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Email Field
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(
                              labelText: 'Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              prefixIcon: Icon(
                                Icons.email,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          if (!_forgotMode) ...[
                            // Password Field
                            TextField(
                              controller: _passwordController,
                              obscureText: true,
                              decoration: InputDecoration(
                                labelText: 'Password',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                prefixIcon: Icon(
                                  Icons.lock,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                          ],

                          // Login Button al centro
                          _isLoading
                              ? const CircularProgressIndicator()
                              : Center(
                                  child: ElevatedButton(
                                    onPressed:
                                        _forgotMode ? _sendReset : _login,
                                    style: ElevatedButton.styleFrom(
                                      shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(12.0),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        vertical: 12.0,
                                        horizontal: 24.0,
                                      ),
                                    ),
                                    child: Text(
                                      _forgotMode ? 'Reset' : 'Login',
                                      style: TextStyle(
                                        fontSize: 16,
                                        color: theme.colorScheme.onPrimary,
                                      ),
                                    ),
                                  ),
                                ),
                          const SizedBox(height: 16),

                          Center(
                            child: TextButton(
                              onPressed: () {
                                setState(() => _forgotMode = !_forgotMode);
                              },
                              child: Text(
                                _forgotMode
                                    ? 'Torna al login'
                                    : 'Password dimenticata?',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Redirect alla registrazione al centro
                          if (!_forgotMode)
                            Center(
                              child: TextButton(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) =>
                                          const RegistrationScreen(),
                                    ),
                                  );
                                },
                                child: Text(
                                  'Non sei registrato? Registrati ora!',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
