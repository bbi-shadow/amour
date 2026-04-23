# amour
Danh sách các file đã được đánh dấu:
1.
lib/services/recommendation_service.dart: (Đã làm trước đó) Giải thích chi tiết 3 thuật toán gợi ý (Content-Based, CF, SVD).
2.
lib/services/firestore_service.dart: Ghi chú cách hàm getDiscoveryProfiles() kết nối với bộ não gợi ý để lấy danh sách người dùng đã được sắp xếp theo độ phù hợp.
3.
lib/screens/swipe_screen.dart: Ghi chú luồng xử lý từ lúc tải dữ liệu đến lúc thực hiện hành động quẹt và nhận kết quả Match.
Bây giờ khi bạn mở bất kỳ file nào liên quan đến logic gợi ý, bạn sẽ thấy các dòng giải thích rõ ràng:
•
Đâu là chỗ tính toán điểm số.
•
Đâu là chỗ lọc người dùng cùng thành phố.
•
Đâu là chỗ kiểm tra Match.