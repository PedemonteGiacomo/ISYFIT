import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/repositories/auth_repository.dart';
import '../widgets/gradient_app_bar.dart';
import '../../domain/utils/firebase_error_translator.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String actionCode;
  final AuthRepository authRepository;

  ResetPasswordScreen(
      {Key? key, required this.actionCode, AuthRepository? authRepository})
      : authRepository = authRepository ?? AuthRepository(),
        super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _pwdController = TextEditingController();
  final TextEditingController _confirmController = TextEditingController();
  bool _isLoading = false;
  bool _showInfo = false;

  bool get _hasUpper => _pwdController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLower => _pwdController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _pwdController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecial =>
      _pwdController.text.contains(RegExp(r'[!@#\\$%^&*(),.?\\":{}|<>]'));
  bool get _hasLen => _pwdController.text.length >= 8;
  bool get _pwdOk =>
      _hasUpper && _hasLower && _hasNumber && _hasSpecial && _hasLen;

  Future<void> _resetPassword() async {
    if (!_pwdOk) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password not strong enough.")),
      );
      return;
    }
    if (_pwdController.text != _confirmController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Passwords do not match.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await widget.authRepository.confirmPasswordReset(
        widget.actionCode,
        _pwdController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Password updated successfully")),
      );
      Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
    } on FirebaseAuthException catch (e) {
      final msg = FirebaseErrorTranslator.fromException(e);
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _pwdRow(String txt, bool ok) => Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel,
              color: ok ? Colors.green : Colors.red, size: 18),
          const SizedBox(width: 6),
          Text(txt, style: TextStyle(color: ok ? Colors.green : Colors.red)),
        ],
      );

  @override
  void dispose() {
    _pwdController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: const GradientAppBar(title: 'Reset Password'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: _pwdController,
                    obscureText: true,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.lock, color: t.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _confirmController,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      border: const OutlineInputBorder(),
                      prefixIcon:
                          Icon(Icons.lock, color: t.colorScheme.primary),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: IconButton(
                      icon: Icon(Icons.info_outline,
                          color: _pwdOk ? Colors.green : Colors.red),
                      onPressed: () => setState(() => _showInfo = !_showInfo),
                    ),
                  ),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: _showInfo
                        ? Container(
                            key: const ValueKey('info'),
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: t.colorScheme.surfaceVariant,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _pwdRow('≥ 8 characters', _hasLen),
                                _pwdRow('1 uppercase', _hasUpper),
                                _pwdRow('1 lowercase', _hasLower),
                                _pwdRow('1 number', _hasNumber),
                                _pwdRow('1 special', _hasSpecial),
                              ],
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const CircularProgressIndicator()
                      : ElevatedButton(
                          onPressed: _resetPassword,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 32, vertical: 14),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text('Reset Password'),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
