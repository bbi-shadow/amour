import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final List<_FaqItem> _faqs = [
    _FaqItem('Làm thế nào để match với ai đó?',
        'Vuốt phải hoặc nhấn ❤️ để thích. Nếu người kia cũng thích bạn, hai bạn sẽ match và có thể nhắn tin.'),
    _FaqItem('Kết bạn khác match như thế nào?',
        'Match là ghép đôi lãng mạn. Kết bạn là kết nối thông thường — hai bên đều đồng ý thì trở thành bạn bè.'),
    _FaqItem('Ảnh hàng ngày là gì?',
        'Mỗi ngày bạn có thể đăng 1 ảnh để bạn bè cùng xem. Tính năng giúp bạn kết nối tự nhiên hơn mỗi ngày.'),
    _FaqItem('Tôi có thể xoá tin nhắn không?',
        'Hiện tại chưa hỗ trợ xoá tin nhắn. Tính năng này đang được phát triển.'),
    _FaqItem('Làm sao để báo cáo người dùng?',
        'Vào hồ sơ người đó → nhấn icon cờ ở góc phải trên → chọn lý do báo cáo.'),
    _FaqItem('Tài khoản bị khoá phải làm gì?',
        'Liên hệ hỗ trợ qua email bên dưới để được giải quyết trong 24 giờ.'),
  ];

  final Set<int> _expanded = {};

  Future<void> _launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@amour.app',
    );
    if (await canLaunchUrl(emailLaunchUri)) {
      await launchUrl(emailLaunchUri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Không thể mở ứng dụng email')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F0F2),
      appBar: AppBar(
        title: const Text('Trợ giúp & Phản hồi',
            style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1A1A1A))),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A1A)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(children: [
            Expanded(child: _contactBtn(
              icon: Icons.email_rounded,
              label: 'Email hỗ trợ',
              color: const Color(0xFFFF6B8A),
              onTap: _launchEmail,
            )),
            const SizedBox(width: 12),
            Expanded(child: _contactBtn(
              icon: Icons.chat_rounded,
              label: 'Chat trực tiếp',
              color: const Color(0xFF5B86E5),
              onTap: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Tính năng Chat Support đang được khởi tạo...'))
                );
              },
            )),
          ]),
          const SizedBox(height: 24),

          const Padding(
            padding: EdgeInsets.only(left: 4, bottom: 10),
            child: Text('Câu hỏi thường gặp',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.grey)),
          ),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 3))],
            ),
            child: Column(
              children: List.generate(_faqs.length, (i) {
                final faq = _faqs[i];
                final isOpen = _expanded.contains(i);
                final isLast = i == _faqs.length - 1;
                return GestureDetector(
                  onTap: () => setState(() {
                    if (isOpen) _expanded.remove(i); else _expanded.add(i);
                  }),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
                    ),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Row(children: [
                        Expanded(child: Text(faq.question,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)))),
                        Icon(isOpen ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                            color: Colors.grey[400]),
                      ]),
                      if (isOpen) ...[
                        const SizedBox(height: 8),
                        Text(faq.answer,
                            style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.5)),
                      ],
                    ]),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          Center(child: Text('Phiên bản 1.0.0', style: TextStyle(fontSize: 12, color: Colors.grey[400]))),
        ],
      ),
    );
  }

  Widget _contactBtn({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(fontSize: 13, color: color, fontWeight: FontWeight.w600)),
        ]),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}
