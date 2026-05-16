# 💕 Amour — Modern Dating & Connection App

<p align="center">
  <img src="assets/image/logo.png" width="160" alt="Amour Logo">
  <br>
  <b>Kết nối những trái tim qua từng dòng code - Ứng dụng hẹn hò thế hệ mới.</b>
</p>

---

## 🌟 Tổng quan (Overview)
**Amour** là một ứng dụng hẹn hò hoàn chỉnh được xây dựng trên nền tảng **Flutter** và **Firebase**. Dự án kết hợp giao diện người dùng (UI/UX) hiện đại với các giải pháp kỹ thuật tối ưu như trí tuệ nhân tạo (AI), giao tiếp thời gian thực (Real-time) và hệ thống thanh toán nâng cấp hội viên tích hợp mã QR chuyên nghiệp.

---

## 📊 1. Bảng đối chiếu tiêu chí chấm điểm (Evaluation Criteria)
*Bảng tổng hợp nhanh minh chứng kỹ thuật phục vụ việc đánh giá dự án.*

| Payment (2đ) | NoSQL Database (1đ) | Calling API (1đ) | Realtime/Network (1đ) | Chức năng AI | Bao nhiêu chức năng | Video chạy code demo |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **VietQR System**: Tích hợp thanh toán mã QR tự động.<br>Code: `lib/controllers/premium_controller.dart` | **Firestore**: Cấu trúc Document-oriented, Schema linh hoạt, đồng bộ Real-time. | **Tích hợp đa API**: Google Maps (Vị trí), Cloudinary (Media), **ZegoCloud** (Call), VietQR, FCM. | **Realtime Streams**: Tin nhắn & Cuộc gọi (<100ms). Xử lý lỗi Network trong Call Screen. | **AI Recommendation**: Thuật toán so khớp hồ sơ dựa trên sở thích và vị trí. | **12+ Chức năng chính**: Xem chi tiết tại mục 5. | [Link Video Demo tại đây] |

---

## 🏗️ 2. Kiến Trúc Hệ Thống (Architecture)
Dự án được phát triển theo mô hình **MVC (Model-View-Controller)** kết hợp với **Repository Pattern** nhằm tách biệt hoàn toàn logic xử lý dữ liệu và giao diện hiển thị.

### 📂 Tổ chức mã nguồn theo mô hình MVC:
- **Model (`lib/models/`)**: Định nghĩa cấu trúc dữ liệu NoSQL chuẩn hóa (User, Post, Message...).
- **View (`lib/screens/`)**: Toàn bộ giao diện người dùng được module hóa, phản hồi linh hoạt theo trạng thái từ Controller.
- **Controller (`lib/controllers/`)**: "Bộ não" điều khiển toàn bộ logic nghiệp vụ và quản lý trạng thái ứng dụng sử dụng **GetX**.
- **Repository (`lib/repositories/`)**: Lớp trung gian đảm nhận việc giao tiếp với Firestore/API, cung cấp dữ liệu "sạch" cho Controller.
- **Service (`lib/services/`)**: Các dịch vụ độc lập (Gợi ý AI, ZegoCloud Call, Cloudinary API, FCM).

---

## 🧠 3. Điểm nhấn Kỹ thuật chuyên sâu (Technical Highlights)

### 🤖 Hệ Thống Gợi Ý AI (Recommendation Engine)
Ứng dụng sử dụng thuật toán phân tích đa chiều kết hợp **Google Maps API** để tính toán độ tương hợp cho mỗi cặp người dùng:
1. **Sở thích (Interests)**: Phân tích mảng sở thích chung của người dùng.
2. **Vị trí (Google Maps)**: Ưu tiên gợi ý hồ sơ trong cùng khu vực địa lý dựa trên tọa độ thực tế.
3. **Mục tiêu (Goals)**: Đối chiếu mục đích sử dụng (Kết bạn, Hẹn hò, Nghiêm túc).

### 🗄️ Giải pháp NoSQL & Real-time
- **Denormalization**: Dữ liệu tin nhắn được lồng trực tiếp giúp tốc độ đọc real-time cực nhanh (< 100ms).
- **Real-time Streams**: Sử dụng `StreamBuilder` để cập nhật tin nhắn, thông báo "Matched" và trạng thái cuộc gọi ngay lập tức.
- **Offline Persistence**: Tích hợp bộ nhớ đệm giúp xem lại dữ liệu ngay cả khi không có mạng.

### 💳 Hệ thống Thanh toán (Payment System)
- **VietQR Integration**: Tự động tạo mã QR thanh toán kèm nội dung chuyển khoản định sẵn giúp người dùng nâng cấp tài khoản VIP nhanh chóng.
- **Admin Approval**: Luồng kiểm duyệt giao dịch chặt chẽ tại Dashboard quản trị trước khi kích hoạt quyền lợi Premium.

---

## 🛡️ 4. Phân Quyền & Bảo Mật (Security & Roles)
- **Quyền Admin**: Được xác định qua collection `admins` trong Firestore để quản lý toàn bộ hệ thống.
- **AuthGate (Optimized)**: Hệ thống kiểm tra trạng thái tập trung giúp ngăn chặn lag khi mở app và điều hướng tự động vào đúng vai trò người dùng.
- **Safety Center**: Tích hợp tính năng Chặn (Block) và Báo cáo (Report) để bảo vệ cộng đồng.

---

## ✨ 5. Danh sách Chức năng chính (Features List)
1.  **Hệ thống Auth**: Đăng nhập/Đăng ký qua Email và **Google Sign-In**.
2.  **Khám phá (AI Discovery)**: Thuật toán AI gợi ý hồ sơ tiềm năng thông minh.
3.  **Vuốt thẻ (Swipe UI)**: Trải nghiệm vuốt mượt mà để Thích hoặc Bỏ qua.
4.  **Tương hợp (Matching)**: Thông báo tức thời khi hai người cùng "Like" nhau.
5.  **Trò chuyện Real-time**: Nhắn tin văn bản, hình ảnh, thả cảm xúc thời gian thực.
6.  **Cuộc gọi HD**: Gọi điện Video/Voice chất lượng cao tích hợp **ZegoCloud SDK**.
7.  **Social Feed**: Đăng bài khoảnh khắc cá nhân, thả tim và bình luận.
8.  **Premium**: Hệ thống nâng cấp tài khoản VIP tích hợp VietQR.
9.  **Quản trị viên (Admin)**: Dashboard thống kê, quản lý User, bài đăng và duyệt Thanh toán.
10. **Safety Center**: Chặn và báo cáo người dùng vi phạm tiêu chuẩn cộng đồng.
11. **Thông báo đẩy (FCM)**: Nhận tin nhắn, match mới ngay cả khi ứng dụng ở nền.
12. **Giao diện đa chế độ**: Hỗ trợ **Dark/Light Mode** chuyên nghiệp theo hệ thống.

---

## 🚀 6. Hướng dẫn cài đặt (Setup Guide)

1. **Tải thư viện**: `flutter pub get`
2. **Cấu hình Firebase**: Thêm file `google-services.json` vào thư mục `android/app/`.
3. **Cấu hình API Keys**: Điền `zegoAppId` và `zegoAppSign` vào `lib/utils/app_constants.dart`.
4. **Chạy ứng dụng**: `flutter run`

---
*Amour — Connecting hearts through code.*
