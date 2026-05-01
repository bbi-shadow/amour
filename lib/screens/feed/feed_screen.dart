import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/post_model.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../widgets/cached_photo_widget.dart';
import '../profile_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  final controller = Get.put(FeedController());
  late TabController _tabController;
  final _postCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _postCtrl.dispose();
    super.dispose();
  }

  void _showCreatePostSheet() {
    _postCtrl.clear();
    controller.clearSelectedImage();
    final isDark = ThemeController.to.isDark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Obx(() => Container(
        height: MediaQuery.of(ctx).size.height * 0.88,
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: EdgeInsets.fromLTRB(20, 16, 20, 16 + MediaQuery.of(ctx).viewInsets.bottom),
        child: Column(children: [
          Container(
            width: 40, height: 4,
            margin: const EdgeInsets.only(bottom: 14),
            decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            TextButton(
              onPressed: controller.isPosting.value ? null : () => Get.back(),
              child: const Text('Huy', style: TextStyle(color: Colors.grey)),
            ),
            const Text('Dang bai moi', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
            controller.isPosting.value
                ? const SizedBox(width: 48, child: Center(child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))))
                : ElevatedButton(
                    onPressed: () async {
                      final ok = await controller.createPost(_postCtrl.text);
                      if (ok) Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25)),
                    ),
                    child: const Text('Dang'),
                  ),
          ]),
          const Divider(),
          Expanded(
            child: SingleChildScrollView(
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _UserAvatarSmall(isDark: isDark),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(AuthController.to.currentUser.value?.name ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      controller: _postCtrl,
                      maxLines: null,
                      minLines: 3,
                      autofocus: true,
                      decoration: const InputDecoration(hintText: 'Ban dang nghi gi?', border: InputBorder.none),
                    ),
                    if (controller.selectedImage.value != null)
                      _ImagePreview(file: controller.selectedImage.value!, onClear: controller.clearSelectedImage),
                  ]),
                ),
              ]),
            ),
          ),
          const Divider(),
          Row(children: [
            _ToolBtn(icon: Icons.image_outlined, label: 'Anh', onTap: () => controller.pickImage(ImageSource.gallery)),
            _ToolBtn(icon: Icons.camera_alt_outlined, label: 'Camera', onTap: () => controller.pickImage(ImageSource.camera)),
          ]),
        ]),
      )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bg = isDark ? AppColors.darkBg : const Color(0xFFF7F8FA);

      return Scaffold(
        backgroundColor: bg,
        appBar: _buildAppBar(isDark, bg),
        body: TabBarView(
          controller: _tabController,
          children: [
            _FeedList(controller: controller, isDark: isDark),
            _FeedList(controller: controller, isDark: isDark),
            _FeedList(controller: controller, isDark: isDark),
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _showCreatePostSheet,
          backgroundColor: AppColors.primary,
          child: const Icon(Icons.add, color: Colors.white),
        ),
      );
    });
  }

  PreferredSizeWidget _buildAppBar(bool isDark, Color bg) {
    return AppBar(
      backgroundColor: bg,
      elevation: 0,
      title: const Text('Amour Social', style: TextStyle(fontWeight: FontWeight.w900)),
      actions: [
        IconButton(
          icon: Icon(isDark ? Icons.wb_sunny_rounded : Icons.nightlight_round),
          onPressed: () => ThemeController.to.toggleTheme(),
        ),
      ],
      bottom: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
        indicatorColor: AppColors.primary,
        tabs: const [Tab(text: 'Kham pha'), Tab(text: 'Theo doi'), Tab(text: 'Gan day')],
      ),
    );
  }
}

class _FeedList extends StatelessWidget {
  final FeedController controller;
  final bool isDark;
  const _FeedList({required this.controller, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) return const Center(child: CircularProgressIndicator());
      if (controller.posts.isEmpty) return const Center(child: Text('Chua co bai dang nao'));

      return RefreshIndicator(
        onRefresh: () async => controller.listenToFeed(),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: controller.posts.length,
          itemBuilder: (_, i) => _PostCard(post: controller.posts[i], isDark: isDark),
        ),
      );
    });
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  const _PostCard({required this.post, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthController.to.currentUid;
    final isLiked = post.likes.contains(currentUid);
    final controller = FeedController.to;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          CircleAvatar(radius: 20, backgroundImage: post.authorPhoto.isNotEmpty ? NetworkImage(post.authorPhoto) : null),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.authorName, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(AppHelpers.timeAgo(post.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
        ]),
        const SizedBox(height: 12),
        if (post.content.isNotEmpty) Text(post.content),
        if (post.imageUrl != null) Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.network(post.imageUrl!, fit: BoxFit.cover, width: double.infinity))),
        const Divider(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ActionItem(icon: isLiked ? Icons.favorite : Icons.favorite_border, label: '${post.likes.length}', color: isLiked ? Colors.red : Colors.grey, onTap: () => controller.toggleLike(post)),
          _ActionItem(icon: Icons.chat_bubble_outline, label: '${post.commentCount}', color: Colors.grey, onTap: () {}),
          _ActionItem(icon: Icons.share_outlined, label: '', color: Colors.grey, onTap: () {}),
        ]),
      ]),
    );
  }
}

// -- Helpers UI Widgets --
class _UserAvatarSmall extends StatelessWidget {
  final bool isDark;
  const _UserAvatarSmall({required this.isDark});
  @override
  Widget build(BuildContext context) {
    final photo = AuthController.to.currentUser.value?.photoUrl;
    return CircleAvatar(radius: 20, backgroundImage: photo != null && photo.isNotEmpty ? NetworkImage(photo) : null, child: photo == null || photo.isEmpty ? const Icon(Icons.person) : null);
  }
}

class _ImagePreview extends StatelessWidget {
  final XFile file;
  final VoidCallback onClear;
  const _ImagePreview({required this.file, required this.onClear});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Padding(padding: const EdgeInsets.only(top: 10), child: ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(File(file.path), height: 200, width: double.infinity, fit: BoxFit.cover))),
      Positioned(right: 8, top: 18, child: GestureDetector(onTap: onClear, child: const CircleAvatar(radius: 14, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 16, color: Colors.white)))),
    ]);
  }
}

class _ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ToolBtn({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return TextButton.icon(onPressed: onTap, icon: Icon(icon, size: 20, color: AppColors.primary), label: Text(label, style: const TextStyle(color: Colors.grey)));
  }
}

class _ActionItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ActionItem({required this.icon, required this.label, required this.color, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(onTap: onTap, child: Row(children: [Icon(icon, size: 20, color: color), const SizedBox(width: 4), Text(label, style: TextStyle(color: color, fontSize: 13))]));
  }
}

// Fallback logic for stream errors
class _FeedFallback extends StatelessWidget {
  final String uid;
  final bool isDark;
  const _FeedFallback({required this.uid, required this.isDark});
  @override
  Widget build(BuildContext context) => const Center(child: Text('Loi tai du lieu'));
}
