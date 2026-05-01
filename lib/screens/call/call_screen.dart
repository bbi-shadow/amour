import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../controllers/call_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_theme.dart';

class CallScreen extends StatelessWidget {
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
  Widget build(BuildContext context) {
    // Khoi tao controller voi tham so truyen vao
    final controller = Get.put(CallController(
      callId: callId,
      otherUserId: otherUserId,
      otherUserName: otherUserName,
      isVideo: isVideo,
      isIncoming: isIncoming,
    ));

    return Obx(() {
      if (controller.callEnded.value) return _buildEndedScreen(isIncoming);

      if (isIncoming && !controller.localUserJoined.value) {
        return _buildIncomingUI(controller);
      }

      return Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            Center(child: _remoteVideo(controller)),
            _localVideo(controller),
            _buildCallHeader(controller),
            _buildControls(controller),
          ],
        ),
      );
    });
  }

  Widget _buildCallHeader(CallController controller) {
    return Positioned(
      top: 0, left: 0, right: 0,
      child: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 20),
            Text(otherUserName, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(
              controller.remoteUid.value != -1 ? controller.timerText : "Dang ket noi...",
              style: const TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _remoteVideo(CallController controller) {
    if (controller.remoteUid.value != -1 && isVideo) {
      return AgoraVideoView(
        controller: VideoViewController.remote(
          rtcEngine: controller.engine!,
          canvas: VideoCanvas(uid: controller.remoteUid.value),
          connection: RtcConnection(channelId: callId),
        ),
      );
    }
    return Container(
      color: const Color(0xFF0D0D1A),
      child: Center(
        child: CircleAvatar(
          radius: 60,
          backgroundImage: otherUserPhotoUrl != null ? NetworkImage(otherUserPhotoUrl!) : null,
          child: otherUserPhotoUrl == null ? Text(otherUserName[0].toUpperCase(), style: const TextStyle(fontSize: 40)) : null,
        ),
      ),
    );
  }

  Widget _localVideo(CallController controller) {
    if (controller.localUserJoined.value && isVideo && !controller.isCameraOff.value) {
      return Positioned(
        top: 40, right: 20,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: SizedBox(
            width: 100, height: 150,
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: controller.engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildControls(CallController controller) {
    return Positioned(
      bottom: 50, left: 0, right: 0,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _controlBtn(
            icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
            onTap: controller.toggleMute,
            color: controller.isMuted.value ? Colors.red : Colors.white24,
          ),
          _controlBtn(
            icon: Icons.call_end,
            onTap: () => controller.endCall(),
            color: Colors.red,
            size: 70,
          ),
          if (isVideo)
            _controlBtn(
              icon: controller.isCameraOff.value ? Icons.videocam_off : Icons.videocam,
              onTap: controller.toggleCamera,
              color: controller.isCameraOff.value ? Colors.red : Colors.white24,
            )
          else
            _controlBtn(
              icon: controller.isSpeaker.value ? Icons.volume_up : Icons.volume_down,
              onTap: controller.toggleSpeaker,
              color: controller.isSpeaker.value ? AppColors.primary : Colors.white24,
            ),
        ],
      ),
    );
  }

  Widget _controlBtn({required IconData icon, required VoidCallback onTap, required Color color, double size = 56}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: size * 0.5),
      ),
    );
  }

  Widget _buildIncomingUI(CallController controller) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Spacer(),
          CircleAvatar(
            radius: 70,
            backgroundImage: otherUserPhotoUrl != null ? NetworkImage(otherUserPhotoUrl!) : null,
          ),
          const SizedBox(height: 24),
          Text(otherUserName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(isVideo ? "Cuoc goi video den..." : "Cuoc goi den...", style: const TextStyle(color: Colors.white60)),
          const Spacer(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _incomingActionBtn(Icons.call_end, "Tu choi", Colors.red, controller.rejectCall),
              _incomingActionBtn(Icons.call, "Chap nhan", Colors.green, controller.acceptCall),
            ],
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Widget _incomingActionBtn(IconData icon, String label, Color color, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 70, height: 70,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 12),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 14)),
      ],
    );
  }

  Widget _buildEndedScreen(bool incoming) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call_end, color: Colors.red, size: 80),
            const SizedBox(height: 24),
            const Text("Cuoc goi da ket thuc", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("Dang quay lai...", style: TextStyle(color: Colors.white.withOpacity(0.3))),
          ],
        ),
      ),
    );
  }
}
