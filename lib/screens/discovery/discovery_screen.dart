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
            : Column(
                children: [
                  _buildSearchBar(isDark),
                  _buildTabBar(isDark, context),
                  Expanded(
                    child: TabBarView(
                      controller: controller.tabController,
                      children: [
                        _buildNearbyGrid(isDark),
                        _buildTrendingList(isDark),
                      ],
                    ),
                  ),
                ],
              ),
      );
    });
  }

  AppBar _buildAppBar(bool isDark) {
    return AppBar(
      title: Text('Kham pha',
          style: TextStyle(fontWeight: FontWeight.w800, color: isDark ? Colors.white : AppColors.lightText)),
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
                    child: Container(
                      width: 8, height: 8,
                      decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    ),
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
          hintText: 'Tim theo ten hoac thanh pho...',
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
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: [
          Tab(text: 'Gan ban (${controller.filteredProfiles.length})'),
          const Tab(text: 'Noi bat'),
        ],
      ),
    );
  }

  Widget _buildNearbyGrid(bool isDark) {
    if (controller.filteredProfiles.isEmpty) {
      return _buildEmptyState(isDark);
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, crossAxisSpacing: 12, mainAxisSpacing: 12, childAspectRatio: 0.75,
      ),
      itemCount: controller.filteredProfiles.length,
      itemBuilder: (_, i) => _ProfileGridCard(user: controller.filteredProfiles[i], isDark: isDark),
    );
  }

  Widget _buildTrendingList(bool isDark) {
    final trending = controller.getTrendingProfiles();
    if (trending.isEmpty) return const Center(child: Text('Chua co ho so noi bat'));

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: trending.length,
      itemBuilder: (_, i) => _TrendingCard(user: trending[i], rank: i + 1, isDark: isDark),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.search_off_rounded, size: 64, color: isDark ? Colors.white10 : Colors.grey.shade200),
        const SizedBox(height: 16),
        const Text('Khong tim thay ket qua', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
        TextButton(
          onPressed: controller.clearFilters,
          child: const Text('Xoa bo loc', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
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
          child: Stack(
            fit: StackFit.expand,
            children: [
              user.photoUrl.isNotEmpty
                  ? Image.network(user.photoUrl, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),
              Positioned.fill(child: DecoratedBox(decoration: BoxDecoration(gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Colors.transparent, Colors.black.withOpacity(0.8)], stops: const [0.6, 1.0])))),
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(child: Text('${user.name}, ${user.age}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14), overflow: TextOverflow.ellipsis)),
                      if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 14),
                    ]),
                    if (user.city.isNotEmpty) Row(children: [const Icon(Icons.location_on, color: Colors.white60, size: 10), const SizedBox(width: 2), Text(user.city, style: const TextStyle(color: Colors.white60, fontSize: 10))]),
                  ],
                ),
              ),
              if (user.isOnline) Positioned(top: 10, right: 10, child: Container(width: 10, height: 10, decoration: BoxDecoration(color: AppColors.online, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1.5)))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(color: Colors.grey.shade300, child: const Icon(Icons.person, size: 50, color: Colors.white));
}

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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8)],
        ),
        child: Row(children: [
          Container(width: 32, height: 32, decoration: BoxDecoration(color: _getRankColor(), shape: BoxShape.circle), child: Center(child: Text('$rank', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900)))),
          const SizedBox(width: 12),
          CircleAvatar(radius: 26, backgroundImage: user.photoUrl.isNotEmpty ? NetworkImage(user.photoUrl) : null, backgroundColor: Colors.grey.shade200),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [Text('${user.name}, ${user.age}', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: isDark ? Colors.white : Colors.black87)), if (user.isVerified) const Icon(Icons.verified, color: Colors.blue, size: 14)]),
            Text(user.city, style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ])),
          Column(children: [const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 18), Text('${user.likeCount}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 12))]),
        ]),
      ),
    );
  }

  Color _getRankColor() {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFC0C0C0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.grey.shade400;
  }
}

class _FilterSheet extends StatelessWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context) {
    final controller = DiscoveryController.to;
    final isDark = ThemeController.to.isDark;

    return Container(
      decoration: BoxDecoration(color: isDark ? AppColors.darkBg : Colors.white, borderRadius: const BorderRadius.vertical(top: Radius.circular(28))),
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
        Center(child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)))),
        const SizedBox(height: 20),
        const Text('Bo loc tim kiem', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
        const SizedBox(height: 24),
        const Text('Gioi tinh', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Obx(() => Row(children: ['Tất cả', 'Nam', 'Nữ'].map((g) {
          final sel = controller.filterGender.value == g;
          return Expanded(child: GestureDetector(onTap: () => controller.filterGender.value = g, child: Container(margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(vertical: 12), decoration: BoxDecoration(color: sel ? AppColors.primary : (isDark ? Colors.white10 : const Color(0xFFF5F5F5)), borderRadius: BorderRadius.circular(12)), child: Text(g, textAlign: TextAlign.center, style: TextStyle(color: sel ? Colors.white : Colors.grey, fontWeight: FontWeight.bold)))));
        }).toList())),
        const SizedBox(height: 24),
        Row(children: [const Text('Do tuoi', style: TextStyle(fontWeight: FontWeight.bold)), const Spacer(), Obx(() => Text('${controller.ageRange.value.start.round()} - ${controller.ageRange.value.end.round()}', style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)))]),
        Obx(() => RangeSlider(values: controller.ageRange.value, min: 18, max: 60, activeColor: AppColors.primary, onChanged: (v) => controller.ageRange.value = v)),
        const SizedBox(height: 32),
        Row(children: [
          Expanded(child: OutlinedButton(onPressed: () { controller.clearFilters(); Get.back(); }, child: const Text('Xoa tat ca'))),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: ElevatedButton(onPressed: () { controller.applyFilters(); Get.back(); }, child: const Text('Ap dung'))),
        ]),
        const SizedBox(height: 16),
      ]),
    );
  }
}
