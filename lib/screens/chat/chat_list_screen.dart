import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  final String _currentUid = FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('💬 Tin nhắn',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('users', arrayContains: _currentUid)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
                child: CircularProgressIndicator(color: Color(0xFFFF4B6E)));
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chat_bubble_outline, size: 80, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Chưa có match nào!',
                      style: TextStyle(fontSize: 20, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Hãy swipe để tìm người phù hợp 💕',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          final matches = snapshot.data!.docs;
          return ListView.builder(
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final match = matches[index];
              final users = List<String>.from(match['users']);
              final otherUid = users.firstWhere((uid) => uid != _currentUid);
              final matchId = match.id;
              final lastMessage = match['lastMessage'] ?? '';

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(otherUid)
                    .get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return SizedBox();
                  final userData =
                  userSnap.data!.data() as Map<String, dynamic>;
                  final name = userData['name'] ?? 'Người dùng';
                  final photoUrl = userData['photoUrl'] ?? '';

                  return ListTile(
                    contentPadding:
                    EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: CircleAvatar(
                      radius: 28,
                      backgroundColor: Color(0xFFFF8E9B),
                      backgroundImage: photoUrl.isNotEmpty
                          ? NetworkImage(photoUrl)
                          : null,
                      child: photoUrl.isEmpty
                          ? Icon(Icons.person, color: Colors.white)
                          : null,
                    ),
                    title: Text(name,
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(
                      lastMessage.isEmpty ? 'Bắt đầu trò chuyện 💕' : lastMessage,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.grey),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatDetailScreen(
                            matchId: matchId,
                            otherUserName: name,
                            otherUserPhoto: photoUrl,
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
}