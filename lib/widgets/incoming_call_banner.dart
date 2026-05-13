import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/call/call_screen.dart';
import '../services/firestore_service.dart';
import '../themes/app_theme.dart';

class IncomingCallBanner extends StatefulWidget {
  final dynamic caller;
  final String callId;
  final bool isVideo;
  final String conversationId;
  final VoidCallback? onDismissed;

  const IncomingCallBanner({
    super.key,
    required this.caller,
    required this.callId,
    required this.isVideo,
    required this.conversationId,
    this.onDismissed,
  });

  @override
  State<IncomingCallBanner> createState() => _IncomingCallBannerState();
}

class _IncomingCallBannerState extends State<IncomingCallBanner> {
  StreamSubscription? _callSub;
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    // Tự đóng dialog khi caller hủy / hết timeout
    _callSub = FirestoreService.watchCall(widget.callId).listen((snap) {
      if (!snap.exists || _dismissed) return;
      final status =
      (snap.data() as Map<String, dynamic>?)?['status'] as String?;
      if (status == 'ended' || status == 'no_answer' || status == 'rejected') {
        _dismiss();
      }
    });
  }

  @override
  void dispose() {
    _callSub?.cancel();
    super.dispose();
  }

  void _dismiss() {
    if (_dismissed) return;
    _dismissed = true;
    widget.onDismissed?.call();
    if (Get.isDialogOpen ?? false) Get.back();
  }

  Future<void> _accept() async {
    if (_dismissed) return;
    _dismissed = true;
    _callSub?.cancel();
    widget.onDismissed?.call();

    if (Get.isDialogOpen ?? false) Get.back();

    // Báo cho caller biết: người nhận đã chấp nhận → caller dừng no-answer timer
    await FirestoreService.updateCallStatus(widget.callId, 'accepted');

    Get.to(() => CallScreen(
      callId: widget.callId,
      otherUserId: widget.caller.uid,
      otherUserName: widget.caller.name,
      otherUserPhotoUrl: widget.caller.photoUrl,
      isVideo: widget.isVideo,
      isIncoming: true,
      conversationId: widget.conversationId,
    ));
  }

  Future<void> _reject() async {
    if (_dismissed) return;
    _dismissed = true;
    _callSub?.cancel();
    widget.onDismissed?.call();
    if (Get.isDialogOpen ?? false) Get.back();
    await FirestoreService.updateCallStatus(widget.callId, 'rejected');
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF0D0D1A),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircleAvatar(
              radius: 50,
              backgroundImage: (widget.caller.photoUrl != null &&
                  widget.caller.photoUrl.isNotEmpty)
                  ? NetworkImage(widget.caller.photoUrl)
                  : null,
              backgroundColor: Colors.white24,
              child: (widget.caller.photoUrl == null ||
                  widget.caller.photoUrl.isEmpty)
                  ? Text(
                widget.caller.name[0].toUpperCase(),
                style:
                const TextStyle(fontSize: 32, color: Colors.white),
              )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              widget.caller.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  widget.isVideo
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  color: Colors.white60,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.isVideo
                      ? 'Cuộc gọi video đến...'
                      : 'Cuộc gọi đến...',
                  style: const TextStyle(color: Colors.white60, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _actionBtn(
                  icon: Icons.call_end_rounded,
                  label: 'Từ chối',
                  color: Colors.red,
                  onTap: _reject,
                ),
                _actionBtn(
                  icon: widget.isVideo
                      ? Icons.videocam_rounded
                      : Icons.call_rounded,
                  label: 'Chấp nhận',
                  color: Colors.green,
                  onTap: _accept,
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withOpacity(0.4),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 30),
          ),
        ),
        const SizedBox(height: 10),
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 13)),
      ],
    );
  }
}