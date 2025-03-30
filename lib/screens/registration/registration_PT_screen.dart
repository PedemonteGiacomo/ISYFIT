import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../widgets/country_codes.dart'; // Expanded country codes
import 'package:dropdown_button2/dropdown_button2.dart'; // Note: Corrected package name
import '../base_screen.dart';
import '../../widgets/gradient_app_bar.dart';

class RegisterPTScreen extends StatefulWidget {
  const RegisterPTScreen({Key? key}) : super(key: key);

  @override
  State<RegisterPTScreen> createState() => _RegisterPTScreenState();
}

class _RegisterPTScreenState extends State<RegisterPTScreen> {
  // -------------------- Controllers --------------------
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _vatController = TextEditingController();
  final TextEditingController _legalInfoController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  // -------------------- State Variables --------------------
  String? _selectedCountryCode;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _showPasswordInfo = false;
  bool _emailFieldTouched = false;

  // -------------------- Gender Field --------------------
  String? _gender; // "Male" or "Female"

  // -------------------- Password Requirements --------------------
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _hasMinLength => _passwordController.text.length >= 8;

  bool get _isEmailValid => RegExp(
        r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
      ).hasMatch(_emailController.text);

  bool get _allRequirementsMet =>
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar &&
      _hasMinLength;

  // ===================================================================
  //                    Registration Logic
  // ===================================================================
  Future<void> _registerPT() async {
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('You must agree to the terms and conditions to register.'),
        ),
      );
      return;
    }

    if (!_isEmailValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid email address.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Save PT information in Firestore including gender
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set({
        'role': 'PT',
        'email': _emailController.text.trim(),
        'name': _nameController.text.trim(),
        'surname': _surnameController.text.trim(),
        'vat': _vatController.text.trim(),
        'legalInfo': _legalInfoController.text.trim(),
        'phone': '$_selectedCountryCode ${_phoneController.text.trim()}',
        'dateOfBirth': _selectedDate?.toIso8601String(),
        'gender': _gender,
      });

      // Redirect to PT Dashboard (or BaseScreen)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BaseScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content:
              Text('An error occurred during registration. Please try again.'),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _pickDate() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );

    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

  // ===================================================================
  //                             UI Helpers
  // ===================================================================
  Widget _buildPasswordRequirement(String text, bool isSatisfied) {
    return Row(
      children: [
        Icon(
          isSatisfied ? Icons.check_circle : Icons.cancel,
          color: isSatisfied ? Colors.green : Colors.red,
          size: 20,
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(color: isSatisfied ? Colors.green : Colors.red),
        ),
      ],
    );
  }

  Widget _buildPasswordInfo() {
    return Visibility(
      visible: _showPasswordInfo,
      child: Container(
        padding: const EdgeInsets.all(12.0),
        margin: const EdgeInsets.only(top: 8.0),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPasswordRequirement('At least 8 characters', _hasMinLength),
            _buildPasswordRequirement(
                'At least one uppercase letter', _hasUppercase),
            _buildPasswordRequirement(
                'At least one lowercase letter', _hasLowercase),
            _buildPasswordRequirement('At least one number', _hasNumber),
            _buildPasswordRequirement(
                'At least one special character', _hasSpecialChar),
          ],
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
          // Male Icon Button
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
          // Female Icon Button
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
          padding: const EdgeInsets.all(16.0),
          child: Card(
            elevation: 8,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0)),
            shadowColor: theme.colorScheme.primary.withOpacity(0.5),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 400),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // // Title
                    // Text(
                    //   'Register as PT',
                    //   style: textTheme.headlineLarge?.copyWith(
                    //     fontWeight: FontWeight.bold,
                    //     color: theme.colorScheme.onSurface,
                    //   ),
                    // ),
                    // const SizedBox(height: 24),

                    // Name and Surname Fields
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _nameController,
                            decoration: InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0)),
                              prefixIcon: Icon(Icons.person,
                                  color: theme.colorScheme.primary),
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
                                  borderRadius: BorderRadius.circular(12.0)),
                              prefixIcon: Icon(Icons.person_outline,
                                  color: theme.colorScheme.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Gender selection with icons
                    _buildGenderSelection(),
                    const SizedBox(height: 16),

                    // Email Field
                    Focus(
                      onFocusChange: (hasFocus) {
                        if (!hasFocus) {
                          setState(() {
                            _emailFieldTouched = true;
                          });
                        }
                      },
                      child: TextField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        onChanged: (value) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: 'Email',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0)),
                          prefixIcon: Icon(Icons.email,
                              color: theme.colorScheme.primary),
                          suffixIcon: _emailFieldTouched
                              ? Icon(
                                  _isEmailValid
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color:
                                      _isEmailValid ? Colors.green : Colors.red,
                                )
                              : null,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Password Field with Info Icon
                    Stack(
                      children: [
                        TextField(
                          controller: _passwordController,
                          obscureText: true,
                          onChanged: (value) => setState(() {}),
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0)),
                            prefixIcon: Icon(Icons.lock,
                                color: theme.colorScheme.primary),
                          ),
                        ),
                        Positioned(
                          right: 10,
                          top: 10,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _showPasswordInfo = !_showPasswordInfo;
                              });
                            },
                            child: Icon(
                              Icons.info_outline,
                              color: _allRequirementsMet
                                  ? Colors.green
                                  : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),
                    _buildPasswordInfo(),
                    const SizedBox(height: 16),

                    // Phone Number Field with Prefix Dropdown
                    // ---------------------------------------------------
                    // Phone Prefix + Number
                    // ---------------------------------------------------
                    Row(
                      children: [
                        SizedBox(
                          width: 100,
                          child: DropdownButton2<String>(
                            isExpanded: true,
                            value: _selectedCountryCode,
                            hint: const Text('Prefix'),
                            items: countryCodes.map((country) {
                              final code = country['code']!;
                              final flag = country['flag']!;
                              final name = country['name']!;
                              return DropdownMenuItem<String>(
                                value: code,
                                child: Row(
                                  children: [
                                    Text(flag,
                                        style: const TextStyle(fontSize: 18)),
                                    const SizedBox(width: 8),
                                    Text('$name ($code)'),
                                  ],
                                ),
                              );
                            }).toList(),
                            selectedItemBuilder: (context) =>
                                countryCodes.map((country) {
                              return Row(
                                children: [
                                  Text(country['flag']!,
                                      style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 4),
                                  Text(country['code']!),
                                ],
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() {
                                _selectedCountryCode = value;
                              });
                            },
                            dropdownStyleData: DropdownStyleData(
                              width: 250,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(8),
                                color: theme.colorScheme.surface,
                              ),
                            ),
                            buttonStyleData: const ButtonStyleData(
                              height: 48,
                              padding: EdgeInsets.symmetric(horizontal: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: _phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(
                              labelText: 'Phone Number',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // VAT Field
                    TextField(
                      controller: _vatController,
                      decoration: InputDecoration(
                        labelText: 'VAT/P.IVA',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon: Icon(Icons.business,
                            color: theme.colorScheme.primary),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Legal Information Field
                    TextField(
                      controller: _legalInfoController,
                      decoration: InputDecoration(
                        labelText: 'Legal Information',
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0)),
                        prefixIcon:
                            Icon(Icons.gavel, color: theme.colorScheme.primary),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Date Picker
                    GestureDetector(
                      onTap: _pickDate,
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0)),
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

                    // Agreement Checkbox
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
                                  title: const Text('Terms and Conditions'),
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
                                      onPressed: () => Navigator.pop(context),
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

                    // Register Button
                    _isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton(
                            onPressed: _registerPT,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.primaryColor,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12.0,
                                horizontal: 24.0,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                            ),
                            child: Text(
                              'Register',
                              style: TextStyle(
                                  fontSize: 16,
                                  color: theme.colorScheme.onPrimary),
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
}
