import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/chat_list_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';
import 'chat_detail_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ChatListController());

    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF8F9FE);
      final textColor = isDark ? Colors.white : Colors.black;

      return Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(context, controller, isDark, textColor, bgColor),
        body: controller.isLoading.value
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : controller.allConversations.isEmpty
                ? _buildEmpty(isDark)
                : _buildBody(context, controller, isDark),
      );
    });
  }

  Widget _buildBody(BuildContext context, ChatListController controller, bool isDark) {
    final filtered = controller.filteredConversations;

    return CustomScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      slivers: [
        SliverToBoxAdapter(child: _buildSearchBarPlaceholder(context, controller, isDark)),

        if (controller.isSearching.value) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Text(
                filtered.isEmpty ? 'Khong tim thay ket qua' : '${filtered.length} ket qua',
                style: TextStyle(fontSize: 12, color: isDark ? Colors.white38 : Colors.grey),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildConversationTile(controller, filtered[i], isDark),
              childCount: filtered.length,
            ),
          ),
        ] else ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 10),
              child: Text('BAN BE MOI',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 0.8)),
            ),
          ),
          SliverToBoxAdapter(child: _buildMatchBubbles(controller, isDark)),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
              child: Text('TIN NHAN',
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: isDark ? Colors.white38 : Colors.grey, letterSpacing: 0.8)),
            ),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildConversationTile(controller, controller.allConversations[i], isDark),
              childCount: controller.allConversations.length,
            ),
          ),
        ],
        const SliverToBoxAdapter(child: SizedBox(height: 80)),
      ],
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context, ChatListController controller, bool isDark, Color textColor, Color bgColor) {
    return AppBar(
      backgroundColor: bgColor,
      elevation: 0,
      title: controller.isSearching.value
          ? TextField(
              onChanged: controller.updateSearch,
              autofocus: true,
              style: TextStyle(color: textColor, fontSize: 16),
              decoration: const InputDecoration(hintText: 'Tim ten ban be...', border: InputBorder.none),
            )
          : Text('Tin nhan', style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 24)),
      actions: [
        IconButton(
          icon: Icon(controller.isSearching.value ? Icons.close : Icons.search, color: isDark ? Colors.white70 : Colors.black87),
          onPressed: controller.toggleSearch,
        ),
      ],
    );
  }

  Widget _buildSearchBarPlaceholder(BuildContext context, ChatListController controller, bool isDark) {
    if (controller.isSearching.value) return const SizedBox.shrink();
    return GestureDetector(
      onTap: controller.toggleSearch,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(color: isDark ? AppColors.darkCard : const Color(0xFFF5F5F5), borderRadius: BorderRadius.circular(14)),
        child: Row(children: [
          Icon(Icons.search, color: isDark ? Colors.white38 : Colors.grey, size: 18),
          const SizedBox(width: 10),
          Text('Tim kiem...', style: TextStyle(fontSize: 14, color: isDark ? Colors.white38 : Colors.grey)),
        ]),
      ),
    );
  }

  Widget _buildMatchBubbles(ChatListController controller, bool isDark) {
    return SizedBox(
      height: 90,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: controller.allConversations.length,
        itemBuilder: (context, i) {
          final otherUid = controller.getOtherUidFromDoc(controller.allConversations[i]);
          final user = controller.getCachedUser(otherUid);
          if (user == null) return const SizedBox.shrink();

          return GestureDetector(
            onTap: () => _openChat(controller.allConversations[i].id, user),
            child: Container(
              margin: const EdgeInsets.only(right: 14),
              child: Column(
                children: [
                  Stack(children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
                      child: user.photoUrl.isEmpty ? Text(user.name[0]) : null,
                    ),
                    if (user.isOnline)
                      Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.darkBg : Colors.white, width: 2)))),
                  ]),
                  const SizedBox(height: 4),
                  Text(user.name, style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : Colors.black87), overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationTile(ChatListController controller, dynamic doc, bool isDark) {
    final otherUid = controller.getOtherUidFromDoc(doc);
    final user = controller.getCachedUser(otherUid);
    if (user == null) return const SizedBox.shrink();

    final data = doc.data() as Map<String, dynamic>;
    return ListTile(
      onTap: () => _openChat(doc.id, user),
      leading: Stack(children: [
        CircleAvatar(
          radius: 26,
          backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
          child: user.photoUrl.isEmpty ? Text(user.name[0]) : null,
        ),
        if (user.isOnline)
          Positioned(right: 0, bottom: 0, child: Container(width: 12, height: 12, decoration: BoxDecoration(color: Colors.green, shape: BoxShape.circle, border: Border.all(color: isDark ? AppColors.darkBg : Colors.white, width: 2)))),
      ]),
      title: Text(user.name, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
      subtitle: Text(data['lastMessage'] ?? '', maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: isDark ? Colors.white38 : Colors.grey)),
      trailing: Text(AppHelpers.timeAgo(data['lastMessageTime']?.toDate()), style: const TextStyle(fontSize: 11, color: Colors.grey)),
    );
  }

  void _openChat(String convId, dynamic user) {
    Get.to(() => ChatDetailScreen(
      conversationId: convId,
      otherUserId: user.uid,
      otherUserName: user.name,
      otherUserPhotoUrl: user.photoUrl,
    ));
  }

  Widget _buildEmpty(bool isDark) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.chat_bubble_outline, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
        const SizedBox(height: 16),
        const Text('Chua co tin nhan', style: TextStyle(color: Colors.grey)),
      ]),
    );
  }
}
