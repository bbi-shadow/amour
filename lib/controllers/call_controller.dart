import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';

class CallController extends GetxController {
  final String callId;
  final String otherUserId;
  final String otherUserName;
  final bool isVideo;
  final bool isIncoming;

  CallController({
    required this.callId,
    required this.otherUserId,
    required this.otherUserName,
    required this.isVideo,
    required this.isIncoming,
  });

  static CallController get to => Get.find();

  // -- Agora Config --
  final String _appId = "e60b853ab652045a6af74da86d5e9e304";
  final String _myId = FirebaseAuth.instance.currentUser?.uid ?? '';
  RtcEngine? engine;

  // -- States --
  final RxInt duration = 0.obs;
  final RxString status = 'calling'.obs;
  final RxBool isMuted = false.obs;
  final RxBool isCameraOff = false.obs;
  final RxBool isSpeaker = false.obs;
  final RxBool localUserJoined = false.obs;
  final RxInt remoteUid = (-1).obs; 
  final RxInt ringingCountdown = 10.obs;
  final RxBool callEnded = false.obs;
  final RxString endReason = ''.obs;

  Timer? _callTimer;
  Timer? _noAnswerTimer;
  Timer? _countdownTimer;
  StreamSubscription? _callSub;

  @override
  void onInit() {
    super.onInit();
    if (!isIncoming) {
      initAgora();
      _startNoAnswerTimer();
    }
    _listenToCallStatus();
  }

  @override
  void onClose() {
    _stopAllTimers();
    _callSub?.cancel();
    _releaseAgora();
    super.onClose();
  }

  // -- Agora Logic --
  Future<void> initAgora() async {
    if (engine != null) return;

    await [Permission.microphone, Permission.camera].request();

    engine = createAgoraRtcEngine();
    await engine!.initialize(RtcEngineContext(appId: _appId));

    engine!.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (connection, elapsed) {
          localUserJoined.value = true;
        },
        onUserJoined: (connection, rUid, elapsed) {
          _stopNoAnswerTimer();
          remoteUid.value = rUid;
          _startCallTimer();
        },
        onUserOffline: (connection, rUid, reason) {
          endCall(reason: 'ended');
        },
      ),
    );

    if (isVideo) {
      await engine!.enableVideo();
      await engine!.startPreview();
    } else {
      await engine!.enableAudio();
    }

    await engine!.joinChannel(
      token: "",
      channelId: callId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _releaseAgora() async {
    if (engine != null) {
      await engine!.leaveChannel();
      await engine!.release();
      engine = null;
    }
  }

  // -- Timers --
  void _startCallTimer() {
    _callTimer?.cancel();
    _callTimer = Timer.periodic(const Duration(seconds: 1), (_) => duration.value++);
  }

  void _startNoAnswerTimer() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (ringingCountdown.value > 0) {
        ringingCountdown.value--;
      } else {
        t.cancel();
      }
    });

    _noAnswerTimer = Timer(const Duration(seconds: 10), () => _handleNoAnswer());
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

  // -- Call Actions --
  Future<void> _handleNoAnswer() async {
    await endCall(reason: 'no_answer');
  }

  Future<void> acceptCall() async {
    _stopNoAnswerTimer();
    await FirestoreService.updateCallStatus(callId, 'accepted');
    await initAgora();
    _startCallTimer();
  }

  Future<void> rejectCall() async {
    _stopNoAnswerTimer();
    await FirestoreService.updateCallStatus(callId, 'rejected');
    Get.back();
  }

  Future<void> endCall({String reason = 'ended'}) async {
    if (callEnded.value) return;
    
    _stopAllTimers();
    final finalDuration = duration.value;
    
    await FirestoreService.updateCallStatus(callId, reason, duration: finalDuration);

    callEnded.value = true;
    endReason.value = reason;
    
    Future.delayed(const Duration(seconds: 2), () {
      if (Get.isOverlaysOpen) Get.back();
      Get.back();
    });
  }

  // -- Firestore Messaging --
  void _listenToCallStatus() {
    _callSub = FirestoreService.watchCall(callId).listen((snap) {
      if (!snap.exists) return;
      final d = snap.data() as Map<String, dynamic>;
      final s = d['status'] as String;

      if (s == 'accepted' && isIncoming && engine == null) {
        _stopNoAnswerTimer();
      }

      if (s == 'ended' || s == 'rejected' || s == 'no_answer') {
        _handleRemoteEnd(s);
      }
    });
  }

  void _handleRemoteEnd(String s) {
    if (callEnded.value) return;
    _stopAllTimers();
    callEnded.value = true;
    endReason.value = s;
    Future.delayed(const Duration(seconds: 2), () => Get.back());
  }

  // -- Helpers --
  void toggleMute() {
    isMuted.value = !isMuted.value;
    engine?.muteLocalAudioStream(isMuted.value);
  }

  void toggleCamera() {
    isCameraOff.value = !isCameraOff.value;
    engine?.muteLocalVideoStream(isCameraOff.value);
  }

  void toggleSpeaker() {
    isSpeaker.value = !isSpeaker.value;
    engine?.setEnableSpeakerphone(isSpeaker.value);
  }

  String get timerText {
    final m = duration.value ~/ 60;
    final s = duration.value % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}
