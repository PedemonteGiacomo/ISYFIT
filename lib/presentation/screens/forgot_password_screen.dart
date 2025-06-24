import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/gradient_app_bar.dart';
import '../../domain/utils/firebase_error_translator.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AuthRepository authRepository;

  ForgotPasswordScreen({Key? key, AuthRepository? authRepository})
      : authRepository = authRepository ?? AuthRepository(),
        super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;

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
      Navigator.pop(context);
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
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: const GradientAppBar(title: 'Reset Password'),
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
                  elevation: 12,
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
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
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
                          const SizedBox(height: 24),
                          _isLoading
                              ? const CircularProgressIndicator()
                              : ElevatedButton(
                                  onPressed: _sendReset,
                                  style: ElevatedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12.0),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 12.0,
                                      horizontal: 24.0,
                                    ),
                                  ),
                                  child: Text(
                                    'Invia Email',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: theme.colorScheme.onPrimary,
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
