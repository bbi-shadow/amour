import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'swipe_screen.dart';
import 'chat/chat_list_screen.dart';
import 'auth/login_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // Index tab đang được chọn
  int _currentIndex = 0;

  // Danh sách màn hình theo từng tab
  final List<Widget> _screens = [
    SwipeScreen(),      // Tab 0: Khám phá
    ChatListScreen(),   // Tab 1: Tin nhắn
    ProfileTab(),       // Tab 2: Hồ sơ
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // Hiện màn hình theo tab đang chọn
      body: _screens[_currentIndex],

      // Thanh điều hướng phía dưới
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: Color(0xFFFF4B6E),
        unselectedItemColor: Colors.grey,
        items: [
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Khám phá',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.chat_bubble),
            label: 'Tin nhắn',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Hồ sơ',
          ),
        ],
      ),
    );
  }
}

// ── Tab Hồ sơ cá nhân ──
class ProfileTab extends StatelessWidget {
  final _user = FirebaseAuth.instance.currentUser;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hồ sơ của tôi',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        actions: [
          // Nút đăng xuất
          IconButton(
            icon: Icon(Icons.logout, color: Color(0xFFFF4B6E)),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Get.offAll(() => LoginScreen());
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // ── Header ảnh và tên ──
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Color(0xFFFF4B6E), Color(0xFFFF8E9B)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 60,
                        color: Color(0xFFFF4B6E)),
                  ),
                  SizedBox(height: 12),
                  Text(
                    _user?.email ?? 'Chưa đăng nhập',
                    style: TextStyle(color: Colors.white, fontSize: 18,
                        fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 4),
                  Text('Thành viên Amour 💕',
                      style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            SizedBox(height: 16),

            // ── Menu ──
            _buildMenuItem(
              icon: Icons.edit,
              title: 'Chỉnh sửa hồ sơ',
              onTap: () => Get.snackbar('Sắp ra mắt', '🚧 Đang phát triển'),
            ),
            _buildMenuItem(
              icon: Icons.settings,
              title: 'Cài đặt',
              onTap: () => Get.snackbar('Sắp ra mắt', '🚧 Đang phát triển'),
            ),
            _buildMenuItem(
              icon: Icons.help,
              title: 'Trợ giúp',
              onTap: () => Get.snackbar('Sắp ra mắt', '🚧 Đang phát triển'),
            ),
            SizedBox(height: 16),

            // ── Nút đăng xuất ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () async {
                    await FirebaseAuth.instance.signOut();
                    Get.offAll(() => LoginScreen());
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF4B6E),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  child: Text('Đăng xuất',
                      style: TextStyle(color: Colors.white, fontSize: 16,
                          fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  // Widget tái sử dụng cho từng dòng menu
  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Color(0xFFFF4B6E).withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Color(0xFFFF4B6E)),
      ),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500)),
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
      onTap: onTap,
    );
  }
}