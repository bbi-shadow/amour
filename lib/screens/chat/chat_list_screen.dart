import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../themes/app_theme.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});
  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> {
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Tin nhắn', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirestoreService.getConversationsStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final allDocs = snap.data?.docs ?? [];
          if (allDocs.isEmpty) return _buildEmpty();

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: allDocs.length,
            itemBuilder: (context, i) => _ConversationTile(doc: allDocs[i], currentUid: _uid),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() => Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text('💬', style: TextStyle(fontSize: 60)),
    const SizedBox(height: 16),
    const Text('Chưa có trò chuyện nào', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.grey)),
  ]));
}

class _ConversationTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  final String currentUid;

  const _ConversationTile({required this.doc, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final participants = List<String>.from(data['participants']);
    final otherUid = participants.firstWhere((p) => p != currentUid);
    final unreadCount = (data['unreadCount']?[currentUid] ?? 0) as int;

    // ✅ Sử dụng StreamBuilder để lắng nghe trạng thái Online của đối phương thời gian thực
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance.collection('users').doc(otherUid).snapshots(),
      builder: (context, userSnap) {
        if (!userSnap.hasData) return const SizedBox.shrink();
        final user = UserModel.fromFirestore(userSnap.data!);

        return ListTile(
          onTap: () {
            // ✅ Khi nhấn vào, đánh dấu đã xem ngay lập tức
            FirestoreService.markMessagesAsSeen(doc.id);
            Get.to(() => ChatDetailScreen(
              conversationId: doc.id,
              otherUserId: user.uid,
              otherUserName: user.name,
              otherUserPhotoUrl: user.photoUrl,
            ));
          },
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Stack(
            children: [
              CircleAvatar(
                radius: 30, 
                backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null, 
                backgroundColor: Colors.grey[200],
                child: user.photoUrl.isEmpty ? const Icon(Icons.person, color: Colors.grey) : null,
              ),
              // ✅ Chấm xanh Online động
              if (user.isOnline)
                Positioned(
                  bottom: 0, 
                  right: 0, 
                  child: Container(
                    width: 16, 
                    height: 16, 
                    decoration: BoxDecoration(
                      color: Colors.green, 
                      shape: BoxShape.circle, 
                      border: Border.all(color: Colors.white, width: 3)
                    ),
                  ),
                ),
            ],
          ),
          title: Text(
            user.name, 
            style: TextStyle(
              fontWeight: unreadCount > 0 ? FontWeight.w900 : FontWeight.w700, 
              fontSize: 16, 
              color: unreadCount > 0 ? Colors.black : Colors.black87
            )
          ),
          subtitle: Text(
            data['lastMessage'] ?? 'Bắt đầu trò chuyện ngay...',
            maxLines: 1, 
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unreadCount > 0 ? Colors.black : Colors.grey[600], 
              fontWeight: unreadCount > 0 ? FontWeight.w700 : FontWeight.normal
            ),
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatTime(data['lastMessageTime']), 
                style: TextStyle(
                  color: unreadCount > 0 ? AppColors.primary : Colors.grey, 
                  fontSize: 12, 
                  fontWeight: unreadCount > 0 ? FontWeight.bold : FontWeight.normal
                )
              ),
              // ✅ Badge thông báo số tin nhắn chưa đọc
              if (unreadCount > 0)
                Container(
                  margin: const EdgeInsets.only(top: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary, 
                    borderRadius: BorderRadius.circular(12)
                  ),
                  child: Text(
                    '$unreadCount', 
                    style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _formatTime(dynamic ts) {
    if (ts == null) return '';
    final d = (ts as Timestamp).toDate();
    final now = DateTime.now();
    if (now.difference(d).inDays == 0) return '${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    return '${d.day}/${d.month}';
  }
}
