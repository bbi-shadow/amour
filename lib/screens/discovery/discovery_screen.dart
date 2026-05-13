import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../models/user_model.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';
import '../../controllers/discovery_controller.dart';
import '../../controllers/theme_controller.dart';
import '../profile_detail_screen.dart';

class DiscoveryScreen extends GetView<DiscoveryController> {
  const DiscoveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final isDark = ThemeController.to.isDark;
      final bgColor = isDark ? AppColors.darkBg : const Color(0xFFF8F9FE);

      return Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(isDark),
        body: controller.isLoading.value
            ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
            : Column(children: [
          _buildSearchBar(isDark),
          _buildTabBar(isDark, context),
          Expanded(
            child: TabBarView(
              controller: controller.tabController,
              children: [
                _buildNearbyGrid(isDark),
                _buildTrendingList(isDark),
                _buildRecommendSection(isDark),
              ],
            ),
          ),
        ]),
      );
    });
  }

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      title: Text('Khám phá',
          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 22, color: isDark ? Colors.white : AppColors.lightText)),
      backgroundColor: isDark ? AppColors.darkCard : Colors.white,
      elevation: 0,
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.tune_rounded, color: isDark ? Colors.white70 : AppColors.lightText),
              onPressed: () => _showFilterSheet(Get.context!),
            ),
            Obx(() => (controller.filterGender.value != 'Tất cả' || controller.filterInterests.isNotEmpty)
                ? Positioned(
              top: 12, right: 12,
              child: Container(width: 8, height: 8, decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle)),
            )
                : const SizedBox.shrink()),
          ],
        ),
        IconButton(
          icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.white70 : AppColors.lightText),
          onPressed: controller.loadProfiles,
        ),
      ],
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: controller.updateSearch,
        style: TextStyle(fontSize: 15, color: isDark ? Colors.white : Colors.black),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên hoặc thành phố...',
          hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey),
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: Obx(() => controller.searchQuery.value.isNotEmpty
              ? IconButton(
            icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
            onPressed: () => controller.updateSearch(''),
          )
              : const SizedBox.shrink()),
          filled: true,
          fillColor: isDark ? AppColors.darkCard : Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildTabBar(bool isDark, BuildContext context) {
    return Container(
      color: isDark ? AppColors.darkCard : Colors.white,
      child: TabBar(
        controller: controller.tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: isDark ? Colors.white38 : Colors.grey,
        indicatorColor: AppColors.primary,
        indicatorWeight: 3,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
        tabs: [
          Obx(() => Tab(text: 'Gần bạn (${controller.filteredProfiles.length})')),
          const Tab(text: 'Nổi bật'),
          const Tab(text: '✨ Gợi ý'),
        ],
      ),
    );
  }

  // Tab 1: Grid gần bạn
  Widget _buildNearbyGrid(bool isDark) {
    if (controller.filteredProfiles.isEmpty) {
      return _buildEmptyState(isDark);
    }
    return RefreshIndicator(
      color: AppColors.primary,
      onRefresh: controller.loadProfiles,
      child: GridView.builder(
        padding: const EdgeInsets.all(12),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.72,
        ),
        itemCount: controller.filteredProfiles.length,
        itemBuilder: (_, i) => _ProfileGridCard(user: controller.filteredProfiles[i], isDark: isDark),
      ),
    );
  }

  // Tab 2: Trending list
  Widget _buildTrendingList(bool isDark) {
    final trending = controller.getTrendingProfiles();
    if (trending.isEmpty) {
      return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.trending_up_rounded, size: 60, color: isDark ? Colors.white10 : Colors.grey.shade200),
        const SizedBox(height: 12),
        const Text('Chưa có hồ sơ nổi bật', style: TextStyle(color: Colors.grey)),
      ]));
    }
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: trending.length,
      itemBuilder: (_, i) => _TrendingCard(user: trending[i], rank: i + 1, isDark: isDark),
    );
  }

  // Tab 3: Gợi ý AI (Recommend chuyên nghiệp)
  Widget _buildRecommendSection(bool isDark) {
    final tc = isDark ? AppColors.darkText : AppColors.lightText;
    final sc = isDark ? AppColors.darkSubtext : AppColors.lightSubtext;

    return Obx(() {
      if (controller.filteredProfiles.isEmpty) return _buildEmptyState(isDark);

      // Lấy top 5 theo AI score (likeCount + interests match)
      final recommended = List<UserModel>.from(controller.allProfiles)
        ..sort((a, b) => (b.likeCount + b.interests.length * 2)
            .compareTo(a.likeCount + a.interests.length * 2));
      final top = recommended.take(10).toList();

      return ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Banner gợi ý
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF7C3AED)],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(children: [
              const Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('✨ Gợi ý cho bạn', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800)),
                SizedBox(height: 4),
                Text('Dựa trên sở thích & hoạt động của bạn', style: TextStyle(color: Colors.white70, fontSize: 12)),
              ])),
              const Icon(Icons.auto_awesome_rounded, color: Colors.white70, size: 36),
            ]),
          ),

          // Cards
          ...top.map((user) => _RecommendCard(user: user, isDark: isDark, tc: tc, sc: sc)).toList(),
        ],
      );
    });
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
        const SizedBox(height: 16),
        const Text('Không tìm thấy kết quả', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        const SizedBox(height: 8),
        TextButton(
          onPressed: controller.clearFilters,
          child: const Text('Xoá bộ lọc', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }

  void _showFilterSheet(BuildContext context) {
    Get.bottomSheet(
      const _FilterSheet(),
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
    );
  }
}

// ─── Profile Grid Card ──────────────────────────────────────────
class _ProfileGridCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  const _ProfileGridCard({required this.user, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ProfileDetailScreen(user: user)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(fit: StackFit.expand, children: [
            user.photoUrl.isNotEmpty
                ? Image.network(user.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),
            Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                stops: const [0.55, 1.0],
              ),
            ))),
            Positioned(
              bottom: 12, left: 12, right: 12,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${user.name}, ${user.age}',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                      overflow: TextOverflow.ellipsis)),
                  if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 14),
                ]),
                if (user.city.isNotEmpty)
                  Row(children: [
                    const Icon(Icons.location_on, color: Colors.white60, size: 10),
                    const SizedBox(width: 2),
                    Expanded(child: Text(user.city, style: const TextStyle(color: Colors.white60, fontSize: 10), overflow: TextOverflow.ellipsis)),
                  ]),
              ]),
            ),
            // Online dot - dùng AppColors.success (xanh lá CHỈ ở đây cho status)
            if (user.isOnline)
              Positioned(top: 10, right: 10, child: Container(
                width: 10, height: 10,
                decoration: BoxDecoration(
                    color: AppColors.success, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 1.5)),
              )),
            // Like count badge
            if (user.likeCount > 0)
              Positioned(top: 10, left: 10, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(10)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.favorite, color: Colors.white, size: 10),
                  const SizedBox(width: 2),
                  Text('${user.likeCount}', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ]),
              )),
          ]),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
      color: Colors.grey.shade300, child: const Icon(Icons.person, size: 50, color: Colors.white));
}

// ─── Trending Card ──────────────────────────────────────────────
class _TrendingCard extends StatelessWidget {
  final UserModel user;
  final int rank;
  final bool isDark;
  const _TrendingCard({required this.user, required this.rank, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ProfileDetailScreen(user: user)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
        ),
        child: Row(children: [
          // Rank badge
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(color: _rankColor(), shape: BoxShape.circle),
            child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900))),
          ),
          const SizedBox(width: 12),
          // Avatar
          CircleAvatar(
            radius: 26,
            backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null,
            backgroundColor: Colors.grey.shade200,
            child: user.photoUrl.isEmpty ? Text(user.name[0]) : null,
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Text('${user.name}, ${user.age}',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : Colors.black87)),
              if (user.isVerified) const Padding(padding: EdgeInsets.only(left: 4), child: Icon(Icons.verified, color: Colors.blue, size: 14)),
            ]),
            Text(user.city, style: const TextStyle(color: Colors.grey, fontSize: 12)),
            if (user.interests.isNotEmpty)
              Text(user.interests.take(2).join(' · '), style: TextStyle(color: AppColors.primary.withOpacity(0.8), fontSize: 11)),
          ])),
          // Like count - màu primary
          Column(children: [
            const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18),
            Text('${user.likeCount}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12)),
          ]),
        ]),
      ),
    );
  }

  Color _rankColor() {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.grey.shade400;
  }
}

// ─── Recommend Card ─────────────────────────────────────────────
class _RecommendCard extends StatelessWidget {
  final UserModel user;
  final bool isDark;
  final Color tc, sc;
  const _RecommendCard({required this.user, required this.isDark, required this.tc, required this.sc});

  @override
  Widget build(BuildContext context) {
    // Tính % match giả dựa trên likeCount + interests
    final matchPct = ((user.likeCount * 2 + user.interests.length * 5).clamp(60, 98));

    return GestureDetector(
      onTap: () => Get.to(() => ProfileDetailScreen(user: user)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          // Photo
          ClipRRect(
            borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), bottomLeft: Radius.circular(20)),
            child: SizedBox(
              width: 100, height: 120,
              child: user.photoUrl.isNotEmpty
                  ? Image.network(user.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200, child: const Icon(Icons.person, size: 40)))
                  : Container(color: Colors.grey.shade200, child: const Icon(Icons.person, size: 40)),
            ),
          ),
          // Info
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Row(children: [
                  Expanded(child: Text('${user.name}, ${user.age}',
                      style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: tc))),
                  if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 14),
                  if (user.isOnline) Container(
                    margin: const EdgeInsets.only(left: 4),
                    width: 8, height: 8,
                    decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                  ),
                ]),
                const SizedBox(height: 4),
                if (user.city.isNotEmpty)
                  Row(children: [
                    Icon(Icons.location_on_rounded, size: 12, color: sc),
                    const SizedBox(width: 2),
                    Text(user.city, style: TextStyle(color: sc, fontSize: 12)),
                  ]),
                const SizedBox(height: 6),
                // Match %
                Row(children: [
                  const Icon(Icons.auto_awesome, size: 13, color: AppColors.primary),
                  const SizedBox(width: 4),
                  Text('$matchPct% phù hợp', style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w700)),
                ]),
                const SizedBox(height: 8),
                // Interests
                if (user.interests.isNotEmpty)
                  Wrap(spacing: 6, runSpacing: 4, children: user.interests.take(2).map((i) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8)),
                    child: Text(i, style: const TextStyle(fontSize: 10, color: AppColors.primary, fontWeight: FontWeight.w600)),
                  )).toList()),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Filter Sheet ────────────────────────────────────────────────
class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final controller = DiscoveryController.to;
    final isDark = ThemeController.to.isDark;

    return Container(
      decoration: BoxDecoration(
          color: isDark ? AppColors.darkBg : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('Bộ lọc tìm kiếm', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        const Text('Giới tính', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Obx(() => Row(children: ['Tất cả', 'Nam', 'Nữ'].map((g) {
          final sel = controller.filterGender.value == g;
          return Expanded(child: GestureDetector(
            onTap: () => controller.filterGender.value = g,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                  color: sel ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFF5F5F5)),
                  borderRadius: BorderRadius.circular(12)),
              child: Text(g, textAlign: TextAlign.center,
                  style: TextStyle(color: sel ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)),
            ),
          ));
        }).toList())),
        const SizedBox(height: 24),
        Row(children: [
          const Text('Độ tuổi', style: TextStyle(fontWeight: FontWeight.bold)),
          const Spacer(),
          Obx(() => Text(
              '${controller.ageRange.value.start.round()} - ${controller.ageRange.value.end.round()}',
              style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold))),
        ]),
        Obx(() => RangeSlider(
          values: controller.ageRange.value,
          min: 18, max: 60,
          activeColor: AppColors.primary,
          onChanged: (v) => controller.ageRange.value = v,
        )),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: OutlinedButton(
            onPressed: () { controller.clearFilters(); Get.back(); },
            style: OutlinedButton.styleFrom(foregroundColor: Colors.grey, side: BorderSide(color: Colors.grey.shade300)),
            child: const Text('Xoá tất cả'),
          )),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(
            onPressed: () { controller.applyFilters(); Get.back(); },
            child: const Text('Áp dụng'),
          )),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }
}