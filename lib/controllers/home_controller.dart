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
import '../screens/home_profile_tab.dart';
import '../screens/call/call_screen.dart';
import '../widgets/incoming_call_banner.dart';

class HomeController extends GetxController {
  static HomeController get to => Get.find();

  // -- States --
  final RxInt currentIndex = 0.obs;
  final RxInt unreadNotifs = 0.obs;
  final RxInt unreadMessages = 0.obs;

  final List<Widget> screens = [
    const FeedScreen(),
    const SwipeScreen(),
    const DiscoveryScreen(),
    const ChatListScreen(),
    const HomeProfileTab(),
  ];

  StreamSubscription? _callSub;
  StreamSubscription? _notifSub;
  StreamSubscription? _msgSub;

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
    FirebaseFirestore.instance.collection(AppConstants.colUsers).doc(uid).update({
      'isOnline': online,
      'lastSeen': FieldValue.serverTimestamp(),
    }).catchError((_) {});
  }

  void _listenIncomingCalls() {
    _callSub = FirestoreService.incomingCallStream().listen((snap) {
      for (final doc in snap.docs) {
        final d = doc.data() as Map<String, dynamic>;
        final callerId = d['callerId'] as String;
        if (callerId == uid) continue;
        _showCallDialog(doc.id, callerId, d['type'] as String? ?? 'voice');
      }
    });
  }

  Future<void> _showCallDialog(String callId, String callerId, String type) async {
    final caller = await FirestoreService.getUser(callerId);
    if (caller == null) return;
    
    Get.dialog(
      IncomingCallBanner(
        caller: caller,
        callId: callId,
        isVideo: type == 'video',
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
