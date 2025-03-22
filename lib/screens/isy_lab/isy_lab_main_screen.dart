import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:isyfit/screens/measurements/measurements_home_screen.dart';
import 'package:isyfit/screens/isy_lab/pt_clients_measurements_list_screen.dart';
import 'package:isyfit/widgets/gradient_app_bar.dart';

/// The main isy-lab “entry point”.
/// 1) If clientUid is provided => show that client’s normal 3-tab lab screen
/// 2) Otherwise, if user is PT => show the PT’s client list for isy-lab
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

        // 1) If we have a clientUid => show that client's 3-tab isy-lab
        if (_clientUid != null) {
          return _IsyLabThreeTabScreen(clientUid: _clientUid);
        }
        // 2) If user is not PT => show *own* 3-tab isy-lab
        if (!isPT) {
          return _IsyLabThreeTabScreen(clientUid: null); 
        }
        // 3) Otherwise user is PT => show PT clients list
        return const PTClientsIsyLabListScreen();
      },
    );
  }
}

/// The normal 3-tab screen for isy-lab
/// We embed it in a separate widget for clarity
class _IsyLabThreeTabScreen extends StatelessWidget {
  final String? clientUid;
  const _IsyLabThreeTabScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final String actualClientUid = clientUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
    return DefaultTabController(
      length: 3,
      initialIndex: 1, // If you want "Measurements" as default
      child: Scaffold(
        bottomNavigationBar: const TabBar(
          tabs: [
            Tab(icon: Icon(Icons.photo_camera), text: "Photo"),
            Tab(icon: Icon(Icons.monitor_weight_outlined), text: "Measurements"),
            Tab(icon: Icon(Icons.insights_outlined), text: "Bodyfat"),
          ],
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
        ),
        appBar: GradientAppBar(
          title: "isy-lab",
        ),
        body: TabBarView(
          children: [
            Center(child: Text("Photo Screen")),
            MeasurementsHomeScreen(clientUid: actualClientUid),
            Center(child: Text("Bodyfat Comparison Screen")),
          ],
        ),
      ),
    );
  }
}
