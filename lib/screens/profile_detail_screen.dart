import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';
import '../themes/app_theme.dart';
import '../utils/app_constants.dart';
import 'chat/chat_detail_screen.dart';
import 'call/call_screen.dart';

class ProfileDetailScreen extends StatefulWidget {
  final UserModel user;
  const ProfileDetailScreen({super.key, required this.user});
  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _pageCtrl = PageController();
  int _photoIndex = 0;

  bool _isMatched = false;
  bool _isLiking = false;
  String? _conversationId;

  @override
  void initState() {
    super.initState();
    _checkMatchStatus();
  }

  Future<void> _checkMatchStatus() async {
    final matchId = ([_uid, widget.user.uid]..sort()).join('_');
    final doc = await FirebaseFirestore.instance
        .collection(AppConstants.colMatches).doc(matchId).get();
    if (doc.exists && mounted) {
      setState(() {
        _isMatched = true;
        _conversationId = matchId;
      });
    }
  }

  void _initiateCall({required bool isVideo}) async {
    if (_conversationId == null) return;
    
    await FirestoreService.updateCallStatus(_conversationId!, 'ringing');
    // Note: In a real app, you'd set callerId and receiverId too.
    // The current updateCallStatus only takes status and duration.
    // Let's use a raw Firestore call for now to ensure all fields are set.
    await FirebaseFirestore.instance.collection(AppConstants.colCalls).doc(_conversationId).set({
      'callerId': _uid,
      'receiverId': widget.user.uid,
      'status': 'ringing',
      'type': isVideo ? 'video' : 'voice',
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    Get.to(() => CallScreen(
      callId: _conversationId!,
      otherUserId: widget.user.uid,
      otherUserName: widget.user.name,
      otherUserPhotoUrl: widget.user.photoUrl,
      isVideo: isVideo,
      isIncoming: false,
    ));
  }

  void _openChat() {
    if (_conversationId == null) return;
    Get.to(() => ChatDetailScreen(
      conversationId: _conversationId!,
      otherUserId: widget.user.uid,
      otherUserName: widget.user.name,
      otherUserPhotoUrl: widget.user.photoUrl,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          _buildPhotoSlider(),
          SafeArea(child: _buildTopBar()),
          Positioned(bottom: 0, left: 0, right: 0, child: _buildBottomPanel()),
        ],
      ),
    );
  }

  Widget _buildPhotoSlider() {
    final photos = widget.user.photoUrl.isNotEmpty ? [widget.user.photoUrl] : [''];
    return PageView.builder(
      controller: _pageCtrl,
      itemCount: photos.length,
      itemBuilder: (_, i) => photos[i].isNotEmpty 
        ? Image.network(photos[i], fit: BoxFit.cover) 
        : Container(color: AppColors.primary),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(children: [
        _topButton(Icons.arrow_back_ios_new_rounded, () => Get.back()),
        const Spacer(),
        _topButton(Icons.more_horiz_rounded, () {}),
      ]),
    );
  }

  Widget _topButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40, height: 40,
        decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.35), shape: BoxShape.circle),
        child: Icon(icon, color: Colors.white, size: 20),
      ),
    );
  }

  Widget _buildBottomPanel() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black]),
      ),
      padding: const EdgeInsets.fromLTRB(20, 40, 20, 36),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('${widget.user.name}, ${widget.user.age}', style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(widget.user.city, style: const TextStyle(color: Colors.white70, fontSize: 16)),
          const SizedBox(height: 24),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    if (_isMatched) {
      return Row(children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _openChat,
            icon: const Icon(Icons.chat_bubble_rounded),
            label: const Text('Nhắn tin'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary, 
              foregroundColor: Colors.white, 
              padding: const EdgeInsets.symmetric(vertical: 15), 
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))
            ),
          ),
        ),
        const SizedBox(width: 10),
        _circleActionBtn(Icons.call, Colors.green, () => _initiateCall(isVideo: false)),
        const SizedBox(width: 10),
        _circleActionBtn(Icons.videocam, Colors.blue, () => _initiateCall(isVideo: true)),
      ]);
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _circleActionBtn(Icons.close, Colors.red, () => Get.back()),
      _circleActionBtn(Icons.favorite, Colors.green, () async {
        final isMatch = await FirestoreService.recordSwipe(targetUid: widget.user.uid, isLike: true);
        if (isMatch) {
          _checkMatchStatus();
          AppHelpers.showSuccess('Bạn đã Match với ${widget.user.name}! 🎉');
        } else {
          Get.back();
          AppHelpers.showSuccess('Đã thích ${widget.user.name}!');
        }
      }, size: 70),
      _circleActionBtn(Icons.star, Colors.blue, () {}),
    ]);
  }

  Widget _circleActionBtn(IconData icon, Color color, VoidCallback onTap, {double size = 55}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10)]),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }
}
