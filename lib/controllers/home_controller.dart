import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';
import '../screens/feed/feed_screen.dart';
import '../screens/swipe_screen.dart';
import '../screens/discovery/discovery_screen.dart';
import '../screens/chat/chat_list_screen.dart';
import '../screens/settings_screen.dart';
import '../widgets/incoming_call_banner.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  final RxInt currentIndex = 0.obs;
  final RxInt unreadNotifs = 0.obs;
  final RxInt unreadMessages = 0.obs;

  // Tab 4 giờ là SettingsScreen thay vì HomeProfileTab
  final List<Widget> screens = [
    const FeedScreen(),
    const DiscoveryScreen(),
    const SwipeScreen(),
    const ChatListScreen(),
    const SettingsScreen(),
  ];

  StreamSubscription? _callSub;
  StreamSubscription? _notifSub;
  StreamSubscription? _msgSub;

  // Track call IDs đã hiển thị để tránh duplicate dialog
  final Set<String> _shownCallIds = {};

  String get uid => AuthController.to.currentUid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (uid.isNotEmpty) {
      updateOnlineStatus(true);
      _listenIncomingCalls();
      _listenUnreadCounts();
    }
  }

  @override
  void onClose() {
    _callSub?.cancel();
    _notifSub?.cancel();
    _msgSub?.cancel();
    updateOnlineStatus(false);
    super.onClose();
  }

  void changeTab(int index) => currentIndex.value = index;

  void updateOnlineStatus(bool online) {
    if (uid.isEmpty) return;
    FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(uid)
        .update({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  void _listenIncomingCalls() {
    _callSub = FirestoreService.incomingCallStream().listen((snap) {
      // FIX Bug 2: dọn _shownCallIds khi quá lớn để tránh memory leak
      if (_shownCallIds.length > 50) _shownCallIds.clear();

      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final callerId = d['callerId'] as String? ?? '';
        final callId = doc.id;

        if (callerId == uid) continue;
        if (_shownCallIds.contains(callId)) continue;

        _shownCallIds.add(callId);
        _showCallDialog(callId, callerId, d['type'] as String? ?? 'voice');
      }
    });
  }

  Future<void> _showCallDialog(String callId, String callerId, String type) async {
    final caller = await FirestoreService.getUser(callerId);
    if (caller == null) return;

    // Kiểm tra xem call còn 'ringing' không trước khi hiển thị
    final callDoc = await FirebaseFirestore.instance
        .collection(AppConstants.colCalls)
        .doc(callId)
        .get();
    if (!callDoc.exists) return;
    final callData = callDoc.data() as Map<String, dynamic>;
    final status = callData['status'];
    if (status != 'ringing') return;

    // Lấy conversationId từ call document để ghi lịch sử sau cuộc gọi
    final conversationId = callData['conversationId'] as String? ?? '';

    Get.dialog(
      IncomingCallBanner(
        caller: caller,
        callId: callId,
        isVideo: type == 'video',
        conversationId: conversationId,
        onDismissed: () => _shownCallIds.remove(callId),
      ),
      barrierDismissible: false,
    );
  }

  void _listenUnreadCounts() {
    if (uid.isEmpty) return;

    _notifSub = FirebaseFirestore.instance
        .collection(AppConstants.colNotifications)
        .where('userId', isEqualTo: uid)
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((snap) => unreadNotifs.value = snap.docs.length);

    _msgSub = FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: uid)
        .snapshots()
        .listen((snap) {
      int total = 0;
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final count = (d['unreadCount'] as Map?)?[uid] ?? 0;
        total += (count as num).toInt();
      }
      unreadMessages.value = total;
    });
  }
}