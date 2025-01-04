import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'package:isyfit/screens/login_screen.dart';

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
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BaseScreen()),
    );
  }

  /// Save changes to Firestore
  Future<void> _saveChanges() async {
    try {
      final uid = targetUid;
      if (uid == null) return;

      if (!isOwnAccount) {
        // PT editing client’s info is disabled (or you can allow it, your choice)
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
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Theme.of(context).primaryColor,
        actions: [
          // Show logout icon only if it's the user’s own account
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: _logout,
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Profile Header with editing capabilities
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Avatar with ability to tap and upload
                    GestureDetector(
                      onTap: _uploadProfilePicture,
                      child: CircleAvatar(
                        radius: 50,
                        backgroundImage: _profileImageUrl != null
                            ? NetworkImage(_profileImageUrl!)
                            : const AssetImage('assets/avatar_placeholder.png')
                                as ImageProvider,
                        backgroundColor: Colors.grey[200],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _name != null
                                ? '$_name' + (_surname != null ? ' $_surname' : '')
                                : 'Welcome, Loading...',
                            style: textTheme.headlineSmall,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _email ?? 'No Email',
                            style: textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Account Information card
            Card(
              elevation: 4,
              margin: const EdgeInsets.all(16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Column(
                children: [
                  ListTile(
                    title: Text(
                      'Account Information',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: IconButton(
                      icon: Icon(_isEditMode ? Icons.check : Icons.edit),
                      onPressed: () {
                        if (_isEditMode) {
                          _saveChanges();
                        }
                        setState(() {
                          _isEditMode = !_isEditMode;
                        });
                      },
                    ),
                  ),
                  const Divider(),

                  // Name
                  _buildField(
                    label: 'Name',
                    value: _name,
                    isEditable: _isEditMode,
                    onChanged: (value) => _name = value,
                  ),

                  // Surname
                  _buildField(
                    label: 'Surname',
                    value: _surname,
                    isEditable: _isEditMode,
                    onChanged: (value) => _surname = value,
                  ),

                  // Phone
                  _buildField(
                    label: 'Phone',
                    value: _phone,
                    isEditable: _isEditMode,
                    onChanged: (value) => _phone = value,
                  ),

                  // VAT/P.IVA (only if present)
                  if (_vat != null)
                    _buildField(
                      label: 'VAT/P.IVA',
                      value: _vat,
                      isEditable: _isEditMode,
                      onChanged: (value) => _vat = value,
                    ),

                  // Legal Info (if present)
                  if (_legalInfo != null)
                    _buildField(
                      label: 'Legal Info',
                      value: _legalInfo,
                      isEditable: _isEditMode,
                      maxLines: 3,
                      onChanged: (value) => _legalInfo = value,
                    ),

                  // Date of Birth (non-editable for now)
                  _buildNonEditableField(
                    label: 'Date of Birth',
                    value: _dateOfBirth != null
                        ? '${_dateOfBirth!.day}/${_dateOfBirth!.month}/${_dateOfBirth!.year}'
                        : 'Not available',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Layout if a PT is viewing a client’s account – a different representation
  Widget _buildPtViewingClientLayout(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Account'),
        centerTitle: true,
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // A bigger "profile" card showing the client’s info in a read-only style
            Card(
              elevation: 4,
              margin: const EdgeInsets.only(bottom: 16.0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: Colors.deepPurple.shade50,
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _profileImageUrl != null
                          ? NetworkImage(_profileImageUrl!)
                          : const AssetImage('assets/avatar_placeholder.png')
                              as ImageProvider,
                      backgroundColor: Colors.deepPurple.shade100,
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
                              color: Colors.deepPurple.shade700,
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _email ?? 'No Email',
                            style: textTheme.bodyMedium?.copyWith(
                              color: Colors.deepPurple.shade400,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Another card with basic account info in a read-only format
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  color: Colors.white,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Client Details',
                      style: textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const Divider(thickness: 1.2),

                    _buildReadOnlyRow('Name', _name),
                    _buildReadOnlyRow('Surname', _surname),
                    _buildReadOnlyRow('Phone', _phone),
                    if (_vat != null) _buildReadOnlyRow('VAT/P.IVA', _vat),
                    if (_legalInfo != null) _buildReadOnlyRow('Legal Info', _legalInfo),
                    _buildReadOnlyRow(
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

            // If you want a "Return" button or something else:
            ElevatedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              label: const Text('Return'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Reusable editable field
  Widget _buildField({
    required String label,
    required String? value,
    required bool isEditable,
    required ValueChanged<String> onChanged,
    int maxLines = 1,
  }) {
    return ListTile(
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

  /// Simple read-only field for the PT side
  Widget _buildReadOnlyRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          SizedBox(width: 120, child: Text(label, style: const TextStyle(fontWeight: FontWeight.bold))),
          const SizedBox(width: 8),
          Expanded(child: Text(value ?? 'Not available')),
        ],
      ),
    );
  }

  /// Non-editable field for user’s own side
  Widget _buildNonEditableField({
    required String label,
    required String value,
  }) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
