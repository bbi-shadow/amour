import 'package:flutter/material.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/match_service.dart';

class SwipeScreen extends StatefulWidget {
  @override
  _SwipeScreenState createState() => _SwipeScreenState();
}

class _SwipeScreenState extends State<SwipeScreen> {
  // Danh sách user để swipe
  List<UserModel> _users = [];

  // Service xử lý logic match
  final _matchService = MatchService();

  // Controller điều khiển swipe bằng nút bấm
  final CardSwiperController _swiperController = CardSwiperController();

  // Trạng thái đang tải
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  // Tải danh sách user từ Firestore
  Future<void> _loadUsers() async {
    final currentUid = FirebaseAuth.instance.currentUser!.uid;

    final snap = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isNotEqualTo: currentUid)
        .limit(20)
        .get();

    setState(() {
      _users = snap.docs.map((d) => UserModel.fromMap(d.data())).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8F8F8),
      appBar: AppBar(
        title: Text('💕 Khám phá',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: Color(0xFFFF4B6E)))
          : _users.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey),
            SizedBox(height: 16),
            Text('Không còn ai nữa!',
                style: TextStyle(fontSize: 20, color: Colors.grey)),
            SizedBox(height: 8),
            Text('Quay lại sau nhé 💕',
                style: TextStyle(color: Colors.grey)),
          ],
        ),
      )
          : Column(
        children: [
          // Khu vực swipe card
          Expanded(
            child: CardSwiper(
              controller: _swiperController,
              cardsCount: _users.length,
              // Build từng card theo index
              cardBuilder: (context, index, percentX, percentY) {
                return _buildCard(_users[index]);
              },
              onSwipe: (prevIndex, currentIndex, direction) {
                // Swipe phải = Like
                if (direction == CardSwiperDirection.right) {
                  _matchService.likeUser(_users[prevIndex].uid);
                  Get.snackbar(
                    '💕 Like!',
                    'Bạn đã thích người này!',
                    backgroundColor: Color(0xFFFF4B6E),
                    colorText: Colors.white,
                    duration: Duration(seconds: 1),
                  );
                }
                return true;
              },
            ),
          ),

          // Các nút hành động
          Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Nút bỏ qua
                _buildActionButton(
                  icon: Icons.close,
                  color: Colors.red,
                  size: 56,
                  onTap: () => _swiperController
                      .swipeLeft(),
                ),
                // Nút super like
                _buildActionButton(
                  icon: Icons.star,
                  color: Colors.amber,
                  size: 48,
                  onTap: () => _swiperController
                      .swipeTop(),
                ),
                // Nút like
                _buildActionButton(
                  icon: Icons.favorite,
                  color: Color(0xFFFF4B6E),
                  size: 56,
                  onTap: () => _swiperController
                      .swipeRight(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Widget card hiện thông tin từng người
  Widget _buildCard(UserModel user) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(blurRadius: 16, color: Colors.black26)],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Ảnh profile hoặc icon mặc định
            user.photoUrl.isEmpty
                ? Container(
              color: Color(0xFFFF8E9B),
              child: Icon(Icons.person, size: 120, color: Colors.white),
            )
                : Image.network(user.photoUrl, fit: BoxFit.cover),

            // Gradient tối phía dưới
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.transparent, Colors.black87],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    stops: [0.5, 1.0],
                  ),
                ),
              ),
            ),

            // Thông tin user
            Positioned(
              bottom: 24, left: 20, right: 20,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${user.name}, ${user.age}',
                      style: TextStyle(color: Colors.white,
                          fontSize: 28, fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Row(children: [
                    Icon(Icons.location_on, color: Colors.white70, size: 16),
                    SizedBox(width: 4),
                    Text(user.city,
                        style: TextStyle(color: Colors.white70, fontSize: 14)),
                  ]),
                  SizedBox(height: 8),
                  Text(user.bio,
                      style: TextStyle(color: Colors.white, fontSize: 14),
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Widget nút tròn
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
          boxShadow: [BoxShadow(blurRadius: 8, color: Colors.black12)],
        ),
        child: Icon(icon, color: color, size: size * 0.5),
      ),
    );
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }
}