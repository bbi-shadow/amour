import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../../services/firestore_service.dart';
import '../../themes/app_theme.dart';
import '../../utils/app_constants.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});
  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text('Quản trị Amour', style: TextStyle(fontWeight: FontWeight.w900)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: Colors.red),
            onPressed: () => Get.offAllNamed(AppRoutes.login),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Thống kê'),
            Tab(icon: Icon(Icons.people_alt_rounded), text: 'Người dùng'),
            Tab(icon: Icon(Icons.person_add_alt_1_rounded), text: 'Tạo User'),
            Tab(icon: Icon(Icons.campaign_rounded), text: 'Báo cáo'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          const _DashboardTab(),
          const _UsersTab(),
          const _CreateUserTab(),
          const _ReportsTab(),
        ],
      ),
    );
  }
}

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, int>>(
      future: FirestoreService.getStats(),
      builder: (context, snap) {
        final s = snap.data ?? {'users': 0, 'matches': 0, 'reports': 0, 'posts': 0};
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const Text("Tổng quan hệ thống", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            GridView.count(
              crossAxisCount: 2, crossAxisSpacing: 15, mainAxisSpacing: 15, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
              children: [
                _card("Tổng User", "${s['users']}", Icons.person, Colors.blue),
                _card("Matches", "${s['matches']}", Icons.favorite, Colors.pink),
                _card("Báo cáo", "${s['reports']}", Icons.warning, Colors.orange),
                _card("Bài đăng", "${s['posts']}", Icons.chat_bubble, Colors.teal),
              ],
            ),
            const SizedBox(height: 30),
            // Giữ lại nút dọn dẹp để bạn xóa những gì không cần thiết
            ElevatedButton.icon(
              onPressed: () => _confirmClearFakeUsers(context),
              icon: const Icon(Icons.cleaning_services),
              label: const Text("DỌN DẸP HỆ THỐNG"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: 15)),
            ),
          ],
        );
      },
    );
  }

  void _confirmClearFakeUsers(BuildContext context) async {
    final confirmed = await AppHelpers.confirm(
      title: "Xác nhận dọn dẹp", 
      message: "Xóa sạch các tài khoản thử nghiệm cũ để bắt đầu tạo mới?"
    );
    
    if (confirmed) {
      await FirestoreService.deleteAllFakeUsers();
      AppHelpers.showSuccess("Hệ thống đã sạch sẽ!");
    }
  }

  Widget _card(String t, String v, IconData i, Color c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        borderRadius: BorderRadius.circular(20), 
        boxShadow: [BoxShadow(color: c.withValues(alpha: 0.1), blurRadius: 10)]
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(i, color: c, size: 30),
        const SizedBox(height: 10),
        Text(v, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
        Text(t, style: const TextStyle(color: Colors.grey, fontSize: 12)),
      ]),
    );
  }
}

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
  final _gender = "Nữ";
  bool _isSaving = false;

  Future<void> _createRealUser() async {
    if (_email.text.isEmpty || _pass.text.isEmpty || _name.text.isEmpty) {
      AppHelpers.showError("Vui lòng điền đủ thông tin");
      return;
    }
    setState(() => _isSaving = true);
    try {
      UserCredential credential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _email.text.trim(),
        password: _pass.text.trim(),
      );
      await FirebaseFirestore.instance.collection('users').doc(credential.user!.uid).set({
        'uid': credential.user!.uid,
        'name': _name.text,
        'email': _email.text.trim(),
        'age': int.tryParse(_age.text) ?? 20,
        'gender': _gender,
        'isVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
        'isOnline': false,
        'photos': [],
        'photoUrl': "https://i.pravatar.cc/300?u=${credential.user!.uid}",
      });
      AppHelpers.showSuccess("Tài khoản người dùng thật đã sẵn sàng!");
      _email.clear(); _pass.clear(); _name.clear(); _age.clear();
    } catch (e) {
      AppHelpers.showError("Lỗi: $e");
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(children: [
        const Text("Thông tin đăng nhập mới", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 15),
        TextField(controller: _email, decoration: const InputDecoration(labelText: "Email", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _pass, decoration: const InputDecoration(labelText: "Mật khẩu", border: OutlineInputBorder()), obscureText: true),
        const SizedBox(height: 10),
        TextField(controller: _name, decoration: const InputDecoration(labelText: "Tên hiển thị", border: OutlineInputBorder())),
        const SizedBox(height: 10),
        TextField(controller: _age, decoration: const InputDecoration(labelText: "Tuổi", border: OutlineInputBorder()), keyboardType: TextInputType.number),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _createRealUser, 
            child: Text(_isSaving ? "Đang tạo..." : "TẠO NGƯỜI DÙNG THẬT")
          )
        ),
      ]),
    );
  }
}

class _UsersTab extends StatelessWidget {
  const _UsersTab();
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirestoreService.getAllUsersStream(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        final docs = snap.data?.docs ?? [];
        return ListView.builder(
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: (data['photoUrl'] != null && data['photoUrl'].toString().isNotEmpty) 
                  ? NetworkImage(data['photoUrl']) : null,
                child: data['photoUrl'] == null ? const Icon(Icons.person) : null,
              ),
              title: Text(data['name'] ?? "Không tên"),
              subtitle: Text(data['email'] ?? "Chưa có email"),
            );
          },
        );
      },
    );
  }
}

class _ReportsTab extends StatelessWidget {
  const _ReportsTab();
  @override
  Widget build(BuildContext context) {
    return const Center(child: Text("Danh sách báo cáo vi phạm"));
  }
}
