import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../../controllers/admin_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final controller = Get.put(AdminController());

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = ThemeController.to.isDark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quản trị hệ thống',
            style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor:
            isDark ? AppColors.darkCard : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: controller.logout,
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_outlined),    text: 'Thống kê'),
            Tab(icon: Icon(Icons.people_outline),         text: 'Người dùng'),
            Tab(icon: Icon(Icons.person_add_outlined),    text: 'Tạo User'),
            Tab(icon: Icon(Icons.payment_outlined),       text: 'Thanh toán'),
            Tab(icon: Icon(Icons.flag_outlined),          text: 'Báo cáo'),
            Tab(icon: Icon(Icons.location_city_outlined), text: 'Thành phố'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DashboardTab(),
          _UsersTab(),
          _CreateUserTab(),
          _PendingPaymentsTab(),
          _ReportsTab(),
          _CitiesTab(),
        ],
      ),
    );
  }
}

// ── TAB 1: DASHBOARD ──────────────────────────────────────────────────────────
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminController.to;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text('Tổng quan',
            style:
                TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            Obx(() => _card('User', '${ctrl.stats['users']}',
                Icons.person_outline, Colors.blue)),
            Obx(() => _card('Matches', '${ctrl.stats['matches']}',
                Icons.favorite_border, Colors.pink)),
            Obx(() => _card('Báo cáo', '${ctrl.stats['reports']}',
                Icons.warning_amber_rounded, Colors.orange)),
            Obx(() => _card('Bài đăng', '${ctrl.stats['posts']}',
                Icons.chat_bubble_outline, Colors.teal)),
          ],
        ),
      ],
    );
  }

  Widget _card(String t, String v, IconData i, Color c) {
    return Container(
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: c.withOpacity(0.05), blurRadius: 10)
          ]),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(i, color: c, size: 30),
            const SizedBox(height: 8),
            Text(v,
                style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87)),
            Text(t,
                style: const TextStyle(
                    color: Colors.grey, fontSize: 12)),
          ]),
    );
  }
}

// ── TAB 2: USER MANAGEMENT ────────────────────────────────────────────────────
class _UsersTab extends StatelessWidget {
  const _UsersTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminController.to;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: (v) =>
              ctrl.searchQuery.value = v.toLowerCase(),
          decoration: InputDecoration(
            hintText: 'Tìm kiếm theo tên...',
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: ctrl.usersStream,
          builder: (context, snap) {
            if (!snap.hasData)
              return const Center(
                  child: CircularProgressIndicator());
            final docs = snap.data!.docs;
            return Obx(() {
              final filtered = docs.where((doc) {
                final name =
                    (doc['name'] ?? '').toString().toLowerCase();
                return name.contains(ctrl.searchQuery.value);
              }).toList();
              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final data =
                      filtered[i].data() as Map<String, dynamic>;
                  final isBanned = data['isBanned'] == true;
                  return ListTile(
                    leading: CircleAvatar(
                        backgroundImage:
                            data['photoUrl']?.toString().isNotEmpty ==
                                    true
                                ? NetworkImage(data['photoUrl'])
                                : null),
                    title: Text(data['name'] ?? 'User',
                        style: TextStyle(
                            color: isBanned
                                ? Colors.red
                                : Colors.black87)),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'ban')
                          ctrl.banUser(filtered[i].id, 'Vi phạm tiêu chuẩn');
                        if (val == 'unban')
                          ctrl.unbanUser(filtered[i].id);
                        if (val == 'delete')
                          ctrl.deleteUser(filtered[i].id);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(
                            value: isBanned ? 'unban' : 'ban',
                            child: Text(
                                isBanned ? 'Bỏ cấm' : 'Cấm user')),
                        const PopupMenuItem(
                            value: 'delete',
                            child: Text('Xoá vĩnh viễn')),
                      ],
                    ),
                  );
                },
              );
            });
          },
        ),
      ),
    ]);
  }
}

// ── TAB 3: CREATE USER ────────────────────────────────────────────────────────
class _CreateUserTab extends StatefulWidget {
  const _CreateUserTab();

  @override
  State<_CreateUserTab> createState() => _CreateUserTabState();
}

class _CreateUserTabState extends State<_CreateUserTab> {
  final _email = TextEditingController();
  final _pass  = TextEditingController();
  final _name  = TextEditingController();
  final _age   = TextEditingController();
  String _selectedCity = '';
  String _gender = 'Nam';
  bool _obscurePass = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    _name.dispose();
    _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl   = AdminController.to;
    final isDark = ThemeController.to.isDark;
    final bg     = isDark ? AppColors.darkBg : const Color(0xFFF8F9FA);
    final cardBg = isDark ? AppColors.darkCard : Colors.white;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header card ────────────────────────────────────────────
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: AppColors.primary.withOpacity(0.2)),
            ),
            child: Row(children: [
              const Icon(Icons.person_add_outlined,
                  color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Tạo tài khoản mới',
                          style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15)),
                      Text(
                          'Tạo user mà không đăng xuất admin hiện tại.',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600)),
                    ]),
              ),
            ]),
          ),
          const SizedBox(height: 20),

          // ── Form fields ────────────────────────────────────────────
          _adminField(_email, 'Email *', Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              cardBg: cardBg),
          const SizedBox(height: 12),
          _adminField(
            _pass, 'Mật khẩu * (tối thiểu 6 ký tự)', Icons.lock_outline,
            obscure: _obscurePass,
            cardBg: cardBg,
            suffix: IconButton(
              icon: Icon(
                _obscurePass
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.grey,
              ),
              onPressed: () =>
                  setState(() => _obscurePass = !_obscurePass),
            ),
          ),
          const SizedBox(height: 12),
          _adminField(_name, 'Họ tên *', Icons.person_outline,
              cardBg: cardBg),
          const SizedBox(height: 12),
          _adminField(_age, 'Tuổi *', Icons.cake_outlined,
              keyboardType: TextInputType.number, cardBg: cardBg),
          const SizedBox(height: 12),

          // ── City Picker ────────────────────────────────────────────
          _buildCityPicker(context, ctrl, cardBg),
          const SizedBox(height: 16),

          // ── Giới tính ─────────────────────────────────────────────
          const Text('Giới tính',
              style: TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: ['Nam', 'Nữ', 'Khác']
                .map((g) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(g),
                        selected: _gender == g,
                        onSelected: (_) =>
                            setState(() => _gender = g),
                        selectedColor:
                            AppColors.primary.withOpacity(0.15),
                        labelStyle: TextStyle(
                          color: _gender == g
                              ? AppColors.primary
                              : Colors.black87,
                          fontWeight: _gender == g
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 24),

          // ── Error / Success banner ─────────────────────────────────
          Obx(() {
            if (ctrl.createUserError.value.isNotEmpty) {
              return _banner(ctrl.createUserError.value,
                  isError: true);
            }
            if (ctrl.createUserSuccess.value.isNotEmpty) {
              return _banner(ctrl.createUserSuccess.value,
                  isError: false);
            }
            return const SizedBox.shrink();
          }),

          // ── Submit button ──────────────────────────────────────────
          Obx(() => SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: ctrl.isCreatingUser.value
                  ? null
                  : () {
                      ctrl.createUserError.value   = '';
                      ctrl.createUserSuccess.value = '';
                      ctrl.createUser(
                        email:    _email.text,
                        password: _pass.text,
                        name:     _name.text,
                        age:      int.tryParse(_age.text.trim()) ?? 20,
                        gender:   _gender,
                        city:     _selectedCity,
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14)),
              ),
              child: ctrl.isCreatingUser.value
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2.5))
                  : const Text('Tạo tài khoản',
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16)),
            ),
          )),
        ],
      ),
    );
  }

  // City picker — dùng citiesStream real-time ─────────────────────────────────
  Widget _buildCityPicker(
      BuildContext context, AdminController ctrl, Color cardBg) {
    return StreamBuilder<QuerySnapshot>(
      stream: ctrl.citiesStream,
      builder: (context, snap) {
        final isLoading = !snap.hasData;
        final cities = snap.hasData
            ? snap.data!.docs
                .map((d) =>
                    (d.data() as Map)['name']?.toString() ?? '')
                .where((n) => n.isNotEmpty)
                .toList()
            : <String>[];

        // Reset selected city if it no longer exists
        if (!isLoading &&
            _selectedCity.isNotEmpty &&
            !cities.contains(_selectedCity)) {
          WidgetsBinding.instance
              .addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedCity = '');
          });
        }

        return GestureDetector(
          onTap: isLoading || cities.isEmpty
              ? null
              : () => _showCityPicker(context, cities),
          child: Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _selectedCity.isNotEmpty
                    ? AppColors.primary.withOpacity(0.5)
                    : Colors.transparent,
              ),
            ),
            child: Row(children: [
              Icon(
                _selectedCity.isNotEmpty
                    ? Icons.location_on
                    : Icons.location_city_outlined,
                color: _selectedCity.isNotEmpty
                    ? AppColors.primary
                    : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  isLoading
                      ? 'Đang tải thành phố...'
                      : cities.isEmpty
                          ? 'Chưa có thành phố (thêm ở tab Thành phố)'
                          : _selectedCity.isEmpty
                              ? 'Chọn thành phố'
                              : _selectedCity,
                  style: TextStyle(
                    color: _selectedCity.isNotEmpty
                        ? Colors.black87
                        : Colors.grey,
                    fontSize: 15,
                    fontWeight: _selectedCity.isNotEmpty
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                ),
              ),
              if (isLoading)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2),
                )
              else if (cities.isEmpty)
                const Icon(Icons.info_outline,
                    color: Colors.orange, size: 18)
              else
                Icon(
                  _selectedCity.isNotEmpty
                      ? Icons.check_circle
                      : Icons.arrow_drop_down,
                  color: _selectedCity.isNotEmpty
                      ? AppColors.primary
                      : Colors.grey,
                ),
            ]),
          ),
        );
      },
    );
  }

  void _showCityPicker(BuildContext context, List<String> cities) {
    Get.bottomSheet(
      StatefulBuilder(builder: (ctx, setS) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const Text('Chọn thành phố',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text('${cities.length} thành phố',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 8),
            const Divider(height: 1),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: cities.length,
                separatorBuilder: (_, __) =>
                    const Divider(height: 1, indent: 56),
                itemBuilder: (ctx, i) {
                  final city = cities[i];
                  final isSelected = _selectedCity == city;
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: isSelected
                          ? AppColors.primary.withOpacity(0.12)
                          : Colors.grey.shade100,
                      child: Text(
                        city[0].toUpperCase(),
                        style: TextStyle(
                          color: isSelected
                              ? AppColors.primary
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    title: Text(city,
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.normal,
                          color: isSelected
                              ? AppColors.primary
                              : Colors.black87,
                        )),
                    trailing: isSelected
                        ? const Icon(Icons.check_circle,
                            color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedCity = city);
                      Get.back();
                    },
                  );
                },
              ),
            ),
          ]),
        );
      }),
      isScrollControlled: true,
    );
  }

  Widget _adminField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    TextInputType keyboardType = TextInputType.text,
    bool obscure = false,
    Widget? suffix,
    required Color cardBg,
  }) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: Colors.grey),
        suffixIcon: suffix,
        filled: true,
        fillColor: cardBg,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(
                color: AppColors.primary, width: 1.5)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _banner(String msg, {required bool isError}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isError ? Colors.red.shade50 : Colors.green.shade50,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
            color: isError
                ? Colors.red.shade200
                : Colors.green.shade200),
      ),
      child: Row(children: [
        Icon(
          isError ? Icons.error_outline : Icons.check_circle_outline,
          color: isError ? Colors.red : Colors.green,
          size: 18,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(msg,
              style: TextStyle(
                  color: isError ? Colors.red : Colors.green,
                  fontSize: 13)),
        ),
      ]),
    );
  }
}

// ── TAB 4: PENDING PAYMENTS ───────────────────────────────────────────────────
class _PendingPaymentsTab extends StatelessWidget {
  const _PendingPaymentsTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminController.to;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('pending_payments')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle_outline,
                      color: Colors.green, size: 48),
                  SizedBox(height: 12),
                  Text('Không có thanh toán chờ xử lý'),
                ]),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final status  = data['status'] as String? ?? 'pending';
            final plan    = data['plan'] as String? ?? '';
            final price   = (data['price'] as num?)?.toInt() ?? 0;
            final userId  = data['userId'] as String? ?? '';
            final isPending = status == 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Icon(
                  isPending
                      ? Icons.hourglass_top
                      : Icons.check_circle,
                  color:
                      isPending ? Colors.orange : Colors.green,
                ),
                title: Text(
                  'Gói ${plan.toUpperCase()} — ${AppHelpers.formatPrice(price)}',
                  style:
                      const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(
                    'User: $userId\nTrạng thái: $status',
                    style: const TextStyle(fontSize: 12)),
                isThreeLine: true,
                trailing: isPending
                    ? ElevatedButton(
                        onPressed: () =>
                            ctrl.confirmPendingPayment(docs[i].id),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(10)),
                        ),
                        child: const Text('Xác nhận'),
                      )
                    : null,
              ),
            );
          },
        );
      },
    );
  }
}

// ── TAB 5: REPORTS ────────────────────────────────────────────────────────────
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminController.to;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.colReports)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData)
          return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty)
          return const Center(child: Text('Không có báo cáo nào'));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data =
                docs[i].data() as Map<String, dynamic>;
            final isResolved = data['isResolved'] == true;
            return ListTile(
              leading: Icon(Icons.report_problem_outlined,
                  color:
                      isResolved ? Colors.green : Colors.red),
              title: Text(data['reason'] ?? 'Báo cáo vi phạm'),
              trailing: isResolved
                  ? const Icon(Icons.check_circle_outline,
                      color: Colors.green)
                  : TextButton(
                      onPressed: () =>
                          ctrl.resolveReport(docs[i].id),
                      child: const Text('XỬ LÝ'),
                    ),
            );
          },
        );
      },
    );
  }
}

// ── TAB 6: CITIES ─────────────────────────────────────────────────────────────
class _CitiesTab extends StatefulWidget {
  const _CitiesTab();

  @override
  State<_CitiesTab> createState() => _CitiesTabState();
}

class _CitiesTabState extends State<_CitiesTab> {
  final _cityCtrl = TextEditingController();

  @override
  void dispose() {
    _cityCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminController.to;

    return Column(children: [
      // ── Input thêm thành phố ──────────────────────────────────────
      Container(
        color: Colors.white,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Quản lý thành phố',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                'Danh sách hiển thị khi người dùng đăng ký tài khoản',
                style: TextStyle(
                    fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _cityCtrl,
                  textCapitalization: TextCapitalization.words,
                  decoration: InputDecoration(
                    hintText: 'Nhập tên thành phố...',
                    prefixIcon: const Icon(
                        Icons.add_location_alt_outlined,
                        color: AppColors.primary),
                    filled: true,
                    fillColor: const Color(0xFFF5F5F5),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                  ),
                  onSubmitted: (v) {
                    ctrl.addCity(v);
                    _cityCtrl.clear();
                  },
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton(
                onPressed: () {
                  ctrl.addCity(_cityCtrl.text);
                  _cityCtrl.clear();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text('Thêm',
                    style:
                        TextStyle(fontWeight: FontWeight.bold)),
              ),
            ]),
          ],
        ),
      ),
      const Divider(height: 1),

      // ── Danh sách từ Firestore (real-time stream) ─────────────────
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: ctrl.citiesStream,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }
            if (snap.hasError) {
              return Center(
                  child: Text('Lỗi: ${snap.error}',
                      style:
                          const TextStyle(color: Colors.red)));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(
                child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 56,
                          color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Chưa có thành phố nào',
                          style: TextStyle(
                              color: Colors.grey,
                              fontSize: 15)),
                      const SizedBox(height: 6),
                      Text('Nhập tên và nhấn Thêm ở trên',
                          style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade400)),
                    ]),
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: docs.length,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, indent: 56),
              itemBuilder: (ctx, i) {
                final data =
                    docs[i].data() as Map<String, dynamic>;
                final name = data['name'] as String? ?? '';
                return ListTile(
                  leading: CircleAvatar(
                    radius: 20,
                    backgroundColor:
                        AppColors.primary.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty
                          ? name[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                  title: Text(name,
                      style: const TextStyle(
                          fontWeight: FontWeight.w500)),
                  subtitle: Text('ID: ${docs[i].id}',
                      style: const TextStyle(
                          fontSize: 10, color: Colors.grey)),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline,
                        color: Colors.redAccent),
                    onPressed: () =>
                        ctrl.deleteCity(docs[i].id, name),
                    tooltip: 'Xoá thành phố',
                  ),
                );
              },
            );
          },
        ),
      ),

      // ── Footer count (real-time) ───────────────────────────────────
      StreamBuilder<QuerySnapshot>(
        stream: ctrl.citiesStream,
        builder: (context, snap) {
          final count = snap.data?.docs.length ?? 0;
          return Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Center(
              child: Text(
                'Tổng cộng: $count thành phố',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
            ),
          );
        },
      ),
    ]);
  }
}
