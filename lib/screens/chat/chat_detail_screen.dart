import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:get/get.dart';
import '../../services/firestore_service.dart';
import '../../utils/app_constants.dart';
import '../../themes/app_theme.dart';
import '../call/call_screen.dart';

class ChatDetailScreen extends StatefulWidget {
  final String conversationId;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhotoUrl;

  const ChatDetailScreen({
    super.key,
    required this.conversationId,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhotoUrl,
  });

  @override
  State<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends State<ChatDetailScreen> {
  final TextEditingController _textCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // ✅ Messenger logic: Vừa vào là đánh dấu đã xem ngay
    FirestoreService.markMessagesAsSeen(widget.conversationId);
  }

  void _scrollToBottom() {
    if (_scrollCtrl.hasClients) {
      _scrollCtrl.animateTo(_scrollCtrl.position.maxScrollExtent, 
          duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
    }
  }

  void _initiateCall({required bool isVideo}) async {
    final callId = widget.conversationId;
    await FirebaseFirestore.instance.collection(AppConstants.colCalls).doc(callId).set({
      'callerId': currentUserId,
      'receiverId': widget.otherUserId,
      'status': 'ringing',
      'type': isVideo ? 'video' : 'voice',
      'createdAt': FieldValue.serverTimestamp(),
    });

    Get.to(() => CallScreen(
      callId: callId,
      otherUserId: widget.otherUserId,
      otherUserName: widget.otherUserName,
      otherUserPhotoUrl: widget.otherUserPhotoUrl,
      isVideo: isVideo,
      isIncoming: false,
    ));
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textCtrl.clear();

    try {
      final msgRef = FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(widget.conversationId)
          .collection(AppConstants.colMessages)
          .doc();

      await msgRef.set({
        'senderId': currentUserId,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
        'seen': false,
      });

      await FirebaseFirestore.instance.collection(AppConstants.colConversations).doc(widget.conversationId).update({
        'lastMessage': text,
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderId': currentUserId,
        'unreadCount.${widget.otherUserId}': FieldValue.increment(1),
      });

      _scrollToBottom();
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        title: Row(
          children: [
            CircleAvatar(radius: 18, backgroundImage: widget.otherUserPhotoUrl != null ? NetworkImage(widget.otherUserPhotoUrl!) : null),
            const SizedBox(width: 10),
            Expanded(child: Text(widget.otherUserName, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.call, color: AppColors.primary), onPressed: () => _initiateCall(isVideo: false)),
          IconButton(icon: const Icon(Icons.videocam, color: AppColors.primary), onPressed: () => _initiateCall(isVideo: true)),
          const SizedBox(width: 5),
        ],
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colConversations)
          .doc(widget.conversationId)
          .collection(AppConstants.colMessages)
          .orderBy('timestamp', descending: false)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
        
        // ✅ Đánh dấu đã xem khi có tin nhắn mới trong lúc đang mở app
        FirestoreService.markMessagesAsSeen(widget.conversationId);
        
        final messages = snapshot.data!.docs;
        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.all(16),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data() as Map<String, dynamic>;
            final bool isMe = data['senderId'] == currentUserId;
            final bool isLast = index == messages.length - 1;
            
            return _MessageBubble(
              text: data['text'],
              isMe: isMe,
              showSeen: isLast && isMe && (data['seen'] == true),
            );
          },
        );
      },
    );
  }

  Widget _buildInputBar() {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 10, 16, MediaQuery.of(context).padding.bottom + 10),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey[200]!))),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textCtrl,
              decoration: InputDecoration(
                hintText: "Nhắn tin...",
                filled: true, fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(25), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _sendMessage,
            child: const CircleAvatar(backgroundColor: AppColors.primary, child: Icon(Icons.send, color: Colors.white, size: 20)),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final bool showSeen;

  const _MessageBubble({required this.text, required this.isMe, required this.showSeen});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.symmetric(vertical: 2),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isMe ? AppColors.primary : Colors.grey[200],
            borderRadius: BorderRadius.circular(20).copyWith(
              bottomRight: isMe ? const Radius.circular(0) : const Radius.circular(20),
              bottomLeft: isMe ? const Radius.circular(20) : const Radius.circular(0),
            ),
          ),
          child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontSize: 15)),
        ),
        if (showSeen)
          const Padding(
            padding: EdgeInsets.only(top: 2, right: 4),
            child: Text("Đã xem", style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }
}
