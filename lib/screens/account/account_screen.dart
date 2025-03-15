import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'package:isyfit/screens/login_screen.dart';

//TODO: implement the settings part here

class AccountScreen extends StatefulWidget {
  /// If `clientUid` is non-null, show that client's data (PT perspective).
  /// If `clientUid` is null, show the logged-in user's data (self).
  final String? clientUid;

  const AccountScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  _AccountScreenState createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String? _name;
  String? _surname;
  String? _email;
  String? _phone;
  String? _vat;
  String? _legalInfo;
  DateTime? _dateOfBirth;
  String? _profileImageUrl;

  bool _isEditMode = false;

  /// Return [widget.clientUid] if provided, else the current user's UID.
  String? get targetUid {
    if (widget.clientUid != null) {
      return widget.clientUid;
    }
    return _auth.currentUser?.uid;
  }

  /// True if it's the user's own account; false if PT is viewing someone else.
  bool get isOwnAccount {
    final currentUid = _auth.currentUser?.uid;
    // If clientUid is null or equals currentUid → user’s own account
    return widget.clientUid == null || widget.clientUid == currentUid;
  }

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  /// Fetch the user data for targetUid
  Future<void> _fetchUserData() async {
    try {
      if (targetUid == null) return;

      final userDoc = await _firestore.collection('users').doc(targetUid).get();
      final data = userDoc.data();
      if (data != null) {
        setState(() {
          _name = data['name'];
          _surname = data['surname'];
          _email = data['email'] ?? 'No Email';
          _phone = data['phone'];
          _vat = data['vat'];
          _legalInfo = data['legalInfo'];
          if (data['dateOfBirth'] != null) {
            _dateOfBirth = DateTime.tryParse(data['dateOfBirth']);
          }
          _profileImageUrl = data['profileImageUrl'];
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    }
  }

  /// Upload/change the user’s (or client’s) profile picture
  Future<void> _uploadProfilePicture() async {
    try {
      final uid = targetUid;
      if (uid == null) return;

      if (!isOwnAccount) {
        // PT is not allowed to edit client’s profile photo
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Editing client’s profile photo is disabled.'),
          ),
        );
        return;
      }

      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);

        final storageRef = _storage.ref().child('profile_images/$uid.jpg');
        await storageRef.putFile(file);

        final downloadUrl = await storageRef.getDownloadURL();
        await _firestore.collection('users').doc(uid).update({
          'profileImageUrl': downloadUrl,
        });

        setState(() {
          _profileImageUrl = downloadUrl;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile picture updated!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
    }
  }

  /// Log out only if it's the user’s own account
  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  /// Save changes to Firestore
  Future<void> _saveChanges() async {
    try {
      final uid = targetUid;
      if (uid == null) return;

      if (!isOwnAccount) {
        // PT editing client’s info is disabled
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Editing client’s info is disabled.')),
        );
        return;
      }

      await _firestore.collection('users').doc(uid).update({
        'name': _name,
        'surname': _surname,
        'phone': _phone,
        if (_vat != null) 'vat': _vat,
        if (_legalInfo != null) 'legalInfo': _legalInfo,
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile updated successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const LoginScreen();
    }

    return isOwnAccount
        ? _buildOwnAccountLayout(context)
        : _buildPtViewingClientLayout(context);
  }

  /// Layout for the user’s own account
  Widget _buildOwnAccountLayout(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Account',
            style: TextStyle(color: theme.colorScheme.onPrimary)),
        backgroundColor: theme.colorScheme.primary,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: theme.colorScheme.onPrimary),
            onPressed: _logout,
            tooltip: 'Logout',
          )
        ],
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            /// Profile Header with editing capabilities
            const SizedBox(height: 20),

            /// 1) Profile Card (Material 3 style, tinted surface)
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: theme.colorScheme.onPrimary,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: theme.colorScheme.primary.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    /// Avatar with an InkWell ripple for a more “material” feel
                    InkWell(
                      onTap: _uploadProfilePicture,
                      borderRadius: BorderRadius.circular(50),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const NetworkImage(
                                'https://api.dicebear.com/6.x/avataaars-neutral/png?seed=Katherine&flip=true'),
                        backgroundColor:
                            theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name != null
                                ? '$_name' +
                                    (_surname != null ? ' $_surname' : '')
                                : 'Welcome, Loading...',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _email ?? 'No Email',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 2) Account Information card
            Card(
              elevation: 3,
              margin: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: theme.colorScheme.onPrimary,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  /// Header: “Account Information” + Edit/Check icon
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16.0, vertical: 12),
                    child: Row(
                      children: [
                        Text(
                          'Account Information',
                          style: textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(
                            _isEditMode ? Icons.check : Icons.edit,
                            color: theme.colorScheme.primary,
                          ),
                          onPressed: () {
                            if (_isEditMode) {
                              _saveChanges();
                            }
                            setState(() {
                              _isEditMode = !_isEditMode;
                            });
                          },
                          tooltip:
                              _isEditMode ? 'Save changes' : 'Edit information',
                        ),
                      ],
                    ),
                  ),
                  const Divider(),

                  // Name
                  _buildEditableListTile(
                    label: 'Name',
                    value: _name,
                    isEditable: _isEditMode,
                    icon: Icons.person_outline,
                    onChanged: (value) => _name = value,
                  ),

                  // Surname
                  _buildEditableListTile(
                    label: 'Surname',
                    value: _surname,
                    isEditable: _isEditMode,
                    icon: Icons.person,
                    onChanged: (value) => _surname = value,
                  ),

                  // Phone
                  _buildEditableListTile(
                    label: 'Phone',
                    value: _phone,
                    isEditable: _isEditMode,
                    icon: Icons.phone,
                    onChanged: (value) => _phone = value,
                  ),

                  // VAT/P.IVA (only if present)
                  if (_vat != null)
                    _buildEditableListTile(
                      label: 'VAT/P.IVA',
                      value: _vat,
                      isEditable: _isEditMode,
                      icon: Icons.badge,
                      onChanged: (value) => _vat = value,
                    ),

                  // Legal Info (if present)
                  if (_legalInfo != null)
                    _buildEditableListTile(
                      label: 'Legal Info',
                      value: _legalInfo,
                      isEditable: _isEditMode,
                      maxLines: 3,
                      icon: Icons.info_outline,
                      onChanged: (value) => _legalInfo = value,
                    ),

                  // Date of Birth (non-editable for now)
                  _buildNonEditableListTile(
                    label: 'Date of Birth',
                    value: _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Not available',
                    icon: Icons.calendar_today_outlined,
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  /// Layout if a PT is viewing a client’s account – read-only representation
  Widget _buildPtViewingClientLayout(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text('Client Account',
            style: TextStyle(color: theme.colorScheme.onPrimary)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        actions: [
                  // Add a "Home" icon that takes the PT back to the main flow.
                  IconButton(
                    icon: Icon(Icons.home,
                        color: Theme.of(context).colorScheme.onPrimary),
                    onPressed: () {
                      // For example, pushReplacement to the main BaseScreen
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(builder: (_) => const BaseScreen()),
                      );
                    },
                  ),
                ],
        iconTheme: IconThemeData(
          color: Theme.of(context).colorScheme.onPrimary,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            /// 1) A bigger "profile" card with tinted surface
            Card(
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: theme.colorScheme.onPrimary,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: theme.colorScheme.primary.withOpacity(0.05),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const NetworkImage(
                              'https://api.dicebear.com/6.x/avataaars-neutral/png?seed=Katherine&flip=true'),
                      backgroundColor:
                          theme.colorScheme.primary.withOpacity(0.2),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name ?? 'Loading Name...',
                            style: textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Row(
                            children: [
                              Icon(Icons.email_outlined,
                                  size: 18, color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                _email ?? 'No Email',
                                style: textTheme.bodyMedium?.copyWith(
                                  fontStyle: FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            /// 2) A "Client Details" card, read-only
            Card(
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              color: theme.colorScheme.surfaceTint,
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: theme.colorScheme.surface,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Details',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Divider(thickness: 1.2),
                    _buildReadOnlyRow(Icons.person_outline, 'Name', _name),
                    _buildReadOnlyRow(Icons.person, 'Surname', _surname),
                    _buildReadOnlyRow(Icons.phone, 'Phone', _phone),
                    if (_vat != null)
                      _buildReadOnlyRow(Icons.badge, 'VAT/P.IVA', _vat),
                    if (_legalInfo != null)
                      _buildReadOnlyRow(
                          Icons.info_outline, 'Legal Info', _legalInfo),
                    _buildReadOnlyRow(
                      Icons.calendar_today_outlined,
                      'Date of Birth',
                      _dateOfBirth != null
                          ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                          : 'Not available',
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            /// 3) Return button to go back
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.arrow_back,
                  color: Theme.of(context).colorScheme.onPrimary),
              label: Text('Return',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.onPrimary)),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable editable tile with an icon
  Widget _buildEditableListTile({
    required String label,
    required String? value,
    required bool isEditable,
    required IconData icon,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    final theme = Theme.of(context);

    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      subtitle: isEditable
          ? TextField(
              controller: TextEditingController(text: value),
              maxLines: maxLines,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
              ),
              onChanged: onChanged,
            )
          : Text(value ?? 'Not available'),
    );
  }

  /// Non-editable tile for user’s own side
  Widget _buildNonEditableListTile({
    required String label,
    required String value,
    required IconData icon,
  }) {
    final theme = Theme.of(context);
    return ListTile(
      leading: Icon(icon, color: theme.colorScheme.primary),
      title: Text(label),
      subtitle: Text(value),
    );
  }

  /// Simple read-only field for PT side, with optional icon
  Widget _buildReadOnlyRow(IconData icon, String label, String? value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, color: theme.colorScheme.primary),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value ?? 'Not available',
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ),
        ],
      ),
    );
  }
}


// TO USE THE ACCOUNT PROFILE SCRREN AND SETTING USE THIS:

// import 'package:flutter/material.dart';
// import 'account_profile_screen.dart';
// import 'account_settings_screen.dart';

// class AccountScreen extends StatefulWidget {
//   /// If clientUid is non-null, show that client's data (PT view)
//   /// Otherwise, show the logged-in user's account.
//   final String? clientUid;
//   const AccountScreen({Key? key, this.clientUid}) : super(key: key);

//   @override
//   State<AccountScreen> createState() => _AccountScreenState();
// }

// class _AccountScreenState extends State<AccountScreen> {
//   int _selectedTab = 0;

//   final List<Widget> _tabs = [
//     AccountProfileScreen(), // Displays full profile details
//     AccountSettingsScreen(), // Displays settings options (placeholder)
//   ];

//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Account"),
//         centerTitle: true,
//         backgroundColor: theme.colorScheme.primary,
//         iconTheme: IconThemeData(color: theme.colorScheme.onPrimary),
//       ),
//       body: _tabs[_selectedTab],
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedTab,
//         onTap: (index) => setState(() => _selectedTab = index),
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: "Profile",
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.settings),
//             label: "Settings",
//           ),
//         ],
//       ),
//     );
//   }
// }
