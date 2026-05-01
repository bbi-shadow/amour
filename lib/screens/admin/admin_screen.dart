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
    _tabController = TabController(length: 4, vsync: this);
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
            Tab(icon: Icon(Icons.analytics_outlined), text: 'Thong ke'),
            Tab(icon: Icon(Icons.people_outline), text: 'Nguoi dung'),
            Tab(icon: Icon(Icons.person_add_outlined), text: 'Tao User'),
            Tab(icon: Icon(Icons.flag_outlined), text: 'Bao cao'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _DashboardTab(),
          _UsersTab(),
          _CreateUserTab(),
          _ReportsTab(),
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
    return Obx(() => ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Text("Tong quan", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
          children: [
            _card("User", "${controller.stats['users']}", Icons.person_outline, Colors.blue),
            _card("Matches", "${controller.stats['matches']}", Icons.favorite_border, Colors.pink),
            _card("Bao cao", "${controller.stats['reports']}", Icons.warning_amber_rounded, Colors.orange),
            _card("Bai dang", "${controller.stats['posts']}", Icons.chat_bubble_outline, Colors.teal),
          ],
        ),
        const SizedBox(height: 32),
        OutlinedButton.icon(
          onPressed: controller.clearFakeUsers,
          icon: const Icon(Icons.cleaning_services_outlined),
          label: const Text("DON DEP FAKE USERS"),
          style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red), padding: const EdgeInsets.all(16)),
        ),
      ],
    ));
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
  final _email = TextEditingController();
  final _pass = TextEditingController();
  final _name = TextEditingController();
  final _age = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final controller = AdminController.to;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(children: [
        const Text("Tao tai khoan moi", style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 20),
        TextField(controller: _email, decoration: const InputDecoration(labelText: "Email")),
        const SizedBox(height: 12),
        TextField(controller: _pass, decoration: const InputDecoration(labelText: "Mat khau"), obscureText: true),
        const SizedBox(height: 12),
        TextField(controller: _name, decoration: const InputDecoration(labelText: "Ten")),
        const SizedBox(height: 12),
        TextField(controller: _age, decoration: const InputDecoration(labelText: "Tuoi"), keyboardType: TextInputType.number),
        const SizedBox(height: 32),
        Obx(() => SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: controller.isCreatingUser.value ? null : () {
              controller.createUser(
                email: _email.text, password: _pass.text, 
                name: _name.text, age: int.tryParse(_age.text) ?? 20, 
                gender: "Nu"
              );
            }, 
            child: controller.isCreatingUser.value ? const CircularProgressIndicator() : const Text("TAO TAI KHOAN")
          ),
        )),
      ]),
    );
  }
}

// -- TAB 4: REPORTS --
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
