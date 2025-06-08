import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' hide Card;
import 'package:dropdown_button2/dropdown_button2.dart';

import '../../widgets/country_codes.dart';
import '../../widgets/gradient_app_bar.dart';
import "../../utils/firebase_error_translator.dart";
import '../base_screen.dart';
import 'plan_selection_screen.dart';

class RegisterPTScreen extends StatefulWidget {
  const RegisterPTScreen({Key? key}) : super(key: key);

  @override
  State<RegisterPTScreen> createState() => _RegisterPTScreenState();
}

class _RegisterPTScreenState extends State<RegisterPTScreen> {
  // -------------------- Controllers --------------------
  final _emailController      = TextEditingController();
  final _passwordController   = TextEditingController();
  final _nameController       = TextEditingController();
  final _surnameController    = TextEditingController();
  final _vatController        = TextEditingController();
  final _legalInfoController  = TextEditingController();
  final _phoneController      = TextEditingController();
  final AuthRepository _authRepo = AuthRepository();

  // -------------------- State --------------------
  String? _selectedCountryCode;
  DateTime? _selectedDate;
  String? _gender; // "Male" | "Female"
  bool _agreeToTerms = false;
  bool _showPwdInfo  = false;
  bool _emailTouched = false;
  bool _isLoading    = false;
  bool _isPayLoading = false;

  QueryDocumentSnapshot<Map<String, dynamic>>? _selectedPlan;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sessionSub;

  // -------------------- Validators --------------------
  bool get _isEmailValid {
    final email = _emailController.text.trim();
    final regex = RegExp(r'^[\w\-.]+@([\w-]+\.)+[\w-]{2,4}$');
    return regex.hasMatch(email);
  }
  bool get _pwdUpper => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _pwdLower => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _pwdNum   => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _pwdSpec  => _passwordController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _pwdLen   => _passwordController.text.length >= 8;
  bool get _pwdOk    => _pwdUpper && _pwdLower && _pwdNum && _pwdSpec && _pwdLen;

  @override
  void dispose() {
    _sessionSub?.cancel();
    super.dispose();
  }

  Future<void> _registerPT() async {
    // ── 1. Validazione ─────────────────────────────────
    if (!_agreeToTerms) return _msg('You must accept terms.');
    if (!_isEmailValid) return _msg('Invalid email.');
    if (!_pwdOk)        return _msg('Password not strong enough.');
    if (_nameController.text.trim().isEmpty)      return _msg('Please enter your name.');
    if (_surnameController.text.trim().isEmpty)   return _msg('Please enter your surname.');
    if (_selectedCountryCode == null)             return _msg('Please select a country code.');
    if (_phoneController.text.trim().isEmpty)     return _msg('Please enter your phone number.');
    if (_vatController.text.trim().isEmpty)       return _msg('Please enter your VAT/P.IVA.');
    if (_legalInfoController.text.trim().isEmpty) return _msg('Please enter legal info.');
    if (_selectedDate == null)                    return _msg('Please select your date of birth.');
    if (_gender == null)                          return _msg('Please select your gender.');

    // ── 2. Seleziona piano se non già fatto ───────────
    if (_selectedPlan == null) {
      final plan = await Navigator.of(context).push<
          QueryDocumentSnapshot<Map<String, dynamic>>>(
        MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
      );
      if (plan == null) return;
      setState(() => _selectedPlan = plan);
    }

    setState(() => _isLoading = true);

    UserCredential? cred;
    try {
      // ── 3. Crea utente Firebase Auth ─────────────────
      cred = await _authRepo.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );
      final uid = cred.user!.uid;

      // ── 4. Trova priceId dal piano scelto ────────────
      final priceSnap = await FirebaseFirestore.instance
          .collection('products')
          .doc(_selectedPlan!.id)
          .collection('prices')
          .where('active', isEqualTo: true)
          .limit(1)
          .get();
      final priceId = priceSnap.docs.first.id;

      // ── 5. Crea checkout_session (Payment Sheet) ─────
      setState(() => _isPayLoading = true);
      final sessionRef = await FirebaseFirestore.instance
          .collection('customers')
          .doc(uid)
          .collection('checkout_sessions')
          .add({
        'price': priceId,
        'mode' : 'setup',      // oppure 'subscription' su ramo next
        'client': 'mobile',
      });

      // ── 6. Ascolta i secret che l’estensione scrive ──
      _sessionSub?.cancel();
      _sessionSub = sessionRef.snapshots().listen((snap) async {
        final data = snap.data();
        if (data == null) return;

        if (data['error'] != null) {
          setState(() {
            _isPayLoading = false;
            _isLoading = false;
          });
          return _msg(data['error']['message'] ?? 'Stripe error');
        }

        final clientSecret = data['setupIntentClientSecret'] ??
                             data['paymentIntentClientSecret'];
        final eKey         = data['ephemeralKeySecret'];
        final customer     = data['customer'];
        if (clientSecret == null || eKey == null || customer == null) return;

        await _sessionSub?.cancel();
        try {
          // ── 7. Mostra la Payment Sheet ───────────────
          await Stripe.instance.initPaymentSheet(
            paymentSheetParameters: SetupPaymentSheetParameters(
              merchantDisplayName: 'IsyFit',
              customerId: customer,
              customerEphemeralKeySecret: eKey,
              setupIntentClientSecret: clientSecret,
              style: Theme.of(context).brightness == Brightness.dark
                  ? ThemeMode.dark
                  : ThemeMode.light,
              billingDetails: BillingDetails(
                email: _emailController.text.trim(),
                phone: _phoneController.text.trim(),
                name:  '${_nameController.text.trim()} '
                       '${_surnameController.text.trim()}',
              ),
            ),
          );
          await Stripe.instance.presentPaymentSheet();

          // ── 8. Successo → salva utente su Firestore ──
          if (_selectedCountryCode == null) {
            setState(() {
              _isPayLoading = false;
              _isLoading = false;
            });
            return _msg('Please select a country code.');
          }

          await FirebaseFirestore.instance
              .collection('users')
              .doc(uid)
              .set({
            'role'      : 'PT',
            'email'     : _emailController.text.trim(),
            'name'      : _nameController.text.trim(),
            'surname'   : _surnameController.text.trim(),
            'vat'       : _vatController.text.trim(),
            'legalInfo' : _legalInfoController.text.trim(),
            'phone'     : '$_selectedCountryCode ${_phoneController.text.trim()}',
            'dateOfBirth': _selectedDate?.toIso8601String(),
            'gender'    : _gender,
            'planId'    : _selectedPlan!.id,
          });

          // ── 9. Vai in app ────────────────────────────
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const BaseScreen()),
            (_) => false,
          );
        } on StripeException catch (e) {
          setState(() {
            _isPayLoading = false;
            _isLoading = false;
          });
          _msg(e.error.message ?? 'Payment cancelled');
          await cred?.user?.delete();
        } catch (e) {
          setState(() {
            _isPayLoading = false;
            _isLoading = false;
          });
          _msg('Payment error: $e');
          await cred?.user?.delete();
        }
      });
    } on FirebaseAuthException catch (e) {
      final msg = FirebaseErrorTranslator.fromException(e);
      _msg(msg);
      setState(() {
        _isLoading    = false;
        _isPayLoading = false;
      });
      if (cred?.user != null) await cred!.user!.delete();
    } catch (e) {
      final msg = FirebaseErrorTranslator.fromException(e as Exception);
      _msg(msg);
      setState(() {
        _isLoading    = false;
        _isPayLoading = false;
      });
      if (cred?.user != null) await cred!.user!.delete();
    }
  }

  void _msg(String m) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  Future<void> _pickDate() async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (d != null) setState(() => _selectedDate = d);
  }

  Widget _pwdRow(String txt, bool ok) => Row(
        children: [
          Icon(ok ? Icons.check_circle : Icons.cancel,
              color: ok ? Colors.green : Colors.red, size: 18),
          const SizedBox(width: 6),
          Text(txt, style: TextStyle(color: ok ? Colors.green : Colors.red)),
        ],
      );

  Widget _genderOpt(String g, IconData icn) {
    final c = Theme.of(context).colorScheme;
    final sel = _gender == g;
    return GestureDetector(
      onTap: () => setState(() => _gender = g),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: sel ? c.primary : Colors.grey),
          color: sel ? c.primary.withOpacity(.15) : Colors.transparent,
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(icn, color: sel ? c.primary : Colors.grey),
          const SizedBox(width: 8),
          Text(g, style: TextStyle(color: sel ? c.primary : Colors.grey)),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context);
    return Scaffold(
      appBar: GradientAppBar(title: 'Registration'),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            shadowColor: t.colorScheme.primary.withOpacity(.5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name & Surname
                    Row(children: [
                      Expanded(child: _textField(_nameController, 'Name', Icons.person)),
                      const SizedBox(width: 16),
                      Expanded(child: _textField(_surnameController, 'Surname', Icons.person_outline)),
                    ]),
                    const SizedBox(height: 16),

                    // Gender
                    Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      _genderOpt('Male', Icons.male),
                      const SizedBox(width: 16),
                      _genderOpt('Female', Icons.female),
                    ]),
                    const SizedBox(height: 16),

                    // Email
                    Focus(
                      onFocusChange: (f) => setState(() => _emailTouched = !f),
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: outline,
                          prefixIcon: Icon(Icons.email, color: t.colorScheme.primary),
                          suffixIcon: _emailTouched
                              ? Icon(_isEmailValid ? Icons.check_circle : Icons.cancel,
                                     color: _isEmailValid ? Colors.green : Colors.red)
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password
                    Stack(children: [
                      TextField(
                        controller: _passwordController,
                        obscureText: true,
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Password',
                          border: outline,
                          prefixIcon: Icon(Icons.lock, color: t.colorScheme.primary),
                        ),
                      ),
                      Positioned(
                        right: 10, top: 10,
                        child: GestureDetector(
                          onTap: () => setState(() => _showPwdInfo = !_showPwdInfo),
                          child: Icon(Icons.info_outline, color: _pwdOk ? Colors.green : Colors.red),
                        ),
                      ),
                    ]),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      child: _showPwdInfo
                          ? Container(
                              key: const ValueKey('pwd'),
                              margin: const EdgeInsets.only(top: 8),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: t.colorScheme.surfaceVariant,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _pwdRow('≥ 8 characters', _pwdLen),
                                  _pwdRow('1 uppercase', _pwdUpper),
                                  _pwdRow('1 lowercase', _pwdLower),
                                  _pwdRow('1 number', _pwdNum),
                                  _pwdRow('1 special', _pwdSpec),
                                ],
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 16),

                    // Phone
                    Row(children: [
                      SizedBox(
                        width: 100,
                        child: DropdownButton2<String>(
                          value: _selectedCountryCode,
                          hint: const Text('Prefix'),
                          isExpanded: true,
                          items: [
                            for (final c in countryCodes)
                              DropdownMenuItem(
                                value: c['code'],
                                child: Row(children: [
                                  Text(c['flag']!, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text('${c['name']} (${c['code']})'),
                                ]),
                              ),
                          ],
                          onChanged: (v) => setState(() => _selectedCountryCode = v),
                          buttonStyleData: const ButtonStyleData(height: 48),
                          dropdownStyleData: DropdownStyleData(width: 250),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(child: _textField(_phoneController, 'Phone', Icons.phone,
                                                  keyboard: TextInputType.phone)),
                    ]),
                    const SizedBox(height: 16),

                    // VAT & Legal
                    _textField(_vatController, 'VAT/P.IVA', Icons.business),
                    const SizedBox(height: 16),
                    _textField(_legalInfoController, 'Legal info', Icons.gavel, maxLines: 3),
                    const SizedBox(height: 16),

                    // Date picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date of birth',
                          border: outline,
                          prefixIcon: Icon(Icons.calendar_today, color: t.colorScheme.primary),
                        ),
                        child: Text(
                          _selectedDate == null
                              ? 'Select date'
                              : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                          style: TextStyle(
                              color: _selectedDate == null
                                  ? Colors.grey
                                  : t.textTheme.bodyMedium?.color),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Subscription plan selector
                    GestureDetector(
                      onTap: () async {
                        final plan = await Navigator.of(context).push<
                            QueryDocumentSnapshot<Map<String, dynamic>>>(
                          MaterialPageRoute(builder: (_) => const PlanSelectionScreen()),
                        );
                        if (plan != null) setState(() => _selectedPlan = plan);
                      },
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Subscription plan',
                          border: outline,
                          prefixIcon: Icon(Icons.workspace_premium,
                                             color: t.colorScheme.primary),
                        ),
                        child: Text(
                          _selectedPlan?.data()['name'] ?? 'Select a plan',
                          style: TextStyle(
                            color: _selectedPlan == null
                                ? Colors.grey
                                : t.textTheme.bodyMedium?.color,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Terms & button
                    Row(children: [
                      Checkbox(
                        value: _agreeToTerms,
                        onChanged: (v) => setState(() => _agreeToTerms = v ?? false),
                      ),
                      Expanded(
                        child: InkWell(
                          onTap: () => showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Terms and conditions'),
                              content: const Text('By using this app you accept our privacy policy…'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context),
                                  child: const Text('Close'),
                                )
                              ],
                            ),
                          ),
                          child: Text('I accept terms and privacy.',
                              style: TextStyle(
                                  color: t.colorScheme.primary,
                                  decoration: TextDecoration.underline)),
                        ),
                      ),
                    ]),
                    const SizedBox(height: 24),

                    (_isLoading || _isPayLoading)
                        ? const CircularProgressIndicator()
                        : FilledButton(
                            onPressed: _registerPT,
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 14),
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                            ),
                            child: Text(
                              _isPayLoading ? 'Processing…' : 'Register & Pay',
                              style: const TextStyle(fontSize: 16),
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  final outline = OutlineInputBorder(borderRadius: BorderRadius.circular(12));

  Widget _textField(TextEditingController c, String label, IconData icn,
          {int maxLines = 1, TextInputType keyboard = TextInputType.text}) =>
      TextField(
        controller: c,
        maxLines: maxLines,
        keyboardType: keyboard,
        decoration: InputDecoration(
          labelText: label,
          border: outline,
          prefixIcon: Icon(icn, color: Theme.of(context).colorScheme.primary),
        ),
      );
}
