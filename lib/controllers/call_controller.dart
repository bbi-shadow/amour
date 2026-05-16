import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';

/// CallController dùng Zego UIKit Prebuilt
/// Zego tự quản lý engine — controller chỉ xử lý timer, Firestore, trạng thái.
class CallController extends GetxController {
  final String callId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final bool isVideo;
  final bool isIncoming;
  final String conversationId;

  CallController({
    required this.callId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.isVideo,
    required this.isIncoming,
    required this.conversationId,
  });

  final String _myId = FirebaseAuth.instance.currentUser?.uid ?? '';

  final RxInt duration = 0.obs;
  final RxString status = 'calling'.obs;
  final RxInt ringingCountdown = 30.obs;
  final RxBool callEnded = false.obs;
  final RxString endReason = ''.obs;

  Timer? _callTimer;
  Timer? _noAnswerTimer;
  Timer? _countdownTimer;
  StreamSubscription? _callSub;

  @override
  void onInit() {
    super.onInit();
    _listenToCallStatus();
    if (!isIncoming) {
      _startNoAnswerTimer();
    } else {
      status.value = 'connecting';
    }
  }

  @override
  void onClose() {
    _stopAllTimers();
    _callSub?.cancel();
    super.onClose();
  }

  /// Gọi khi Zego UIKit báo cả 2 user đã vào phòng
  void onCallConnected() {
    _stopNoAnswerTimer();
    status.value = 'connected';
    _startCallTimer();
  }

  /// Gọi khi user bấm hang up trong Zego UI
  void onZegoCallEnded() => endCall(reason: 'ended');

  void _startCallTimer() =>
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) => duration.value++);

  void _startNoAnswerTimer() {
    ringingCountdown.value = 30;
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (ringingCountdown.value > 0) ringingCountdown.value--;
    });
    _noAnswerTimer = Timer(const Duration(seconds: 30), () => endCall(reason: 'no_answer'));
  }

  void _stopNoAnswerTimer() {
    _noAnswerTimer?.cancel();
    _countdownTimer?.cancel();
  }

  void _stopAllTimers() {
    _callTimer?.cancel();
    _noAnswerTimer?.cancel();
    _countdownTimer?.cancel();
  }

  Future<void> endCall({String reason = 'ended'}) async {
    if (callEnded.value) return;
    _stopAllTimers();
    await _logCallMessage(reason: reason, durationSecs: duration.value);
    await FirestoreService.updateCallStatus(callId, reason, duration: duration.value);
    callEnded.value = true;
    endReason.value = reason;
    Future.delayed(const Duration(seconds: 1), () {
      if (Get.currentRoute.contains('CallScreen')) Get.back();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<CallController>(tag: callId)) {
          Get.delete<CallController>(tag: callId);
        }
      });
    });
  }

  Future<void> _logCallMessage({required String reason, required int durationSecs}) async {
    if (conversationId.isEmpty || _myId.isEmpty) return;
    try {
      String text;
      if (reason == 'no_answer') {
        text = isVideo ? '📹 Cuộc gọi video nhỡ' : '📞 Cuộc gọi thoại nhỡ';
      } else if (reason == 'rejected') {
        text = '🚫 Cuộc gọi bị từ chối';
      } else {
        final m = durationSecs ~/ 60;
        final s = durationSecs % 60;
        final dur = '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
        text = isVideo ? '📹 Cuộc gọi video ($dur)' : '📞 Cuộc gọi thoại ($dur)';
      }
      final convRef = FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(conversationId);
      await convRef.collection(AppConstants.colMessages).add({
        'senderId': _myId,
        'text': text,
        'type': isVideo ? 'video_call' : 'voice_call',
        'timestamp': FieldValue.serverTimestamp(),
        'isCallMessage': true,
      });
      await convRef.update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('LogCall error: $e');
    }
  }

  void _listenToCallStatus() {
    _callSub = FirestoreService.watchCall(callId).listen((snap) {
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>?;
      final s = data?['status'] as String? ?? '';
      if (s == 'accepted' && !isIncoming) {
        _stopNoAnswerTimer();
        status.value = 'accepted';
      }
      if (['ended', 'rejected', 'no_answer'].contains(s)) _handleRemoteEnd(s);
    });
  }

  void _handleRemoteEnd(String s) {
    if (callEnded.value) return;
    _stopAllTimers();
    callEnded.value = true;
    endReason.value = s;
    Future.delayed(const Duration(seconds: 1), () {
      if (Get.currentRoute.contains('CallScreen')) Get.back();
      Future.delayed(const Duration(milliseconds: 300), () {
        if (Get.isRegistered<CallController>(tag: callId)) {
          Get.delete<CallController>(tag: callId);
        }
      });
    });
  }

  String get timerText {
    final m = duration.value ~/ 60;
    final s = duration.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status.value) {
      case 'calling':
        return isIncoming ? 'Cuộc gọi đến...' : 'Đang gọi... (${ringingCountdown.value}s)';
      case 'accepted':
      case 'connecting':
        return 'Đang kết nối...';
      case 'connected':
        return timerText;
      default:
        return 'Đang kết nối...';
    }
  }
}