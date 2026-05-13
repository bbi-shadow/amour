import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/chat_detail_controller.dart';
import '../../models/message_model.dart';
import '../../themes/app_theme.dart';

// ══════════════════════════════════════════════════════════════════
// ChatDetailScreen — Dark Messenger 1000%
// ══════════════════════════════════════════════════════════════════
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

class _ChatDetailScreenState extends State<ChatDetailScreen>
    with TickerProviderStateMixin {
  late ChatDetailController _c;
  final _textCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _hasText = false.obs;
  final _showEmoji = false.obs;
  final _showAttach = false.obs;

  static const _emojis = ['❤️', '😂', '😮', '😢', '😡', '👍'];
  static const _reactionEmojis = ['❤️', '👍', '😂', '😮', '😢', '😡'];

  @override
  void initState() {
    super.initState();
    _c = Get.put(
      ChatDetailController(
        conversationId: widget.conversationId,
        otherUserId: widget.otherUserId,
      ),
      tag: widget.conversationId,
    );
    _scrollCtrl.addListener(_onScroll);
    _textCtrl.addListener(
            () => _hasText.value = _textCtrl.text.trim().isNotEmpty);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels <= 100 &&
        _c.hasMoreMessages.value) {
      _c.loadMoreMessages();
    }
  }

  void _scrollToBottom({bool jump = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollCtrl.hasClients) return;
      final max = _scrollCtrl.position.maxScrollExtent;
      if (jump) {
        _scrollCtrl.jumpTo(max);
      } else {
        _scrollCtrl.animateTo(max,
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: _buildAppBar(),
      body: GestureDetector(
        onTap: () {
          _showEmoji.value = false;
          _showAttach.value = false;
          FocusScope.of(context).unfocus();
        },
        child: Column(children: [
          // Load more bar
          Obx(() => _c.isLoadingMore.value
              ? LinearProgressIndicator(
              minHeight: 2,
              color: AppColors.primary,
              backgroundColor: AppColors.darkCard)
              : const SizedBox.shrink()),

          // Messages
          Expanded(child: _buildMessageList()),

          // Typing
          Obx(() => _c.isOtherTyping.value
              ? _buildTypingIndicator()
              : const SizedBox.shrink()),

          // Emoji quick bar
          Obx(() =>
          _showEmoji.value ? _buildEmojiBar() : const SizedBox.shrink()),

          // Reply preview
          Obx(() => _c.replyToMessage.value != null
              ? _buildReplyPreview()
              : const SizedBox.shrink()),

          // Attach menu
          Obx(() => _showAttach.value
              ? _buildAttachMenu()
              : const SizedBox.shrink()),

          _buildInputBar(),
        ]),
      ),
    );
  }

  // ── AppBar ─────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppColors.darkCard,
      elevation: 0,
      titleSpacing: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded,
            color: Colors.white, size: 18),
        onPressed: () => Get.back(),
      ),
      title: Obx(() {
        final user = _c.otherUser.value;
        final isOnline = user?.isOnline == true;
        final isTyping = _c.isOtherTyping.value;
        return Row(children: [
          Stack(children: [
            CircleAvatar(
              radius: 19,
              backgroundColor: const Color(0xFF2A2A3D),
              backgroundImage:
              (user?.photoUrl.isNotEmpty ?? false)
                  ? NetworkImage(user!.photoUrl)
                  : null,
              child: (user?.photoUrl.isEmpty ?? true)
                  ? Text(widget.otherUserName[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14))
                  : null,
            ),
            if (isOnline)
              Positioned(
                right: 0, bottom: 0,
                child: Container(
                  width: 11, height: 11,
                  decoration: BoxDecoration(
                    color: AppColors.online,
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: AppColors.darkCard, width: 1.5),
                  ),
                ),
              ),
          ]),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.otherUserName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: isTyping
                        ? const Text('đang nhập...',
                        key: ValueKey('typing'),
                        style: TextStyle(
                            color: AppColors.primary,
                            fontSize: 11))
                        : Text(
                      key: ValueKey('status'),
                      isOnline
                          ? 'Đang hoạt động'
                          : _lastSeenText(user),
                      style: TextStyle(
                        fontSize: 11,
                        color: isOnline
                            ? AppColors.online
                            : const Color(0xFF8A8A9A),
                      ),
                    ),
                  ),
                ]),
          ),
        ]);
      }),
      actions: [
        IconButton(
          icon: const Icon(Icons.call_rounded,
              color: Colors.white, size: 22),
          onPressed: () => _c.initiateCall(isVideo: false),
        ),
        IconButton(
          icon: const Icon(Icons.videocam_rounded,
              color: Colors.white, size: 24),
          onPressed: () => _c.initiateCall(isVideo: true),
        ),
        const SizedBox(width: 4),
      ],
    );
  }

  String _lastSeenText(dynamic user) {
    if (user?.lastSeen == null) return 'Offline';
    final diff =
    DateTime.now().difference(user!.lastSeen as DateTime);
    if (diff.inMinutes < 5) return 'Vừa mới online';
    if (diff.inHours < 1) return 'Online ${diff.inMinutes}p trước';
    if (diff.inDays < 1) return 'Online ${diff.inHours}g trước';
    return 'Online ' + DateFormat('dd/MM').format(user.lastSeen);
  }

  // ── Message List ───────────────────────────────────────────────
  Widget _buildMessageList() {
    return Obx(() {
      final msgs = _c.messages
          .where((m) => m.deletedFor[_c.myId] != true)
          .toList();

      if (msgs.isEmpty) return _buildEmptyChat();
      _scrollToBottom();

      return ListView.builder(
        controller: _scrollCtrl,
        physics: const BouncingScrollPhysics(),
        padding:
        const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        itemCount: msgs.length,
        itemBuilder: (ctx, i) {
          final msg = msgs[i];
          final isMe = msg.senderId == _c.myId;
          final showDate = i == 0 ||
              !_isSameDay(msg.timestamp, msgs[i - 1].timestamp);
          final showTime = i == 0 ||
              ((msg.timestamp
                  ?.difference(
                  msgs[i - 1].timestamp ?? DateTime(0))
                  .inMinutes ??
                  0)
                  .abs() >
                  5);
          // nhóm avatar — chỉ show avatar ở tin cuối cùng liên tiếp của người kia
          final isLastInGroup = !isMe &&
              (i == msgs.length - 1 ||
                  msgs[i + 1].senderId == _c.myId);
          final isFirstInGroup = isMe
              ? false
              : (i == 0 || msgs[i - 1].senderId == _c.myId);
          final isLastMsg = i == msgs.length - 1;

          return Column(children: [
            if (showDate) _dateDivider(msg.timestamp),
            if (showTime && !showDate) _timeDivider(msg.timestamp),
            _MessageRow(
              msg: msg,
              isMe: isMe,
              isLastInGroup: isLastInGroup,
              isFirstInGroup: isFirstInGroup,
              isLastMsg: isLastMsg,
              controller: _c,
              otherUser: _c.otherUser.value,
              onLongPress: () =>
                  _showActions(ctx, msg, isMe),
              onDoubleTap: () => _showReactions(ctx, msg),
            ),
          ]);
        },
      );
    });
  }

  bool _isSameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day;
  }

  Widget _dateDivider(DateTime? ts) {
    if (ts == null) return const SizedBox.shrink();
    final now = DateTime.now();
    String label;
    if (_isSameDay(ts, now)) {
      label = 'Hôm nay';
    } else if (_isSameDay(
        ts, now.subtract(const Duration(days: 1)))) {
      label = 'Hôm qua';
    } else {
      label = DateFormat('dd/MM/yyyy').format(ts);
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(children: [
        Expanded(
            child: Divider(
                color: Colors.white.withOpacity(0.08), height: 1)),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  color: Color(0xFF6A6A7A),
                  fontWeight: FontWeight.w500)),
        ),
        Expanded(
            child: Divider(
                color: Colors.white.withOpacity(0.08), height: 1)),
      ]),
    );
  }

  Widget _timeDivider(DateTime? ts) {
    if (ts == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Center(
        child: Text(DateFormat('HH:mm').format(ts),
            style: const TextStyle(
                fontSize: 10, color: Color(0xFF6A6A7A))),
      ),
    );
  }

  Widget _buildEmptyChat() {
    return Center(
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: const Color(0xFF1A1A2E),
              backgroundImage:
              (widget.otherUserPhotoUrl?.isNotEmpty ?? false)
                  ? NetworkImage(widget.otherUserPhotoUrl!)
                  : null,
              child: (widget.otherUserPhotoUrl?.isEmpty ?? true)
                  ? Text(widget.otherUserName[0].toUpperCase(),
                  style: const TextStyle(
                      fontSize: 28,
                      color: Colors.white,
                      fontWeight: FontWeight.bold))
                  : null,
            ),
            const SizedBox(height: 12),
            Text(widget.otherUserName,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            const Text('Hãy nói xin chào đi! 👋',
                style:
                TextStyle(color: Color(0xFF8A8A9A), fontSize: 13)),
          ]),
    );
  }

  // ── Typing indicator ───────────────────────────────────────────
  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(left: 14, bottom: 6, top: 2),
      child: Row(children: [
        CircleAvatar(
          radius: 13,
          backgroundColor: const Color(0xFF2A2A3D),
          backgroundImage:
          (_c.otherUser.value?.photoUrl.isNotEmpty ?? false)
              ? NetworkImage(_c.otherUser.value!.photoUrl)
              : null,
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(
              horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF2A2A3D),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(18),
              topRight: Radius.circular(18),
              bottomLeft: Radius.circular(4),
              bottomRight: Radius.circular(18),
            ),
          ),
          child: const _TypingDots(),
        ),
      ]),
    );
  }

  // ── Input Bar ──────────────────────────────────────────────────
  Widget _buildInputBar() {
    final bottomPad = MediaQuery.of(context).padding.bottom;
    return Container(
      padding:
      EdgeInsets.fromLTRB(8, 8, 8, bottomPad > 0 ? bottomPad : 8),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(
            top: BorderSide(color: Color(0xFF2A2A3D), width: 0.5)),
      ),
      child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
        // Emoji
        Obx(() => _IconBtn(
          icon: _showEmoji.value
              ? Icons.keyboard_rounded
              : Icons.emoji_emotions_outlined,
          color: _showEmoji.value
              ? AppColors.primary
              : const Color(0xFF8A8A9A),
          onTap: () {
            _showEmoji.toggle();
            _showAttach.value = false;
            if (_showEmoji.value)
              FocusScope.of(context).unfocus();
          },
        )),

        // Attach
        _IconBtn(
          icon: Icons.add_circle_outline_rounded,
          color: const Color(0xFF8A8A9A),
          onTap: () {
            _showAttach.toggle();
            _showEmoji.value = false;
          },
        ),

        // Text field
        Expanded(
          child: Container(
            constraints: const BoxConstraints(maxHeight: 120),
            decoration: BoxDecoration(
              color: const Color(0xFF2A2A3D),
              borderRadius: BorderRadius.circular(22),
            ),
            child: TextField(
              controller: _textCtrl,
              onChanged: _c.onTextChanged,
              maxLines: null,
              minLines: 1,
              style: const TextStyle(
                  color: Colors.white, fontSize: 14.5, height: 1.4),
              decoration: const InputDecoration(
                hintText: 'Aa',
                hintStyle:
                TextStyle(color: Color(0xFF6A6A7A), fontSize: 14.5),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                    horizontal: 16, vertical: 10),
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Send / Like
        Obx(() {
          if (_c.isUploading.value) {
            return Container(
              width: 38, height: 38,
              decoration: const BoxDecoration(
                  color: AppColors.primary, shape: BoxShape.circle),
              child: const Padding(
                padding: EdgeInsets.all(9),
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              ),
            );
          }
          if (_hasText.value) {
            return GestureDetector(
              onTap: _sendText,
              child: Container(
                width: 38, height: 38,
                decoration: const BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle),
                child: const Icon(Icons.send_rounded,
                    color: Colors.white, size: 18),
              ),
            );
          }
          // Like button khi không có text
          return GestureDetector(
            onTap: () {
              _c.sendMessage('👍');
              _scrollToBottom();
            },
            child: const Text('👍', style: TextStyle(fontSize: 28)),
          );
        }),
      ]),
    );
  }

  void _sendText() {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) return;
    _c.sendMessage(text);
    _textCtrl.clear();
    _hasText.value = false;
    _showEmoji.value = false;
    _scrollToBottom();
  }

  Widget _buildEmojiBar() {
    return Container(
      height: 54,
      color: AppColors.darkCard,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: _emojis
            .map((e) => GestureDetector(
          onTap: () {
            _c.sendMessage(e);
            _showEmoji.value = false;
            _scrollToBottom();
          },
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Text(e,
                style: const TextStyle(fontSize: 26)),
          ),
        ))
            .toList(),
      ),
    );
  }

  Widget _buildAttachMenu() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(
            top: BorderSide(color: Color(0xFF2A2A3D), width: 0.5)),
      ),
      child: Row(children: [
        _AttachItem(
          icon: Icons.photo_library_rounded,
          label: 'Thư viện',
          color: const Color(0xFF7B5EA7),
          onTap: () {
            _c.sendImage(fromCamera: false);
            _showAttach.value = false;
          },
        ),
        const SizedBox(width: 20),
        _AttachItem(
          icon: Icons.camera_alt_rounded,
          label: 'Camera',
          color: const Color(0xFFE94057),
          onTap: () {
            _c.sendImage(fromCamera: true);
            _showAttach.value = false;
          },
        ),
      ]),
    );
  }

  Widget _buildReplyPreview() {
    final reply = _c.replyToMessage.value!;
    final isMyReply = reply.senderId == _c.myId;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: const BoxDecoration(
        color: Color(0xFF1A1A2E),
        border: Border(
            left: BorderSide(color: AppColors.primary, width: 3)),
      ),
      child: Row(children: [
        Expanded(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isMyReply
                      ? 'Trả lời chính mình'
                      : 'Trả lời ${widget.otherUserName}',
                  style: const TextStyle(
                      color: AppColors.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 2),
                Text(reply.text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        color: Color(0xFF8A8A9A), fontSize: 12)),
              ]),
        ),
        IconButton(
          icon: const Icon(Icons.close,
              size: 16, color: Color(0xFF8A8A9A)),
          onPressed: _c.clearReply,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
        ),
      ]),
    );
  }

  // ── Modals ─────────────────────────────────────────────────────
  void _showActions(
      BuildContext ctx, MessageModel msg, bool isMe) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: ctx,
      backgroundColor: const Color(0xFF1E1E30),
      shape: const RoundedRectangleBorder(
          borderRadius:
          BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 36, height: 4,
            margin: const EdgeInsets.only(top: 10, bottom: 14),
            decoration: BoxDecoration(
                color: Colors.white24,
                borderRadius: BorderRadius.circular(2)),
          ),
          // Reactions
          Padding(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: _reactionEmojis
                  .map((e) => GestureDetector(
                onTap: () {
                  _c.reactToMessage(msg.id, e);
                  Navigator.pop(ctx);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  child: Text(e,
                      style: const TextStyle(
                          fontSize: 28)),
                ),
              ))
                  .toList(),
            ),
          ),
          Divider(
              color: Colors.white.withOpacity(0.08), height: 1),
          _ActionTile(
            icon: Icons.reply_rounded,
            label: 'Trả lời',
            onTap: () {
              _c.setReply(msg);
              Navigator.pop(ctx);
            },
          ),
          if (!msg.isDeleted)
            _ActionTile(
              icon: Icons.copy_rounded,
              label: 'Sao chép',
              onTap: () {
                Clipboard.setData(ClipboardData(text: msg.text));
                Navigator.pop(ctx);
                Get.snackbar('', 'Đã sao chép',
                    snackPosition: SnackPosition.BOTTOM,
                    duration: const Duration(seconds: 1),
                    backgroundColor: const Color(0xFF2A2A3D),
                    colorText: Colors.white,
                    margin: const EdgeInsets.all(12),
                    borderRadius: 12);
              },
            ),
          if (isMe && !msg.isDeleted)
            _ActionTile(
              icon: Icons.undo_rounded,
              label: 'Thu hồi tin nhắn',
              color: Colors.orange,
              onTap: () {
                _c.unsendMessage(msg.id);
                Navigator.pop(ctx);
              },
            ),
          _ActionTile(
            icon: Icons.delete_outline_rounded,
            label: 'Xoá với tôi',
            color: Colors.redAccent,
            onTap: () {
              _c.deleteMessageForMe(msg.id);
              Navigator.pop(ctx);
            },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  void _showReactions(BuildContext ctx, MessageModel msg) {
    HapticFeedback.lightImpact();
    showDialog(
      context: ctx,
      builder: (_) => Dialog(
        backgroundColor: const Color(0xFF1E1E30),
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _reactionEmojis
                .map((e) => GestureDetector(
              onTap: () {
                _c.reactToMessage(msg.id, e);
                Navigator.pop(ctx);
              },
              child: Text(e,
                  style: const TextStyle(fontSize: 30)),
            ))
                .toList(),
          ),
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// MessageRow
// ══════════════════════════════════════════════════════════════════
class _MessageRow extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final bool isLastInGroup;
  final bool isFirstInGroup;
  final bool isLastMsg;
  final ChatDetailController controller;
  final dynamic otherUser;
  final VoidCallback onLongPress;
  final VoidCallback onDoubleTap;

  const _MessageRow({
    required this.msg,
    required this.isMe,
    required this.isLastInGroup,
    required this.isFirstInGroup,
    required this.isLastMsg,
    required this.controller,
    required this.otherUser,
    required this.onLongPress,
    required this.onDoubleTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onLongPress: onLongPress,
      onDoubleTap: onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 1.5),
        child: Column(
          crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: isMe
                  ? MainAxisAlignment.end
                  : MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Avatar người kia
                if (!isMe) ...[
                  if (isLastInGroup)
                    CircleAvatar(
                      radius: 13,
                      backgroundColor: const Color(0xFF2A2A3D),
                      backgroundImage:
                      (otherUser?.photoUrl?.isNotEmpty ?? false)
                          ? NetworkImage(otherUser!.photoUrl)
                          : null,
                    )
                  else
                    const SizedBox(width: 26),
                  const SizedBox(width: 6),
                ],

                // Bubble
                Flexible(
                    child: _Bubble(
                        msg: msg,
                        isMe: isMe,
                        context: context)),

                // Space for my side
                if (isMe) const SizedBox(width: 2),
              ],
            ),

            // Reactions
            if (msg.reaction.isNotEmpty)
              Padding(
                padding: EdgeInsets.only(
                    left: isMe ? 0 : 46,
                    right: isMe ? 6 : 0,
                    top: 2,
                    bottom: 2),
                child: Wrap(
                  spacing: 3,
                  children: msg.reactionSummary.entries
                      .map((e) => Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF2A2A3D),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: AppColors.darkBg, width: 1.5),
                    ),
                    child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(e.key,
                              style: const TextStyle(
                                  fontSize: 11)),
                          if (e.value > 1) ...[
                            const SizedBox(width: 2),
                            Text('${e.value}',
                                style: const TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey)),
                          ],
                        ]),
                  ))
                      .toList(),
                ),
              ),

            // Status (chỉ tin nhắn cuối của mình)
            if (isMe && isLastMsg)
              Padding(
                padding: const EdgeInsets.only(top: 2, right: 6),
                child: _StatusRow(msg: msg),
              ),
          ],
        ),
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════
// Bubble
// ══════════════════════════════════════════════════════════════════
class _Bubble extends StatelessWidget {
  final MessageModel msg;
  final bool isMe;
  final BuildContext context;

  const _Bubble(
      {required this.msg,
        required this.isMe,
        required this.context});

  @override
  Widget build(BuildContext buildCtx) {
    final maxW = MediaQuery.of(context).size.width * 0.72;
    final isDeleted = msg.isDeleted;

    // Call message — centered system bubble
    if (msg.isCallMessage ||
        msg.type == MessageType.video_call ||
        msg.type == MessageType.voice_call) {
      return _CallBubble(msg: msg);
    }

    // Deleted
    if (isDeleted) {
      return Container(
        constraints: BoxConstraints(maxWidth: maxW),
        padding: const EdgeInsets.symmetric(
            horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.white.withOpacity(0.1)),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.remove_circle_outline,
              size: 13,
              color: Colors.white.withOpacity(0.3)),
          const SizedBox(width: 6),
          Text('Tin nhắn đã thu hồi',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.3),
                  fontSize: 13,
                  fontStyle: FontStyle.italic)),
        ]),
      );
    }

    // Reply preview inside
    Widget? replyWidget;
    if (msg.replyToText != null) {
      replyWidget = Container(
        padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.15),
          border: const Border(
              left: BorderSide(color: Colors.white38, width: 2)),
          borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              topRight: Radius.circular(14)),
        ),
        child: Text(
          msg.replyToText!,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: 12,
              color: isMe
                  ? Colors.white60
                  : const Color(0xFF8A8A9A)),
        ),
      );
    }

    // Image
    if (msg.type == MessageType.image && msg.mediaUrl != null) {
      return GestureDetector(
        onTap: () => _viewImage(msg.mediaUrl!),
        child: ClipRRect(
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          child: Image.network(
            msg.mediaUrl!,
            width: 220,
            height: 220,
            fit: BoxFit.cover,
            loadingBuilder: (c, child, prog) {
              if (prog == null) return child;
              return Container(
                width: 220, height: 220,
                color: const Color(0xFF2A2A3D),
                child: const Center(
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppColors.primary)),
              );
            },
            errorBuilder: (_, __, ___) => Container(
              width: 220, height: 100,
              color: const Color(0xFF2A2A3D),
              child: const Icon(Icons.broken_image_outlined,
                  color: Colors.grey),
            ),
          ),
        ),
      );
    }

    // Pure emoji — no bubble bg
    final isOnlyEmoji = _isPureEmoji(msg.text) && replyWidget == null;
    if (isOnlyEmoji) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: Text(msg.text,
            style: const TextStyle(fontSize: 36)),
      );
    }

    // Text bubble
    return Container(
      constraints: BoxConstraints(maxWidth: maxW),
      decoration: BoxDecoration(
        color: isMe
            ? AppColors.primary
            : const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.only(
          topLeft: const Radius.circular(18),
          topRight: const Radius.circular(18),
          bottomLeft: Radius.circular(isMe ? 18 : 4),
          bottomRight: Radius.circular(isMe ? 4 : 18),
        ),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (replyWidget != null) replyWidget,
            Padding(
              padding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 9),
              child: Text(msg.text,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      height: 1.4)),
            ),
          ]),
    );
  }

  bool _isPureEmoji(String text) {
    if (text.isEmpty || text.length > 8) return false;
    final noEmoji =
    text.replaceAll(RegExp(r'\p{Emoji}', unicode: true), '');
    return noEmoji.trim().isEmpty;
  }

  void _viewImage(String url) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white)),
        body: Center(
            child: InteractiveViewer(
                child: Image.network(url, fit: BoxFit.contain))),
      ),
    ));
  }
}

// ── Call Bubble ────────────────────────────────────────────────────
class _CallBubble extends StatelessWidget {
  final MessageModel msg;
  const _CallBubble({required this.msg});

  @override
  Widget build(BuildContext context) {
    final isVideo = msg.type == MessageType.video_call ||
        msg.text.contains('📹') ||
        msg.text.contains('video');
    final isMissed = msg.callStatus == 'no_answer' ||
        msg.callStatus == 'rejected' ||
        msg.text.contains('nhỡ') ||
        msg.text.contains('Không kết nối');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF2A2A3D),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
            color: isMissed
                ? Colors.red.withOpacity(0.3)
                : Colors.white.withOpacity(0.06)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: isMissed
                ? Colors.red.withOpacity(0.15)
                : AppColors.primary.withOpacity(0.15),
            shape: BoxShape.circle,
          ),
          child: Icon(
            isVideo ? Icons.videocam_rounded : Icons.call_rounded,
            size: 16,
            color: isMissed ? Colors.redAccent : AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            isVideo ? 'Cuộc gọi video' : 'Cuộc gọi thoại',
            style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w600),
          ),
          Text(
            isMissed ? 'Không kết nối được' : _duration(),
            style: TextStyle(
                fontSize: 11,
                color: isMissed
                    ? Colors.redAccent
                    : const Color(0xFF8A8A9A)),
          ),
        ]),
      ]),
    );
  }

  String _duration() {
    final d = msg.callDuration ?? 0;
    if (d == 0) return 'Không kết nối được';
    final m = d ~/ 60;
    final s = d % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }
}

// ── Status Row ─────────────────────────────────────────────────────
class _StatusRow extends StatelessWidget {
  final MessageModel msg;
  const _StatusRow({required this.msg});

  @override
  Widget build(BuildContext context) {
    if (msg.isDeleted) return const SizedBox.shrink();
    IconData icon;
    Color color;
    String label;
    if (msg.seen) {
      icon = Icons.done_all_rounded;
      color = AppColors.primary;
      label = 'Đã xem';
    } else if (msg.delivered) {
      icon = Icons.done_all_rounded;
      color = Colors.grey;
      label = 'Đã nhận';
    } else {
      icon = Icons.done_rounded;
      color = Colors.grey;
      label = 'Đã gửi';
    }
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 3),
      Text(label,
          style: TextStyle(fontSize: 10, color: color)),
    ]);
  }
}

// ── Helpers ────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _IconBtn(
      {required this.icon,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
        child: Icon(icon, color: color, size: 26),
      ),
    );
  }
}

class _AttachItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _AttachItem(
      {required this.icon,
        required this.label,
        required this.color,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: 52, height: 52,
          decoration: BoxDecoration(
            color: color.withOpacity(0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(icon, color: color, size: 26),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontSize: 11, color: Colors.grey)),
      ]),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionTile(
      {required this.icon,
        required this.label,
        required this.onTap,
        this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? Colors.white;
    return ListTile(
      leading: Icon(icon, color: c, size: 22),
      title: Text(label,
          style: TextStyle(
              color: c, fontWeight: FontWeight.w500, fontSize: 14)),
      onTap: onTap,
    );
  }
}

// ── Typing Dots ────────────────────────────────────────────────────
class _TypingDots extends StatefulWidget {
  const _TypingDots();
  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _ctls;
  late List<Animation<double>> _anims;

  @override
  void initState() {
    super.initState();
    _ctls = List.generate(
        3,
            (_) => AnimationController(
            vsync: this,
            duration: const Duration(milliseconds: 400)));
    _anims = _ctls
        .map((c) => Tween<double>(begin: 0, end: -5).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
    for (var i = 0; i < 3; i++) {
      Future.delayed(Duration(milliseconds: i * 140), () {
        if (mounted) _ctls[i].repeat(reverse: true);
      });
    }
  }

  @override
  void dispose() {
    for (final c in _ctls) c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 18,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(
          3,
              (i) => AnimatedBuilder(
            animation: _anims[i],
            builder: (_, __) => Transform.translate(
              offset: Offset(0, _anims[i].value),
              child: Container(
                width: 7, height: 7,
                margin:
                const EdgeInsets.symmetric(horizontal: 2),
                decoration: const BoxDecoration(
                    color: Color(0xFF8A8A9A),
                    shape: BoxShape.circle),
              ),
            ),
          ),
        ),
      ),
    );
  }
}