import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/chat_list_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/user_model.dart';
import '../../themes/app_theme.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Get.put(ChatListController());
    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bg    = isDark ? AppColors.darkBg   : Colors.white;
      return Scaffold(
        backgroundColor: bg,
        body: SafeArea(
          child: Obx(() => Column(children: [
            _buildHeader(c, isDark),
            _buildSearchBar(c, isDark),
            Expanded(
              child: c.isLoading.value
                  ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                  : c.allConversations.isEmpty
                  ? _buildEmpty(isDark)
                  : _buildBody(c, isDark),
            ),
          ])),
        ),
      );
    });
  }

  Widget _buildHeader(ChatListController c, bool isDark) {
    final tc = isDark ? Colors.white : AppColors.lightText;
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 16, 4),
      child: Row(children: [
        Text('Đoạn chat',
            style: TextStyle(
                color: tc, fontSize: 26,
                fontWeight: FontWeight.w800, letterSpacing: -0.5)),
        const Spacer(),
        _HeaderBtn(icon: Icons.edit_rounded, onTap: () {}, isDark: isDark),
      ]),
    );
  }

  Widget _buildSearchBar(ChatListController c, bool isDark) {
    final fieldBg = isDark ? const Color(0xFF2A2A3D) : const Color(0xFFF0F0F0);
    final hintColor = isDark ? Colors.grey : Colors.grey.shade500;
    final textColor = isDark ? Colors.white : AppColors.lightText;
    return GestureDetector(
      onTap: c.toggleSearch,
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        child: c.isSearching.value
            ? Container(
          key: const ValueKey('input'),
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          height: 40,
          decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: hintColor, size: 18),
            const SizedBox(width: 8),
            Expanded(
              child: TextField(
                autofocus: true,
                onChanged: c.updateSearch,
                style: TextStyle(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Tìm kiếm...',
                  hintStyle: TextStyle(color: hintColor, fontSize: 14),
                  border: InputBorder.none, isDense: true,
                ),
              ),
            ),
            GestureDetector(
              onTap: c.toggleSearch,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: const Text('Huỷ', style: TextStyle(color: AppColors.primary, fontSize: 13)),
              ),
            ),
          ]),
        )
            : Container(
          key: const ValueKey('tap'),
          margin: const EdgeInsets.fromLTRB(16, 4, 16, 10),
          height: 40,
          decoration: BoxDecoration(color: fieldBg, borderRadius: BorderRadius.circular(20)),
          child: Row(children: [
            const SizedBox(width: 12),
            Icon(Icons.search, color: hintColor, size: 18),
            const SizedBox(width: 8),
            Text('Tìm kiếm', style: TextStyle(color: hintColor, fontSize: 14)),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody(ChatListController c, bool isDark) {
    final myUid = AuthController.to.currentUid ?? '';
    final convs = c.isSearching.value ? c.filteredConversations : c.allConversations;
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (!c.isSearching.value) ...[
          SliverToBoxAdapter(child: _sectionLabel('Bạn bè mới', isDark)),
          SliverToBoxAdapter(child: _buildBubbleRow(c, myUid, isDark)),
          SliverToBoxAdapter(child: _sectionLabel('Đoạn chat', isDark)),
        ],
        if (convs.isEmpty)
          SliverFillRemaining(
            child: Center(child: Text('Không có kết quả',
                style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500, fontSize: 14))),
          )
        else
          SliverList(delegate: SliverChildBuilderDelegate(
                (_, i) => _ConvTile(doc: convs[i], controller: c, myUid: myUid, isDark: isDark),
            childCount: convs.length,
          )),
        const SliverToBoxAdapter(child: SizedBox(height: 90)),
      ],
    );
  }

  Widget _sectionLabel(String label, bool isDark) => Padding(
    padding: const EdgeInsets.fromLTRB(20, 8, 0, 6),
    child: Text(label, style: TextStyle(
        color: isDark ? Colors.grey : Colors.grey.shade500,
        fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
  );

  Widget _buildBubbleRow(ChatListController c, String myUid, bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: c.allConversations.length,
        itemBuilder: (_, i) {
          final doc  = c.allConversations[i];
          final uid  = c.getOtherUidFromDoc(doc);
          final user = c.getCachedUser(uid);
          if (user == null) return const SizedBox.shrink();
          final data   = doc.data() as Map<String, dynamic>;
          final unread = _unreadCount(data, myUid);
          return _BubbleItem(user: user, unread: unread, isDark: isDark,
              onTap: () => _openChat(doc.id, user));
        },
      ),
    );
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 80, height: 80,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A2E) : Colors.grey.shade100,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.chat_bubble_outline_rounded,
              size: 38, color: isDark ? Colors.white24 : Colors.grey.shade400),
        ),
        const SizedBox(height: 16),
        Text('Chưa có đoạn chat',
            style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 16, fontWeight: FontWeight.w600)),
        const SizedBox(height: 6),
        Text('Match và bắt đầu trò chuyện 💬',
            style: TextStyle(color: isDark ? Colors.grey : Colors.grey.shade500, fontSize: 13)),
      ]),
    );
  }

  static int _unreadCount(Map<String, dynamic> data, String uid) {
    if (uid.isEmpty) return 0;
    final map = data['unreadCount'] as Map? ?? {};
    return (map[uid] as num?)?.toInt() ?? 0;
  }

  static void _openChat(String convId, UserModel user) {
    Get.to(() => ChatDetailScreen(
      conversationId: convId, otherUserId: user.uid,
      otherUserName: user.name, otherUserPhotoUrl: user.photoUrl,
    ), transition: Transition.cupertino);
  }
}

// ── Bubble Item ─────────────────────────────────────────────────────
class _BubbleItem extends StatelessWidget {
  final UserModel user;
  final int unread;
  final bool isDark;
  final VoidCallback onTap;
  const _BubbleItem({required this.user, required this.unread, required this.isDark, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final avatarBg = isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade200;
    final borderColor = isDark ? AppColors.darkBg : Colors.white;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 68,
        margin: const EdgeInsets.only(right: 14),
        child: Column(children: [
          Stack(children: [
            Container(
              padding: unread > 0 ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: unread > 0
                    ? const LinearGradient(colors: [Color(0xFFE94057), Color(0xFF8A2387)])
                    : null,
              ),
              child: CircleAvatar(
                radius: 28,
                backgroundColor: avatarBg,
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                child: user.photoUrl.isEmpty
                    ? Text(user.name[0].toUpperCase(),
                    style: TextStyle(fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87, fontSize: 18))
                    : null,
              ),
            ),
            if (user.isOnline)
              Positioned(
                right: unread > 0 ? 3 : 0, bottom: unread > 0 ? 3 : 0,
                child: Container(
                  width: 13, height: 13,
                  decoration: BoxDecoration(
                      color: AppColors.online, shape: BoxShape.circle,
                      border: Border.all(color: borderColor, width: 2)),
                ),
              ),
            if (unread > 0)
              Positioned(
                top: 0, right: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                      color: AppColors.primary, borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: borderColor, width: 1.5)),
                  child: Text(unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                ),
              ),
          ]),
          const SizedBox(height: 5),
          Text(user.name,
              maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: 11,
                  color: unread > 0 ? (isDark ? Colors.white : Colors.black87) : Colors.grey,
                  fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.normal)),
        ]),
      ),
    );
  }
}

// ── Conversation Tile ────────────────────────────────────────────────
class _ConvTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final ChatListController controller;
  final String myUid;
  final bool isDark;
  const _ConvTile({required this.doc, required this.controller, required this.myUid, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final uid  = controller.getOtherUidFromDoc(doc);
    final user = controller.getCachedUser(uid);
    if (user == null) return const SizedBox.shrink();

    final data         = doc.data() as Map<String, dynamic>;
    final unread       = _unread(data);
    final lastMsg      = data['lastMessage'] as String? ?? '';
    final lastTime     = (data['lastMessageTime'] as Timestamp?)?.toDate();
    final lastSenderId = data['lastSenderId'] as String? ?? '';
    final isMe         = lastSenderId == myUid;
    final hasUnread    = unread > 0 && !isMe;

    final nameColor    = isDark ? Colors.white : Colors.black87;
    final subColor     = hasUnread
        ? (isDark ? Colors.white : Colors.black87)
        : (isDark ? const Color(0xFF8A8A9A) : Colors.grey.shade500);
    final timeColor    = hasUnread ? AppColors.primary : (isDark ? const Color(0xFF6A6A7A) : Colors.grey.shade500);
    final avatarBg     = isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade200;
    final onlineBorder = isDark ? AppColors.darkBg : Colors.white;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _open(doc.id, user),
        splashColor: isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
        highlightColor: isDark ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [
            Stack(children: [
              CircleAvatar(
                radius: 28, backgroundColor: avatarBg,
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                child: user.photoUrl.isEmpty
                    ? Text(user.name[0].toUpperCase(),
                    style: TextStyle(color: isDark ? Colors.white : Colors.black87,
                        fontWeight: FontWeight.bold, fontSize: 18))
                    : null,
              ),
              if (user.isOnline)
                Positioned(right: 0, bottom: 0,
                    child: Container(width: 14, height: 14,
                        decoration: BoxDecoration(color: AppColors.online, shape: BoxShape.circle,
                            border: Border.all(color: onlineBorder, width: 2)))),
            ]),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(user.name, style: TextStyle(
                  fontSize: 15,
                  fontWeight: hasUnread ? FontWeight.w800 : FontWeight.w600,
                  color: nameColor)),
              const SizedBox(height: 3),
              Row(children: [
                if (_isCallMsg(lastMsg)) ...[
                  Icon(lastMsg.contains('video') || lastMsg.contains('📹')
                      ? Icons.videocam_rounded : Icons.call_rounded,
                      size: 13,
                      color: _isMissed(lastMsg) ? Colors.red : Colors.grey),
                  const SizedBox(width: 3),
                ],
                Expanded(child: Text(_preview(lastMsg, isMe), maxLines: 1, overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 13,
                        fontWeight: hasUnread ? FontWeight.w600 : FontWeight.normal,
                        color: subColor))),
              ]),
            ])),
            const SizedBox(width: 8),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(_formatTime(lastTime), style: TextStyle(fontSize: 11, color: timeColor,
                  fontWeight: hasUnread ? FontWeight.w700 : FontWeight.normal)),
              const SizedBox(height: 5),
              if (hasUnread)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(10)),
                  constraints: const BoxConstraints(minWidth: 20, minHeight: 20),
                  child: Text(unread > 99 ? '99+' : '$unread',
                      style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center),
                )
              else
                const SizedBox(height: 20),
            ]),
          ]),
        ),
      ),
    );
  }

  int _unread(Map<String, dynamic> data) {
    if (myUid.isEmpty) return 0;
    final map = data['unreadCount'] as Map? ?? {};
    return (map[myUid] as num?)?.toInt() ?? 0;
  }

  String _preview(String msg, bool isMe) {
    if (msg.isEmpty) return 'Bạn đã match với nhau! 👋';
    if (isMe) return 'Bạn: $msg';
    return msg;
  }

  bool _isCallMsg(String msg) =>
      msg.contains('Cuộc gọi') || msg.contains('📞') || msg.contains('📹');
  bool _isMissed(String msg) =>
      msg.contains('nhỡ') || msg.contains('Không trả lời') || msg.contains('Không kết nối');

  String _formatTime(DateTime? dt) {
    if (dt == null) return '';
    final now  = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inSeconds < 60) return 'Vừa xong';
    if (diff.inMinutes < 60) return '${diff.inMinutes}p';
    if (diff.inHours < 24)   return '${diff.inHours}g';
    if (diff.inDays == 1)    return 'Hôm qua';
    if (diff.inDays < 7)     return DateFormat('EEE', 'vi').format(dt);
    return DateFormat('dd/MM').format(dt);
  }

  void _open(String convId, UserModel user) {
    Get.to(() => ChatDetailScreen(
      conversationId: convId, otherUserId: user.uid,
      otherUserName: user.name, otherUserPhotoUrl: user.photoUrl,
    ), transition: Transition.cupertino);
  }
}

// ── Header button ────────────────────────────────────────────────────
class _HeaderBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isDark;
  const _HeaderBtn({required this.icon, required this.onTap, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A3D) : Colors.grey.shade100,
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: isDark ? Colors.white : AppColors.lightText, size: 18),
      ),
    );
  }
}
