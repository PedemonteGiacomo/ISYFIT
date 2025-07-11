import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/presentation/screens/base_screen.dart';
import 'package:isyfit/presentation/screens/measurements/measurements_home_screen.dart';
import 'package:isyfit/presentation/screens/isy_lab/pt_clients_measurements_list_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/presentation/screens/isy_lab/photo_section/photo_home_screen.dart';

/// The main IsyLab “entry point”.
/// 1) If clientUid is provided => show that client’s normal 3-tab lab screen
/// 2) Otherwise, if user is PT => show the PT’s client list for IsyLab
/// 3) Otherwise => show the user’s own 3-tab lab screen
class IsyLabMainScreen extends StatefulWidget {
  final String? clientUid;
  const IsyLabMainScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<IsyLabMainScreen> createState() => _IsyLabMainScreenState();
}

class _IsyLabMainScreenState extends State<IsyLabMainScreen> {
  late Future<bool> _isPTFuture;
  late String? _clientUid;

  @override
  void initState() {
    super.initState();
    _clientUid = widget.clientUid;
    _isPTFuture = _fetchIsPT();
  }

  Future<bool> _fetchIsPT() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;
    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    final data = docSnap.data() ?? {};
    return (data['role'] == 'PT');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isPTFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final isPT = snapshot.data ?? false;

        // 1) If we have a clientUid => show that client's 3-tab IsyLab
        if (_clientUid != null) {
          return _IsyLabTwoTabScreen(clientUid: _clientUid);
        }
        // 2) If user is not PT => show *own* 3-tab IsyLab
        if (!isPT) {
          return _IsyLabTwoTabScreen(clientUid: null);
        }
        // 3) Otherwise user is PT => show PT clients list
        return const PTClientsIsyLabListScreen();
      },
    );
  }
}

/// The normal 2-tab screen for IsyLab
/// We embed it in a separate widget for clarity
class _IsyLabTwoTabScreen extends StatefulWidget {
  final String? clientUid;
  const _IsyLabTwoTabScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<_IsyLabTwoTabScreen> createState() => _IsyLabTwoTabScreenState();
}

class _IsyLabTwoTabScreenState extends State<_IsyLabTwoTabScreen> {
  late Future<String> _userDisplayNameFuture;

  @override
  void initState() {
    super.initState();
    final String actualClientUid =
        widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    _userDisplayNameFuture = _fetchUserDisplayName(actualClientUid);
  }

  Future<String> _fetchUserDisplayName(String uid) async {
    try {
      final docSnap = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();
      final data = docSnap.data();
      
      if (data == null) return 'Unknown User';
      
      final name = data['name']?.toString().trim() ?? '';
      final surname = data['surname']?.toString().trim() ?? '';
      
      // Priorità 1: Nome e Cognome
      if (name.isNotEmpty && surname.isNotEmpty) {
        return '$name $surname';
      }
      
      // Priorità 2: Solo nome o solo cognome se uno dei due c'è
      if (name.isNotEmpty) {
        return name;
      }
      if (surname.isNotEmpty) {
        return surname;
      }
      
      // Priorità 3: Email come fallback
      final email = data['email']?.toString().trim() ?? '';
      if (email.isNotEmpty) {
        return email;
      }
      
      // Priorità 4: Fallback finale
      return 'Unknown User';
    } catch (e) {
      return 'Unknown User';
    }
  }

  @override
  Widget build(BuildContext context) {
    final String actualClientUid =
        widget.clientUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    
    return FutureBuilder<String>(
      future: _userDisplayNameFuture,
      builder: (context, snapshot) {
        final displayName = snapshot.data ?? 'Loading...';
        
        return DefaultTabController(
          length: 2, // Changed from 3 to 2
          initialIndex: 1, // If you want "Measurements" as default
          child: Scaffold(
            bottomNavigationBar: const TabBar(
              tabs: [
                Tab(icon: Icon(Icons.photo_camera), text: "Photo"),
                Tab(
                    icon: Icon(Icons.monitor_weight_outlined),
                    text: "Measurements"),
                // Removed bodyfat tab
              ],
              labelColor: Colors.blue,
              unselectedLabelColor: Colors.grey,
            ),
            appBar: GradientAppBar(
              title: "IsyLab - $displayName",
              actions: [
                IconButton(
                  icon: Icon(Icons.home,
                      color: Theme.of(context).colorScheme.onPrimary),
                  onPressed: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const BaseScreen()),
                    );
                  },
                ),
              ],
            ),
            body: TabBarView(
              children: [
                PhotoHomeScreen(clientUid: actualClientUid),
                MeasurementsHomeScreen(clientUid: actualClientUid),
                // Removed bodyfat widget
              ],
            ),
          ),
        );
      },
    );
  }
}
