import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../auth/login_screen.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  final _db = FirebaseFirestore.instance;

  // ── Stats ──
  int _totalUsers    = 0;
  int _totalMatches  = 0;
  int _totalMessages = 0;
  int _totalReports  = 0;
  int _bannedUsers   = 0;
  bool _statsLoading  = true;
  bool _scanningPhotos = false;
  String _searchQuery  = '';

  // ── Tạo User ──
  final _nameCtrl   = TextEditingController();
  final _ageCtrl    = TextEditingController();
  final _bioCtrl    = TextEditingController();
  final _photoCtrl  = TextEditingController();
  final _emailCtrl  = TextEditingController();
  String _selectedGender = 'Nam';
  String _selectedCity   = '';
  List<String> _availableCities = [];
  List<String> _selectedInterests = [];
  bool _creatingUser = false;

  static const _allInterests = [
    '🎵 Âm nhạc', '🎬 Phim ảnh', '📚 Đọc sách', '✈️ Du lịch',
    '🍜 Ẩm thực', '🏋️ Thể thao', '🎮 Game', '📸 Nhiếp ảnh',
    '🎨 Nghệ thuật', '🐾 Thú cưng', '🌿 Thiên nhiên', '💃 Khiêu vũ',
  ];

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 6, vsync: this);
    _loadStats();
    _loadCities();
  }

  @override
  void dispose() {
    _tab.dispose();
    _nameCtrl.dispose();
    _ageCtrl.dispose();
    _bioCtrl.dispose();
    _photoCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ════════════════════════════════════════════════
  //  STATS
  // ════════════════════════════════════════════════
  Future<void> _loadStats() async {
    setState(() => _statsLoading = true);
    try {
      final results = await Future.wait([
        _db.collection('users').count().get(),
        _db.collection('matches').count().get(),
        _db.collection('users').where('isBanned', isEqualTo: true).count().get(),
        _db.collection('reports').where('status', isEqualTo: 'pending').count().get(),
      ]);

      int msgCount = 0;
      final matches = await _db.collection('matches').get();
      for (final m in matches.docs) {
        final snap = await _db
            .collection('matches').doc(m.id).collection('messages').count().get();
        msgCount += snap.count ?? 0;
      }

      setState(() {
        _totalUsers    = results[0].count ?? 0;
        _totalMatches  = results[1].count ?? 0;
        _bannedUsers   = results[2].count ?? 0;
        _totalReports  = results[3].count ?? 0;
        _totalMessages = msgCount;
        _statsLoading  = false;
      });
    } catch (_) {
      setState(() => _statsLoading = false);
    }
  }

  // ════════════════════════════════════════════════
  //  TẠO USER
  // ════════════════════════════════════════════════
  Future<void> _loadCities() async {
    try {
      final snap = await _db.collection('cities').orderBy('name').get();
      setState(() {
        _availableCities = snap.docs
            .map((d) => d['name']?.toString() ?? '')
            .where((c) => c.isNotEmpty)
            .toList();
        if (_availableCities.isNotEmpty) _selectedCity = _availableCities.first;
      });
    } catch (_) {}
  }

  Future<void> _createFakeUser() async {
    final name  = _nameCtrl.text.trim();
    final age   = int.tryParse(_ageCtrl.text.trim());
    final email = _emailCtrl.text.trim();

    if (name.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng nhập tên',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }
    if (age == null || age < 18 || age > 99) {
      Get.snackbar('Lỗi', 'Tuổi không hợp lệ (18–99)',
          backgroundColor: Colors.red, colorText: Colors.white);
      return;
    }

    setState(() => _creatingUser = true);
    try {
      final uid = _db.collection('users').doc().id;

      await _db.collection('users').doc(uid).set({
        'uid':       uid,
        'name':      name,
        'age':       age,
        'gender':    _selectedGender,
        'city':      _selectedCity,
        'location':  _selectedCity,
        'bio':       _bioCtrl.text.trim(),
        'photoUrl':  _photoCtrl.text.trim(),
        'email':     email,
        'interests': _selectedInterests,
        'isBanned':  false,
        'isFake':    true,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Reset form
      _nameCtrl.clear();
      _ageCtrl.clear();
      _bioCtrl.clear();
      _photoCtrl.clear();
      _emailCtrl.clear();
      setState(() {
        _selectedGender    = 'Nam';
        _selectedInterests = [];
        if (_availableCities.isNotEmpty) _selectedCity = _availableCities.first;
      });

      _loadStats();
      Get.snackbar('✅ Thành công', 'Đã tạo user "$name"',
          backgroundColor: Colors.green, colorText: Colors.white);
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể tạo user: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    setState(() => _creatingUser = false);
  }

  Future<void> _createBatchUsers() async {
    final ok = await _confirmDialog(
      context,
      title: '🤖 Tạo user hàng loạt?',
      content: 'Sẽ tạo 10 user giả ngẫu nhiên để test. Tiếp tục?',
      confirmLabel: 'Tạo ngay',
      confirmColor: const Color(0xFFFF4B6E),
    );
    if (!ok) return;

    setState(() => _creatingUser = true);

    final names = ['An', 'Bình', 'Chi', 'Dung', 'Em', 'Phương', 'Giang', 'Hoa', 'Iris', 'Jade'];
    final bios  = [
      'Yêu thích du lịch và khám phá 🌍',
      'Coffee addict ☕ | Sống chậm lại',
      'Đang học yoga 🧘 và nấu ăn 🍳',
      'Phim và sách là cuộc sống 📚🎬',
      'Thích chó hơn người 🐶',
    ];
    final photos = [
      'https://i.pravatar.cc/400?img=1',
      'https://i.pravatar.cc/400?img=2',
      'https://i.pravatar.cc/400?img=3',
      'https://i.pravatar.cc/400?img=4',
      'https://i.pravatar.cc/400?img=5',
      'https://i.pravatar.cc/400?img=6',
      'https://i.pravatar.cc/400?img=7',
      'https://i.pravatar.cc/400?img=8',
      'https://i.pravatar.cc/400?img=9',
      'https://i.pravatar.cc/400?img=10',
    ];

    int created = 0;
    for (int i = 0; i < 10; i++) {
      try {
        final uid  = _db.collection('users').doc().id;
        final city = _availableCities.isNotEmpty
            ? _availableCities[i % _availableCities.length]
            : 'Hà Nội';
        await _db.collection('users').doc(uid).set({
          'uid':       uid,
          'name':      names[i],
          'age':       18 + (i * 2),
          'gender':    i % 2 == 0 ? 'Nữ' : 'Nam',
          'city':      city,
          'location':  city,
          'bio':       bios[i % bios.length],
          'photoUrl':  photos[i],
          'email':     'fake_${uid.substring(0, 6)}@test.com',
          'interests': _allInterests.sublist(0, 3 + (i % 4)),
          'isBanned':  false,
          'isFake':    true,
          'createdAt': FieldValue.serverTimestamp(),
        });
        created++;
      } catch (_) {}
    }

    _loadStats();
    setState(() => _creatingUser = false);
    Get.snackbar('✅ Xong', 'Đã tạo $created/10 user giả',
        backgroundColor: Colors.green, colorText: Colors.white);
  }

  // ════════════════════════════════════════════════
  //  AI PHÂN TÍCH ẢNH
  // ════════════════════════════════════════════════
  Future<bool> _isImageSensitive(String imageUrl) async {
    try {
      final response = await http.post(
        Uri.parse('https://api.anthropic.com/v1/messages'),
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': 'YOUR_ANTHROPIC_API_KEY',
          'anthropic-version': '2023-06-01',
        },
        body: jsonEncode({
          'model': 'claude-opus-4-5',
          'max_tokens': 100,
          'messages': [
            {
              'role': 'user',
              'content': [
                {'type': 'image', 'source': {'type': 'url', 'url': imageUrl}},
                {
                  'type': 'text',
                  'text': 'Phân tích ảnh này. Trả lời CHỈ "SENSITIVE" nếu ảnh chứa nội dung nhạy cảm (khỏa thân, bạo lực, nội dung 18+) hoặc "SAFE" nếu ảnh bình thường. Không giải thích thêm.'
                }
              ]
            }
          ]
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = data['content'][0]['text'].toString().trim().toUpperCase();
        return text.contains('SENSITIVE');
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<void> _scanAllPhotos() async {
    setState(() => _scanningPhotos = true);
    int scanned = 0, banned = 0;
    try {
      final users = await _db
          .collection('users')
          .where('photoUrl', isNotEqualTo: '')
          .where('isBanned', isEqualTo: false)
          .get();

      for (final doc in users.docs) {
        final data     = doc.data();
        final photoUrl = data['photoUrl']?.toString() ?? '';
        final uid      = data['uid']?.toString() ?? doc.id;
        final name     = data['name']?.toString() ?? 'Người dùng';
        if (photoUrl.isEmpty) continue;
        scanned++;
        final isSensitive = await _isImageSensitive(photoUrl);
        if (isSensitive) {
          await _db.collection('users').doc(uid).update({
            'isBanned':  true,
            'banReason': 'Ảnh profile vi phạm tiêu chuẩn cộng đồng (AI phát hiện)',
            'bannedAt':  FieldValue.serverTimestamp(),
          });
          await _db.collection('reports').add({
            'reportedUid': uid,
            'reporterUid': 'AI_SYSTEM',
            'reason':      'Ảnh nhạy cảm - Phát hiện bởi AI',
            'photoUrl':    photoUrl,
            'status':      'approved',
            'createdAt':   FieldValue.serverTimestamp(),
            'resolvedAt':  FieldValue.serverTimestamp(),
            'resolvedBy':  'AI_AUTO',
          });
          banned++;
          Get.snackbar('🚫 Phát hiện vi phạm', '$name bị khóa do ảnh nhạy cảm',
              backgroundColor: Colors.red, colorText: Colors.white,
              duration: const Duration(seconds: 3));
        }
      }

      _loadStats();
      Get.dialog(AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('✅ Quét hoàn tất',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          _resultRow('📸 Tổng ảnh đã quét', '$scanned'),
          _resultRow('🚫 Tài khoản bị khóa', '$banned'),
          _resultRow('✅ Ảnh an toàn', '${scanned - banned}'),
        ]),
        actions: [
          ElevatedButton(
            onPressed: () => Get.back(),
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF4B6E)),
            child: const Text('Đóng', style: TextStyle(color: Colors.white)),
          ),
        ],
      ));
    } catch (e) {
      Get.snackbar('Lỗi', 'Không thể quét ảnh: $e',
          backgroundColor: Colors.red, colorText: Colors.white);
    }
    setState(() => _scanningPhotos = false);
  }

  Future<void> _scanSinglePhoto(String uid, String name, String photoUrl) async {
    Get.dialog(const Center(
        child: CircularProgressIndicator(color: Color(0xFFFF4B6E))),
        barrierDismissible: false);
    final isSensitive = await _isImageSensitive(photoUrl);
    Get.back();
    if (isSensitive) {
      await _db.collection('users').doc(uid).update({
        'isBanned':  true,
        'banReason': 'Ảnh profile vi phạm (AI xác nhận)',
        'bannedAt':  FieldValue.serverTimestamp(),
      });
      Get.snackbar('🚫 Vi phạm!', '$name bị khóa do ảnh nhạy cảm',
          backgroundColor: Colors.red, colorText: Colors.white);
    } else {
      Get.snackbar('✅ An toàn', 'Ảnh của $name không vi phạm',
          backgroundColor: Colors.green, colorText: Colors.white);
    }
  }

  Widget _resultRow(String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      Text(label),
      Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
    ]),
  );

  // ── Khoá / Mở khoá ──
  Future<void> _toggleBan(String uid, bool currentBanned) async {
    await _db.collection('users').doc(uid).update({'isBanned': !currentBanned});
    Get.snackbar(
      currentBanned ? '✅ Đã mở khoá' : '🔒 Đã khoá',
      currentBanned ? 'User có thể đăng nhập lại' : 'User bị khoá tài khoản',
      backgroundColor: currentBanned ? Colors.green : Colors.orange,
      colorText: Colors.white,
    );
    _loadStats();
  }

  // ── Xoá user ──
  Future<void> _deleteUser(BuildContext ctx, String uid, String name) async {
    final ok = await _confirmDialog(ctx,
        title: 'Xoá "$name"?',
        content: 'Xoá toàn bộ dữ liệu. Không thể hoàn tác!',
        confirmLabel: 'Xoá',
        confirmColor: Colors.red);
    if (!ok) return;
    await _db.collection('users').doc(uid).delete();
    await _db.collection('likes').doc(uid).delete();
    Get.snackbar('🗑️ Đã xoá', 'User "$name" đã bị xoá',
        backgroundColor: Colors.red, colorText: Colors.white);
    _loadStats();
  }

  // ── Xử lý báo cáo ──
  Future<void> _resolveReport(String reportId, String action) async {
    await _db.collection('reports').doc(reportId).update({
      'status':     action,
      'resolvedAt': FieldValue.serverTimestamp(),
      'resolvedBy': FirebaseAuth.instance.currentUser!.uid,
    });
    Get.snackbar(
      action == 'approved' ? '✅ Đã duyệt' : '❌ Đã bỏ qua',
      'Báo cáo đã được xử lý',
      backgroundColor: action == 'approved' ? Colors.green : Colors.grey,
      colorText: Colors.white,
    );
  }

  // ── Dialog xác nhận ──
  Future<bool> _confirmDialog(BuildContext ctx, {
    required String title,
    required String content,
    required String confirmLabel,
    Color confirmColor = Colors.red,
  }) async {
    final result = await showDialog<bool>(
      context: ctx,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(content),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Huỷ')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmLabel, style: const TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  // ════════════════════════════════════════════════
  //  BUILD
  // ════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color(0xFFFF4B6E),
        foregroundColor: Colors.white,
        title: const Row(children: [
          Icon(Icons.admin_panel_settings, size: 22),
          SizedBox(width: 8),
          Text('Admin Dashboard',
              style: TextStyle(fontWeight: FontWeight.bold)),
        ]),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Tải lại',
              onPressed: _loadStats),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Đăng xuất',
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => LoginScreen());
            },
          ),
        ],
        bottom: TabBar(
          controller: _tab,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: const [
            Tab(icon: Icon(Icons.bar_chart),         text: 'Thống kê'),
            Tab(icon: Icon(Icons.people),             text: 'Users'),
            Tab(icon: Icon(Icons.person_add),         text: 'Tạo User'),
            Tab(icon: Icon(Icons.flag),               text: 'Báo cáo'),
            Tab(icon: Icon(Icons.favorite),           text: 'Matches'),
            Tab(icon: Icon(Icons.location_city),      text: 'Thành phố'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tab,
        children: [
          _buildStatsTab(),
          _buildUsersTab(),
          _buildCreateUserTab(),
          _buildReportsTab(),
          _buildMatchesTab(),
          _buildCitiesTab(),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  TAB 1: THỐNG KÊ
  // ════════════════════════════════════════════════
  Widget _buildStatsTab() {
    if (_statsLoading) {
      return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4B6E)));
    }
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('💕 Tổng quan hệ thống',
                style: TextStyle(color: Colors.white, fontSize: 18,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              'Cập nhật: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}  ${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // AI quét ảnh
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06))],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Row(children: [
              Icon(Icons.smart_toy, color: Color(0xFFFF4B6E)),
              SizedBox(width: 8),
              Text('🤖 AI Kiểm duyệt ảnh tự động',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ]),
            const SizedBox(height: 8),
            const Text(
              'AI sẽ tự động quét toàn bộ ảnh profile và khóa tài khoản nếu phát hiện nội dung nhạy cảm.',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _scanningPhotos ? null : () async {
                  final ok = await _confirmDialog(context,
                      title: '🤖 Xác nhận quét AI',
                      content: 'AI sẽ quét toàn bộ ảnh profile. Tài khoản có ảnh vi phạm sẽ bị khóa tự động!',
                      confirmLabel: 'Bắt đầu quét',
                      confirmColor: const Color(0xFFFF4B6E));
                  if (ok) _scanAllPhotos();
                },
                icon: _scanningPhotos
                    ? const SizedBox(width: 16, height: 16,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Icon(Icons.search, color: Colors.white),
                label: Text(
                  _scanningPhotos ? 'Đang quét ảnh...' : '🔍 Quét toàn bộ ảnh ngay',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF4B6E),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Stats grid
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 1.25,
          children: [
            _statCard('👥 Tổng users',    _totalUsers,               Colors.blue,             Icons.people),
            _statCard('💕 Matches',        _totalMatches,             const Color(0xFFFF4B6E), Icons.favorite),
            _statCard('💬 Tin nhắn',       _totalMessages,            Colors.green,            Icons.chat_bubble),
            _statCard('🔒 Bị khoá',        _bannedUsers,              Colors.orange,           Icons.lock),
            _statCard('🚨 Báo cáo chờ',   _totalReports,             Colors.red,              Icons.flag),
            _statCard('✅ Đang hoạt động', _totalUsers - _bannedUsers, Colors.teal,             Icons.check_circle),
          ],
        ),
        const SizedBox(height: 20),

        // Quick actions
        const Text('Thao tác nhanh',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _quickAction(icon: Icons.people_outline,  label: 'Danh sách users', color: Colors.blue,             onTap: () => _tab.animateTo(1))),
          const SizedBox(width: 12),
          Expanded(child: _quickAction(icon: Icons.person_add,      label: 'Tạo user mới',   color: const Color(0xFFFF4B6E), onTap: () => _tab.animateTo(2))),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _quickAction(icon: Icons.flag_outlined,   label: 'Xem báo cáo',    color: Colors.red,              onTap: () => _tab.animateTo(3))),
          const SizedBox(width: 12),
          Expanded(child: _quickAction(icon: Icons.location_city,   label: 'Thành phố',      color: Colors.teal,             onTap: () => _tab.animateTo(5))),
        ]),
      ]),
    );
  }

  Widget _statCard(String label, int value, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 20),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(value.toString(),
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11)),
          ]),
        ],
      ),
    );
  }

  Widget _quickAction({
    required IconData icon, required String label,
    required Color color,   required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        ]),
      ),
    );
  }

  // ════════════════════════════════════════════════
  //  TAB 2: DANH SÁCH USERS
  // ════════════════════════════════════════════════
  Widget _buildUsersTab() {
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
          decoration: InputDecoration(
            hintText: 'Tìm theo tên hoặc thành phố...',
            prefixIcon: const Icon(Icons.search, color: Color(0xFFFF4B6E)),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('users').orderBy('createdAt', descending: true).snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4B6E)));
            }
            var docs = snap.data?.docs ?? [];
            if (_searchQuery.isNotEmpty) {
              docs = docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return (data['name']?.toString().toLowerCase() ?? '').contains(_searchQuery) ||
                    (data['city']?.toString().toLowerCase() ?? '').contains(_searchQuery);
              }).toList();
            }
            if (docs.isEmpty) {
              return const Center(child: Text('Không tìm thấy user nào'));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data     = docs[i].data() as Map<String, dynamic>;
                final uid      = data['uid']?.toString() ?? docs[i].id;
                final name     = data['name']?.toString() ?? 'Không tên';
                final age      = data['age']?.toString() ?? '?';
                final city     = data['city']?.toString() ?? '';
                final gender   = data['gender']?.toString() ?? '';
                final photoUrl = data['photoUrl']?.toString() ?? '';
                final isBanned = data['isBanned'] == true;
                final isFake   = data['isFake'] == true;
                final banReason = data['banReason']?.toString() ?? '';

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    leading: Stack(children: [
                      CircleAvatar(
                        radius: 26,
                        backgroundColor: const Color(0xFFFF8E9B),
                        backgroundImage: photoUrl.isNotEmpty ? NetworkImage(photoUrl) : null,
                        child: photoUrl.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      if (isBanned)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: Colors.red, shape: BoxShape.circle),
                            child: const Icon(Icons.lock, color: Colors.white, size: 11),
                          ),
                        ),
                      if (isFake && !isBanned)
                        Positioned(
                          bottom: 0, right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(
                                color: Colors.purple, shape: BoxShape.circle),
                            child: const Icon(Icons.smart_toy, color: Colors.white, size: 11),
                          ),
                        ),
                    ]),
                    title: Row(children: [
                      Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 6),
                      if (isFake)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('Fake',
                              style: TextStyle(color: Colors.purple, fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      if (isBanned) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: Colors.red.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('Khoá',
                              style: TextStyle(color: Colors.red, fontSize: 11,
                                  fontWeight: FontWeight.bold)),
                        ),
                      ],
                    ]),
                    subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('$age tuổi • $gender • $city',
                          style: const TextStyle(color: Colors.grey, fontSize: 13)),
                      if (isBanned && banReason.isNotEmpty)
                        Text('🔒 $banReason',
                            style: const TextStyle(color: Colors.red, fontSize: 11)),
                    ]),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (action) {
                        if (action == 'ban')    _toggleBan(uid, isBanned);
                        if (action == 'delete') _deleteUser(context, uid, name);
                        if (action == 'detail') _showUserDetail(context, data);
                        if (action == 'scan' && photoUrl.isNotEmpty)
                          _scanSinglePhoto(uid, name, photoUrl);
                      },
                      itemBuilder: (_) => [
                        const PopupMenuItem(value: 'detail', child: Row(children: [
                          Icon(Icons.info_outline, size: 18),
                          SizedBox(width: 8), Text('Xem chi tiết'),
                        ])),
                        const PopupMenuItem(value: 'scan', child: Row(children: [
                          Icon(Icons.smart_toy, size: 18, color: Colors.purple),
                          SizedBox(width: 8),
                          Text('AI quét ảnh', style: TextStyle(color: Colors.purple)),
                        ])),
                        PopupMenuItem(value: 'ban', child: Row(children: [
                          Icon(isBanned ? Icons.lock_open : Icons.lock_outline,
                              size: 18, color: Colors.orange),
                          const SizedBox(width: 8),
                          Text(isBanned ? 'Mở khoá' : 'Khoá tài khoản',
                              style: const TextStyle(color: Colors.orange)),
                        ])),
                        const PopupMenuItem(value: 'delete', child: Row(children: [
                          Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Xoá user', style: TextStyle(color: Colors.red)),
                        ])),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }

  void _showUserDetail(BuildContext ctx, Map<String, dynamic> data) {
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(ctx).size.height * 0.65,
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        padding: const EdgeInsets.all(24),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(
            child: CircleAvatar(
              radius: 48,
              backgroundColor: const Color(0xFFFF8E9B),
              backgroundImage: (data['photoUrl'] ?? '').isNotEmpty
                  ? NetworkImage(data['photoUrl']) : null,
              child: (data['photoUrl'] ?? '').isEmpty
                  ? const Icon(Icons.person, size: 48, color: Colors.white) : null,
            ),
          ),
          const SizedBox(height: 12),
          Center(child: Text(data['name'] ?? '',
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
          if (data['isFake'] == true)
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 4),
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                decoration: BoxDecoration(
                    color: Colors.purple.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: const Text('🤖 User giả',
                    style: TextStyle(color: Colors.purple, fontSize: 12)),
              ),
            ),
          const Divider(height: 28),
          _detailRow(Icons.cake,          'Tuổi',       '${data['age']} tuổi'),
          _detailRow(Icons.people,        'Giới tính',  data['gender'] ?? ''),
          _detailRow(Icons.location_city, 'Thành phố',  data['city'] ?? ''),
          _detailRow(Icons.info_outline,  'Bio',
              data['bio']?.toString().isEmpty == true ? '(trống)' : data['bio'] ?? '(trống)'),
          _detailRow(
            data['isBanned'] == true ? Icons.lock : Icons.check_circle,
            'Trạng thái',
            data['isBanned'] == true ? '🔒 Bị khoá' : '✅ Hoạt động',
          ),
          if (data['banReason'] != null && data['banReason'].toString().isNotEmpty)
            _detailRow(Icons.warning, 'Lý do khoá', data['banReason']),
        ]),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Row(children: [
      Icon(icon, size: 18, color: const Color(0xFFFF4B6E)),
      const SizedBox(width: 10),
      Text('$label: ', style: const TextStyle(fontWeight: FontWeight.bold)),
      Expanded(child: Text(value, overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black87))),
    ]),
  );

  // ════════════════════════════════════════════════
  //  TAB 3: TẠO USER
  // ════════════════════════════════════════════════
  Widget _buildCreateUserTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
                colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)]),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(children: [
            Icon(Icons.person_add, color: Colors.white, size: 24),
            SizedBox(width: 10),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Tạo user mới',
                    style: TextStyle(color: Colors.white, fontSize: 16,
                        fontWeight: FontWeight.bold)),
                Text('Tạo user thật hoặc user giả để test',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 16),

        // Tạo hàng loạt
        _formCard(children: [
          const Row(children: [
            Icon(Icons.auto_awesome, color: Color(0xFFFF4B6E), size: 20),
            SizedBox(width: 8),
            Text('Tạo nhanh hàng loạt',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          ]),
          const SizedBox(height: 8),
          const Text('Tạo 10 user giả ngẫu nhiên để test tính năng swipe/recommend.',
              style: TextStyle(color: Colors.grey, fontSize: 13)),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _creatingUser ? null : _createBatchUsers,
              icon: const Icon(Icons.groups, color: Color(0xFFFF4B6E)),
              label: const Text('⚡ Tạo 10 user ngẫu nhiên',
                  style: TextStyle(color: Color(0xFFFF4B6E), fontWeight: FontWeight.bold)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFFF4B6E)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ]),
        const SizedBox(height: 12),

        // Form thông tin cơ bản
        _formCard(children: [
          const Text('Thông tin cơ bản',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),

          _formField(
            controller: _nameCtrl,
            label: 'Tên *',
            icon: Icons.person,
            hint: 'Nguyễn Văn A',
          ),
          const SizedBox(height: 12),

          _formField(
            controller: _ageCtrl,
            label: 'Tuổi * (18–99)',
            icon: Icons.cake,
            hint: '25',
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 12),

          _formField(
            controller: _emailCtrl,
            label: 'Email (tuỳ chọn)',
            icon: Icons.email_outlined,
            hint: 'example@email.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 12),

          // Giới tính
          const Text('Giới tính',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Row(children: ['Nam', 'Nữ', 'Khác'].map((g) {
            final selected = _selectedGender == g;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => setState(() => _selectedGender = g),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFF4B6E) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFFFF4B6E) : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Text(g, style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
              ),
            );
          }).toList()),
          const SizedBox(height: 12),

          // Thành phố
          if (_availableCities.isNotEmpty) ...[
            const Text('Thành phố',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withOpacity(0.2)),
              ),
              child: DropdownButton<String>(
                value: _selectedCity,
                isExpanded: true,
                underline: const SizedBox(),
                items: _availableCities
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _selectedCity = v!),
              ),
            ),
          ] else
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(children: [
                const Icon(Icons.warning_amber, color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                const Expanded(child: Text('Chưa có thành phố nào. Vào tab Thành phố để thêm.',
                    style: TextStyle(color: Colors.orange, fontSize: 13))),
                TextButton(
                  onPressed: () => _tab.animateTo(5),
                  child: const Text('Thêm ngay', style: TextStyle(color: Colors.orange)),
                ),
              ]),
            ),
        ]),
        const SizedBox(height: 12),

        // Thông tin thêm
        _formCard(children: [
          const Text('Thông tin thêm',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 14),

          _formField(
            controller: _bioCtrl,
            label: 'Bio (giới thiệu)',
            icon: Icons.info_outline,
            hint: 'Yêu thích du lịch, cà phê và đọc sách ☕',
            maxLines: 3,
          ),
          const SizedBox(height: 12),

          _formField(
            controller: _photoCtrl,
            label: 'URL ảnh đại diện',
            icon: Icons.image_outlined,
            hint: 'https://i.pravatar.cc/400?img=1',
          ),
          const SizedBox(height: 4),
          // Gợi ý URL ảnh miễn phí
          Wrap(spacing: 6, children: [1, 2, 3, 4, 5].map((n) => GestureDetector(
            onTap: () {
              _photoCtrl.text = 'https://i.pravatar.cc/400?img=$n';
              setState(() {});
            },
            child: Chip(
              label: Text('Ảnh $n', style: const TextStyle(fontSize: 11)),
              backgroundColor: const Color(0xFFFF4B6E).withOpacity(0.1),
              side: BorderSide.none,
              padding: EdgeInsets.zero,
            ),
          )).toList()),

          // Preview ảnh
          if (_photoCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 12),
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(60),
                child: Image.network(
                  _photoCtrl.text,
                  height: 100, width: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 100, width: 100,
                    decoration: BoxDecoration(
                        color: Colors.grey[200], shape: BoxShape.circle),
                    child: const Icon(Icons.broken_image, color: Colors.grey),
                  ),
                ),
              ),
            ),
          ],
        ]),
        const SizedBox(height: 12),

        // Sở thích
        _formCard(children: [
          const Text('Sở thích',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 4),
          const Text('Chọn tối đa 6 sở thích',
              style: TextStyle(color: Colors.grey, fontSize: 12)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _allInterests.map((interest) {
              final selected = _selectedInterests.contains(interest);
              return GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      _selectedInterests.remove(interest);
                    } else if (_selectedInterests.length < 6) {
                      _selectedInterests.add(interest);
                    }
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFFFF4B6E) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: selected ? const Color(0xFFFF4B6E) : Colors.grey.withOpacity(0.3),
                    ),
                  ),
                  child: Text(interest, style: TextStyle(
                    fontSize: 13,
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                  )),
                ),
              );
            }).toList(),
          ),
          if (_selectedInterests.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text('Đã chọn: ${_selectedInterests.length}/6',
                style: const TextStyle(color: Color(0xFFFF4B6E), fontSize: 12,
                    fontWeight: FontWeight.bold)),
          ],
        ]),
        const SizedBox(height: 20),

        // Submit
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _creatingUser ? null : _createFakeUser,
            icon: _creatingUser
                ? const SizedBox(width: 18, height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : const Icon(Icons.person_add, color: Colors.white),
            label: Text(
              _creatingUser ? 'Đang tạo...' : 'Tạo user',
              style: const TextStyle(color: Colors.white, fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B6E),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            '* User được đánh dấu "isFake: true" trong Firestore',
            style: TextStyle(color: Colors.grey[500], fontSize: 11),
          ),
        ),
        const SizedBox(height: 20),
      ]),
    );
  }

  // Helper widgets cho form
  Widget _formCard({required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black.withOpacity(0.06))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _formField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
      const SizedBox(height: 6),
      TextField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        onChanged: (_) => setState(() {}),
        decoration: InputDecoration(
          hintText: hint,
          prefixIcon: Icon(icon, color: const Color(0xFFFF4B6E), size: 20),
          filled: true,
          fillColor: Colors.grey.withOpacity(0.08),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    ]);
  }

  // ════════════════════════════════════════════════
  //  TAB 4: BÁO CÁO
  // ════════════════════════════════════════════════
  Widget _buildReportsTab() {
    return DefaultTabController(
      length: 2,
      child: Column(children: [
        Container(
          color: Colors.white,
          child: const TabBar(
            labelColor: Color(0xFFFF4B6E),
            indicatorColor: Color(0xFFFF4B6E),
            tabs: [Tab(text: '🚨 Chờ duyệt'), Tab(text: '✅ Đã xử lý')],
          ),
        ),
        Expanded(
          child: TabBarView(children: [
            _reportsList('pending'),
            _reportsList('resolved'),
          ]),
        ),
      ]),
    );
  }

  Widget _reportsList(String status) {
    final isPending = status == 'pending';
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('reports')
          .where('status', isEqualTo: status)
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4B6E)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) {
          return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 12),
            Text(
              isPending ? 'Không có báo cáo nào chờ xử lý 🎉' : 'Chưa có báo cáo nào được xử lý',
              style: TextStyle(color: Colors.grey[600]),
            ),
          ]));
        }
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data        = docs[i].data() as Map<String, dynamic>;
            final reportId    = docs[i].id;
            final reason      = data['reason']?.toString() ?? 'Không rõ';
            final reportedUid = data['reportedUid']?.toString() ?? '';
            final photoUrl    = data['photoUrl']?.toString() ?? '';
            final createdAt   = (data['createdAt'] as Timestamp?)?.toDate();
            final dateStr     = createdAt != null
                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : '';
            final isAI        = data['reporterUid'] == 'AI_SYSTEM';

            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                          color: (isAI ? Colors.purple : Colors.red).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Icon(isAI ? Icons.smart_toy : Icons.flag,
                          color: isAI ? Colors.purple : Colors.red, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        if (isAI)
                          Container(
                            margin: const EdgeInsets.only(right: 6),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.purple.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('🤖 AI',
                                style: TextStyle(color: Colors.purple, fontSize: 11,
                                    fontWeight: FontWeight.bold)),
                          ),
                        Expanded(child: Text('Lý do: $reason',
                            style: const TextStyle(fontWeight: FontWeight.bold))),
                      ]),
                      Text('User ID: $reportedUid',
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                          overflow: TextOverflow.ellipsis),
                    ])),
                    if (dateStr.isNotEmpty)
                      Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ]),
                  if (photoUrl.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(photoUrl,
                          height: 140, width: double.infinity, fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                              height: 60, color: Colors.grey[200],
                              child: const Center(child: Text('Không tải được ảnh')))),
                    ),
                  ],
                  if (isPending) ...[
                    const SizedBox(height: 12),
                    Row(children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _resolveReport(reportId, 'rejected'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Bỏ qua'),
                          style: OutlinedButton.styleFrom(foregroundColor: Colors.grey),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            await _resolveReport(reportId, 'approved');
                            if (reportedUid.isNotEmpty) await _toggleBan(reportedUid, false);
                          },
                          icon: const Icon(Icons.lock, size: 16),
                          label: const Text('Khoá user'),
                          style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red, foregroundColor: Colors.white),
                        ),
                      ),
                    ]),
                  ] else ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                          color: data['status'] == 'approved'
                              ? Colors.red.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(
                        data['status'] == 'approved' ? '✅ Đã khoá user' : '❌ Đã bỏ qua',
                        style: TextStyle(
                            color: data['status'] == 'approved' ? Colors.red : Colors.grey,
                            fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ]),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════
  //  TAB 5: MATCHES
  // ════════════════════════════════════════════════
  Widget _buildMatchesTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: _db.collection('matches').orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4B6E)));
        }
        final docs = snap.data?.docs ?? [];
        if (docs.isEmpty) return const Center(child: Text('Chưa có match nào'));
        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (context, i) {
            final data      = docs[i].data() as Map<String, dynamic>;
            final matchId   = docs[i].id;
            final users     = List<String>.from(data['users'] ?? []);
            final lastMsg   = data['lastMessage']?.toString() ?? '';
            final createdAt = (data['createdAt'] as Timestamp?)?.toDate();
            final dateStr   = createdAt != null
                ? '${createdAt.day}/${createdAt.month}/${createdAt.year}' : '';

            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFF4B6E).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10)),
                  child: const Icon(Icons.favorite, color: Color(0xFFFF4B6E), size: 22),
                ),
                title: Text(
                  matchId.length > 22 ? '${matchId.substring(0, 22)}...' : matchId,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('${users.length} người dùng',
                      style: const TextStyle(fontSize: 12)),
                  if (lastMsg.isNotEmpty)
                    Text('Tin nhắn cuối: $lastMsg',
                        style: const TextStyle(color: Colors.grey, fontSize: 12),
                        overflow: TextOverflow.ellipsis),
                ]),
                trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(dateStr, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () async {
                      final ok = await _confirmDialog(context,
                          title: 'Xoá match này?',
                          content: 'Toàn bộ tin nhắn sẽ bị xoá!',
                          confirmLabel: 'Xoá');
                      if (ok) {
                        await _db.collection('matches').doc(matchId).delete();
                        Get.snackbar('🗑️ Đã xoá', 'Match đã bị xoá',
                            backgroundColor: Colors.red, colorText: Colors.white);
                      }
                    },
                    child: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  ),
                ]),
              ),
            );
          },
        );
      },
    );
  }

  // ════════════════════════════════════════════════
  //  TAB 6: QUẢN LÝ THÀNH PHỐ
  // ════════════════════════════════════════════════
  Widget _buildCitiesTab() {
    final cityCtrl = TextEditingController();
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: Row(children: [
          Expanded(
            child: TextField(
              controller: cityCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: InputDecoration(
                hintText: 'Nhập tên thành phố...',
                prefixIcon: const Icon(Icons.location_city, color: Color(0xFFFF4B6E)),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () async {
              final name = cityCtrl.text.trim().toUpperCase();
              if (name.isEmpty) return;
              final existing = await _db.collection('cities')
                  .where('name', isEqualTo: name).get();
              if (existing.docs.isNotEmpty) {
                Get.snackbar('Lỗi', 'Thành phố đã tồn tại!',
                    backgroundColor: Colors.red, colorText: Colors.white);
                return;
              }
              await _db.collection('cities').add({
                'name': name, 'createdAt': FieldValue.serverTimestamp(),
              });
              cityCtrl.clear();
              _loadCities(); // reload cho dropdown tab Tạo User
              Get.snackbar('✅ Thành công', 'Đã thêm thành phố $name',
                  backgroundColor: Colors.green, colorText: Colors.white);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF4B6E),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Icon(Icons.add, color: Colors.white),
          ),
        ]),
      ),
      Expanded(
        child: StreamBuilder<QuerySnapshot>(
          stream: _db.collection('cities').orderBy('name').snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Color(0xFFFF4B6E)));
            }
            final docs = snap.data?.docs ?? [];
            if (docs.isEmpty) {
              return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.location_off, size: 64, color: Colors.grey[400]),
                const SizedBox(height: 12),
                Text('Chưa có thành phố nào', style: TextStyle(color: Colors.grey[600])),
              ]));
            }
            return ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: docs.length,
              itemBuilder: (context, i) {
                final data    = docs[i].data() as Map<String, dynamic>;
                final docId   = docs[i].id;
                final name    = data['name']?.toString() ?? '';
                final editCtrl = TextEditingController(text: name);

                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF4B6E).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.location_city, color: Color(0xFFFF4B6E)),
                    ),
                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (_) => AlertDialog(
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                              title: const Text('Sửa thành phố',
                                  style: TextStyle(fontWeight: FontWeight.bold)),
                              content: TextField(
                                controller: editCtrl,
                                decoration: InputDecoration(
                                  labelText: 'Tên thành phố',
                                  border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                              actions: [
                                TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text('Huỷ')),
                                ElevatedButton(
                                  onPressed: () async {
                                    final newName = editCtrl.text.trim().toUpperCase();
                                    if (newName.isEmpty) return;
                                    await _db.collection('cities').doc(docId)
                                        .update({'name': newName});
                                    Navigator.pop(context);
                                    _loadCities();
                                    Get.snackbar('✅ Đã cập nhật', 'Thành phố đã được sửa',
                                        backgroundColor: Colors.green, colorText: Colors.white);
                                  },
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFFFF4B6E)),
                                  child: const Text('Lưu',
                                      style: TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        onPressed: () async {
                          final ok = await _confirmDialog(context,
                              title: 'Xoá "$name"?',
                              content: 'Thành phố này sẽ bị xoá!',
                              confirmLabel: 'Xoá',
                              confirmColor: Colors.red);
                          if (ok) {
                            await _db.collection('cities').doc(docId).delete();
                            _loadCities();
                            Get.snackbar('🗑️ Đã xoá', 'Thành phố "$name" đã bị xoá',
                                backgroundColor: Colors.red, colorText: Colors.white);
                          }
                        },
                      ),
                    ]),
                  ),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}