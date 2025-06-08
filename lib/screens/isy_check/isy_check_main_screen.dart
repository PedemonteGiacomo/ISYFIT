import 'package:flutter/material.dart';
import '../../services/user_repository.dart';

// Import your existing MedicalHistoryScreen
import 'package:isyfit/screens/medical_history/anamnesis_screen.dart';
// Import the PT clients list screen from the separate file
import 'package:isyfit/screens/isy_check/pt_clients_medical_list_screen.dart';

class IsyCheckMainScreen extends StatefulWidget {
  final String? clientUid;
  const IsyCheckMainScreen({Key? key, this.clientUid}) : super(key: key);

  @override
  State<IsyCheckMainScreen> createState() => _IsyCheckMainScreenState();
}

class _IsyCheckMainScreenState extends State<IsyCheckMainScreen> {
  final UserRepository _userRepo = UserRepository();
  late Future<bool> _isPTFuture;
  late String? _clientUid;

  @override
  void initState() {
    super.initState();
    _clientUid = widget.clientUid;
    _isPTFuture = _fetchIsPT();
  }

  Future<bool> _fetchIsPT() => _userRepo.isCurrentUserPT();

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

        // 1) If we have a clientUid => show that client’s medical data
        if (_clientUid != null) {
          return MedicalHistoryScreen(clientUid: _clientUid);
        }

        // 2) If user is not PT => show *own* MedicalHistoryScreen
        if (!isPT) {
          return MedicalHistoryScreen(clientUid: null);
        }

        // 3) Otherwise user is PT and no clientUid => show PT clients list
        return const PTClientsMedicalListScreen();
      },
    );
  }
}
