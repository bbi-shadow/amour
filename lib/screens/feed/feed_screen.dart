import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../controllers/feed_controller.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/post_model.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../services/firestore_service.dart';
import '../profile_detail_screen.dart';

class FeedScreen extends StatefulWidget {
  const FeedScreen({super.key});
  @override
  State<FeedScreen> createState() => _FeedScreenState();
}

class _FeedScreenState extends State<FeedScreen> with SingleTickerProviderStateMixin {
  late FeedController controller;
  late TabController _tabController;
  final _postCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    controller = Get.put(FeedController());
    _tabController = TabController(length: 2, vsync: this); // ← 2 tab
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

    Get.bottomSheet(
      _CreatePostSheet(
        controller: controller,
        postCtrl: _postCtrl,
      ),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      enterBottomSheetDuration: const Duration(milliseconds: 250),
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
            // Tab 1: Khám phá — tất cả bài
            _FeedList(controller: controller, isDark: isDark, feedType: FeedType.all),
            // Tab 2: Của tôi — chỉ bài của bản thân
            _FeedList(controller: controller, isDark: isDark, feedType: FeedType.mine),
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
        indicatorWeight: 3,
        tabs: const [
          Tab(text: 'Khám phá'),
          Tab(text: 'Của tôi'),
        ],
      ),
    );
  }
}

// ── Enum chỉ còn 2 loại ──────────────────────────────────────────
enum FeedType { all, mine }

class _FeedList extends StatelessWidget {
  final FeedController controller;
  final bool isDark;
  final FeedType feedType;
  const _FeedList({required this.controller, required this.isDark, required this.feedType});

  List<PostModel> _filtered(List<PostModel> all) {
    final uid = AuthController.to.currentUid ?? '';
    switch (feedType) {
      case FeedType.all:
        return all;
      case FeedType.mine:
        return all.where((p) => p.authorId == uid).toList();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator(color: AppColors.primary));
      }

      final posts = _filtered(controller.posts);

      if (posts.isEmpty) {
        if (feedType == FeedType.mine) return _buildEmptyMine();
        return const Center(child: Text('Chưa có bài đăng nào', style: TextStyle(color: Colors.grey)));
      }

      return RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => controller.listenToFeed(),
        child: ListView.builder(
          padding: const EdgeInsets.only(top: 8, bottom: 100),
          itemCount: posts.length,
          itemBuilder: (_, i) => _PostCard(post: posts[i], isDark: isDark),
        ),
      );
    });
  }

  Widget _buildEmptyMine() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 90,
            height: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withOpacity(0.15),
                  AppColors.secondary.withOpacity(0.15),
                ],
              ),
            ),
            child: const Icon(Icons.edit_outlined, size: 40, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Bạn chưa có bài đăng nào',
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Nhấn + để chia sẻ khoảnh khắc đầu tiên',
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  const _PostCard({required this.post, required this.isDark});

  void _showOptions(BuildContext context) {
    final currentUid = AuthController.to.currentUid;
    final isMe = post.authorId == currentUid;

    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isMe)
              ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('Xóa bài viết', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                onTap: () {
                  Get.back();
                  FeedController.to.deletePost(post.id);
                },
              ),
            ListTile(
              leading: const Icon(Icons.flag_outlined),
              title: const Text('Báo cáo vi phạm'),
              onTap: () {
                Get.back();
                AppHelpers.showSuccess("Cảm ơn bạn đã báo cáo!");
              },
            ),
            ListTile(
              leading: const Icon(Icons.share_outlined),
              title: const Text('Chia sẻ'),
              onTap: () => Get.back(),
            ),
          ],
        ),
      ),
    );
  }

  void _showComments(BuildContext context) {
    Get.bottomSheet(
      _CommentSheet(post: post, isDark: isDark),
      isScrollControlled: true,
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUid = AuthController.to.currentUid;
    final isLiked = post.likes.contains(currentUid);
    final controller = FeedController.to;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          GestureDetector(
            onTap: () async {
              final user = await FirestoreService.getUser(post.authorId);
              if (user != null) Get.to(() => ProfileDetailScreen(user: user));
            },
            child: _buildAvatar(post.authorPhoto, post.authorName, 16),
          ),
          const SizedBox(width: 10),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(post.authorName, style: TextStyle(fontWeight: FontWeight.bold, color: textColor)),
            Text(AppHelpers.timeAgo(post.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
          ])),
          IconButton(
            icon: const Icon(Icons.more_horiz, color: Colors.grey),
            onPressed: () => _showOptions(context),
          ),
        ]),
        const SizedBox(height: 12),
        if (post.content.isNotEmpty) Text(post.content, style: TextStyle(fontSize: 14.5, height: 1.4, color: textColor)),
        if (post.imageUrl != null && post.imageUrl!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                post.imageUrl!,
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 120,
                  color: isDark ? Colors.white10 : Colors.grey[100],
                  child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.grey)),
                ),
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    height: 200,
                    color: isDark ? Colors.white10 : Colors.grey[100],
                    child: const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                  );
                },
              ),
            ),
          ),
        const Divider(height: 24),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _ActionItem(
            icon: isLiked ? Icons.favorite : Icons.favorite_border,
            label: '${post.likes.length}',
            color: isLiked ? Colors.red : Colors.grey,
            onTap: () {
              HapticFeedback.lightImpact();
              controller.toggleLike(post);
            },
          ),
          _ActionItem(
            icon: Icons.chat_bubble_outline,
            label: '${post.commentCount}',
            color: Colors.grey,
            onTap: () => _showComments(context),
          ),
          _ActionItem(
            icon: Icons.share_outlined,
            label: '',
            color: Colors.grey,
            onTap: () {},
          ),
        ]),
      ]),
    );
  }

  Widget _buildAvatar(String photoUrl, String name, double radius) {
    if (photoUrl.isNotEmpty) {
      return CircleAvatar(
        radius: radius,
        child: ClipOval(
          child: Image.network(
            photoUrl,
            width: radius * 2,
            height: radius * 2,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => CircleAvatar(
              radius: radius,
              backgroundColor: AppColors.primary.withOpacity(0.2),
              child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: radius * 0.8)),
            ),
          ),
        ),
      );
    }
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary.withOpacity(0.2),
      child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?', style: TextStyle(fontSize: radius * 0.8)),
    );
  }
}

class _CommentSheet extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  _CommentSheet({required this.post, required this.isDark});

  final _commentCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = FeedController.to;
    final textColor = isDark ? Colors.white : Colors.black;

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [
        const SizedBox(height: 12),
        Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2))),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Text('Bình luận', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor)),
        ),
        const Divider(height: 1),
        Expanded(
          child: StreamBuilder<List<CommentModel>>(
            stream: controller.getComments(post.id),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator(color: AppColors.primary));
              final comments = snap.data ?? [];
              if (comments.isEmpty) return const Center(child: Text('Hãy là người đầu tiên bình luận', style: TextStyle(color: Colors.grey)));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: comments.length,
                itemBuilder: (ctx, i) {
                  final c = comments[i];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      CircleAvatar(
                        radius: 16,
                        child: c.authorPhoto.isNotEmpty
                            ? ClipOval(child: Image.network(c.authorPhoto, width: 32, height: 32, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Text(c.authorName.isNotEmpty ? c.authorName[0] : '?')))
                            : Text(c.authorName.isNotEmpty ? c.authorName[0] : '?'),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(c.authorName, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: textColor)),
                              const SizedBox(height: 4),
                              Text(c.content, style: TextStyle(fontSize: 14, color: textColor)),
                            ]),
                          ),
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 4),
                            child: Text(AppHelpers.timeAgo(c.createdAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                          ),
                        ]),
                      ),
                    ]),
                  );
                },
              );
            },
          ),
        ),
        Container(
          padding: EdgeInsets.fromLTRB(16, 8, 16, 16 + MediaQuery.of(context).viewInsets.bottom),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.1))),
          ),
          child: Row(children: [
            Expanded(
              child: TextField(
                controller: _commentCtrl,
                style: TextStyle(color: textColor),
                decoration: const InputDecoration(
                  hintText: 'Viết bình luận...',
                  hintStyle: TextStyle(color: Colors.grey),
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.send, color: AppColors.primary),
              onPressed: () {
                if (_commentCtrl.text.trim().isEmpty) return;
                controller.addComment(post.id, _commentCtrl.text);
                _commentCtrl.clear();
                FocusScope.of(context).unfocus();
              },
            ),
          ]),
        ),
      ]),
    );
  }
}

class _UserAvatarSmall extends StatelessWidget {
  const _UserAvatarSmall();
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final photo = AuthController.to.currentUser.value?.photoUrl;
      final name = AuthController.to.currentUser.value?.name ?? '';
      if (photo != null && photo.isNotEmpty) {
        return CircleAvatar(
          radius: 22,
          child: ClipOval(
            child: Image.network(
              photo,
              width: 44, height: 44, fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => CircleAvatar(
                radius: 22,
                child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
              ),
            ),
          ),
        );
      }
      return CircleAvatar(
        radius: 22,
        child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?'),
      );
    });
  }
}

class _ImagePreview extends StatelessWidget {
  final XFile file;
  final VoidCallback onClear;
  const _ImagePreview({required this.file, required this.onClear});
  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      Padding(
        padding: const EdgeInsets.only(top: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.file(File(file.path), height: 140, width: double.infinity, fit: BoxFit.cover),
        ),
      ),
      Positioned(
        right: 8, top: 18,
        child: GestureDetector(
          onTap: onClear,
          child: const CircleAvatar(radius: 14, backgroundColor: Colors.black54, child: Icon(Icons.close, size: 16, color: Colors.white)),
        ),
      ),
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
    return TextButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 20, color: AppColors.primary),
      label: Text(label, style: const TextStyle(color: Colors.grey)),
    );
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
    return GestureDetector(
      onTap: onTap,
      child: Row(children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: color, fontSize: 13))
      ]),
    );
  }
}

// ── Sheet đăng bài ──────────────────────────────────────────────
class _CreatePostSheet extends StatefulWidget {
  final FeedController controller;
  final TextEditingController postCtrl;
  const _CreatePostSheet({required this.controller, required this.postCtrl});
  @override
  State<_CreatePostSheet> createState() => _CreatePostSheetState();
}

class _CreatePostSheetState extends State<_CreatePostSheet> {
  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.to.isDark;
    final bg = isDark ? const Color(0xFF1E1E2E) : Colors.white;
    final kb = MediaQuery.of(context).viewInsets.bottom;
    final screenH = MediaQuery.of(context).size.height;

    return Container(
      height: screenH * 0.55 + kb,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(bottom: kb),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 36, height: 4,
              decoration: BoxDecoration(color: Colors.grey.shade400, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 10),

            Obx(() => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(children: [
                GestureDetector(
                  onTap: widget.controller.isPosting.value ? null : () => Get.back(),
                  child: Text('Hủy', style: TextStyle(
                    color: widget.controller.isPosting.value ? Colors.grey.shade400 : Colors.grey,
                    fontSize: 15,
                  )),
                ),
                const Expanded(child: Text('Đăng bài mới',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                )),
                widget.controller.isPosting.value
                    ? const SizedBox(width: 60, height: 34,
                    child: Center(child: SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    )))
                    : SizedBox(height: 34,
                  child: ElevatedButton(
                    onPressed: () async {
                      final ok = await widget.controller.createPost(widget.postCtrl.text);
                      if (ok) Get.back();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      minimumSize: const Size(60, 34),
                    ),
                    child: const Text('Đăng', style: TextStyle(fontSize: 14)),
                  ),
                ),
              ]),
            )),

            const Divider(height: 16),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _UserAvatarSmall(),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Obx(() => Text(
                            AuthController.to.currentUser.value?.name ?? '',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          )),
                          const SizedBox(height: 4),
                          TextField(
                            controller: widget.postCtrl,
                            maxLines: null,
                            minLines: 2,
                            autofocus: true,
                            style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black87),
                            decoration: InputDecoration(
                              hintText: 'Bạn đang nghĩ gì?',
                              hintStyle: TextStyle(color: Colors.grey.shade500),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                            ),
                          ),
                          Obx(() => widget.controller.selectedImage.value != null
                              ? _ImagePreview(
                            file: widget.controller.selectedImage.value!,
                            onClear: widget.controller.clearSelectedImage,
                          )
                              : const SizedBox.shrink()),
                          const SizedBox(height: 8),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const Divider(height: 1),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(children: [
                _ToolBtn(icon: Icons.image_outlined, label: 'Ảnh',
                    onTap: () => widget.controller.pickImage(ImageSource.gallery)),
                _ToolBtn(icon: Icons.camera_alt_outlined, label: 'Camera',
                    onTap: () => widget.controller.pickImage(ImageSource.camera)),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}