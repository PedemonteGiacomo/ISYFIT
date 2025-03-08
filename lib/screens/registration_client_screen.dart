import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/country_codes.dart'; // Import your expanded country codes
import 'package:dropdown_button2/dropdown_button2.dart'; // Import the dropdown_button2 package
import 'base_screen.dart';

class RegisterClientScreen extends StatefulWidget {
  const RegisterClientScreen({Key? key}) : super(key: key);

  @override
  State<RegisterClientScreen> createState() => _RegisterClientScreenState();
}

class _RegisterClientScreenState extends State<RegisterClientScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _ptEmailController = TextEditingController();

  String? _selectedCountryCode;
  DateTime? _selectedDate;
  bool _isLoading = false;
  bool _agreeToTerms = false;
  bool _showPasswordInfo = false;
  bool _emailFieldTouched = false;
  bool isSolo = true;

  // Password requirements
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar =>
      _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _hasMinLength => _passwordController.text.length >= 8;

  bool get _isEmailValid =>
      RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$')
          .hasMatch(_emailController.text);

  Future<void> _registerClient() async {
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

    setState(() {
      _isLoading = true;
    });

    try {
      // Create user account
      UserCredential userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      // Prepare data for Firestore
      final Map<String, dynamic> clientData = {
        'role': 'Client',
        'email': _emailController.text,
        'name': _nameController.text,
        'surname': _surnameController.text,
        'phone': '$_selectedCountryCode ${_phoneController.text}',
        'dateOfBirth': _selectedDate?.toIso8601String(),
        'isSolo': isSolo,
      };

      if (!isSolo) {
        // Fetch the PT by email
        final ptQuery = await FirebaseFirestore.instance
            .collection('users')
            .where('email', isEqualTo: _ptEmailController.text.trim())
            .where('role', isEqualTo: 'PT')
            .get();

        if (ptQuery.docs.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No PT found with this email.')),
          );
          setState(() {
            _isLoading = false;
          });
          return;
        }

        final ptDoc = ptQuery.docs.first;
        final ptId = ptDoc.id;

        // Add the PT ID to the client data
        clientData['supervisorPT'] = ptId;

        // Add the client ID to the PT's clients array
        await FirebaseFirestore.instance.collection('users').doc(ptId).update({
          'clients': FieldValue.arrayUnion([userCredential.user!.uid])
        });
      }

      // Save client information in Firestore
      await FirebaseFirestore.instance
          .collection('users')
          .doc(userCredential.user!.uid)
          .set(clientData);

      // Redirect to BaseScreen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const BaseScreen()),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              'An error occurred during registration. Please try again.\nError: $e'),
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
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
      setState(() {
        _selectedDate = pickedDate;
      });
    }
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

  Widget _buildPasswordRequirement(String text, bool isSatisfied) {
    // We keep green/red for clarity on password feedback:
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
          style: TextStyle(
            color: isSatisfied ? Colors.green : Colors.red,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      // appBar: AppBar(
      //   backgroundColor: theme.colorScheme.primary, // or theme.primaryColor
      //   elevation: 8,
      // ),
      body: Center(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              shadowColor: theme.colorScheme.primary.withOpacity(0.5),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        'Register as Client',
                        style: textTheme.headlineLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Name and Surname Fields
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Name',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                prefixIcon: const Icon(Icons.person),
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
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                                prefixIcon: const Icon(Icons.person_outline),
                              ),
                            ),
                          ),
                        ],
                      ),
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
                          onChanged: (value) {
                            setState(() {});
                          },
                          decoration: InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            prefixIcon: const Icon(Icons.email),
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

                      // Password Field with Info Icon
                      Stack(
                        children: [
                          TextField(
                            controller: _passwordController,
                            obscureText: true,
                            onChanged: (value) {
                              setState(() {});
                            },
                            decoration: InputDecoration(
                              labelText: 'Password',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              prefixIcon: const Icon(Icons.lock),
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
                              child: const Icon(
                                Icons.info_outline,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                        ],
                      ),
                      _buildPasswordInfo(),
                      const SizedBox(height: 16),

                      // Phone Number Field with Prefix Dropdown
                      Row(
                        children: [
                          SizedBox(
                            width: 120,
                            child: DropdownButton2<String>(
                              hint: const Text('Prefix'),
                              value: _selectedCountryCode,
                              items: countryCodes
                                  .map(
                                    (country) => DropdownMenuItem<String>(
                                      value: country['code'],
                                      child: Row(
                                        children: [
                                          Text(
                                            country['flag']!,
                                            style:
                                                const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 8),
                                          Text(country['code']!),
                                        ],
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedCountryCode = value;
                                });
                              },
                              dropdownStyleData: DropdownStyleData(
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8.0),
                                  color: theme.colorScheme.surface,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Phone Number Input
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                labelText: 'Phone Number',
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12.0),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Date Picker
                      GestureDetector(
                        onTap: _pickDate,
                        child: InputDecorator(
                          decoration: InputDecoration(
                            labelText: 'Date of Birth',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12.0),
                            ),
                            prefixIcon: const Icon(Icons.calendar_today),
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
                            child: GestureDetector(
                              onTap: () {
                                // Could show a Terms & Privacy policy dialog or route
                              },
                              child: Text(
                                'I accept all the conditions and privacy policy.',
                                style: TextStyle(
                                  color: theme.primaryColorDark,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Toggle for SOLO or Assign PT
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
                              title: const Text("Assign a PT"),
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

                      // PT Email Field (conditionally shown)
                      if (!isSolo)
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: TextField(
                            controller: _ptEmailController,
                            decoration: InputDecoration(
                              labelText: 'PT Email',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              prefixIcon: const Icon(Icons.email_outlined),
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Register Button
                      _isLoading
                          ? const CircularProgressIndicator()
                          : ElevatedButton(
                              onPressed: _registerClient,
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
        ),
      ),
    );
  }
}
