import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../screens/call/call_screen.dart';
import '../services/firestore_service.dart';

class IncomingCallBanner extends StatelessWidget {
  final dynamic caller;
  final String callId;
  final bool isVideo;

  const IncomingCallBanner({
    super.key,
    required this.caller,
    required this.callId,
    required this.isVideo,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.9),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
        ),
        child: Material(
          color: Colors.transparent,
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: (caller.photoUrl != null && caller.photoUrl.isNotEmpty) 
                  ? NetworkImage(caller.photoUrl) : null,
                child: (caller.photoUrl == null || caller.photoUrl.isEmpty) 
                  ? const Icon(Icons.person) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(caller.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Text(isVideo ? 'Cuộc gọi video đến' : 'Cuộc gọi đến', 
                      style: const TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.call_end, color: Colors.red), 
                onPressed: () {
                  Get.back();
                  FirestoreService.updateCallStatus(callId, 'rejected');
                }
              ),
              IconButton(
                icon: const Icon(Icons.call, color: Colors.green), 
                onPressed: () {
                  Get.back();
                  Get.to(() => CallScreen(
                    callId: callId,
                    otherUserId: caller.uid,
                    otherUserName: caller.name,
                    otherUserPhotoUrl: caller.photoUrl,
                    isVideo: isVideo,
                    isIncoming: true,
                  ));
                }
              ),
            ],
          ),
        ),
      ),
    );
  }
}
