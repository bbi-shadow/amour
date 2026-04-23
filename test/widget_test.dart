import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:amour/main.dart'; // Đảm bảo đúng tên package

void main() {
  testWidgets('Kiểm tra màn hình khởi động', (WidgetTester tester) async {
    // Chạy ứng dụng Amour
    await tester.pumpWidget(AmourApp());

    // Kiểm tra xem chữ 'Amour' có xuất hiện không
    expect(find.text('Amour'), findsOneWidget);
  });
}