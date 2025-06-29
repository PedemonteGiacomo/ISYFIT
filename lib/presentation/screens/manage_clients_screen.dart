import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import 'package:isyfit/data/repositories/client_repository.dart';

import 'package:isyfit/presentation/screens/base_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/widgets/isy_client_options_dialog.dart';

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
      builder: (ctx) {
        final TextEditingController nameCtrl = TextEditingController();
        final TextEditingController surnameCtrl = TextEditingController();
        final TextEditingController passCtrl = TextEditingController();
        final TextEditingController confirmCtrl = TextEditingController();
        final FocusNode confirmNode = FocusNode();
        bool confirmTouched = false;
        bool showConfirmInfo = false;
        bool obscurePass = true;
        bool obscureConfirm = true;
        final TextEditingController phoneCtrl = TextEditingController();
        String? selectedGender;
        DateTime? selectedDOB;

        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: StatefulBuilder(
              builder: (ctx2, setStateDialog) {
                Future<void> pickDOB() async {
                  final picked = await showDatePicker(
                    context: ctx2,
                    initialDate: DateTime(1990),
                    firstDate: DateTime(1900),
                    lastDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setStateDialog(() => selectedDOB = picked);
                  }
                }

                confirmNode.addListener(() {
                  if (!confirmNode.hasFocus) {
                    setStateDialog(() => confirmTouched = true);
                  }
                });

                Widget confirmInfo() {
                  return AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: showConfirmInfo &&
                            confirmTouched &&
                            passCtrl.text != confirmCtrl.text
                        ? Container(
                            key: const ValueKey('confirm_info'),
                            margin: const EdgeInsets.only(top: 8),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(ctx2).colorScheme.surfaceVariant,
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

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Register New Client',
                      style: Theme.of(ctx2).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'No existing client found for "$email".\n'
                      'Please fill in details to create a new account.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: surnameCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Surname',
                              border: OutlineInputBorder(),
                              prefixIcon: Icon(Icons.person_outline),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _genderOption(
                          context: ctx2,
                          label: 'Male',
                          icon: Icons.male,
                          isSelected: selectedGender == 'Male',
                          onTap: () => setStateDialog(() {
                            selectedGender = 'Male';
                          }),
                        ),
                        const SizedBox(width: 16),
                        _genderOption(
                          context: ctx2,
                          label: 'Female',
                          icon: Icons.female,
                          isSelected: selectedGender == 'Female',
                          onTap: () => setStateDialog(() {
                            selectedGender = 'Female';
                          }),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      enabled: false,
                      controller: TextEditingController(text: email),
                      decoration: const InputDecoration(
                        labelText: 'Client Email',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.email),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: passCtrl,
                      obscureText: obscurePass,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: 'Temporary Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock),
                        suffixIcon: IconButton(
                          icon: Icon(obscurePass
                              ? Icons.visibility
                              : Icons.visibility_off),
                          onPressed: () =>
                              setStateDialog(() => obscurePass = !obscurePass),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: confirmCtrl,
                      focusNode: confirmNode,
                      obscureText: obscureConfirm,
                      onChanged: (_) => setStateDialog(() {}),
                      decoration: InputDecoration(
                        labelText: 'Confirm Password',
                        border: const OutlineInputBorder(),
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (confirmTouched)
                              GestureDetector(
                                onTap: () => setStateDialog(
                                    () => showConfirmInfo = !showConfirmInfo),
                                child: Icon(
                                  passCtrl.text == confirmCtrl.text
                                      ? Icons.check_circle
                                      : Icons.cancel,
                                  color: passCtrl.text == confirmCtrl.text
                                      ? Colors.green
                                      : Colors.red,
                                ),
                              ),
                            IconButton(
                              icon: Icon(obscureConfirm
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setStateDialog(
                                  () => obscureConfirm = !obscureConfirm),
                            ),
                          ],
                        ),
                      ),
                    ),
                    confirmInfo(),
                    const SizedBox(height: 12),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'Phone Number',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.phone),
                      ),
                    ),
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: pickDOB,
                      child: InputDecorator(
                        decoration: const InputDecoration(
                          labelText: 'Date of Birth',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.calendar_today),
                        ),
                        child: Text(
                          selectedDOB == null
                              ? 'Select DOB'
                              : DateFormat('yyyy-MM-dd').format(selectedDOB!),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.app_registration),
                            label: const Text('Register'),
                            onPressed: () {
                              if (passCtrl.text.trim() !=
                                  confirmCtrl.text.trim()) {
                                ScaffoldMessenger.of(ctx2).showSnackBar(
                                  const SnackBar(
                                      content: Text('Passwords do not match.')),
                                );
                                return;
                              }
                              Navigator.pop(ctx2);
                              _registerClient(
                                email: email,
                                name: nameCtrl.text.trim(),
                                surname: surnameCtrl.text.trim(),
                                password: passCtrl.text.trim(),
                                phone: phoneCtrl.text.trim(),
                                gender: selectedGender,
                                dob: selectedDOB,
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _genderOption({
    required BuildContext context,
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary.withOpacity(0.2) : null,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? theme.colorScheme.primary : Colors.grey,
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? theme.colorScheme.primary : Colors.grey,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? theme.colorScheme.primary : Colors.grey,
              ),
            ),
          ],
        ),
      ),
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
