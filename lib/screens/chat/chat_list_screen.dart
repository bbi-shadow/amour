import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '/models/user_model.dart';
import 'chat_detail_screen.dart'; // ✅ FIX: đổi từ chat_screen.dart

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;
  final _firestore = FirebaseFirestore.instance;

  final Map<String, UserModel> _userCache = {};

  Future<UserModel?> _getUser(String uid) async {
    if (_userCache.containsKey(uid)) return _userCache[uid];
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      final user = UserModel.fromFirestore(doc);
      _userCache[uid] = user;
      return user;
    } catch (_) {
      return null;
    }
  }

  String _formatTime(Timestamp? ts) {
    if (ts == null) return '';
    final dt = ts.toDate();
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inMinutes < 1) return 'Vừa xong';
    if (diff.inHours < 1) return '${diff.inMinutes} phút';
    if (diff.inDays < 1) return '${diff.inHours} giờ';
    if (diff.inDays < 7) return '${diff.inDays} ngày';
    return '${dt.day}/${dt.month}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F2),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Row(
          children: [
            Icon(Icons.favorite, color: Color(0xFFFF4B6E), size: 22),
            SizedBox(width: 8),
            Text(
              'Tin nhắn',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Color(0xFF333333),
                fontSize: 20,
              ),
            ),
          ],
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _firestore
            .collection('conversations')
            .where('participants', arrayContains: _uid)
            .orderBy('lastMessageTime', descending: true)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Color(0xFFFF4B6E)),
            );
          }

          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.grey, size: 48),
                  const SizedBox(height: 12),
                  Text('Lỗi: ${snap.error}',
                      style: const TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }

          final docs = snap.data?.docs ?? [];

          if (docs.isEmpty) {
            return _buildEmpty();
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const Divider(
              height: 1,
              indent: 80,
              endIndent: 16,
              color: Color(0xFFEEEEEE),
            ),
            itemBuilder: (context, i) {
              final data = docs[i].data() as Map<String, dynamic>;
              final conversationId = docs[i].id;
              final participants = List<String>.from(data['participants'] ?? []);
              final otherUid =
              participants.firstWhere((p) => p != _uid, orElse: () => '');

              if (otherUid.isEmpty) return const SizedBox.shrink();

              final lastMessage = data['lastMessage'] as String? ?? '';
              final lastMessageTime = data['lastMessageTime'] as Timestamp?;
              final lastSenderId = data['lastSenderId'] as String? ?? '';
              final unreadMap =
                  data['unreadCount'] as Map<String, dynamic>? ?? {};
              final unread = (unreadMap[_uid] as int?) ?? 0;

              return FutureBuilder<UserModel?>(
                future: _getUser(otherUid),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data == null) {
                    return const SizedBox.shrink(); // or a loading/placeholder widget
                  }
                  final UserModel user = snapshot.data!;
                  return _ConversationTile(
                    user: user,
                    otherUid: otherUid,
                    lastMessage: lastMessage,
                    lastTime: _formatTime(lastMessageTime),
                    unreadCount: unread,
                    isLastMine: lastSenderId == _uid,
                    onTap: () {
                      if (user == null) return;
                      // ✅ FIX: dùng ChatDetailScreen với đúng params
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            conversationId: conversationId,
                            otherUserId: user.uid,
                            otherUserName: user.name,
                            otherUserPhotoUrl: user.photoUrl.isNotEmpty
                                ? user.photoUrl
                                : null,
                          ),
                        ),
                      );
                    },
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFFFF6B8A).withOpacity(0.1),
            ),
            child: const Center(
              child: Text('💌', style: TextStyle(fontSize: 48)),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Chưa có tin nhắn nào',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Khi bạn match với ai đó,\nhãy bắt đầu trò chuyện nhé!',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey, fontSize: 14, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final UserModel user;
  final String otherUid;
  final String lastMessage;
  final String lastTime;
  final int unreadCount;
  final bool isLastMine;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.user,
    required this.otherUid,
    required this.lastMessage,
    required this.lastTime,
    required this.unreadCount,
    required this.isLastMine,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final name = user?.name ?? '...';
    final photoUrl = user?.photoUrl ?? '';

    return InkWell(
      onTap: onTap,
      child: Container(
        color: unreadCount > 0
            ? const Color(0xFFFF6B8A).withOpacity(0.04)
            : Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Stack(
              children: [
                Container(
                  width: 58,
                  height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFF6B8A), Color(0xFFFFB3C1)],
                    ),
                    border: Border.all(
                      color: unreadCount > 0
                          ? const Color(0xFFFF6B8A)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                  child: photoUrl.isNotEmpty
                      ? ClipOval(
                    child: Image.network(
                      photoUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _initials(name),
                    ),
                  )
                      : _initials(name),
                ),
                Positioned(
                  bottom: 2,
                  right: 2,
                  child: Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: const Color(0xFF4CAF50),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: unreadCount > 0
                                ? FontWeight.bold
                                : FontWeight.w600,
                            color: const Color(0xFF333333),
                          ),
                        ),
                      ),
                      Text(
                        lastTime,
                        style: TextStyle(
                          fontSize: 11,
                          color: unreadCount > 0
                              ? const Color(0xFFFF6B8A)
                              : Colors.grey,
                          fontWeight: unreadCount > 0
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (isLastMine && lastMessage.isNotEmpty)
                        const Padding(
                          padding: EdgeInsets.only(right: 4),
                          child: Icon(Icons.done_all,
                              size: 14, color: Color(0xFFFF6B8A)),
                        ),
                      Expanded(
                        child: Text(
                          lastMessage.isEmpty
                              ? '💕 Đã match với nhau!'
                              : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: unreadCount > 0
                                ? const Color(0xFF333333)
                                : Colors.grey,
                            fontWeight: unreadCount > 0
                                ? FontWeight.w500
                                : FontWeight.normal,
                            fontStyle: lastMessage.isEmpty
                                ? FontStyle.italic
                                : FontStyle.normal,
                          ),
                        ),
                      ),
                      if (unreadCount > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF6B8A),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : '$unreadCount',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _initials(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
      ),
    );
  }
}