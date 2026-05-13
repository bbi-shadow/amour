import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';

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
  RtcEngine? engine;

  final RxInt duration = 0.obs;
  final RxString status = 'calling'.obs;
  final RxBool isMuted = false.obs;
  final RxBool isCameraOff = false.obs;
  final RxBool isSpeakerOn = false.obs;
  final RxBool localUserJoined = false.obs;
  final RxInt remoteUid = (-1).obs;
  // FIX Bug 5: đồng nhất countdown với noAnswerTimer (cùng 30s)
  final RxInt ringingCountdown = 30.obs;
  final RxBool callEnded = false.obs;
  final RxString endReason = ''.obs;
  final RxBool isFrontCamera = true.obs;
  final RxBool engineReady = false.obs;
  final RxBool isInitializing = false.obs;

  Timer? _callTimer;
  Timer? _noAnswerTimer;
  Timer? _countdownTimer;
  Timer? _initTimeoutTimer;
  StreamSubscription? _callSub;

  @override
  void onInit() {
    super.onInit();
    debugPrint('[Call] onInit: $callId, isVideo: $isVideo');
    _listenToCallStatus();

    isSpeakerOn.value = isVideo;

    _initTimeoutTimer = Timer(const Duration(seconds: 15), () {
      if (isInitializing.value) {
        debugPrint('[Call] Agora Init Timeout');
        isInitializing.value = false;
        if (status.value == 'connecting') status.value = 'error';
      }
    });

    if (!isIncoming) {
      initAgora();
      _startNoAnswerTimer();
    } else {
      status.value = 'connecting';
      initAgora();
    }
  }

  @override
  void onClose() {
    _stopAllTimers();
    _callSub?.cancel();
    _releaseAgora();
    super.onClose();
  }

  Future<void> initAgora() async {
    if (engine != null || isInitializing.value) return;
    isInitializing.value = true;

    try {
      if (!kIsWeb) {
        await [Permission.microphone, if (isVideo) Permission.camera].request();
      }

      final appId = AppConstants.agoraAppId.trim();
      engine = createAgoraRtcEngine();
      await engine!.initialize(RtcEngineContext(
        appId: appId,
        channelProfile: ChannelProfileType.channelProfileCommunication,
      ));

      engine!.registerEventHandler(RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          debugPrint('[Agora] ✅ Đã vào phòng');
          localUserJoined.value = true;
          isInitializing.value = false;
          _initTimeoutTimer?.cancel();
        },
        onUserJoined: (connection, rUid, elapsed) {
          debugPrint('[Agora] 👤 Đối phương vào phòng: $rUid');
          _stopNoAnswerTimer();
          remoteUid.value = rUid;
          status.value = 'connected';
          _startCallTimer();
        },
        onUserOffline: (connection, rUid, reason) {
          remoteUid.value = -1;
          if (!callEnded.value) endCall(reason: 'ended');
        },
        onError: (err, msg) {
          debugPrint('[Agora] ❌ Lỗi: $err $msg');
          isInitializing.value = false;
        },
      ));

      if (isVideo) {
        await engine!.enableVideo();
        await engine!.startPreview();
      } else {
        await engine!.enableAudio();
      }

      await engine!.setEnableSpeakerphone(isSpeakerOn.value);
      await engine!.setClientRole(role: ClientRoleType.clientRoleBroadcaster);

      // FIX Bug 3: không tạo token phía client nữa
      // Token nên lấy từ server (Cloud Function) hoặc dùng app không có certificate
      // Nếu AppCertificate rỗng → join không cần token (chế độ testing)
      const String? token = null;

      await engine!.joinChannel(
        token: token ?? '',
        channelId: callId,
        uid: 0,
        options: ChannelMediaOptions(
          clientRoleType: ClientRoleType.clientRoleBroadcaster,
          publishCameraTrack: isVideo,
          publishMicrophoneTrack: true,
          autoSubscribeAudio: true,
          autoSubscribeVideo: isVideo,
        ),
      );
    } catch (e) {
      debugPrint('[Agora] initAgora error: $e');
      isInitializing.value = false;
      // Thông báo lỗi cho user thay vì im lặng
      if (!callEnded.value) {
        status.value = 'error';
      }
    }
  }

  void _releaseAgora() async {
    try {
      if (engine != null) {
        await engine!.leaveChannel();
        await engine!.release();
        engine = null;
      }
    } catch (_) {}
  }

  void _startCallTimer() =>
      _callTimer = Timer.periodic(const Duration(seconds: 1), (_) => duration.value++);

  void _startNoAnswerTimer() {
    // FIX Bug 5: đồng nhất 30s cho cả countdown lẫn timeout thực tế
    ringingCountdown.value = 30;
    _countdownTimer = Timer.periodic(
      const Duration(seconds: 1),
          (t) {
        if (ringingCountdown.value > 0) {
          ringingCountdown.value--;
        }
      },
    );
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
    _initTimeoutTimer?.cancel();
  }

  Future<void> endCall({String reason = 'ended'}) async {
    if (callEnded.value) return;
    _stopAllTimers();

    // Ghi lịch sử vào Chat
    await _logCallMessage(reason: reason, durationSecs: duration.value);

    // Cập nhật trạng thái cuộc gọi
    await FirestoreService.updateCallStatus(callId, reason, duration: duration.value);

    callEnded.value = true;
    endReason.value = reason;

    // FIX Bug 4: delete controller sau khi back để tránh leak
    Future.delayed(const Duration(seconds: 1), () {
      if (Get.currentRoute.contains('CallScreen')) Get.back();
      // Dọn controller khỏi GetX registry
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
      String text = '';
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

  void toggleMute() {
    isMuted.value = !isMuted.value;
    engine?.muteLocalAudioStream(isMuted.value);
  }

  void toggleCamera() {
    isCameraOff.value = !isCameraOff.value;
    engine?.muteLocalVideoStream(isCameraOff.value);
  }

  void toggleSpeaker() {
    isSpeakerOn.value = !isSpeakerOn.value;
    engine?.setEnableSpeakerphone(isSpeakerOn.value);
  }

  void switchCamera() {
    isFrontCamera.value = !isFrontCamera.value;
    engine?.switchCamera();
  }

  String get timerText {
    final m = duration.value ~/ 60;
    final s = duration.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  String get statusText {
    switch (status.value) {
      case 'calling':
        return isIncoming
            ? 'Cuộc gọi đến...'
            : 'Đang gọi... (${ringingCountdown.value}s)';
      case 'accepted':
      case 'connecting':
        return 'Đang kết nối...';
      case 'connected':
        return timerText;
      case 'error':
        return 'Lỗi kết nối';
      default:
        return 'Đang kết nối...';
    }
  }
}