import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../services/user_repository.dart';
import '../../../theme/app_gradients.dart';

// Our 3 tabs (each is a separate file, see below)
import 'photo_insert_screen.dart';
import 'photo_collection_screen.dart';
import 'photo_comparison_screen.dart';

/// PhotoHomeScreen is a StatefulWidget that uses a FutureBuilder to check if user is PT.
/// Then it builds [PhotoHomeScreenWithTabs] so we only create the TabController once
/// and preserve state when switching tabs.
class PhotoHomeScreen extends StatefulWidget {
  final String clientUid;
  const PhotoHomeScreen({Key? key, required this.clientUid}) : super(key: key);

  @override
  State<PhotoHomeScreen> createState() => _PhotoHomeScreenState();
}

class _PhotoHomeScreenState extends State<PhotoHomeScreen> {
  final UserRepository _userRepo = UserRepository();
  late Future<bool> _isPTFuture;
  late Future<Map<String, dynamic>?> _clientProfileFuture;

  /// If currentUser.uid != widget.clientUid => means a PT is viewing
  bool get isPTView {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return false;
    return currentUser.uid != widget.clientUid;
  }

  @override
  void initState() {
    super.initState();
    _isPTFuture = _fetchIsPT();
    // We'll fetch client profile if a PT is viewing them
    _clientProfileFuture =
        isPTView ? _fetchClientProfile() : Future.value(null);
  }

  Future<bool> _fetchIsPT() => _userRepo.isCurrentUserPT();

  Future<Map<String, dynamic>?> _fetchClientProfile() =>
      _userRepo.fetchUserProfile(widget.clientUid);

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _isPTFuture,
      builder: (ctx, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        final isPT = snapshot.data ?? false;

        return PhotoHomeScreenWithTabs(
          clientUid: widget.clientUid,
          isPT: isPT,
          isPTView: isPTView,
          clientProfileFuture: _clientProfileFuture,
        );
      },
    );
  }
}

/// This widget is built AFTER we know if user is PT, so we can create the TabController
/// with the correct number of tabs (2 or 3). We also attach the row for the name
/// directly above the TabBar, so there's no gap, and the TabBar is fully wide.
class PhotoHomeScreenWithTabs extends StatefulWidget {
  final String clientUid;
  final bool isPT;
  final bool isPTView;
  final Future<Map<String, dynamic>?> clientProfileFuture;

  const PhotoHomeScreenWithTabs({
    Key? key,
    required this.clientUid,
    required this.isPT,
    required this.isPTView,
    required this.clientProfileFuture,
  }) : super(key: key);

  @override
  State<PhotoHomeScreenWithTabs> createState() =>
      _PhotoHomeScreenWithTabsState();
}

class _PhotoHomeScreenWithTabsState extends State<PhotoHomeScreenWithTabs>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late int _tabCount;

  @override
  void initState() {
    super.initState();
    _tabCount = widget.isPT ? 3 : 2;
    _tabController = TabController(length: _tabCount, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  /// Build the row with the client name or "Your Photos", then the full-width TabBar
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // A Container for the gradient tab bar (full width, no margin)
          Container(
            width: double.infinity, // ensure it's full width
            decoration: BoxDecoration(
              gradient: AppGradients.primary(Theme.of(context)),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              indicatorWeight: 3,
              labelColor: Theme.of(context).colorScheme.onPrimary,
              unselectedLabelColor:
                  Theme.of(context).colorScheme.onPrimary.withOpacity(0.7),

              /// Now we use more "Material-like" icons for each tab:
              tabs: _buildTabs(),
            ),
          ),

          // The row with name or "Your Photos", no vertical gap
          _buildNameRow(),

          // The tab views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: _buildTabViews(),
            ),
          ),
        ],
      ),
    );
  }

  /// The row with either "Your Photos" or "Name Surname (Email)" if PT
  Widget _buildNameRow() {
    if (!widget.isPTView) {
      // Not PT => "Your Photos"
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        width: double.infinity,
        color: Colors.white,
        child: Center(
          child: Text(
            'Your Photos',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
        ),
      );
    } else {
      // We are PT => show name & email
      return FutureBuilder<Map<String, dynamic>?>(
        future: widget.clientProfileFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const SizedBox.shrink();
          }
          final data = snap.data;
          if (data == null) {
            return Container(
              padding: const EdgeInsets.symmetric(vertical: 8),
              width: double.infinity,
              color: Colors.white,
              child: const Center(
                child: Text(
                  'Unknown Client',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }
          final name = data['name'] ?? '';
          final surname = data['surname'] ?? '';
          final email = data['email'] ?? '';
          return Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Center(
              child: Text(
                '$name $surname ($email)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          );
        },
      );
    }
  }

  /// The 2 or 3 tabs, each with a Material-oriented icon
  List<Widget> _buildTabs() {
    final onPrimary = Theme.of(context).colorScheme.onPrimary;
    if (widget.isPT) {
      return [
        Tab(
          icon: Icon(Icons.camera_alt, color: onPrimary),
          text: "Insert",
        ),
        Tab(
          icon: Icon(Icons.photo_library, color: onPrimary),
          text: "Collection",
        ),
        Tab(
          icon: Icon(Icons.compare_arrows, color: onPrimary),
          text: "Comparison",
        ),
      ];
    } else {
      return [
        Tab(
          icon: Icon(Icons.photo_library, color: onPrimary),
          text: "Collection",
        ),
        Tab(
          icon: Icon(Icons.compare_arrows, color: onPrimary),
          text: "Comparison",
        ),
      ];
    }
  }

  /// Each tab is a stateful widget with AutomaticKeepAlive, so we don't lose state
  List<Widget> _buildTabViews() {
    if (widget.isPT) {
      return [
        PhotoInsertTab(
          key: const PageStorageKey('photo_insert_tab'), // preserve
          clientUid: widget.clientUid,
        ),
        PhotoCollectionTab(
          key: const PageStorageKey('photo_collection_tab'),
          clientUid: widget.clientUid,
        ),
        PhotoComparisonTab(
          key: const PageStorageKey('photo_comparison_tab'),
          clientUid: widget.clientUid,
        ),
      ];
    } else {
      return [
        PhotoCollectionTab(
          key: const PageStorageKey('photo_collection_tab'),
          clientUid: widget.clientUid,
        ),
        PhotoComparisonTab(
          key: const PageStorageKey('photo_comparison_tab'),
          clientUid: widget.clientUid,
        ),
      ];
    }
  }
}
