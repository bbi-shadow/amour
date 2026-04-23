import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SafetyScreen extends StatelessWidget {
  const SafetyScreen({super.key});

  Future<void> _blockUser(BuildContext context, String targetUid) async {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    await FirebaseFirestore.instance
        .collection('blocks')
        .doc(myUid)
        .collection('blocked')
        .doc(targetUid)
        .set({'timestamp': FieldValue.serverTimestamp()});
    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Đã chặn người dùng'),
        backgroundColor: Colors.red[400],
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F2),
      appBar: AppBar(
        title: const Text('An toàn & Quyền riêng tư',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSection([
            _buildItem(
              icon: Icons.block_rounded,
              iconBg: Colors.red.shade400,
              title: 'Danh sách đã chặn',
              subtitle: 'Quản lý người dùng bị chặn',
              onTap: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const _BlockedListScreen())),
            ),
            _buildItem(
              icon: Icons.flag_rounded,
              iconBg: const Color(0xFFF5A623),
              title: 'Báo cáo người dùng',
              subtitle: 'Báo cáo hành vi không phù hợp',
              isLast: true,
              onTap: () => _showReportDialog(context),
            ),
          ]),
          const SizedBox(height: 16),
          _buildSection([
            _buildItem(
              icon: Icons.verified_user_rounded,
              iconBg: const Color(0xFF22B07D),
              title: 'Xác minh tài khoản',
              subtitle: 'Xác minh để tăng độ tin cậy',
              onTap: () {},
            ),
            _buildItem(
              icon: Icons.lock_rounded,
              iconBg: const Color(0xFF5B86E5),
              title: 'Đổi mật khẩu',
              subtitle: 'Cập nhật mật khẩu tài khoản',
              isLast: true,
              onTap: () => _showChangePasswordDialog(context),
            ),
          ]),
          const SizedBox(height: 16),
          // Danger zone
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.red.withOpacity(0.2)),
            ),
            child: _buildItem(
              icon: Icons.delete_forever_rounded,
              iconBg: Colors.red,
              title: 'Xoá tài khoản',
              subtitle: 'Xoá vĩnh viễn tất cả dữ liệu',
              titleColor: Colors.red,
              isLast: true,
              onTap: () => _showDeleteAccountDialog(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(List<Widget> children) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(children: children),
    );
  }

  Widget _buildItem({
    required IconData icon,
    required Color iconBg,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
    bool isLast = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withOpacity(0.1))),
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600,
                color: titleColor ?? const Color(0xFF1A1A1A))),
            Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[500])),
          ])),
          Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
        ]),
      ),
    );
  }

  void _showReportDialog(BuildContext context) {
    final reasons = ['Nội dung không phù hợp', 'Spam', 'Giả mạo danh tính', 'Quấy rối', 'Khác'];
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Lý do báo cáo', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          ...reasons.map((r) => ListTile(
            title: Text(r),
            trailing: const Icon(Icons.chevron_right_rounded, color: Colors.grey),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: const Text('Đã gửi báo cáo. Cảm ơn bạn!'),
                backgroundColor: const Color(0xFF22B07D),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ));
            },
          )),
        ]),
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Đổi mật khẩu'),
        content: const Text('Link đặt lại mật khẩu sẽ được gửi đến email của bạn.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              final user = FirebaseAuth.instance.currentUser;
              if (user?.email != null) {
                await FirebaseAuth.instance.sendPasswordResetEmail(email: user!.email!);
              }
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: const Text('Đã gửi email đặt lại mật khẩu'),
                  backgroundColor: const Color(0xFF5B86E5),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ));
              }
            },
            child: const Text('Gửi', style: TextStyle(color: Color(0xFFFF6B8A))),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Xoá tài khoản', style: TextStyle(color: Colors.red)),
        content: const Text('Tất cả dữ liệu của bạn sẽ bị xoá vĩnh viễn. Hành động này không thể hoàn tác.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Huỷ')),
          TextButton(
            onPressed: () async {
              await FirebaseAuth.instance.currentUser?.delete();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Xoá', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}

class _BlockedListScreen extends StatelessWidget {
  const _BlockedListScreen();

  @override
  Widget build(BuildContext context) {
    final myUid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F2),
      appBar: AppBar(
        title: const Text('Đã chặn', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('blocks').doc(myUid).collection('blocked').snapshots(),
        builder: (context, snap) {
          final docs = snap.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Chưa chặn ai', style: TextStyle(color: Colors.grey)));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, i) {
              final uid = docs[i].id;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(uid).get(),
                builder: (context, userSnap) {
                  if (!userSnap.hasData) return const SizedBox(height: 60);
                  final data = userSnap.data!.data() as Map<String, dynamic>?;
                  final name = data?['name'] ?? 'Người dùng';
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(children: [
                      const Icon(Icons.block_rounded, color: Colors.red, size: 20),
                      const SizedBox(width: 12),
                      Expanded(child: Text(name, style: const TextStyle(fontWeight: FontWeight.w600))),
                      TextButton(
                        onPressed: () async {
                          await FirebaseFirestore.instance
                              .collection('blocks').doc(myUid).collection('blocked').doc(uid).delete();
                        },
                        child: const Text('Bỏ chặn', style: TextStyle(color: Color(0xFF5B86E5))),
                      ),
                    ]),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}