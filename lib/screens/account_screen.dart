import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:isyfit/screens/base_screen.dart';
import 'login_screen.dart';

class AccountScreen extends StatefulWidget {
  const AccountScreen({Key? key}) : super(key: key);

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

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        final data = userDoc.data();
        if (data != null) {
          setState(() {
            _name = data['name'];
            _surname = data['surname'];
            _email = user.email ?? 'No Email';
            _phone = data['phone'];
            _vat = data['vat'];
            _legalInfo = data['legalInfo'];
            _dateOfBirth = DateTime.tryParse(data['dateOfBirth'] ?? '');
            _profileImageUrl = data['profileImageUrl'];
          });
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching user data: $e')),
      );
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final file = File(pickedFile.path);
        final user = _auth.currentUser;

        if (user != null) {
          final storageRef =
              _storage.ref().child('profile_images/${user.uid}.jpg');
          await storageRef.putFile(file);

          final downloadUrl = await storageRef.getDownloadURL();
          await _firestore.collection('users').doc(user.uid).update({
            'profileImageUrl': downloadUrl,
          });

          setState(() {
            _profileImageUrl = downloadUrl;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Profile picture updated!')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading profile picture: $e')),
      );
    }
  }

  Future<void> _logout() async {
    await _auth.signOut();
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const BaseScreen()),
    );
  }

  Future<void> _saveChanges() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        await _firestore.collection('users').doc(user.uid).update({
          'name': _name,
          'surname': _surname,
          'phone': _phone,
          if (_vat != null) 'vat': _vat,
          if (_legalInfo != null) 'legalInfo': _legalInfo,
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully!')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving changes: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Account'),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 20),

            // Profile Header with Logout Icon
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
                            'Welcome, ${_name ?? 'Loading...'}',
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
                    IconButton(
                      onPressed: _logout,
                      icon: const Icon(Icons.logout, color: Colors.red),
                    ),
                  ],
                ),
              ),
            ),

            // Account Information
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
                  _buildField(
                    label: 'Name',
                    value: _name,
                    isEditable: _isEditMode,
                    onChanged: (value) => _name = value,
                  ),
                  _buildField(
                    label: 'Surname',
                    value: _surname,
                    isEditable: _isEditMode,
                    onChanged: (value) => _surname = value,
                  ),
                  _buildField(
                    label: 'Phone',
                    value: _phone,
                    isEditable: _isEditMode,
                    onChanged: (value) => _phone = value,
                  ),
                  if (_vat != null)
                    _buildField(
                      label: 'VAT/P.IVA',
                      value: _vat,
                      isEditable: _isEditMode,
                      onChanged: (value) => _vat = value,
                    ),
                  if (_legalInfo != null)
                    _buildField(
                      label: 'Legal Info',
                      value: _legalInfo,
                      isEditable: _isEditMode,
                      maxLines: 3,
                      onChanged: (value) => _legalInfo = value,
                    ),
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
              decoration: const InputDecoration(border: OutlineInputBorder()),
              onChanged: onChanged,
            )
          : Text(value ?? 'Not available'),
    );
  }

  Widget _buildNonEditableField({required String label, required String value}) {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
    );
  }
}
