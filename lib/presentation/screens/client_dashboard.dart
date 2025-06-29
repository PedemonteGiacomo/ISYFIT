import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:isyfit/presentation/screens/login_screen.dart';
import 'package:isyfit/presentation/widgets/gradient_app_bar.dart';
import 'package:isyfit/data/services/notification_service.dart';
import 'notifications/client_notifications_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ClientDashboard extends StatefulWidget {
  const ClientDashboard({Key? key}) : super(key: key);

  @override
  State<ClientDashboard> createState() => _ClientDashboardState();
}

class _ClientDashboardState extends State<ClientDashboard> {
  StreamSubscription<DocumentSnapshot>? _sub;
  int _unread = 0;
  int? _lastNotifiedMs;

  Future<void> _loadLastNotified(String uid) async {
    final prefs = await SharedPreferences.getInstance();
    _lastNotifiedMs = prefs.getInt('last_notif_$uid');
  }

  Future<void> _saveLastNotified(String uid, int tsMs) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('last_notif_$uid', tsMs);
  }

  int? _latestTimestamp(List<Map<String, dynamic>> notifs) {
    int? latest;
    for (final n in notifs) {
      final ts = (n['timestamp'] as Timestamp?)?.millisecondsSinceEpoch;
      if (ts != null && (latest == null || ts > latest)) {
        latest = ts;
      }
    }
    return latest;
  }

  @override
  void initState() {
    super.initState();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      _setupNotifications(user.uid);
    }
  }

  Future<void> _setupNotifications(String uid) async {
    await _loadLastNotified(uid);
    _sub = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((doc) {
      final data = doc.data() as Map<String, dynamic>? ?? {};
      final notifs =
          List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      final count = notifs.where((n) => n['read'] == false).length;
      final latest = _latestTimestamp(notifs);
      if (latest != null &&
          (_lastNotifiedMs == null || latest > _lastNotifiedMs!)) {
        NotificationService.instance.showNotification(
          title: 'Nuova notifica',
          body: 'Il tuo PT ha aggiornato le notifiche',
          target: NotificationTarget.client,
        );
        _lastNotifiedMs = latest;
        _saveLastNotified(uid, latest);
      }
      setState(() => _unread = count);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final User? user = FirebaseAuth.instance.currentUser;

    // If no user is signed in, immediately return LoginScreen
    if (user == null) {
      return LoginScreen();
    }

    return Scaffold(
      appBar: GradientAppBar(
        title: 'Client Dashboard',
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ClientNotificationsScreen(clientId: user.uid),
                ),
              );
            },
            icon: Stack(
              children: [
                const Icon(Icons.notifications),
                if (_unread > 0)
                  Positioned(
                    right: 0,
                    top: 0,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
          )
        ],
      ),
      body: SafeArea(
        child: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data == null) {
              return Center(
                child: Text(
                  'No data found.',
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>?;

            if (userData == null) {
              return Center(
                child: Text(
                  'No data found.',
                  style: theme.textTheme.bodyLarge,
                ),
              );
            }

            final bool isSolo = userData['isSolo'] == true;
            final String? reqStatus = userData['requestStatus'] as String?;
            final String? requestedPt = userData['requestedPT'] as String?;
            if (isSolo) {
              return Column(
                children: [
                  if (reqStatus != null)
                    _buildRequestStatusCard(reqStatus, requestedPt),
                  _buildSoloCard(context),
                ],
              );
            } else {
              final ptId = userData['supervisorPT'];
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(ptId)
                    .get(),
                builder: (context, ptSnapshot) {
                  if (ptSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (!ptSnapshot.hasData || ptSnapshot.data == null) {
                    return Center(
                      child: Text(
                        'PT information not available.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }

                  final ptData =
                      ptSnapshot.data!.data() as Map<String, dynamic>?;
                  if (ptData == null) {
                    return Center(
                      child: Text(
                        'PT information not available.',
                        style: theme.textTheme.bodyLarge,
                      ),
                    );
                  }
                  return _buildPtCard(context, ptData);
                },
              );
            }
          },
        ),
      ),
    );
  }

  /// Shows a Card indicating the user is in SOLO mode
  Widget _buildSoloCard(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final cardWidth =
        (isPortrait ? size.width * 0.8 : size.width * 0.5).clamp(280.0, 420.0);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Card(
          elevation: 3,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.person_outline,
                    size: 60, color: theme.colorScheme.primary),
                const SizedBox(height: 16),
                Text(
                  'SOLO Mode',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are currently training on your own. Explore the app’s features to manage your fitness journey independently.',
                  style: theme.textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRequestStatusCard(String status, String? ptId) {
    final theme = Theme.of(context);
    IconData icon;
    Color color;
    String text;
    String? ptEmail;
    if (ptId != null) {
      FirebaseFirestore.instance
          .collection('users')
          .doc(ptId)
          .get()
          .then((doc) {
        setState(() {
          ptEmail = doc.data()?['email'];
        });
      });
    }
    if (status == 'pending') {
      icon = Icons.hourglass_top;
      color = Colors.orange;
      text = ptEmail != null
          ? 'Awaiting approval from \$ptEmail'
          : 'Link request pending approval.';
    } else {
      icon = Icons.cancel;
      color = theme.colorScheme.error;
      text = ptEmail != null
          ? 'Request to \$ptEmail was rejected. You can send a new one from the Account screen.'
          : 'Link request rejected. You can send a new request from the Account screen.';
    }
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Builds a card displaying the assigned PT’s details
  Widget _buildPtCard(BuildContext context, Map<String, dynamic> ptData) {
    final theme = Theme.of(context);
    final String? ptImageUrl = ptData['profileImageUrl'];
    final size = MediaQuery.of(context).size;
    final isPortrait =
        MediaQuery.of(context).orientation == Orientation.portrait;
    final cardWidth = (isPortrait ? size.width * 0.85 : size.width * 0.55)
        .clamp(300.0, 450.0);

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Card(
          elevation: 4,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Container(
            width: cardWidth,
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Your Personal Trainer',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                CircleAvatar(
                  radius: 50,
                  backgroundColor: theme.colorScheme.primary.withOpacity(0.2),
                  backgroundImage: (ptImageUrl != null && ptImageUrl.isNotEmpty)
                      ? NetworkImage(ptImageUrl)
                      : null,
                  child: (ptImageUrl == null || ptImageUrl.isEmpty)
                      ? Icon(
                          Icons.person,
                          size: 50,
                          color: theme.colorScheme.primary,
                        )
                      : null,
                ),
                const SizedBox(height: 16),
                Text(
                  '${ptData['name']} ${ptData['surname']}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  ptData['email'] ?? '',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),

                // Example: a button for contacting the PT, if you want
                // FilledButton.icon(
                //   onPressed: () {
                //     // Could open a chat or email
                //   },
                //   icon: const Icon(Icons.email_outlined),
                //   label: const Text('Contact PT'),
                //   style: FilledButton.styleFrom(
                //     backgroundColor: theme.colorScheme.primary,
                //     foregroundColor: theme.colorScheme.onPrimary,
                //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
