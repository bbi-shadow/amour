import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';
import '../profile_detail_screen.dart';

/// ══════════════════════════════════════════════════════════════
/// DiscoveryScreen — Khám phá người dùng gần bạn
/// - Nearby people (theo thành phố)
/// - Trending profiles
/// - Bộ lọc: tuổi, giới tính, sở thích
/// - Search user
/// ══════════════════════════════════════════════════════════════
class DiscoveryScreen extends StatefulWidget {
  const DiscoveryScreen({super.key});
  @override
  State<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends State<DiscoveryScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  List<UserModel> _allProfiles = [];
  List<UserModel> _filteredProfiles = [];
  bool _isLoading = true;

  // Filters
  String _filterGender = 'Tất cả';
  RangeValues _ageRange = const RangeValues(18, 45);
  List<String> _filterInterests = [];
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadProfiles();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfiles() async {
    setState(() => _isLoading = true);
    try {
      final profiles = await FirestoreService.getDiscoveryProfiles();
      _allProfiles = profiles;
      _applyFilters();
    } catch (_) {}
    setState(() => _isLoading = false);
  }

  void _applyFilters() {
    var result = List<UserModel>.from(_allProfiles);

    if (_filterGender != 'Tất cả') {
      result = result.where((u) => u.gender == _filterGender).toList();
    }
    result = result.where((u) =>
        u.age >= _ageRange.start && u.age <= _ageRange.end).toList();

    if (_filterInterests.isNotEmpty) {
      result = result.where((u) =>
          u.interests.any((i) => _filterInterests.contains(i))).toList();
    }
    if (_searchQuery.isNotEmpty) {
      result = result.where((u) =>
          u.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          u.city.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
    }

    setState(() => _filteredProfiles = result);
  }

  void _showFilterSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FilterSheet(
        filterGender: _filterGender,
        ageRange: _ageRange,
        selectedInterests: _filterInterests,
        onApply: (gender, age, interests) {
          setState(() {
            _filterGender = gender;
            _ageRange = age;
            _filterInterests = interests;
          });
          _applyFilters();
          Navigator.pop(context);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF8F9),
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Column(
              children: [
                _buildSearchBar(),
                _buildTabBar(),
                Expanded(
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _buildNearbyGrid(),
                      _buildTrendingList(),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: const Text('Khám phá 🌍',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.lightText)),
      backgroundColor: Colors.white,
      elevation: 0,
      actions: [
        Stack(
          children: [
            IconButton(
              icon: const Icon(Icons.tune_rounded, color: AppColors.lightText),
              onPressed: _showFilterSheet,
            ),
            if (_filterGender != 'Tất cả' || _filterInterests.isNotEmpty)
              Positioned(
                top: 8, right: 8,
                child: Container(
                  width: 8, height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle,
                  ),
                ),
              ),
          ],
        ),
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: AppColors.lightText),
          onPressed: _loadProfiles,
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (v) {
          _searchQuery = v;
          _applyFilters();
        },
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          hintText: 'Tìm theo tên hoặc thành phố...',
          prefixIcon: const Icon(Icons.search, color: Colors.grey, size: 20),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear, size: 18, color: Colors.grey),
                  onPressed: () {
                    _searchCtrl.clear();
                    _searchQuery = '';
                    _applyFilters();
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController,
        labelColor: AppColors.primary,
        unselectedLabelColor: Colors.grey,
        indicatorColor: AppColors.primary,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
        tabs: [
          Tab(text: '📍 Gần bạn (${_filteredProfiles.length})'),
          const Tab(text: '🔥 Nổi bật'),
        ],
      ),
    );
  }

  // ── Nearby Grid ──────────────────────────────────────────
  Widget _buildNearbyGrid() {
    if (_filteredProfiles.isEmpty) {
      return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Text('🔍', style: TextStyle(fontSize: 52)),
          const SizedBox(height: 12),
          const Text('Không tìm thấy ai',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() { _filterGender = 'Tất cả'; _filterInterests = []; });
              _applyFilters();
            },
            child: const Text('Xoá bộ lọc',
                style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w600)),
          ),
        ]),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 10,
        mainAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: _filteredProfiles.length,
      itemBuilder: (_, i) => _ProfileGridCard(user: _filteredProfiles[i]),
    );
  }

  // ── Trending List ────────────────────────────────────────
  Widget _buildTrendingList() {
    // Trending = sort theo likeCount
    final trending = List<UserModel>.from(_allProfiles)
      ..sort((a, b) => b.likeCount.compareTo(a.likeCount));

    if (trending.isEmpty) {
      return const Center(child: Text('Chưa có hồ sơ nổi bật'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: trending.length,
      itemBuilder: (_, i) => _TrendingCard(user: trending[i], rank: i + 1),
    );
  }
}

// ── Profile Grid Card ─────────────────────────────────────────
class _ProfileGridCard extends StatelessWidget {
  final UserModel user;
  const _ProfileGridCard({required this.user});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ProfileDetailScreen(user: user)),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08),
                blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Photo
              user.photoUrl.isNotEmpty
                  ? Image.network(user.photoUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholderBg())
                  : _placeholderBg(),

              // Gradient overlay
              Positioned.fill(child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.75)],
                    stops: const [0.5, 1.0],
                  ),
                ),
              )),

              // Info
              Positioned(
                bottom: 12, left: 12, right: 12,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      Expanded(
                        child: Text('${user.name}, ${user.age}',
                            style: const TextStyle(
                                color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14),
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (user.isVerified)
                        const Icon(Icons.verified, color: Colors.blue, size: 14),
                    ]),
                    if (user.city.isNotEmpty)
                      Row(children: [
                        const Icon(Icons.location_on, color: Colors.white60, size: 11),
                        const SizedBox(width: 2),
                        Text(user.city, style: const TextStyle(
                            color: Colors.white60, fontSize: 11)),
                      ]),
                  ],
                ),
              ),

              // Badges
              Positioned(
                top: 10, right: 10,
                child: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                  if (user.isOnline)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.online,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text('Online', style: TextStyle(
                          color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700)),
                    ),
                ]),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholderBg() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFFB3C6), Color(0xFFFF8E9B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontSize: 48, fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ── Trending Card ─────────────────────────────────────────────
class _TrendingCard extends StatelessWidget {
  final UserModel user;
  final int rank;
  const _TrendingCard({required this.user, required this.rank});

  Color get _rankColor {
    if (rank == 1) return const Color(0xFFFFD700);
    if (rank == 2) return const Color(0xFFB0B0B0);
    if (rank == 3) return const Color(0xFFCD7F32);
    return Colors.grey.shade300;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => ProfileDetailScreen(user: user)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Row(children: [
          // Rank badge
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(color: _rankColor, shape: BoxShape.circle),
            child: Center(
              child: Text('$rank', style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
            ),
          ),
          const SizedBox(width: 12),

          // Avatar
          Stack(children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: AppColors.primary.withOpacity(0.15),
              backgroundImage: user.photoUrl.isNotEmpty
                  ? NetworkImage(user.photoUrl) : null,
              child: user.photoUrl.isEmpty
                  ? Text(user.name.isNotEmpty ? user.name[0] : '?',
                      style: const TextStyle(color: AppColors.primary,
                          fontWeight: FontWeight.bold, fontSize: 22))
                  : null,
            ),
            if (user.isOnline)
              Positioned(bottom: 0, right: 0,
                child: Container(
                  width: 12, height: 12,
                  decoration: BoxDecoration(
                    color: AppColors.online, shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                )),
          ]),
          const SizedBox(width: 12),

          // Info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text('${user.name}, ${user.age}',
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                if (user.isVerified) ...[
                  const SizedBox(width: 4),
                  const Icon(Icons.verified, color: Colors.blue, size: 15),
                ],
                if (user.isPremium) ...[
                  const SizedBox(width: 4),
                  const Text('💎', style: TextStyle(fontSize: 13)),
                ],
              ]),
              if (user.city.isNotEmpty)
                Text(user.city, style: const TextStyle(
                    color: AppColors.lightSubtext, fontSize: 12)),
              if (user.interests.isNotEmpty)
                Wrap(
                  spacing: 4,
                  children: user.interests.take(3).map((i) =>
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(i, style: const TextStyle(
                          color: AppColors.primary, fontSize: 10, fontWeight: FontWeight.w600)),
                    )
                  ).toList(),
                ),
            ],
          )),

          // Like count
          Column(crossAxisAlignment: CrossAxisAlignment.center, children: [
            const Text('❤️', style: TextStyle(fontSize: 18)),
            Text('${user.likeCount}',
                style: const TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w700, fontSize: 13)),
          ]),
        ]),
      ),
    );
  }
}

// ── Filter Bottom Sheet ───────────────────────────────────────
class _FilterSheet extends StatefulWidget {
  final String filterGender;
  final RangeValues ageRange;
  final List<String> selectedInterests;
  final Function(String, RangeValues, List<String>) onApply;

  const _FilterSheet({
    required this.filterGender,
    required this.ageRange,
    required this.selectedInterests,
    required this.onApply,
  });

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String _gender;
  late RangeValues _ageRange;
  late List<String> _interests;

  @override
  void initState() {
    super.initState();
    _gender = widget.filterGender;
    _ageRange = widget.ageRange;
    _interests = List.from(widget.selectedInterests);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.4,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: ListView(controller: ctrl, children: [
          // Handle
          Center(
            child: Container(width: 40, height: 4,
                decoration: BoxDecoration(color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2))),
          ),
          const SizedBox(height: 16),
          const Text('🎯 Bộ lọc', style: TextStyle(
              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightText)),
          const SizedBox(height: 24),

          // Gender
          const Text('Giới tính', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.lightSubtext)),
          const SizedBox(height: 10),
          Row(children: ['Tất cả', 'Nam', 'Nữ'].map((g) {
            final selected = _gender == g;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _gender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Text(g, textAlign: TextAlign.center, style: TextStyle(
                    color: selected ? Colors.white : Colors.grey,
                    fontWeight: FontWeight.w700,
                  )),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 24),

          // Age range
          Row(children: [
            const Text('Độ tuổi', style: TextStyle(
                fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.lightSubtext)),
            const Spacer(),
            Text('${_ageRange.start.round()} – ${_ageRange.end.round()} tuổi',
                style: const TextStyle(color: AppColors.primary,
                    fontWeight: FontWeight.w700)),
          ]),
          RangeSlider(
            values: _ageRange,
            min: 18, max: 60,
            activeColor: AppColors.primary,
            inactiveColor: Colors.grey.shade200,
            onChanged: (v) => setState(() => _ageRange = v),
          ),
          const SizedBox(height: 16),

          // Interests
          const Text('Sở thích', style: TextStyle(
              fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.lightSubtext)),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: AppConstants.interestOptions.map((opt) {
              final label = opt['label']!;
              final selected = _interests.contains(label);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    selected ? _interests.remove(label) : _interests.add(label);
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? AppColors.primary : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text('${opt['emoji']} ${opt['label']}',
                      style: TextStyle(
                        color: selected ? Colors.white : AppColors.lightText,
                        fontWeight: FontWeight.w600, fontSize: 13,
                      )),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 28),

          // Buttons
          Row(children: [
            Expanded(
              child: OutlinedButton(
                onPressed: () {
                  setState(() {
                    _gender = 'Tất cả';
                    _ageRange = const RangeValues(18, 45);
                    _interests = [];
                  });
                },
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  side: BorderSide(color: Colors.grey.shade300),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Xoá tất cả', style: TextStyle(color: Colors.grey)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: () => widget.onApply(_gender, _ageRange, _interests),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: const Text('Áp dụng', style: TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700, fontSize: 15)),
              ),
            ),
          ]),
          const SizedBox(height: 16),
        ]),
      ),
    );
  }
}
