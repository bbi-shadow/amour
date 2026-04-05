import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import '../../services/match_service.dart';

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
  final MatchService _matchService = MatchService();
  final String currentUserId = FirebaseAuth.instance.currentUser!.uid;
  bool _isSending = false;

  @override
  void initState() {
    super.initState();
    // Đánh dấu đã xem khi vào màn hình
    _matchService.markAsSeen(widget.conversationId);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty || _isSending) return;

    setState(() => _isSending = true);
    _textCtrl.clear();

    try {
      await _matchService.sendMessage(
        conversationId: widget.conversationId,
        text: text,
        receiverId: widget.otherUserId,
      );
      _scrollToBottom();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể gửi tin nhắn')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      appBar: _buildAppBar(),
      body: Column(
        children: [
          Expanded(child: _buildMessageList()),
          _buildInputBar(),
        ],
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 0.5,
      shadowColor: const Color(0xFFFFEEF2),
      leadingWidth: 40,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios,
            color: Color(0xFF2D2D2D), size: 20),
        onPressed: () => Navigator.pop(context),
      ),
      title: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFFB3C1),
            backgroundImage: widget.otherUserPhotoUrl != null
                ? NetworkImage(widget.otherUserPhotoUrl!)
                : null,
            child: widget.otherUserPhotoUrl == null
                ? Text(
              widget.otherUserName.isNotEmpty
                  ? widget.otherUserName[0].toUpperCase()
                  : '?',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            )
                : null,
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.otherUserName,
                style: const TextStyle(
                  color: Color(0xFF2D2D2D),
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Text(
                'Đang hoạt động',
                style: TextStyle(
                  color: Color(0xFF4CAF50),
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: Color(0xFF888888)),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildMessageList() {
    return StreamBuilder<QuerySnapshot>(
      stream: _matchService.getMessages(widget.conversationId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFF6B8A)),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return _buildChatEmptyState();
        }

        // Đánh dấu seen khi nhận tin mới
        _matchService.markAsSeen(widget.conversationId);
        _scrollToBottom();

        final messages = snapshot.data!.docs;

        return ListView.builder(
          controller: _scrollCtrl,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final msg = messages[index].data() as Map<String, dynamic>;
            final isMe = msg['senderId'] == currentUserId;
            final isLast = index == messages.length - 1;

            // Kiểm tra có hiển thị thời gian không
            bool showTime = false;
            if (index == 0) {
              showTime = true;
            } else {
              final prevMsg =
              messages[index - 1].data() as Map<String, dynamic>;
              final prevTs = prevMsg['timestamp'] as Timestamp?;
              final currTs = msg['timestamp'] as Timestamp?;
              if (prevTs != null && currTs != null) {
                final diff =
                    currTs.toDate().difference(prevTs.toDate()).inMinutes;
                showTime = diff > 10;
              }
            }

            return _MessageBubble(
              text: msg['text'] ?? '',
              isMe: isMe,
              timestamp: msg['timestamp'] as Timestamp?,
              seen: msg['seen'] ?? false,
              showTime: showTime,
              isLastMessage: isLast && isMe,
              otherUserPhoto: widget.otherUserPhotoUrl,
            );
          },
        );
      },
    );
  }

  Widget _buildChatEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('💕', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 12),
          Text(
            'Bạn và ${widget.otherUserName} đã match!',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D2D2D),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Hãy gửi lời chào đầu tiên nhé 👋',
            style: TextStyle(color: Color(0xFFAAAAAA), fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.only(
        left: 16,
        right: 12,
        top: 10,
        bottom: MediaQuery.of(context).padding.bottom + 10,
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF5F5F5),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _textCtrl,
                textCapitalization: TextCapitalization.sentences,
                maxLines: null,
                decoration: const InputDecoration(
                  hintText: 'Nhắn tin...',
                  hintStyle: TextStyle(color: Color(0xFFBBBBBB)),
                  border: InputBorder.none,
                  contentPadding:
                  EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              width: 46,
              height: 46,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF6B8A), Color(0xFFFF9BB0)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: _isSending
                  ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.send_rounded,
                  color: Colors.white, size: 22),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String text;
  final bool isMe;
  final Timestamp? timestamp;
  final bool seen;
  final bool showTime;
  final bool isLastMessage;
  final String? otherUserPhoto;

  const _MessageBubble({
    required this.text,
    required this.isMe,
    required this.timestamp,
    required this.seen,
    required this.showTime,
    required this.isLastMessage,
    this.otherUserPhoto,
  });

  String get timeText {
    if (timestamp == null) return '';
    return DateFormat('HH:mm').format(timestamp!.toDate());
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Hiển thị thời gian phân cách
        if (showTime)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              _formatTimestamp(timestamp),
              style: const TextStyle(
                color: Color(0xFFCCCCCC),
                fontSize: 12,
              ),
            ),
          ),

        // Bong bóng tin nhắn
        Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Row(
            mainAxisAlignment:
            isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Avatar của đối phương
              if (!isMe) ...[
                CircleAvatar(
                  radius: 14,
                  backgroundColor: const Color(0xFFFFB3C1),
                  backgroundImage: otherUserPhoto != null
                      ? NetworkImage(otherUserPhoto!)
                      : null,
                  child: otherUserPhoto == null
                      ? const Icon(Icons.person,
                      color: Colors.white, size: 16)
                      : null,
                ),
                const SizedBox(width: 6),
              ],

              // Bubble
              Flexible(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.68,
                  ),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isMe
                        ? const Color(0xFFFF6B8A)
                        : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(18),
                      topRight: const Radius.circular(18),
                      bottomLeft: Radius.circular(isMe ? 18 : 4),
                      bottomRight: Radius.circular(isMe ? 4 : 18),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Text(
                    text,
                    style: TextStyle(
                      color: isMe ? Colors.white : const Color(0xFF2D2D2D),
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),
                ),
              ),

              // Thời gian + seen (chỉ tin nhắn của mình)
              if (isMe) ...[
                const SizedBox(width: 4),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      timeText,
                      style: const TextStyle(
                        color: Color(0xFFCCCCCC),
                        fontSize: 11,
                      ),
                    ),
                    if (isLastMessage)
                      Text(
                        seen ? 'Đã xem' : 'Đã gửi',
                        style: TextStyle(
                          color: seen
                              ? const Color(0xFFFF6B8A)
                              : const Color(0xFFCCCCCC),
                          fontSize: 11,
                        ),
                      ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  String _formatTimestamp(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    if (now.difference(dt).inDays == 0) {
      return 'Hôm nay ${DateFormat('HH:mm').format(dt)}';
    } else if (now.difference(dt).inDays == 1) {
      return 'Hôm qua ${DateFormat('HH:mm').format(dt)}';
    }
    return DateFormat('dd/MM/yyyy HH:mm').format(dt);
  }
}