import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import '../../controllers/call_controller.dart';

class CallScreen extends StatelessWidget {
  final String callId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;
  final bool isVideo;
  final bool isIncoming;
  final String conversationId;

  const CallScreen({
    super.key,
    required this.callId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
    required this.isVideo,
    this.isIncoming = false,
    required this.conversationId,
  });

  @override
  Widget build(BuildContext context) {
    // FIX Bug 4: kiểm tra trước khi put để tránh dùng lại instance cũ
    if (!Get.isRegistered<CallController>(tag: callId)) {
      Get.put(
        CallController(
          callId: callId,
          otherUserId: otherUserId,
          otherUserName: otherUserName,
          otherUserPhotoUrl: otherUserPhotoUrl,
          isVideo: isVideo,
          isIncoming: isIncoming,
          conversationId: conversationId,
        ),
        tag: callId,
      );
    }
    final controller = Get.find<CallController>(tag: callId);

    return Obx(() {
      if (controller.callEnded.value) {
        return _buildEndedScreen(controller);
      }

      return Scaffold(
        backgroundColor: const Color(0xFF0D0D1A),
        body: Stack(
          children: [
            // 1. Video nền hoặc Avatar
            Positioned.fill(child: _remoteVideo(controller)),

            // 2. Video nhỏ của mình (nếu là video call)
            if (isVideo) _localVideo(controller),

            // 3. Thông tin người gọi (Header)
            _buildCallHeader(controller),

            // 4. Nút chuyển camera
            if (isVideo) _buildSwitchCameraBtn(controller),

            // 5. Bộ điều khiển (Mute, End, Speaker)
            _buildControls(controller),

            // 6. Loading khi đang kết nối
            _buildLoadingOverlay(controller),

            // 7. FIX: hiển thị lỗi kết nối
            _buildErrorOverlay(controller),
          ],
        ),
      );
    });
  }

  Widget _buildLoadingOverlay(CallController controller) {
    return Obx(() {
      if (!controller.isInitializing.value) return const SizedBox.shrink();
      return Container(
        color: Colors.black87,
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 20),
              Text(
                'Đang thiết lập kết nối...',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    });
  }

  // FIX: thêm overlay lỗi kết nối
  Widget _buildErrorOverlay(CallController controller) {
    return Obx(() {
      if (controller.status.value != 'error') return const SizedBox.shrink();
      return Container(
        color: Colors.black87,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.signal_wifi_connected_no_internet_4, color: Colors.red, size: 60),
              const SizedBox(height: 16),
              const Text(
                'Không thể kết nối',
                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                'Kiểm tra kết nối mạng và thử lại',
                style: TextStyle(color: Colors.white60, fontSize: 14),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () => controller.endCall(reason: 'ended'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Kết thúc', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildCallHeader(CallController controller) {
    return Positioned(
      top: 60,
      left: 0,
      right: 0,
      child: Column(
        children: [
          Text(
            otherUserName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              shadows: [Shadow(blurRadius: 8, color: Colors.black)],
            ),
          ),
          const SizedBox(height: 10),
          Obx(() => Text(
            controller.statusText,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 16,
              shadows: [Shadow(blurRadius: 4, color: Colors.black)],
            ),
          )),
        ],
      ),
    );
  }

  Widget _remoteVideo(CallController controller) {
    return Obx(() {
      if (controller.remoteUid.value != -1 && isVideo && controller.engine != null) {
        return AgoraVideoView(
          controller: VideoViewController.remote(
            rtcEngine: controller.engine!,
            canvas: VideoCanvas(uid: controller.remoteUid.value),
            connection: RtcConnection(channelId: callId),
          ),
        );
      }

      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white10, width: 2),
              ),
              child: CircleAvatar(
                radius: 80,
                backgroundColor: Colors.white10,
                backgroundImage: (otherUserPhotoUrl != null && otherUserPhotoUrl!.isNotEmpty)
                    ? NetworkImage(otherUserPhotoUrl!)
                    : null,
                child: (otherUserPhotoUrl == null || otherUserPhotoUrl!.isEmpty)
                    ? Text(
                  otherUserName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 60, color: Colors.white24),
                )
                    : null,
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _localVideo(CallController controller) {
    return Obx(() {
      if (!controller.localUserJoined.value ||
          controller.isCameraOff.value ||
          controller.engine == null) {
        return const SizedBox.shrink();
      }
      return Positioned(
        top: 120,
        right: 20,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 100,
            height: 150,
            color: Colors.black,
            child: AgoraVideoView(
              controller: VideoViewController(
                rtcEngine: controller.engine!,
                canvas: const VideoCanvas(uid: 0),
              ),
            ),
          ),
        ),
      );
    });
  }

  Widget _buildControls(CallController controller) {
    return Positioned(
      bottom: 80,
      left: 0,
      right: 0,
      child: Obx(() => Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _iconBtn(
            icon: controller.isMuted.value ? Icons.mic_off : Icons.mic,
            label: 'Micro',
            color: controller.isMuted.value ? Colors.red : Colors.white12,
            onTap: controller.toggleMute,
          ),
          GestureDetector(
            onTap: () => controller.endCall(),
            child: Container(
              width: 75,
              height: 75,
              decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
              child: const Icon(Icons.call_end, color: Colors.white, size: 35),
            ),
          ),
          _iconBtn(
            icon: controller.isSpeakerOn.value ? Icons.volume_up : Icons.volume_down,
            label: 'Loa',
            color: controller.isSpeakerOn.value ? Colors.blueAccent : Colors.white12,
            onTap: controller.toggleSpeaker,
          ),
        ],
      )),
    );
  }

  Widget _iconBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 55,
            height: 55,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(icon, color: Colors.white),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _buildSwitchCameraBtn(CallController controller) {
    return Positioned(
      top: 50,
      left: 20,
      child: IconButton(
        icon: const Icon(Icons.flip_camera_ios, color: Colors.white),
        onPressed: controller.switchCamera,
      ),
    );
  }

  Widget _buildEndedScreen(CallController controller) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D0D1A),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.call_end, color: Colors.red, size: 80),
            const SizedBox(height: 20),
            Text(
              controller.endReason.value == 'no_answer'
                  ? 'Không trả lời'
                  : controller.endReason.value == 'rejected'
                  ? 'Cuộc gọi bị từ chối'
                  : 'Cuộc gọi kết thúc',
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            const Text('Đang quay lại...', style: TextStyle(color: Colors.white38)),
          ],
        ),
      ),
    );
  }
}