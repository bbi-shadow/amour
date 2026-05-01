# 💕 Amour — Modern Dating App Technical Guide

Tài liệu này cung cấp cái nhìn tổng quan về kiến trúc và các thành phần cốt lõi của **Amour**, giúp định hướng phát triển và bảo trì hệ thống.

---

## 🏗️ 1. Kiến Trúc Hệ Thống (Architecture)
Dự án áp dụng mô hình **MVVM + Repository Pattern**, sử dụng **GetX** để quản lý trạng thái.

- **`lib/models/`**: Định nghĩa cấu trúc dữ liệu (User, Post, Message, v.v.).
- **`lib/repositories/`**: Lớp trừu tượng xử lý dữ liệu thô (Firestore/API). Đảm bảo logic UI không bị phụ thuộc vào database.
- **`lib/controllers/`**: "Bộ não" điều khiển logic nghiệp vụ (Auth, Theme, Chat).
- **`lib/services/`**: Các dịch vụ độc lập như Gợi ý (Recommendation), Upload ảnh (Cloudinary), và Thông báo (FCM).

---

## 🧠 2. Hệ Thống Gợi Ý (Recommendation Engine)
*File chính: `lib/services/recommendation_service.dart`*

Luồng xử lý:
1. `FirestoreService` lấy danh sách người dùng tiềm năng.
2. `RecommendationService` tính toán điểm số dựa trên:
   - **Độ tương đồng sở thích**: Dựa trên danh sách `interests`.
   - **Vị trí địa lý**: Ưu tiên người dùng trong cùng thành phố hoặc khoảng cách gần.
   - **Mục tiêu mối quan hệ**: So khớp `relationshipGoal`.
3. Trả về danh sách đã được xếp hạng (Ranking) cho `DiscoveryScreen`.

---

## 🔐 3. Phân Quyền & Bảo Mật (Auth & Role)
*File chính: `lib/controllers/auth_controller.dart`*

- **Quyền Admin**: Được xác định qua collection `admins` trong Firestore. 
- **Điều hướng (AuthGate)**: Ngay khi mở app, `main.dart` kiểm tra Role để đưa người dùng vào `AdminScreen` hoặc `HomeScreen`.
- **Middleware**: Chặn truy cập trái phép vào các tính năng quản trị từ phía client.

---

## 📸 4. Xử Lý Hình Ảnh (Media Service)
*File chính: `lib/services/upload_service.dart`*

- **Cloudinary**: Thay vì dùng Firebase Storage, Amour dùng Cloudinary (Unsigned Upload) để tối ưu tốc độ và chi phí.
- **Quy trình**: Chọn ảnh (`ImagePicker`) -> Upload (`UploadService`) -> Nhận URL `https` -> Lưu URL vào Firestore.

---

## 💬 5. Tương Tác Real-time
- **Matching**: Sử dụng logic kiểm tra chéo (Double-like) để tạo Match tự động.
- **Chat**: Dùng `StreamBuilder` lắng nghe thay đổi tin nhắn theo thời gian thực.
- **Feed**: Hệ thống bài đăng hỗ trợ Like, Comment và Repost.

---

## 🛠️ Quy Chuẩn Phát Triển (Development Standards)
1. **Clean Logic**: Không viết logic xử lý dữ liệu trực tiếp trong Widget `build`.
2. **Context Safety**: Luôn kiểm tra `if (!mounted) return;` sau các tác vụ `await`.
3. **Helper Usage**: Dùng `AppHelpers` cho mọi thông báo để đảm bảo giao diện đồng bộ.

---
*Amour — Connecting hearts through code.*
