import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';
import '../../controllers/call_controller.dart';
import '../../utils/app_constants.dart';

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
    final myId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final myName = FirebaseAuth.instance.currentUser?.displayName ?? myId;

    final config = isVideo
        ? ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        : ZegoUIKitPrebuiltCallConfig.oneOnOneVoiceCall();

    // Avatar tùy chỉnh
    config.avatarBuilder = (context, size, user, extraInfo) {
      return CircleAvatar(
        radius: size.width / 2,
        backgroundColor: Colors.white24,
        backgroundImage: (otherUserPhotoUrl != null && otherUserPhotoUrl!.isNotEmpty)
            ? NetworkImage(otherUserPhotoUrl!)
            : null,
        child: (otherUserPhotoUrl == null || otherUserPhotoUrl!.isEmpty)
            ? Text(
          otherUserName.isNotEmpty ? otherUserName[0].toUpperCase() : '?',
          style: TextStyle(fontSize: size.width * 0.4, color: Colors.white),
        )
            : null,
      );
    };

    return ZegoUIKitPrebuiltCall(
      appID: AppConstants.zegoAppId,
      appSign: AppConstants.zegoAppSign,
      userID: myId,
      userName: myName,
      callID: callId,
      config: config,
      events: ZegoUIKitPrebuiltCallEvents(
        onCallEnd: (event, defaultAction) {
          controller.endCall(reason: 'ended');
          defaultAction.call();
        },
      ),
    );
  }
}