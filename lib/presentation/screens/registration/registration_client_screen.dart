import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../data/repositories/auth_repository.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import '../../widgets/country_codes.dart';
import 'package:dropdown_button2/dropdown_button2.dart';
import '../base_screen.dart';
import 'package:isyfit/presentation/constants/layout_constants.dart';

import "../../../domain/utils/firebase_error_translator.dart";
import '../../../domain/utils/validators.dart';

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({Key? key}) : super(key: key);

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  // -------------------- Controllers --------------------
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ptEmailController = TextEditingController();
  final FocusNode _ptEmailNode = FocusNode();
  final FocusNode _confirmPasswordNode = FocusNode();
  final AuthRepository _authRepo = AuthRepository();

  // -------------------- State Variables --------------------
  String? _selectedCountryCode;
  DateTime _selectedDate = DateTime(2000, 1, 1); // Default date
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _showPasswordInfo = false;
  bool _emailFieldTouched = false;
  bool _ptEmailTouched = false;
  bool _showConfirmInfo = false;
  bool _confirmTouched = false;
  bool isSolo = true; // If false => user wants to assign PT
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _ptEmailNode.addListener(() {
      if (!_ptEmailNode.hasFocus) {
        setState(() => _ptEmailTouched = true);
      }
    });
    _confirmPasswordNode.addListener(() {
      if (!_confirmPasswordNode.hasFocus) {
        setState(() => _confirmTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    _surnameController.dispose();
    _phoneController.dispose();
    _ptEmailController.dispose();
    _ptEmailNode.dispose();
    _confirmPasswordNode.dispose();
    super.dispose();
  }

  // -------------------- Gender Field --------------------
  String? _gender; // "Male" or "Female"

  // -------------------- Password Requirements --------------------
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _hasMinLength => _passwordController.text.length >= 8;

  /// Email Regex check
  bool get _passwordsMatch =>
      _passwordController.text == _confirmPasswordController.text;
  bool get _isEmailValid => isValidEmail(_emailController.text);
  bool get _isPtEmailValid => isValidEmail(_ptEmailController.text.trim());

  /// If all password checks are true => user meets requirements
  bool get _allRequirementsMet =>
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar &&
      _hasMinLength;

  // ===================================================================
  //                    Registration Logic
  // ===================================================================
  Future<void> _registerClient() async {
    // 1) Must accept T&C
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('You must agree to the terms and conditions to register.'),
        ),
      );
      return;
    }

    // 2) Check if the user have provided the gender
    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }

    // 3) Check email format
    if (!_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address.')),
      );
      return;
    }

    // 4) Check if the name and surname are provided
    if (_nameController.text.trim().isEmpty ||
        _surnameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and surname are required.')),
      );
      return;
    }

    // 5) Check if the password is empty or does not meet requirements
    if (_passwordController.text.trim().isEmpty || !_allRequirementsMet) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Password must be at least 8 characters long and meet all requirements.'),
        ),
      );
      return;
    }

    // 6) Ensure passwords match
    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    // 7) Check phone number is provided
    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required.')),
      );
      return;
    }

    // 8) Attempt creation
    setState(() => _isLoading = true);

    UserCredential? userCredential;
    try {
      // 8) Prepare doc for Firestore
      if (_selectedCountryCode == null) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select a country code.')),
        );
        return;
      }

      // Prepare the client data to save in Firestore
      final clientData = <String, dynamic>{
        'role': 'Client',
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'phone': '$_selectedCountryCode ${_phoneController.text.trim()}',
        'dateOfBirth': _selectedDate.toIso8601String(),
        'isSolo': true,
        'gender': _gender, // store the chosen gender
      };

      // 9) If user chooses "Assign PT", just notify the PT
      String? ptId;
      if (!isSolo) {
        if (!_isPtEmailValid) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please enter a valid PT email.')),
          );
          setState(() => _isLoading = false);
          return;
        }
        final ptQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: _ptEmailController.text.trim())
            .where('role', isEqualTo: 'PT')
            .get();

        if (ptQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No PT found with this email.')),
          );
          setState(() => _isLoading = false);
          return;
        }

        final ptDoc = ptQuery.docs.first;
        ptId = ptDoc.id;
        clientData['requestedPT'] = ptId;
        clientData['requestStatus'] = 'pending';
      }

      // Register the client using the AuthRepository
      userCredential = await _authRepo.register(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      // Save doc in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(clientData);

      // If a PT was chosen, add a notification to that PT
      if (ptId != null) {
        final notifId = FirebaseFirestore.instance.collection('tmp').doc().id;
        final notif = {
          'id': notifId,
          'clientId': userCredential.user!.uid,
          'clientName': _nameController.text.trim(),
          'clientSurname': _surnameController.text.trim(),
          'clientEmail': _emailController.text.trim(),
          'status': 'pending',
          'read': false,
          'timestamp': Timestamp.now(),
        };
        await FirebaseFirestore.instance.collection('users').doc(ptId).update({
          'notifications': FieldValue.arrayUnion([notif])
        });
      }

      // 11) Navigate to main flow and clear navigation stack
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const BaseScreen()),
        (route) => false, // This removes all previous routes
      );
    } on FirebaseAuthException catch (e) {
      final msg = FirebaseErrorTranslator.fromException(e);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      final msg = FirebaseErrorTranslator.fromException(e as Exception);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ===================================================================
  //                             UI Helpers
  // ===================================================================
  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  /// A single line describing one password requirement
  Widget _buildPasswordRequirement(String text, bool met) {
    return Row(
      children: [
        Icon(
          met ? Icons.check_circle : Icons.cancel,
          color: met ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            color: met ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  /// A container that conditionally shows password instructions
  Widget _buildPasswordInfo() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showPasswordInfo
          ? Container(
              key: const ValueKey('password_info'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPasswordRequirement(
                      'At least 8 characters', _hasMinLength),
                  _buildPasswordRequirement(
                      'At least one uppercase letter', _hasUppercase),
                  _buildPasswordRequirement(
                      'At least one lowercase letter', _hasLowercase),
                  _buildPasswordRequirement('At least one number', _hasNumber),
                  _buildPasswordRequirement(
                      'At least one special character', _hasSpecialChar),
                ],
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildConfirmInfo() {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      child: _showConfirmInfo && !_passwordsMatch
          ? Container(
              key: const ValueKey('confirm_info'),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                'Le due password non corrispondono',
                style: TextStyle(color: Colors.red),
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  /// Helper method to create a text field with standard styling
  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon, {
    TextInputType? keyboard,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        prefixIcon: Icon(
          icon,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }

  /// Gender selection with icon buttons for Male and Female.
  Widget _buildGenderSelection() {
    final theme = Theme.of(context);
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          //const Text("Gender: "),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              setState(() {
                _gender = "Male";
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _gender == "Male"
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _gender == "Male"
                      ? theme.colorScheme.primary
                      : Colors.grey,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.male,
                      color: _gender == "Male"
                          ? theme.colorScheme.primary
                          : Colors.grey),
                  const SizedBox(width: 8),
                  Text("Male",
                      style: TextStyle(
                          color: _gender == "Male"
                              ? theme.colorScheme.primary
                              : Colors.grey)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 16),
          GestureDetector(
            onTap: () {
              setState(() {
                _gender = "Female";
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              decoration: BoxDecoration(
                color: _gender == "Female"
                    ? theme.colorScheme.primary.withOpacity(0.2)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _gender == "Female"
                      ? theme.colorScheme.primary
                      : Colors.grey,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.female,
                      color: _gender == "Female"
                          ? theme.colorScheme.primary
                          : Colors.grey),
                  const SizedBox(width: 8),
                  Text("Female",
                      style: TextStyle(
                          color: _gender == "Female"
                              ? theme.colorScheme.primary
                              : Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ===================================================================
  //                             Build Method
  // ===================================================================
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Registration',
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(bottom: kScreenBottomPadding),
          child: Column(
            children: [
              /// The main Card container
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Card(
                  elevation: 6,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  shadowColor: theme.colorScheme.primary.withOpacity(0.4),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // ---------------------------------------------------
                          // Name + Surname
                          // ---------------------------------------------------
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  decoration: InputDecoration(
                                    labelText: 'Name',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: TextField(
                                  controller: _surnameController,
                                  decoration: InputDecoration(
                                    labelText: 'Surname',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(
                                      Icons.person_outline,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ---------------------------------------------------
                          // Gender Selection using Icons
                          // ---------------------------------------------------
                          _buildGenderSelection(),
                          const SizedBox(height: 16),

                          // ---------------------------------------------------
                          // Email Field
                          // ---------------------------------------------------
                          Focus(
                            onFocusChange: (hasFocus) {
                              if (!hasFocus) {
                                setState(() => _emailFieldTouched = true);
                              }
                            },
                            child: TextField(
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              onChanged: (value) {
                                setState(() {});
                              },
                              decoration: InputDecoration(
                                labelText: 'Email',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.email,
                                    color: theme.colorScheme.primary),
                                suffixIcon: _emailFieldTouched
                                    ? Icon(
                                        _isEmailValid
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _isEmailValid
                                            ? Colors.green
                                            : Colors.red,
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ---------------------------------------------------
                          // Password Field with Info Icon
                          // ---------------------------------------------------
                          TextField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.lock,
                                color: theme.colorScheme.primary,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  GestureDetector(
                                    onTap: () => setState(() =>
                                        _showPasswordInfo = !_showPasswordInfo),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: _allRequirementsMet
                                          ? Colors.green
                                          : Colors.red,
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildPasswordInfo(),
                          const SizedBox(height: 16),

                          TextField(
                            controller: _confirmPasswordController,
                            focusNode: _confirmPasswordNode,
                            obscureText: _obscureConfirmPassword,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              labelText: 'Confirm Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              prefixIcon: Icon(
                                Icons.lock_outline,
                                color: theme.colorScheme.primary,
                              ),
                              suffixIcon: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  if (_confirmTouched)
                                    GestureDetector(
                                      onTap: () => setState(() =>
                                          _showConfirmInfo = !_showConfirmInfo),
                                      child: Icon(
                                        _passwordsMatch
                                            ? Icons.check_circle
                                            : Icons.cancel,
                                        color: _passwordsMatch
                                            ? Colors.green
                                            : Colors.red,
                                      ),
                                    ),
                                  IconButton(
                                    icon: Icon(_obscureConfirmPassword
                                        ? Icons.visibility
                                        : Icons.visibility_off),
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _buildConfirmInfo(),
                          const SizedBox(height: 16),

                          // Phone
                          Row(children: [
                            Expanded(
                              flex: 2, // Takes 2/5 of the available space
                              child: DropdownButton2<String>(
                                value: _selectedCountryCode,
                                hint: const Text('Prefix'),
                                isExpanded: true,
                                items: [
                                  for (final c in countryCodes)
                                    DropdownMenuItem(
                                      value: c['code'],
                                      child: Row(children: [
                                        Text(c['flag']!,
                                            style:
                                                const TextStyle(fontSize: 18)),
                                        const SizedBox(width: 8),
                                        Text('${c['name']} (${c['code']})'),
                                      ]),
                                    ),
                                ],
                                selectedItemBuilder: (ctx) =>
                                    countryCodes.map((c) {
                                  return Row(
                                    children: [
                                      Text(c['flag']!,
                                          style: const TextStyle(fontSize: 18)),
                                      const SizedBox(width: 6),
                                      Text(c['code']!),
                                    ],
                                  );
                                }).toList(),
                                onChanged: (v) =>
                                    setState(() => _selectedCountryCode = v),
                                buttonStyleData:
                                    const ButtonStyleData(height: 48),
                                dropdownStyleData:
                                    DropdownStyleData(width: 250),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              flex: 3, // Takes 3/5 of the available space
                              child: _textField(
                                  _phoneController, 'Phone', Icons.phone,
                                  keyboard: TextInputType.phone),
                            ),
                          ]),
                          const SizedBox(height: 16),

                          // ---------------------------------------------------
                          // Date Picker
                          // ---------------------------------------------------
                          GestureDetector(
                            onTap: _pickDate,
                            child: InputDecorator(
                              decoration: InputDecoration(
                                labelText: 'Date of Birth',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                prefixIcon: Icon(Icons.calendar_today,
                                    color: theme.colorScheme.primary),
                              ),
                              child: Text(
                                _selectedDate == null
                                    ? 'Select Date'
                                    : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                                style: TextStyle(
                                  color: _selectedDate == null
                                      ? Colors.grey
                                      : textTheme.bodyMedium?.color,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ---------------------------------------------------
                          // Terms & Conditions
                          // ---------------------------------------------------
                          Row(
                            children: [
                              Checkbox(
                                value: _agreeToTerms,
                                onChanged: (value) {
                                  setState(() {
                                    _agreeToTerms = value ?? false;
                                  });
                                },
                              ),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => AlertDialog(
                                        title:
                                            const Text('Terms and Conditions'),
                                        content: SingleChildScrollView(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisSize: MainAxisSize.min,
                                            children: const [
                                              Text(
                                                'By using this app, you agree to:\n\n'
                                                '1. Share your personal information for account creation\n'
                                                '2. Allow us to process your data according to GDPR\n'
                                                '3. Receive notifications about your training\n'
                                                '4. Follow safety guidelines during workouts\n\n'
                                                'For full terms and privacy policy, visit our website.',
                                              ),
                                            ],
                                          ),
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text('Close'),
                                          ),
                                        ],
                                      ),
                                    );
                                  },
                                  child: Padding(
                                    padding: const EdgeInsets.only(top: 1),
                                    child: Text(
                                      'I accept all the conditions and privacy policy.',
                                      style: TextStyle(
                                        color: theme.colorScheme.primary,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),

                          // ---------------------------------------------------
                          // Solo or Assign PT
                          // ---------------------------------------------------
                          Row(
                            children: [
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text("Go SOLO"),
                                  value: true,
                                  groupValue: isSolo,
                                  onChanged: (value) {
                                    setState(() {
                                      isSolo = value ?? true;
                                    });
                                  },
                                ),
                              ),
                              Expanded(
                                child: RadioListTile<bool>(
                                  title: const Text("Assign PT"),
                                  value: false,
                                  groupValue: isSolo,
                                  onChanged: (value) {
                                    setState(() {
                                      isSolo = value ?? false;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),

                          // If user chooses "Assign PT," show the PT email field
                          if (!isSolo)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Focus(
                                onFocusChange: (hasFocus) {
                                  if (!hasFocus) {
                                    setState(() => _ptEmailTouched = true);
                                  }
                                },
                                child: TextField(
                                  controller: _ptEmailController,
                                  focusNode: _ptEmailNode,
                                  decoration: InputDecoration(
                                    labelText: 'PT Email',
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    prefixIcon: Icon(Icons.email_outlined,
                                        color: theme.colorScheme.primary),
                                    suffixIcon: _ptEmailTouched
                                        ? Icon(
                                            _isPtEmailValid
                                                ? Icons.check_circle
                                                : Icons.cancel,
                                            color: _isPtEmailValid
                                                ? Colors.green
                                                : Colors.red,
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          const SizedBox(height: 20),

                          // ---------------------------------------------------
                          // Register Button
                          // ---------------------------------------------------
                          if (_isLoading)
                            const CircularProgressIndicator()
                          else
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: theme.colorScheme.primary,
                                foregroundColor: theme.colorScheme.onPrimary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 14),
                              ),
                              onPressed: _registerClient,
                              child: const Text(
                                'Register',
                                style: TextStyle(fontSize: 16),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
