import 'dart:io';
import 'package:flutter/foundation.dart'; // ✅ Thêm để dùng kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../models/post_model.dart';
import '../../services/firestore_service.dart';
import '../../services/upload_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/cached_photo_widget.dart';
import '../../widgets/match_popup.dart';
import '../chat/chat_list_screen.dart';
import '../profile_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> {
  final _postCtrl = TextEditingController();
  final _uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  XFile? _selectedXFile; 
  bool _isPosting = false;

  void _showCreatePostSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
          padding: const EdgeInsets.all(20),
          child: Column(children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Hủy', style: TextStyle(color: Colors.grey))),
              const Text('Cập nhật mới', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              _isPosting ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : ElevatedButton(
                onPressed: () async {
                  if (_postCtrl.text.trim().isEmpty && _selectedXFile == null) return;
                  setModalState(() => _isPosting = true);
                  
                  String? url;
                  if (_selectedXFile != null) {
                    // ✅ Sửa logic upload cho cả Web và Mobile
                    if (kIsWeb) {
                      final bytes = await _selectedXFile!.readAsBytes();
                      url = await UploadService.uploadImageWeb(bytes);
                    } else {
                      url = await UploadService.uploadImage(File(_selectedXFile!.path));
                    }
                  }

                  await FirestoreService.createPost(content: _postCtrl.text.trim(), imageUrl: url);
                  setModalState(() { _isPosting = false; _selectedXFile = null; });
                  _postCtrl.clear();
                  if (mounted) Navigator.pop(context);
                  AppHelpers.showSuccess("Đã đăng thành công! ✨");
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25))),
                child: const Text('Đăng'),
              ),
            ]),
            const Divider(height: 30),
            Expanded(child: ListView(children: [
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const CircleAvatar(radius: 22, backgroundColor: Color(0xFFF5F5F5), child: Icon(Icons.person, color: Colors.grey)),
                const SizedBox(width: 15),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  TextField(controller: _postCtrl, maxLines: null, autofocus: true, decoration: const InputDecoration(hintText: 'Bạn đang nghĩ gì...', border: InputBorder.none, hintStyle: TextStyle(fontSize: 18))),
                  if (_selectedXFile != null) Stack(children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20), 
                      child: kIsWeb 
                        ? Image.network(_selectedXFile!.path, width: double.infinity, height: 250, fit: BoxFit.cover) 
                        : Image.file(File(_selectedXFile!.path), width: double.infinity, height: 250, fit: BoxFit.cover)
                    ),
                    Positioned(top: 10, right: 10, child: GestureDetector(onTap: () => setModalState(() => _selectedXFile = null), child: const CircleAvatar(radius: 15, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 18, color: Colors.white)))),
                  ]),
                ])),
              ]),
            ])),
            const Divider(),
            Row(children: [
              IconButton(icon: const Icon(Icons.image_outlined, color: AppColors.primary, size: 28), onPressed: () async {
                final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 70);
                if (picked != null) setModalState(() => _selectedXFile = picked);
              }),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white, elevation: 0,
        title: const Text('Amour Social', style: TextStyle(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 24)),
        centerTitle: true,
      ),
      body: StreamBuilder<List<PostModel>>(
        stream: FirestoreService.getFeedStream(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          final posts = snap.data ?? [];
          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 10),
            itemCount: posts.length,
            separatorBuilder: (c, i) => const Divider(height: 30, color: Color(0xFFFAFAFA), thickness: 8),
            itemBuilder: (c, i) => _PostCard(post: posts[i], currentUid: _uid),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(onPressed: _showCreatePostSheet, backgroundColor: Colors.black, child: const Icon(Icons.add, color: Colors.white, size: 30)),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final String currentUid;
  const _PostCard({required this.post, required this.currentUid});

  @override
  Widget build(BuildContext context) {
    final bool isLiked = post.likes.contains(currentUid);
    final bool isBookmarked = post.bookmarks.contains(currentUid);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        GestureDetector(
          onTap: () async {
            final user = await FirestoreService.getUser(post.authorId);
            if (user != null) Get.to(() => ProfileDetailScreen(user: user));
          },
          child: Row(children: [
            CachedPhotoWidget(uid: post.authorId, photoUrl: post.authorPhoto, width: 40, height: 40),
            const SizedBox(width: 12),
            Expanded(child: Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
            Text(DateFormat('HH:mm').format(post.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ]),
        ),
        const SizedBox(height: 12),
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: ClipRRect(borderRadius: BorderRadius.circular(20), child: Image.network(post.imageUrl!, fit: BoxFit.cover, width: double.infinity)),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(post.content, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
        ),
        const SizedBox(height: 20),
        Row(children: [
          _actionIcon(isLiked ? Icons.favorite : Icons.favorite_border, isLiked ? Colors.red : Colors.black87, post.likes.length.toString(), () => FirestoreService.toggleLikePost(post, isLiked)),
          const SizedBox(width: 25),
          _actionIcon(Icons.chat_bubble_outline, Colors.black87, post.commentCount.toString(), () {
             showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => _CommentSheet(post: post));
          }),
          const SizedBox(width: 25),
          _actionIcon(Icons.repeat, Colors.black87, post.reposts.length.toString(), () {
            FirestoreService.repost(post.id);
            AppHelpers.showSuccess("Đã đăng lại bài viết!");
          }),
          const SizedBox(width: 25),
          _actionIcon(Icons.send_outlined, Colors.black87, "", () {
             Get.toNamed(AppRoutes.chat);
             AppHelpers.showSuccess("Chọn người để chia sẻ!");
          }),
          const Spacer(),
          _actionIcon(isBookmarked ? Icons.bookmark : Icons.bookmark_border, Colors.black87, "", () => FirestoreService.toggleBookmark(post.id, isBookmarked)),
        ]),
        const SizedBox(height: 10),
      ]),
    );
  }

  Widget _actionIcon(IconData icon, Color color, String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Row(children: [Icon(icon, size: 22, color: color), if (label.isNotEmpty && label != "0") ...[const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.w600))]]),
    );
  }
}

class _CommentSheet extends StatefulWidget {
  final PostModel post;
  const _CommentSheet({required this.post});
  @override
  State<_CommentSheet> createState() => _CommentSheetState();
}

class _CommentSheetState extends State<_CommentSheet> {
  final _commentCtrl = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(30))),
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Text('Bình luận', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 18)),
        const Divider(height: 30),
        Expanded(child: StreamBuilder<List<CommentModel>>(
          stream: FirestoreService.getComments(widget.post.id),
          builder: (c, snap) {
            final comments = snap.data ?? [];
            return ListView.builder(
              itemCount: comments.length,
              itemBuilder: (c, i) => ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(radius: 16, backgroundImage: comments[i].authorPhoto.isNotEmpty ? NetworkImage(comments[i].authorPhoto) : null),
                title: Text(comments[i].authorName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                subtitle: Text(comments[i].content),
                trailing: const Icon(Icons.favorite_border, size: 14, color: Colors.grey),
              ),
            );
          },
        )),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(30)),
          child: Row(children: [
            Expanded(child: TextField(controller: _commentCtrl, decoration: const InputDecoration(hintText: 'Để lại phản hồi...', border: InputBorder.none))),
            IconButton(icon: const Icon(Icons.arrow_upward_rounded, color: Colors.black), onPressed: () async {
              if (_commentCtrl.text.trim().isEmpty) return;
              await FirestoreService.addComment(widget.post.id, _commentCtrl.text.trim());
              _commentCtrl.clear();
              FocusScope.of(context).unfocus();
            }),
          ]),
        ),
      ]),
    );
  }
}
