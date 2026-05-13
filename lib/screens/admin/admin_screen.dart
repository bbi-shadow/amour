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

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
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
      backgroundColor: isDark ? AppColors.darkBg : const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quan tri he thong', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: isDark ? AppColors.darkCard : Colors.white,
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
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Thống kê'),
            Tab(icon: Icon(Icons.people_outline), text: 'Người dùng'),
            Tab(icon: Icon(Icons.person_add_outlined), text: 'Tạo User'),
            Tab(icon: Icon(Icons.payment_outlined), text: 'Thanh toán'),
            Tab(icon: Icon(Icons.flag_outlined), text: 'Báo cáo'),
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

// -- TAB 1: DASHBOARD --
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final controller = AdminController.to;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Tong quan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15,
          shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            Obx(() => _card("User", "${controller.stats['users']}", Icons.person_outline, Colors.blue)),
            Obx(() => _card("Matches", "${controller.stats['matches']}", Icons.favorite_border, Colors.pink)),
            Obx(() => _card("Bao cao", "${controller.stats['reports']}", Icons.warning_amber_rounded, Colors.orange)),
            Obx(() => _card("Bai dang", "${controller.stats['posts']}", Icons.chat_bubble_outline, Colors.teal)),
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
          boxShadow: [BoxShadow(color: c.withOpacity(0.05), blurRadius: 10)]
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(i, color: c, size: 30),
        const SizedBox(height: 8),
        Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.black87)),
        Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }
}

// -- TAB 2: USER MANAGEMENT --
class _UsersTab extends StatelessWidget {
  const _UsersTab();
  @override
  Widget build(BuildContext context) {
    final controller = AdminController.to;
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: TextField(
          onChanged: (v) => controller.searchQuery.value = v.toLowerCase(),
          decoration: InputDecoration(
            hintText: 'Tim kiem theo ten...',
            prefixIcon: const Icon(Icons.search),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          ),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: controller.usersStream,
          builder: (context, snap) {
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = snap.data!.docs;

            return Obx(() {
              final filtered = docs.where((doc) {
                final name = (doc['name'] ?? '').toString().toLowerCase();
                return name.contains(controller.searchQuery.value);
              }).toList();

              return ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (ctx, i) {
                  final data = filtered[i].data() as Map<String, dynamic>;
                  final isBanned = data['isBanned'] == true;
                  return ListTile(
                    leading: CircleAvatar(backgroundImage: data['photoUrl']?.toString().isNotEmpty == true ? NetworkImage(data['photoUrl']) : null),
                    title: Text(data['name'] ?? 'User', style: TextStyle(color: isBanned ? Colors.red : Colors.black87)),
                    subtitle: Text(data['email'] ?? ''),
                    trailing: PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'ban') controller.banUser(filtered[i].id, "Vi pham tieu chuan");
                        if (val == 'unban') controller.unbanUser(filtered[i].id);
                        if (val == 'delete') controller.deleteUser(filtered[i].id);
                      },
                      itemBuilder: (_) => [
                        PopupMenuItem(value: isBanned ? 'unban' : 'ban', child: Text(isBanned ? 'Bo cam' : 'Cam user')),
                        const PopupMenuItem(value: 'delete', child: Text('Xoa vinh vien')),
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

// -- TAB 3: CREATE USER --
class _CreateUserTab extends StatefulWidget {
  const _CreateUserTab();
  @override
  State<_CreateUserTab> createState() => _CreateUserTabState();
}

class _CreateUserTabState extends State<_CreateUserTab> {
  final _email    = TextEditingController();
  final _pass     = TextEditingController();
  final _name    = TextEditingController();
  final _age     = TextEditingController();
  String _selectedCity = '';
  String _gender = 'Nam';

  @override
  void dispose() {
    _email.dispose(); _pass.dispose();
    _name.dispose();  _age.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = AdminController.to;
    final isDark = ThemeController.to.isDark;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Tạo tài khoản mới',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text('Tạo user mà không đăng xuất admin hiện tại.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
        const SizedBox(height: 24),

        _field(_email, 'Email *', keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 12),
        _field(_pass, 'Mật khẩu * (tối thiểu 6 ký tự)', obscure: true),
        const SizedBox(height: 12),
        _field(_name, 'Họ tên *'),
        const SizedBox(height: 12),
        _field(_age, 'Tuổi *', keyboardType: TextInputType.number),
        const SizedBox(height: 12),

        // City Picker
        GestureDetector(
          onTap: () => _showCityPicker(context, ctrl),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.location_city_outlined, color: Colors.grey),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _selectedCity.isEmpty ? 'Chọn thành phố' : _selectedCity,
                    style: TextStyle(
                      color: _selectedCity.isEmpty ? Colors.grey : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
                Obx(() => ctrl.isLoadingCities.value
                    ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.arrow_drop_down, color: Colors.grey)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),

        // Giới tính
        Row(children: [
          const Text('Giới tính:', style: TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(width: 16),
          ...['Nam', 'Nữ', 'Khác'].map((g) => Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(g),
              selected: _gender == g,
              onSelected: (_) => setState(() => _gender = g),
              selectedColor: AppColors.primary.withOpacity(0.2),
            ),
          )),
        ]),
        const SizedBox(height: 24),

        // Error / Success message
        Obx(() {
          if (ctrl.createUserError.value.isNotEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(ctrl.createUserError.value,
                  style: const TextStyle(color: Colors.red, fontSize: 13)),
            );
          }
          if (ctrl.createUserSuccess.value.isNotEmpty) {
            return Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Text(ctrl.createUserSuccess.value,
                  style: const TextStyle(color: Colors.green, fontSize: 13)),
            );
          }
          return const SizedBox.shrink();
        }),

        Obx(() => SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: ctrl.isCreatingUser.value
                ? null
                : () {
              ctrl.createUserError.value = '';
              ctrl.createUserSuccess.value = '';
              ctrl.createUser(
                email: _email.text,
                password: _pass.text,
                name: _name.text,
                age: int.tryParse(_age.text.trim()) ?? 20,
                gender: _gender,
                city: _selectedCity,
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: ctrl.isCreatingUser.value
                ? const SizedBox(
                width: 22, height: 22,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2.5))
                : const Text('Tạo tài khoản',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        )),
      ]),
    );
  }

  Widget _field(TextEditingController ctrl, String label,
      {TextInputType keyboardType = TextInputType.text,
        bool obscure = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: keyboardType,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  void _showCityPicker(BuildContext context, AdminController ctrl) {
    if (ctrl.isLoadingCities.value) {
      AppHelpers.showError('Đang tải danh sách thành phố...');
      return;
    }
    if (ctrl.cities.isEmpty) {
      AppHelpers.showError('Không có dữ liệu thành phố');
      return;
    }
    Get.bottomSheet(
      Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text('Chọn thành phố',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            const Divider(),
            Expanded(
              child: Obx(() => ListView.builder(
                itemCount: ctrl.cities.length,
                itemBuilder: (ctx, i) {
                  final city = ctrl.cities[i];
                  final isSelected = _selectedCity == city;
                  return ListTile(
                    leading: Icon(Icons.location_on_outlined,
                        color: isSelected ? AppColors.primary : Colors.grey),
                    title: Text(city,
                        style: TextStyle(
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? AppColors.primary : Colors.black87,
                        )),
                    trailing: isSelected
                        ? const Icon(Icons.check, color: AppColors.primary)
                        : null,
                    onTap: () {
                      setState(() => _selectedCity = city);
                      Get.back();
                    },
                  );
                },
              )),
            ),
          ],
        ),
      ),
    );
  }
}

// -- TAB 4: PENDING PAYMENTS --
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
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return const Center(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.check_circle_outline, color: Colors.green, size: 48),
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
            final status = data['status'] as String? ?? 'pending';
            final plan = data['plan'] as String? ?? '';
            final price = (data['price'] as num?)?.toInt() ?? 0;
            final userId = data['userId'] as String? ?? '';
            final isPending = status == 'pending';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              child: ListTile(
                leading: Icon(
                  isPending ? Icons.hourglass_top : Icons.check_circle,
                  color: isPending ? Colors.orange : Colors.green,
                ),
                title: Text('Gói ${plan.toUpperCase()} — ${AppHelpers.formatPrice(price)}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text('User: $userId\nTrạng thái: $status',
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
                        borderRadius: BorderRadius.circular(10)),
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

// -- TAB 5: REPORTS --
class _ReportsTab extends StatelessWidget {
  const _ReportsTab();
  @override
  Widget build(BuildContext context) {
    final controller = AdminController.to;
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection(AppConstants.colReports).orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text("Khong co bao cao nao"));

        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final isResolved = data['isResolved'] == true;
            return ListTile(
              leading: Icon(Icons.report_problem_outlined, color: isResolved ? Colors.green : Colors.red),
              title: Text(data['reason'] ?? 'Bao cao vi pham'),
              trailing: isResolved ? const Icon(Icons.check_circle_outline) : TextButton(
                onPressed: () => controller.resolveReport(docs[i].id),
                child: const Text("XU LY"),
              ),
            );
          },
        );
      },
    );
  }
}
// -- TAB 6: CITIES --
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

    return Column(
      children: [
        // -- Input thêm thành phố --
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Quản lý thành phố',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text('Danh sách thành phố hiển thị khi đăng ký',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cityCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        hintText: 'Nhập tên thành phố...',
                        prefixIcon: const Icon(Icons.add_location_alt_outlined,
                            color: AppColors.primary),
                        filled: true,
                        fillColor: const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
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
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // -- Danh sách thành phố từ Firestore --
        Expanded(
          child: StreamBuilder<QuerySnapshot>(
            stream: ctrl.citiesStream,
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!.docs;
              if (docs.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.location_off_outlined,
                          size: 56, color: Colors.grey.shade300),
                      const SizedBox(height: 12),
                      const Text('Chưa có thành phố nào',
                          style: TextStyle(color: Colors.grey)),
                      const SizedBox(height: 6),
                      Text('Thêm thành phố ở trên để bắt đầu',
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey.shade400)),
                    ],
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: docs.length,
                separatorBuilder: (_, __) =>
                const Divider(height: 1, indent: 56),
                itemBuilder: (ctx, i) {
                  final data = docs[i].data() as Map<String, dynamic>;
                  final name = data['name'] as String? ?? '';
                  return ListTile(
                    leading: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(name,
                        style: const TextStyle(fontWeight: FontWeight.w500)),
                    subtitle: Text('ID: ${docs[i].id}',
                        style: const TextStyle(
                            fontSize: 10, color: Colors.grey)),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.redAccent),
                      onPressed: () =>
                          ctrl.deleteCity(docs[i].id, name),
                    ),
                  );
                },
              );
            },
          ),
        ),

        // -- Footer: tổng số --
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
      ],
    );
  }
}