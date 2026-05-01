import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/chat_detail_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/message_model.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';

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
  late ChatDetailController controller;
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final RxBool _showEmojiBar = false.obs;

  static const List<String> quickEmojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];

  @override
  void initState() {
    super.initState();
    controller = Get.put(
      ChatDetailController(
        conversationId: widget.conversationId,
        otherUserId: widget.otherUserId,
      ),
      tag: widget.conversationId,
    );
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bg = isDark ? AppColors.darkBg : const Color(0xFFF0F0F5);
      final otherUser = controller.otherUser.value;

      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(isDark, otherUser),
        body: Column(children: [
          Expanded(child: _buildMessageList(isDark)),
          if (_showEmojiBar.value) _buildQuickEmojiBar(isDark),
          if (controller.replyToText.value.isNotEmpty) _buildReplyPreview(isDark),
          _buildInputBar(isDark),
        ]),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(bool isDark, dynamic otherUser) {
    return AppBar(
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, size: 18, color: isDark ? Colors.white : Colors.black87),
        onPressed: () => Get.back(),
      ),
      title: Row(children: [
        CircleAvatar(
          radius: 18,
          backgroundImage: (otherUser?.photoUrl?.isNotEmpty ?? false) ? NetworkImage(otherUser!.photoUrl) : null,
          child: (otherUser?.photoUrl?.isEmpty ?? true) ? Text(widget.otherUserName[0].toUpperCase()) : null,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.otherUserName, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: isDark ? Colors.white : Colors.black)),
              Text(
                controller.isOtherTyping.value ? 'đang nhập...' : (otherUser?.isOnline == true ? 'Hoạt động' : 'Offline'),
                style: TextStyle(fontSize: 11, color: controller.isOtherTyping.value ? AppColors.primary : Colors.grey),
              ),
            ],
          ),
        ),
      ]),
      actions: [
        IconButton(icon: const Icon(Icons.call_rounded, color: AppColors.primary, size: 22), onPressed: () => controller.initiateCall(isVideo: false)),
        IconButton(icon: const Icon(Icons.videocam_rounded, color: AppColors.primary, size: 24), onPressed: () => controller.initiateCall(isVideo: true)),
        const SizedBox(width: 4),
      ],
    );
  }

  Widget _buildMessageList(bool isDark) {
    return Obx(() {
      final msgs = controller.messages;
      if (msgs.isEmpty) return _buildEmptyChat();
      _scrollToBottom();

      return ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        itemCount: msgs.length,
        itemBuilder: (ctx, i) {
          final msg = msgs[i];
          final isMe = msg.senderId == controller.myId;
          final showTime = i == 0 || msg.timestamp!.difference(msgs[i - 1].timestamp!).inMinutes > 5;
          final isLast = i == msgs.length - 1;

          return Column(children: [
            if (showTime) _buildTimeDivider(msg.timestamp),
            _buildMessageBubble(msg, isMe, isDark, isLast),
          ]);
        },
      );
    });
  }

  Widget _buildMessageBubble(MessageModel msg, bool isMe, bool isDark, bool isLast) {
    if (msg.type == MessageType.system) return _buildCallInfo(msg);

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 2),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
            decoration: BoxDecoration(
              color: isMe ? AppColors.primary : (isDark ? AppColors.darkCard : Colors.white),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: Radius.circular(isMe ? 18 : 4),
                bottomRight: Radius.circular(isMe ? 4 : 18),
              ),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 4)],
            ),
            child: Text(
              msg.text,
              style: TextStyle(color: isMe ? Colors.white : (isDark ? Colors.white : Colors.black87), fontSize: 14.5, height: 1.4),
            ),
          ),
          if (isMe && isLast)
            Padding(
              padding: const EdgeInsets.only(top: 2, right: 4),
              child: Text(msg.seen ? 'Đã xem' : 'Đã gửi', style: const TextStyle(fontSize: 10, color: Colors.grey)),
            ),
        ],
      ),
    );
  }

  Widget _buildCallInfo(MessageModel msg) {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(color: Colors.black.withOpacity(0.05), borderRadius: BorderRadius.circular(12)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(msg.text.toLowerCase().contains('video') ? Icons.videocam_outlined : Icons.call_outlined, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Text(msg.text, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildTimeDivider(DateTime? ts) {
    if (ts == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(
        DateFormat('HH:mm').format(ts),
        style: const TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildQuickEmojiBar(bool isDark) {
    return Container(
      height: 50,
      color: isDark ? AppColors.darkCard : Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: quickEmojis.map((e) => GestureDetector(
          onTap: () {
            controller.sendMessage(e);
            _showEmojiBar.value = false;
          },
          child: Text(e, style: const TextStyle(fontSize: 24)),
        )).toList(),
      ),
    );
  }

  Widget _buildReplyPreview(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
        border: Border(left: BorderSide(color: AppColors.primary, width: 4)),
      ),
      child: Row(children: [
        Expanded(child: Text(controller.replyToText.value, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Colors.grey))),
        IconButton(icon: const Icon(Icons.close, size: 16), onPressed: () => controller.replyToText.value = ''),
      ]),
    );
  }

  Widget _buildInputBar(bool isDark) {
    return Container(
      padding: EdgeInsets.fromLTRB(8, 8, 8, MediaQuery.of(context).padding.bottom + 8),
      decoration: BoxDecoration(color: isDark ? AppColors.darkCard : Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)]),
      child: Row(children: [
        IconButton(
          icon: Icon(_showEmojiBar.value ? Icons.emoji_emotions : Icons.emoji_emotions_outlined, color: _showEmojiBar.value ? AppColors.primary : Colors.grey),
          onPressed: () => _showEmojiBar.toggle(),
        ),
        Expanded(
          child: TextField(
            controller: _textCtrl,
            onChanged: controller.onTextChanged,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'Nhắn tin...',
              filled: true,
              fillColor: isDark ? AppColors.darkBg : const Color(0xFFF2F2F7),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        const SizedBox(width: 8),
        GestureDetector(
          onTap: () {
            if (_textCtrl.text.trim().isEmpty) return;
            controller.sendMessage(_textCtrl.text);
            _textCtrl.clear();
            _showEmojiBar.value = false;
          },
          child: const CircleAvatar(
            backgroundColor: AppColors.primary,
            radius: 22,
            child: Icon(Icons.send_rounded, color: Colors.white, size: 20),
          ),
        ),
      ]),
    );
  }

  Widget _buildEmptyChat() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.chat_bubble_outline_rounded, size: 64, color: Colors.grey.withOpacity(0.3)),
      const SizedBox(height: 12),
      const Text('Bắt đầu cuộc trò chuyện', style: TextStyle(color: Colors.grey)),
    ]));
  }
}
