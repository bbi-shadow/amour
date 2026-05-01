import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

class ChatDetailController extends GetxController {
  final String conversationId;
  final String otherUserId;

  ChatDetailController({required this.conversationId, required this.otherUserId});

  static ChatDetailController get to => Get.find();

  // ── States (Reactive) ──────────────────────────────────────
  final RxList<MessageModel> messages = <MessageModel>[].obs; 
  final Rx<UserModel?> otherUser = Rx<UserModel?>(null);
  final RxBool isOtherTyping = false.obs;
  final RxBool isSending = false.obs;
  final RxString replyToText = ''.obs;

  StreamSubscription? _msgSub;
  StreamSubscription? _otherUserSub;
  StreamSubscription? _typingSub;
  Timer? _typingTimer;

  String get myId => AuthController.to.currentUid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (conversationId.isNotEmpty && otherUserId.isNotEmpty) {
      _listenOtherUser();
      _listenMessages();
      _listenTyping();
      resetUnread();
    }
  }

  @override
  void onClose() {
    _msgSub?.cancel();
    _otherUserSub?.cancel();
    _typingSub?.cancel();
    _typingTimer?.cancel();
    setTyping(false);
    super.onClose();
  }

  void _listenOtherUser() {
    _otherUserSub = FirebaseFirestore.instance
        .collection(AppConstants.colUsers)
        .doc(otherUserId)
        .snapshots()
        .listen((snap) {
      if (snap.exists) {
        otherUser.value = UserModel.fromFirestore(snap);
      }
    });
  }

  void _listenMessages() {
    _msgSub = FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .collection(AppConstants.colMessages)
        .orderBy('timestamp', descending: false)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) => MessageModel.fromFirestore(d)).toList();
      messages.assignAll(list);
      _markIncomingAsSeen(snap.docs);
    });
  }

  void _markIncomingAsSeen(List<QueryDocumentSnapshot> docs) {
    if (myId.isEmpty) return;
    
    final batch = FirebaseFirestore.instance.batch();
    bool hasUpdates = false;

    for (var doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['senderId'] != myId && d['seen'] != true) {
        batch.update(doc.reference, {'seen': true});
        hasUpdates = true;
      }
    }

    if (hasUpdates) {
      batch.commit().catchError((e) => debugPrint("Error marking seen: $e"));
    }
  }

  void _listenTyping() {
    _typingSub = FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .snapshots()
        .listen((snap) {
      if (!snap.exists) return;
      final typing = snap.data()?['typing'] as Map<String, dynamic>? ?? {};
      isOtherTyping.value = typing[otherUserId] == true;
    });
  }

  void onTextChanged(String text) {
    if (text.trim().isNotEmpty) {
      setTyping(true);
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () => setTyping(false));
    } else {
      setTyping(false);
    }
  }

  void setTyping(bool typing) {
    if (conversationId.isEmpty || myId.isEmpty) return;
    FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .update({'typing.$myId': typing}).catchError((_) {});
  }

  Future<void> resetUnread() async {
    if (conversationId.isEmpty || myId.isEmpty) return;
    FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .update({'unreadCount.$myId': 0}).catchError((_) {});
  }

  Future<void> sendMessage(String text) async {
    final msg = text.trim();
    if (msg.isEmpty || isSending.value) return;

    isSending.value = true;
    final rText = replyToText.value;
    replyToText.value = '';

    try {
      final convRef = FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId);

      await convRef.collection(AppConstants.colMessages).add({
        'senderId': myId,
        'text': msg,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
        'type': 'text',
        if (rText.isNotEmpty) 'replyToText': rText,
      });

      await convRef.update({
        'lastMessage': msg,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': myId,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint("Error sending message: $e");
    } finally {
      isSending.value = false;
    }
  }

  Future<void> initiateCall({required bool isVideo}) async {
    if (conversationId.isEmpty || myId.isEmpty) return;
    await FirebaseFirestore.instance.collection(AppConstants.colCalls).doc(conversationId).set({
      'callerId': myId,
      'receiverId': otherUserId,
      'status': 'ringing',
      'type': isVideo ? 'video' : 'voice',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}
