import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import '../services/firestore_service.dart';
import 'feed/feed_screen.dart';
import 'swipe_screen.dart'; 
import 'discovery/discovery_screen.dart';
import 'chat/chat_list_screen.dart';
import 'home_profile_tab.dart';
import 'call/call_screen.dart';

/// ══════════════════════════════════════════════════════════════
/// HomeScreen — Shell chính với 5 tabs (Threads | Hẹn hò | Khám phá | Nhắn tin | Hồ sơ)
/// ══════════════════════════════════════════════════════════════
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  int _unreadNotifs = 0;
  int _unreadMessages = 0;
  StreamSubscription? _callSub;
  StreamSubscription? _notifSub;
  StreamSubscription? _msgSub;

  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';

  final List<Widget> _screens = [
    const FeedScreen(),      // Tab 0: Trang chủ (Threads)
    SwipeScreen(),           // Tab 1: Hẹn hò (Swipe)
    const DiscoveryScreen(), // Tab 2: Khám phá
    const ChatListScreen(),  // Tab 3: Nhắn tin
    const HomeProfileTab(),  // Tab 4: Hồ sơ
  ];

  @override
  void initState() {
    super.initState();
    _updateOnlineStatus(true);
    _listenIncomingCalls();
    _listenUnreadCounts();
  }

  @override
  void dispose() {
    _callSub?.cancel();
    _notifSub?.cancel();
    _msgSub?.cancel();
    _updateOnlineStatus(false);
    super.dispose();
  }

  void _updateOnlineStatus(bool online) {
    if (_uid.isEmpty) return;
    FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(_uid).update({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  void _listenIncomingCalls() {
    _callSub = FirestoreService.incomingCallStream().listen((snap) {
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final callerId = d['callerId'] as String;
        if (callerId == _uid) continue;
        _fetchCallerAndShow(doc.id, callerId, d['type'] as String? ?? 'voice');
      }
    });
  }

  Future<void> _fetchCallerAndShow(String callId, String callerId, String type) async {
    final caller = await FirestoreService.getUser(callerId);
    if (caller == null || !mounted) return;

    Get.dialog(
      Align(
        alignment: Alignment.topCenter,
        child: Material(
          color: Colors.transparent,
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: IncomingCallBanner(
                callerName: caller.name,
                callerPhoto: caller.photoUrl.isNotEmpty ? caller.photoUrl : null,
                isVideo: type == 'video',
                onAccept: () {
                  Get.back();
                  Get.to(() => CallScreen(
                    callId: callId,
                    otherUserId: callerId,
                    otherUserName: caller.name,
                    otherUserPhotoUrl: caller.photoUrl,
                    isVideo: type == 'video',
                    isIncoming: true,
                  ));
                },
                onDecline: () {
                  Get.back();
                  FirestoreService.updateCallStatus(callId, 'rejected');
                },
              ),
            ),
          ),
        ),
      ),
      barrierDismissible: false,
      barrierColor: Colors.transparent,
    );
  }

  void _listenUnreadCounts() {
    _notifSub = FirebaseFirestore.instance
        .collection(AppConstants.colNotifications)
        .where('userId', isEqualTo: _uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) {
      if (mounted) setState(() => _unreadNotifs = snap.docs.length);
    });

    _msgSub = FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: _uid)
        .snapshots()
        .listen((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final count = (d['unreadCount'] as Map?)?.entries
            .where((e) => e.key == _uid)
            .map((e) => (e.value as num).toInt())
            .fold<int>(0, (a, b) => a + b) ?? 0;
        total += count;
      }
      if (mounted) setState(() => _unreadMessages = total);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 15, offset: const Offset(0, -4),
        )],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _navItem(0, Icons.home_rounded, Icons.home_outlined, 'Trang chủ'),
              _navItem(1, Icons.favorite_rounded, Icons.favorite_outline_rounded, 'Hẹn hò'), // ✅ Đổi Vút thành Hẹn hò
              _navItem(2, Icons.explore_rounded, Icons.explore_outlined, 'Khám phá'),
              _navItemWithBadge(3, Icons.chat_bubble_rounded, Icons.chat_bubble_outline_rounded, 'Tin nhắn', _unreadMessages),
              _navItemWithBadge(4, Icons.person_rounded, Icons.person_outline_rounded, 'Hồ sơ', _unreadNotifs, badgeColor: Colors.blue),
            ],
          ),
        ),
      ),
    );
  }

  Widget _navItem(int index, IconData active, IconData inactive, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(isSelected ? active : inactive, color: isSelected ? AppColors.primary : Colors.grey.shade400, size: 24),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
            )),
          ]),
        ),
      ),
    );
  }

  Widget _navItemWithBadge(int index, IconData active, IconData inactive,
      String label, int count, {Color badgeColor = AppColors.primary}) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        setState(() => _currentIndex = index);
      },
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: AnimatedScale(
          scale: isSelected ? 1.12 : 1.0,
          duration: const Duration(milliseconds: 300),
          curve: Curves.elasticOut,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Stack(clipBehavior: Clip.none, children: [
              Icon(isSelected ? active : inactive, color: isSelected ? AppColors.primary : Colors.grey.shade400, size: 24),
              if (count > 0)
                Positioned(
                  top: -4, right: -8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                    decoration: BoxDecoration(
                      color: badgeColor,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white, width: 1),
                    ),
                    child: Text(
                      count > 99 ? '99+' : '$count',
                      style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.w800),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
              fontSize: 9,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
              color: isSelected ? AppColors.primary : Colors.grey.shade400,
            )),
          ]),
        ),
      ),
    );
  }
}
