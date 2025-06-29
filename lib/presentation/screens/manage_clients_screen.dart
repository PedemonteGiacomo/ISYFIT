import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_button2/dropdown_button2.dart';

import 'package:isyfit/data/repositories/client_repository.dart';

import 'package:isyfit/presentation/screens/base_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/widgets/isy_client_options_dialog.dart';
import '../widgets/country_codes.dart';

import "../../domain/utils/firebase_error_translator.dart";
import '../../domain/utils/validators.dart';

enum ClientSortOption {
  nameAsc,
  surnameAsc,
  lastInteractedDesc,
}

class ManageClientsScreen extends StatefulWidget {
  const ManageClientsScreen({Key? key}) : super(key: key);

  @override
  State<ManageClientsScreen> createState() => _ManageClientsScreenState();
}

class _ManageClientsScreenState extends State<ManageClientsScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";

  bool _showFilterPanel = false;
  ClientSortOption _sortOption = ClientSortOption.nameAsc;
  final ClientRepository _clientRepo = ClientRepository();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// A helper to build 2-letter initials:
  ///  - If both name & surname are available, name[0] + surname[0].
  ///  - If surname is empty, use the first 2 letters of name.
  ///  - If name too short, default 'U'.
  String _buildClientInitials(String name, String surname) {
    name = name.trim();
    surname = surname.trim();
    if (name.isNotEmpty && surname.isNotEmpty) {
      return name[0].toUpperCase() + surname[0].toUpperCase();
    } else if (name.length >= 2) {
      return name.substring(0, 2).toUpperCase();
    } else if (name.isNotEmpty) {
      return name[0].toUpperCase();
    }
    return 'U';
  }

  /// Called by the refresh FAB to reload the screen's data
  void _refresh() {
    setState(() {
      // Simply re-running build triggers the FutureBuilder to re-fetch data
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Manage Clients',
        actions: [
          IconButton(
            icon: Icon(
              Icons.home,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const BaseScreen()),
              );
            },
          ),
        ],
      ),

      /// Two FABs: REFRESH (top) + ADD CLIENT (bottom)
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.end, // Add this line
        children: [
          // Refresh FAB
          Padding(
            padding: const EdgeInsets.only(right: 5),
            child: FloatingActionButton(
              heroTag: 'refreshFab',
              onPressed: _refresh,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Icon(
                Icons.refresh,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          // Add Client FAB
          FloatingActionButton.extended(
            heroTag: 'addClientFab',
            onPressed: _showSearchOrRegisterDialog,
            icon: Icon(
              Icons.person_add,
              color: Theme.of(context).colorScheme.onPrimary,
            ),
            label: Text(
              'Add New Client',
              style: TextStyle(color: Theme.of(context).colorScheme.onPrimary),
            ),
            backgroundColor: Theme.of(context).colorScheme.primary,
          ),
        ],
      ),

      body: LayoutBuilder(
        builder: (context, constraints) {
          final isPortrait =
              MediaQuery.of(context).orientation == Orientation.portrait;
          final widthFactor = isPortrait ? 0.95 : 0.65;
          final contentWidth =
              (constraints.maxWidth * widthFactor).clamp(320.0, 700.0);

          return Center(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: contentWidth),
              child: Column(
                children: [
                  _buildSearchBar(),
                  if (_showFilterPanel) _buildFilterPanel(),
                  const Divider(),
                  Expanded(
                    child: (currentUser == null)
                        ? const Center(child: Text('Not logged in.'))
                        : FutureBuilder<DocumentSnapshot>(
                            future: FirebaseFirestore.instance
                                .collection('users')
                                .doc(currentUser.uid)
                                .get(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const Center(
                                    child: CircularProgressIndicator());
                              }
                              if (!snapshot.hasData || snapshot.data == null) {
                                return const Center(
                                    child: Text('No data found.'));
                              }
                              final ptData =
                                  snapshot.data!.data() as Map<String, dynamic>;
                              final clientIds =
                                  ptData['clients'] as List<dynamic>? ?? [];
                              if (clientIds.isEmpty) {
                                return const Center(
                                  child: Text('No clients to manage.'),
                                );
                              }
                              return _buildClientList(clientIds);
                            },
                          ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (value) =>
                  setState(() => _searchQuery = value.trim().toLowerCase()),
              decoration: InputDecoration(
                labelText: 'Search Clients',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          InkWell(
            onTap: () {
              setState(() => _showFilterPanel = !_showFilterPanel);
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _showFilterPanel
                    ? Theme.of(context).colorScheme.primary
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.filter_alt,
                color: _showFilterPanel
                    ? Theme.of(context).colorScheme.onPrimary
                    : Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPanel() {
    return Padding(
      padding: const EdgeInsets.only(left: 12, right: 12, bottom: 8),
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        elevation: 2,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Sort Clients By:',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(width: 16),
                // Name Asc
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<ClientSortOption>(
                      value: ClientSortOption.nameAsc,
                      groupValue: _sortOption,
                      onChanged: (val) {
                        if (val != null) setState(() => _sortOption = val);
                      },
                    ),
                    const Text('Name (A-Z)'),
                  ],
                ),
                const SizedBox(width: 24),
                // Surname Asc
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<ClientSortOption>(
                      value: ClientSortOption.surnameAsc,
                      groupValue: _sortOption,
                      onChanged: (val) {
                        if (val != null) setState(() => _sortOption = val);
                      },
                    ),
                    const Text('Surname (A-Z)'),
                  ],
                ),
                const SizedBox(width: 24),
                // Latest Interaction Desc
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Radio<ClientSortOption>(
                      value: ClientSortOption.lastInteractedDesc,
                      groupValue: _sortOption,
                      onChanged: (val) {
                        if (val != null) setState(() => _sortOption = val);
                      },
                    ),
                    const Text('Latest Interacted'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildClientList(List<dynamic> clientIds) {
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: _fetchClientsData(clientIds),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData) {
          return const Center(child: Text('Error loading clients.'));
        }
        var clientsData = snapshot.data!;

        // 1) Filter
        clientsData = clientsData.where((clientMap) {
          final name = (clientMap['name'] ?? '').toString().toLowerCase();
          final surname = (clientMap['surname'] ?? '').toString().toLowerCase();
          final full = '$name $surname';
          return full.contains(_searchQuery);
        }).toList();

        // 2) Sort
        clientsData.sort((a, b) {
          switch (_sortOption) {
            case ClientSortOption.nameAsc:
              return (a['name'] ?? '')
                  .toString()
                  .compareTo((b['name'] ?? '').toString());
            case ClientSortOption.surnameAsc:
              return (a['surname'] ?? '')
                  .toString()
                  .compareTo((b['surname'] ?? '').toString());
            case ClientSortOption.lastInteractedDesc:
              final aTime = a['lastInteractionTime'] as Timestamp?;
              final bTime = b['lastInteractionTime'] as Timestamp?;
              if (aTime == null && bTime == null) return 0;
              if (aTime == null) return 1;
              if (bTime == null) return -1;
              return bTime.compareTo(aTime);
          }
        });

        if (clientsData.isEmpty) {
          return const Center(child: Text('No matching clients.'));
        }

        return ListView.builder(
          itemCount: clientsData.length,
          itemBuilder: (context, index) {
            final clientMap = clientsData[index];
            final clientUid = clientMap['uid'] as String?;
            if (clientUid == null) {
              return const SizedBox.shrink();
            }
            return _buildClientTile(clientMap, clientUid);
          },
        );
      },
    );
  }

  Future<List<Map<String, dynamic>>> _fetchClientsData(
      List<dynamic> clientIds) {
    return _clientRepo
        .fetchClientsData(clientIds.map((e) => e.toString()).toList());
  }

  Widget _buildClientTile(Map<String, dynamic> clientData, String clientUid) {
    final theme = Theme.of(context);
    final clientName = (clientData['name'] ?? '') as String;
    final clientSurname = (clientData['surname'] ?? '') as String;

    return Card(
      color: theme.colorScheme.surface,
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
      child: ListTile(
        leading: CircleAvatar(
          radius: 22,
          backgroundColor: theme.colorScheme.primary.withOpacity(0.75),
          child: Text(
            _buildClientInitials(clientName, clientSurname),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        title: FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            '$clientName $clientSurname',
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
            maxLines: 1,
          ),
        ),
        subtitle: FittedBox(
          alignment: Alignment.centerLeft,
          fit: BoxFit.scaleDown,
          child: Text(
            clientData['email'] ?? 'No Email',
            maxLines: 1,
          ),
        ),
        onTap: () => _showClientOptions(
          context,
          clientUid: clientUid,
          clientName: clientName,
          clientSurname: clientSurname,
        ),
        trailing: IconButton(
          icon: Icon(Icons.remove_circle, color: theme.colorScheme.error),
          onPressed: () => _removeClient(clientUid),
        ),
      ),
    );
  }

  void _showSearchOrRegisterDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        final TextEditingController emailCtrl = TextEditingController();
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Add or Register Client',
                  style: Theme.of(ctx).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Client Email',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.search),
                        label: const Text('Check Email'),
                        onPressed: () async {
                          final email = emailCtrl.text.trim();
                          Navigator.pop(ctx);
                          await _checkEmailAndProceed(email);
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _checkEmailAndProceed(String email) async {
    if (email.isEmpty || !isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email.')),
      );
      return;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not logged in');

      final clientId = await _clientRepo.findClientByEmail(email);
      if (clientId != null) {
        await _clientRepo.linkClientToPT(user.uid, clientId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Client added successfully!')),
          );
          setState(() {});
        }
      } else {
        _showRegisterNewClientDialog(email);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error adding client: $e')),
        );
      }
    }
  }
  void _showRegisterNewClientDialog(String email) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ClientRegistrationDialog(email: email, onRegister: _registerClient),
    );
  }
  Future<void> _registerClient({
    required String email,
    required String name,
    required String surname,
    required String password,
    required String phone,
    required String? gender,
    required DateTime? dob,
  }) async {
    if (email.isEmpty ||
        !isValidEmail(email) ||
        name.isEmpty ||
        surname.isEmpty ||
        password.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Please fill all fields with valid data.')),
        );
      }
      return;
    }
    try {
      final currentPT = FirebaseAuth.instance.currentUser;
      if (currentPT == null) throw Exception('PT not logged in');

      await _clientRepo.registerClient(
        email: email,
        password: password,
        name: name,
        surname: surname,
        phone: phone,
        gender: gender,
        dob: dob,
        ptUid: currentPT.uid,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('New client registered & linked!')),
        );
        setState(() {});
      }
    } on FirebaseAuthException catch (fae) {
      if (mounted) {
        final msg = FirebaseErrorTranslator.fromException(fae);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    } catch (e) {
      if (mounted) {
        final msg = FirebaseErrorTranslator.fromException(e as Exception);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  Future<void> _removeClient(String clientId) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('Not authenticated.');

      await _clientRepo.unlinkClientFromPT(user.uid, clientId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Client removed successfully!')),
        );
        setState(() {});
      }
    } catch (e) {
      if (mounted) {
        final msg = FirebaseErrorTranslator.fromException(e as Exception);
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(msg)));
      }
    }
  }

  void _showClientOptions(
    BuildContext context, {
    required String clientUid,
    required String clientName,
    required String clientSurname,
  }) {
    showDialog(
      context: context,
      builder: (_) => IsyClientOptionsDialog(
        clientUid: clientUid,
        clientName: clientName,
        clientSurname: clientSurname,
      ),
    );
  }
}

class _ClientRegistrationDialog extends StatefulWidget {
  final String email;
  final Function({
    required String email,
    required String name,
    required String surname,
    required String password,
    required String phone,
    required String? gender,
    required DateTime? dob,
  }) onRegister;

  const _ClientRegistrationDialog({
    required this.email,
    required this.onRegister,
  });

  @override
  State<_ClientRegistrationDialog> createState() => _ClientRegistrationDialogState();
}

class _ClientRegistrationDialogState extends State<_ClientRegistrationDialog> {
  // Controllers
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _surnameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final FocusNode _confirmPasswordNode = FocusNode();

  // State variables
  String? _selectedCountryCode;
  DateTime? _selectedDate;
  String? _gender;
  bool _showPasswordInfo = false;
  bool _showConfirmInfo = false;
  bool _confirmTouched = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Set default Italian country code
    final italianCode = countryCodes.firstWhere(
      (c) => c['code'] == '+39',
      orElse: () => countryCodes.first,
    );
    _selectedCountryCode = italianCode['code'];
    
    _confirmPasswordNode.addListener(() {
      if (!_confirmPasswordNode.hasFocus) {
        setState(() => _confirmTouched = true);
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _confirmPasswordNode.dispose();
    super.dispose();
  }

  // Password validation
  bool get _hasUppercase => _passwordController.text.contains(RegExp(r'[A-Z]'));
  bool get _hasLowercase => _passwordController.text.contains(RegExp(r'[a-z]'));
  bool get _hasNumber => _passwordController.text.contains(RegExp(r'[0-9]'));
  bool get _hasSpecialChar => _passwordController.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
  bool get _hasMinLength => _passwordController.text.length >= 8;
  bool get _passwordsMatch => _passwordController.text == _confirmPasswordController.text;
  bool get _allRequirementsMet => _hasUppercase && _hasLowercase && _hasNumber && _hasSpecialChar && _hasMinLength;

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
                  _buildPasswordRequirement('At least 8 characters', _hasMinLength),
                  _buildPasswordRequirement('At least one uppercase letter', _hasUppercase),
                  _buildPasswordRequirement('At least one lowercase letter', _hasLowercase),
                  _buildPasswordRequirement('At least one number', _hasNumber),
                  _buildPasswordRequirement('At least one special character', _hasSpecialChar),
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

  Widget _buildGenderSelection() {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gender',
            style: theme.textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _genderChip('Male', Icons.male, Colors.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _genderChip('Female', Icons.female, Colors.pink),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _genderChip(String value, IconData icon, Color activeColor) {
    final selected = _gender == value;
    return GestureDetector(
      onTap: () => setState(() => _gender = value),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: selected ? activeColor.withOpacity(0.15) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? activeColor : Colors.grey.shade300,
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: selected ? activeColor : Colors.grey.shade600,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              value,
              style: TextStyle(
                color: selected ? activeColor : Colors.grey.shade600,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (pickedDate != null) {
      setState(() => _selectedDate = pickedDate);
    }
  }

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

  void _handleRegister() {
    // Validation
    if (_nameController.text.trim().isEmpty || _surnameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name and surname are required.')),
      );
      return;
    }

    if (_gender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender.')),
      );
      return;
    }

    if (!_allRequirementsMet || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must meet all requirements.')),
      );
      return;
    }

    if (!_passwordsMatch) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match.')),
      );
      return;
    }

    if (_phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Phone number is required.')),
      );
      return;
    }

    if (_selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your date of birth.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final fullPhone = '$_selectedCountryCode ${_phoneController.text.trim()}';
    
    Navigator.pop(context);
    widget.onRegister(
      email: widget.email,
      name: _nameController.text.trim(),
      surname: _surnameController.text.trim(),
      password: _passwordController.text.trim(),
      phone: fullPhone,
      gender: _gender,
      dob: _selectedDate,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Row(
                  children: [
                    Icon(
                      Icons.person_add,
                      color: theme.colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Register New Client',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Creating account for: ${widget.email}',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 24),

                // Name + Surname (responsive layout)
                LayoutBuilder(
                  builder: (context, constraints) {
                    final isWideScreen = constraints.maxWidth > 360;
                    final nameField = TextField(
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
                    );
                    final surnameField = TextField(
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
                    );

                    if (isWideScreen) {
                      return Row(
                        children: [
                          Expanded(child: nameField),
                          const SizedBox(width: 16),
                          Expanded(child: surnameField),
                        ],
                      );
                    } else {
                      return Column(
                        children: [
                          nameField,
                          const SizedBox(height: 16),
                          surnameField,
                        ],
                      );
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Gender Selection
                _buildGenderSelection(),
                const SizedBox(height: 16),

                // Email Field (disabled)
                TextField(
                  enabled: false,
                  controller: TextEditingController(text: widget.email),
                  decoration: InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    prefixIcon: Icon(Icons.email, color: theme.colorScheme.primary),
                    fillColor: Colors.grey.shade100,
                    filled: true,
                  ),
                ),
                const SizedBox(height: 16),

                // Password Field with Info Icon
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    labelText: 'Temporary Password',
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
                          onTap: () => setState(() => _showPasswordInfo = !_showPasswordInfo),
                          child: Icon(
                            Icons.info_outline,
                            color: _allRequirementsMet ? Colors.green : Colors.red,
                          ),
                        ),
                        IconButton(
                          icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildPasswordInfo(),
                const SizedBox(height: 16),

                // Confirm Password
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
                            onTap: () => setState(() => _showConfirmInfo = !_showConfirmInfo),
                            child: Icon(
                              _passwordsMatch ? Icons.check_circle : Icons.cancel,
                              color: _passwordsMatch ? Colors.green : Colors.red,
                            ),
                          ),
                        IconButton(
                          icon: Icon(_obscureConfirmPassword ? Icons.visibility : Icons.visibility_off),
                          onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        ),
                      ],
                    ),
                  ),
                ),
                _buildConfirmInfo(),
                const SizedBox(height: 16),

                // Phone with Country Code
                Row(children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField2<String>(
                      value: countryCodes.any((c) => c['code'] == _selectedCountryCode) 
                          ? _selectedCountryCode 
                          : '+39',
                      decoration: InputDecoration(
                        labelText: 'Prefix',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 16,
                        ),
                      ),
                      items: [
                        for (final c in countryCodes)
                          DropdownMenuItem(
                            value: c['code'],
                            child: Row(children: [
                              Text(c['flag']!, style: const TextStyle(fontSize: 16)),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  '${c['name']} (${c['code']})',
                                  style: const TextStyle(fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                          ),
                      ],
                      selectedItemBuilder: (context) {
                        return countryCodes.map((c) {
                          return Padding(
                            padding: const EdgeInsets.only(left: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(c['flag']!, style: const TextStyle(fontSize: 16)),
                                const SizedBox(width: 2),
                                Flexible(
                                  child: Text(
                                    c['code']!,
                                    style: const TextStyle(fontSize: 16),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList();
                      },
                      onChanged: (v) => setState(() => _selectedCountryCode = v),
                      dropdownStyleData: DropdownStyleData(
                        width: 280,
                        maxHeight: 300,
                      ),
                      buttonStyleData: const ButtonStyleData(
                        padding: EdgeInsets.symmetric(horizontal: 4),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 4,
                    child: _textField(_phoneController, 'Phone', Icons.phone, keyboard: TextInputType.phone),
                  ),
                ]),
                const SizedBox(height: 16),

                // Date Picker
                GestureDetector(
                  onTap: _pickDate,
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Date of Birth',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      prefixIcon: Icon(Icons.calendar_today, color: theme.colorScheme.primary),
                    ),
                    child: Text(
                      _selectedDate == null
                          ? 'Select Date'
                          : '${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}',
                      style: TextStyle(
                        color: _selectedDate == null ? Colors.grey : theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Register Button
                if (_isLoading)
                  const CircularProgressIndicator()
                else
                  Row(
                    children: [
                      Expanded(
                        child: FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: theme.colorScheme.primary,
                            foregroundColor: theme.colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                          ),
                          onPressed: _handleRegister,
                          icon: const Icon(Icons.app_registration),
                          label: const Text('Register Client', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
