# 💕 Amour — Modern Dating & Connection App

<p align="center">
  <img src="assets/image/logo.png" width="160" alt="Amour Logo">
  <br>
  <b>Kết nối những trái tim qua từng dòng code - Ứng dụng hẹn hò thế hệ mới.</b>
</p>

---

## 🌟 Tổng quan (Overview)
**Amour** là một ứng dụng hẹn hò hoàn chỉnh được xây dựng trên nền tảng **Flutter** và **Firebase**. Dự án tập trung vào việc áp dụng các giải pháp kỹ thuật tối ưu như trí tuệ nhân tạo (AI) trong gợi ý hồ sơ, giao tiếp thời gian thực (Real-time) và hệ thống thanh toán hội viên tích hợp mã QR.

---

## 📊 1. Bảng đối chiếu tiêu chí chấm điểm (Evaluation Evidence)
*Phần này tổng hợp các minh chứng kỹ thuật phục vụ việc đánh giá dự án.*

| Tiêu chí |  Chi tiết & Đường dẫn Source Code chính |
| :--- | :--- |
| 💳 **Payment System** |**VietQR Integration**: Tích hợp thanh toán qua mã QR.<br>`lib/controllers/premium_controller.dart` |
| 🧠 **Chức năng AI** | **Recommendation Engine**: Thuật toán gợi ý so khớp hồ sơ.<br>`lib/services/recommendation_service.dart` |
| 🗄️ **NoSQL Database** | **Firestore**: Cấu trúc Document-oriented, Schema linh hoạt.<br>`lib/services/firestore_service.dart` |
| 🌐 **Call API** | **Google Maps** (Vị trí), **Cloudinary** (Media), **Agora** (Video Call).<br>`lib/services/upload_service.dart` |
| ⚡ **Realtime/Network**|  Cập nhật tin nhắn và cuộc gọi tức thời (< 100ms).<br>`lib/controllers/chat_detail_controller.dart` |
| 🎬 **Video Demo** |  |

---

## 🏗️ 2. Kiến Trúc Hệ Thống (Architecture)
Dự án áp dụng mô hình **MVVM (Model-View-ViewModel)** kết hợp với **Repository Pattern** giúp tách biệt hoàn toàn logic dữ liệu và giao diện.

- **`lib/models/`**: Định nghĩa cấu trúc dữ liệu NoSQL chuẩn hóa (User, Post, Message...).
- **`lib/repositories/`**: Lớp trừu tượng xử lý dữ liệu thô (Firestore/API). Đảm bảo logic UI không bị phụ thuộc vào database.
- **`lib/controllers/`**: "Bộ não" điều khiển logic nghiệp vụ sử dụng **GetX**.
- **`lib/services/`**: Các dịch vụ độc lập như Gợi ý AI, Upload ảnh qua API, và Thông báo (FCM).

---

## 🧠 3. Điểm nhấn Kỹ thuật chuyên sâu (Technical Highlights)

### 🤖 Hệ Thống Gợi Ý AI (Recommendation Engine)
Ứng dụng sử dụng thuật toán phân tích đa chiều kết hợp **Google Maps API** để tính toán:
1. **Sở thích (Interests)**: Phân tích mảng sở thích chung của người dùng.
2. **Vị trí (Google Maps)**: Ưu tiên gợi ý hồ sơ trong cùng khu vực địa lý.
3. **Mục tiêu (Goals)**: Đối chiếu mục đích sử dụng (Kết bạn, Hẹn hò, Nghiêm túc).

### 🗄️ Giải pháp NoSQL & Real-time
- **Schema-less**: Linh hoạt trong việc mở rộng thông tin cá nhân mà không cần migration.
- **Denormalization**: Dữ liệu tin nhắn được lồng trực tiếp giúp tốc độ đọc cực nhanh.
- **Realtime Sync**: Sử dụng `Streams` để cập nhật UI ngay khi có thay đổi trên server.

### 💳 Hệ thống Thanh toán (Payment System)
- **Hội viên Premium**: Gói VIP giúp mở khóa tính năng cao cấp.
- **VietQR**: Tự động tạo mã QR thanh toán giúp người dùng nâng cấp tài khoản dễ dàng.
- **Admin Flow**: Quản trị viên duyệt giao dịch tại Dashboard để kích hoạt quyền lợi.

---

## ✨ 4. Danh sách 12 Chức năng chính
1.  **Auth**: Đăng nhập/Đăng ký qua Email và **Google Sign-In**.
2.  **AI Discovery**: Khám phá người dùng tiềm năng thông qua thuật toán AI.
3.  **Swipe UI**: Trải nghiệm vuốt mượt mà để Thích hoặc Bỏ qua.
4.  **Match System**: Tự động kết đôi khi có sự trùng khớp (Double-like).
5.  **Instant Chat**: Nhắn tin văn bản, hình ảnh thời gian thực.
6.  **HD Call**: Gọi điện Video/Voice chất lượng cao tích hợp Agora SDK.
7.  **Social Feed**: Đăng bài khoảnh khắc cá nhân, thả tim và bình luận.
8.  **Premium**: Hệ thống nâng cấp tài khoản VIP tích hợp VietQR.
9.  **Safety Center**: Chặn và báo cáo người dùng vi phạm tiêu chuẩn.
10. **Admin Panel**: Dashboard quản trị toàn bộ hệ thống (User, Post, Payment).
11. **FCM Notify**: Thông báo đẩy thông minh (Match mới, tin nhắn mới).
12. **Dark/Light Mode**: Giao diện chuyên nghiệp tự động theo hệ thống.

---

## 🚀 5. Hướng dẫn cài đặt (Setup Guide)

1. **Cài đặt**: `flutter pub get`
2. **Cấu hình**: Thêm file `google-services.json` vào thư mục `android/app/`.
3. **API Keys**: Điền Agora App ID vào `lib/utils/app_constants.dart`.
4. **Chạy ứng dụng**: `flutter run`

---
*Amour — Connecting hearts through code.*
