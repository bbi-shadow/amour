import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../controllers/auth_controller.dart';
import '../models/message_model.dart';
import '../models/user_model.dart';
import '../screens/call/call_screen.dart';
import '../services/upload_service.dart';
import '../utils/app_constants.dart';

class ChatDetailController extends GetxController {
  final String conversationId;
  final String otherUserId;

  ChatDetailController({
    required this.conversationId,
    required this.otherUserId,
  });

  static ChatDetailController get to => Get.find();

  final RxList<MessageModel> messages = <MessageModel>[].obs;
  final Rx<UserModel?> otherUser = Rx<UserModel?>(null);
  final RxBool isOtherTyping = false.obs;
  final RxBool isSending = false.obs;
  final RxBool isUploading = false.obs;
  final Rx<MessageModel?> replyToMessage = Rx<MessageModel?>(null);
  final RxBool isLoadingMore = false.obs;
  final RxBool hasMoreMessages = true.obs;
  static const int _pageSize = 30;
  DocumentSnapshot? _lastDocument;
  final RxBool isDelivered = false.obs;

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
      if (snap.exists) otherUser.value = UserModel.fromFirestore(snap);
    });
  }

  void _listenMessages() {
    _msgSub = FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .doc(conversationId)
        .collection(AppConstants.colMessages)
        .orderBy('timestamp', descending: false)
        .limitToLast(_pageSize)
        .snapshots()
        .listen((snap) {
      final list = snap.docs.map((d) => MessageModel.fromFirestore(d)).toList();
      messages.assignAll(list);
      _markIncomingAsSeen(snap.docs);
      _updateDeliveredStatus();
      if (snap.docs.isNotEmpty) _lastDocument = snap.docs.first;
      if (list.length < _pageSize) hasMoreMessages.value = false;
    });
  }

  Future<void> loadMoreMessages() async {
    if (isLoadingMore.value || !hasMoreMessages.value || _lastDocument == null) return;
    isLoadingMore.value = true;
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId)
          .collection(AppConstants.colMessages)
          .orderBy('timestamp', descending: true)
          .startAfterDocument(_lastDocument!)
          .limit(_pageSize)
          .get();

      if (snap.docs.isEmpty) {
        hasMoreMessages.value = false;
        return;
      }

      final older = snap.docs.map((d) => MessageModel.fromFirestore(d)).toList();
      older.sort((a, b) => (a.timestamp ?? DateTime(0)).compareTo(b.timestamp ?? DateTime(0)));
      messages.insertAll(0, older);
      _lastDocument = snap.docs.last;
      if (snap.docs.length < _pageSize) hasMoreMessages.value = false;
    } catch (e) {
      debugPrint('loadMoreMessages error: $e');
    } finally {
      isLoadingMore.value = false;
    }
  }

  void _markIncomingAsSeen(List<QueryDocumentSnapshot> docs) {
    if (myId.isEmpty) return;
    final batch = FirebaseFirestore.instance.batch();
    bool hasUpdates = false;
    for (var doc in docs) {
      final d = doc.data() as Map<String, dynamic>;
      if (d['senderId'] != myId && d['seen'] != true && d['isDeleted'] != true) {
        batch.update(doc.reference, {'seen': true, 'seenAt': FieldValue.serverTimestamp()});
        hasUpdates = true;
      }
    }
    if (hasUpdates) batch.commit().catchError((e) => debugPrint('markSeen error: $e'));
  }

  void _updateDeliveredStatus() {
    final myMsgs = messages.where((m) => m.senderId == myId && !m.isDeleted).toList();
    if (myMsgs.isNotEmpty) {
      final last = myMsgs.last;
      isDelivered.value = last.delivered || last.seen;
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
      _typingTimer?.cancel();
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
    final reply = replyToMessage.value;
    replyToMessage.value = null;

    try {
      final convRef = FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId);

      await convRef.collection(AppConstants.colMessages).add({
        'senderId': myId,
        'text': msg,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
        'delivered': false,
        'type': 'text',
        'isDeleted': false,
        'conversationId': conversationId,
        if (reply != null) 'replyToMessageId': reply.id,
        if (reply != null) 'replyToText': reply.text,
        if (reply != null) 'replyToSenderId': reply.senderId,
      });

      await convRef.update({
        'lastMessage': msg,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': myId,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('sendMessage error: $e');
      Get.snackbar('Lỗi', 'Không thể gửi tin nhắn', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isSending.value = false;
    }
  }

  Future<void> sendImage({bool fromCamera = false}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      maxWidth: 1280,
      maxHeight: 1280,
      imageQuality: 80,
    );
    if (picked == null) return;

    isUploading.value = true;
    try {
      final String? url;
      if (kIsWeb) {
        final bytes = await picked.readAsBytes();
        url = await UploadService.uploadImageWeb(bytes);
      } else {
        url = await UploadService.uploadImage(File(picked.path));
      }

      if (url == null) {
        Get.snackbar('Lỗi', 'Không thể upload ảnh', snackPosition: SnackPosition.BOTTOM);
        return;
      }

      final convRef = FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId);

      await convRef.collection(AppConstants.colMessages).add({
        'senderId': myId,
        'text': '📷 Ảnh',
        'mediaUrl': url,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
        'delivered': false,
        'type': 'image',
        'isDeleted': false,
        'conversationId': conversationId,
      });

      await convRef.update({
        'lastMessage': '📷 Ảnh',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': myId,
        'unreadCount.$otherUserId': FieldValue.increment(1),
      });
    } catch (e) {
      debugPrint('sendImage error: $e');
      Get.snackbar('Lỗi', 'Không thể gửi ảnh', snackPosition: SnackPosition.BOTTOM);
    } finally {
      isUploading.value = false;
    }
  }

  Future<void> reactToMessage(String messageId, String emoji) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId)
          .collection(AppConstants.colMessages)
          .doc(messageId)
          .update({'reaction.$myId': emoji});
    } catch (e) {
      debugPrint('reactToMessage error: $e');
    }
  }

  Future<void> unsendMessage(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId)
          .collection(AppConstants.colMessages)
          .doc(messageId)
          .update({
        'isDeleted': true,
        'text': 'Tin nhắn đã được thu hồi',
        'mediaUrl': null,
      });
    } catch (e) {
      debugPrint('unsendMessage error: $e');
    }
  }

  Future<void> deleteMessageForMe(String messageId) async {
    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId)
          .collection(AppConstants.colMessages)
          .doc(messageId)
          .update({'deletedFor.$myId': true});
    } catch (e) {
      debugPrint('deleteMessageForMe error: $e');
    }
  }

  void setReply(MessageModel message) => replyToMessage.value = message;
  void clearReply() => replyToMessage.value = null;

  Future<void> initiateCall({required bool isVideo}) async {
    if (myId.isEmpty) return;

    // FIX Bug 1: tạo callId trước, ghi Firestore xong mới mở CallScreen
    final callId = FirebaseFirestore.instance.collection(AppConstants.colCalls).doc().id;

    try {
      await FirebaseFirestore.instance
          .collection(AppConstants.colCalls)
          .doc(callId)
          .set({
        'callerId': myId,
        'receiverId': otherUserId,
        'status': 'ringing',
        'type': isVideo ? 'video' : 'voice',
        'channelId': callId,
        'createdAt': FieldValue.serverTimestamp(),
        'conversationId': conversationId,
      });

      // Chỉ mở CallScreen sau khi Firestore ghi thành công
      Get.to(() => CallScreen(
        callId: callId,
        otherUserId: otherUserId,
        otherUserName: otherUser.value?.name ?? 'Unknown',
        otherUserPhotoUrl: otherUser.value?.photoUrl,
        isVideo: isVideo,
        isIncoming: false,
        conversationId: conversationId,
      ));
    } catch (e) {
      debugPrint('initiateCall error: $e');
      // FIX: thông báo lỗi cho user thay vì im lặng
      Get.snackbar(
        'Lỗi',
        'Không thể thực hiện cuộc gọi. Kiểm tra kết nối và thử lại!',
        snackPosition: SnackPosition.TOP,
      );
    }
  }

  String messageStatusText(MessageModel msg) {
    if (!msg.seen && !msg.delivered) return 'Đã gửi';
    if (msg.delivered && !msg.seen) return 'Đã nhận';
    return 'Đã xem';
  }
}