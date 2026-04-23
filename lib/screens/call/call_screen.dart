import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../themes/app_theme.dart';
import '../../services/firestore_service.dart';

class CallScreen extends StatefulWidget {
  final String callId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final bool isVideo;
  final bool isIncoming;

  const CallScreen({
    super.key,
    required this.callId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.isVideo,
    this.isIncoming = false,
  });

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  final String _appId = "e60b853ab652045a6af74da86d5e9e304";

  int? _remoteUid;
  bool _localUserJoined = false;
  late RtcEngine _engine;

  bool _isMuted = false;
  bool _isCameraOff = false;
  int _seconds = 0;
  Timer? _timer;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    // Nếu là người gọi đi, khởi tạo ngay. 
    // Nếu là người nhận, sẽ hiển thị UI nhận cuộc gọi trước.
    if (!widget.isIncoming) {
      initAgora();
    } else {
      // Lắng nghe nếu người gọi hủy cuộc gọi
      _listenToCallStatus();
    }
  }

  void _listenToCallStatus() {
    FirestoreService.watchCall(widget.callId).listen((snap) {
      if (snap.exists) {
        final status = snap.get('status');
        if (status == 'ended' || status == 'rejected') {
          if (mounted) Navigator.pop(context);
        }
      }
    });
  }

  Future<void> initAgora() async {
    if (_isInitialized) return;

    await [Permission.microphone, Permission.camera].request();

    _engine = createAgoraRtcEngine();
    await _engine.initialize(RtcEngineContext(appId: _appId));

    _engine.registerEventHandler(
      RtcEngineEventHandler(
        onJoinChannelSuccess: (RtcConnection connection, int elapsed) {
          if (mounted) {
            setState(() {
              _localUserJoined = true;
              _isInitialized = true;
            });
            _startTimer();
          }
        },
        onUserJoined: (RtcConnection connection, int remoteUid, int elapsed) {
          if (mounted) setState(() => _remoteUid = remoteUid);
        },
        onUserOffline: (RtcConnection connection, int remoteUid, UserOfflineReasonType reason) {
          _endCall();
        },
      ),
    );

    if (widget.isVideo) {
      await _engine.enableVideo();
      await _engine.startPreview();
    } else {
      await _engine.enableAudio();
    }

    await _engine.joinChannel(
      token: "", 
      channelId: widget.callId,
      uid: 0,
      options: const ChannelMediaOptions(),
    );
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _endCall() async {
    _timer?.cancel();
    if (_isInitialized) {
      await _engine.leaveChannel();
      await _engine.release();
    }
    await FirestoreService.updateCallStatus(widget.callId, 'ended', duration: _seconds);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _acceptCall() async {
    await FirestoreService.updateCallStatus(widget.callId, 'accepted');
    initAgora(); // Bắt đầu kết nối Agora sau khi chấp nhận
  }

  Future<void> _rejectCall() async {
    await FirestoreService.updateCallStatus(widget.callId, 'rejected');
    if (mounted) Navigator.pop(context);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Nếu là cuộc gọi đến và chưa nhấn Chấp nhận
    if (widget.isIncoming && !_localUserJoined) {
      return _buildIncomingUI();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Center(child: _remoteVideo()),
          _localVideo(),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildIncomingUI() {
    return Scaffold(
      backgroundColor: const Color(0xFF1A1A2E),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          CircleAvatar(radius: 60, backgroundImage: widget.otherUserPhotoUrl != null ? NetworkImage(widget.otherUserPhotoUrl!) : null),
          const SizedBox(height: 20),
          Text(widget.otherUserName, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          const Text("Cuộc gọi đến...", style: TextStyle(color: Colors.white70, fontSize: 16)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _incomingBtn(Icons.call_end, Colors.red, "Từ chối", _rejectCall),
              _incomingBtn(widget.isVideo ? Icons.videocam : Icons.call, Colors.green, "Chấp nhận", _acceptCall),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _incomingBtn(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 32),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70)),
      ],
    );
  }

  Widget _remoteVideo() {
    if (_remoteUid != null && widget.isVideo) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: _engine,
          canvas: VideoCanvas(uid: _remoteUid),
          connection: RtcConnection(channelId: widget.callId),
        ),
      );
    } else {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(radius: 60, backgroundImage: widget.otherUserPhotoUrl != null ? NetworkImage(widget.otherUserPhotoUrl!) : null),
          const SizedBox(height: 20),
          Text(widget.otherUserName, style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
          Text(_localUserJoined ? (_remoteUid != null ? _timerText : "Đang chờ đối phương...") : "Đang kết nối...", style: const TextStyle(color: Colors.white70)),
        ],
      );
    }
  }

  Widget _localVideo() {
    if (_localUserJoined && widget.isVideo && !_isCameraOff) {
      return Positioned(
        top: 50, right: 20,
        child: SizedBox(
          width: 100, height: 150,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: _engine,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildControls() {
    return Positioned(
      bottom: 50, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlBtn(_isMuted ? Icons.mic_off : Icons.mic, () {
            setState(() => _isMuted = !_isMuted);
            _engine.muteLocalAudioStream(_isMuted);
          }),
          FloatingActionButton(
            backgroundColor: Colors.red,
            onPressed: _endCall,
            child: const Icon(Icons.call_end, color: Colors.white),
          ),
          if (widget.isVideo)
            _controlBtn(_isCameraOff ? Icons.videocam_off : Icons.videocam, () {
              setState(() => _isCameraOff = !_isCameraOff);
              _engine.muteLocalVideoStream(_isCameraOff);
            }),
        ],
      ),
    );
  }

  Widget _controlBtn(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(15),
        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 28),
      ),
    );
  }

  String get _timerText {
    final m = _seconds ~/ 60;
    final s = _seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

class IncomingCallBanner extends StatelessWidget {
  final String callerName;
  final String? callerPhoto;
  final bool isVideo;
  final VoidCallback onAccept;
  final VoidCallback onDecline;

  const IncomingCallBanner({
    super.key,
    required this.callerName,
    this.callerPhoto,
    required this.isVideo,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1A1A2E), Color(0xFF16213E)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            image: callerPhoto != null ? DecorationImage(image: NetworkImage(callerPhoto!), fit: BoxFit.cover) : null,
            color: callerPhoto == null ? Colors.pink : null,
          ),
          child: callerPhoto == null ? Center(child: Text(callerName[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))) : null,
        ),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(callerName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            Text(isVideo ? '📹 Gọi video...' : '📞 Gọi thoại...', style: const TextStyle(color: Colors.white70, fontSize: 13)),
          ],
        )),
        IconButton(onPressed: onDecline, icon: const Icon(Icons.call_end, color: Colors.red)),
        IconButton(onPressed: onAccept, icon: Icon(isVideo ? Icons.videocam : Icons.call, color: Colors.green)),
      ]),
    );
  }
}
