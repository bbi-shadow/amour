import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../utils/app_constants.dart';

class HelpController extends GetxController {
  static HelpController get to => Get.find();

  final RxSet<int> expandedIndices = <int>{}.obs;

  final List<FaqItem> faqs = [
    FaqItem('Lam the nao de match voi ai do?',
        'Vuot phai hoac nhan icon trai tim de thich. Neu nguoi kia cung thich ban, hai ban se match va co the nhan tin.'),
    FaqItem('Ket ban khac match nhu the nao?',
        'Match la ghep doi lang man. Ket ban la ket noi thong thuong - hai ben deu dong y thi tro thanh ban be.'),
    FaqItem('Anh hang ngay la gi?',
        'Moi ngay ban co the dang 1 anh de ban be cung xem. Tinh nang giup ban ket noi tu nhien hon moi ngay.'),
    FaqItem('Toi co the xoa tin nhan khong?',
        'Hien tai chua ho tro xoa tin nhan. Tinh nang nay dang duoc phat trien.'),
    FaqItem('Lam sao de bao cao nguoi dung?',
        'Vao ho so nguoi do -> nhan icon More -> chon ly do bao cao.'),
    FaqItem('Tai khoan bi khoa phai lam gi?',
        'Lien he ho tro qua email ben duoi de duoc giai quyet trong 24 gio.'),
  ];

  void toggleExpanded(int index) {
    if (expandedIndices.contains(index)) {
      expandedIndices.remove(index);
    } else {
      expandedIndices.add(index);
    }
  }

  Future<void> launchEmail() async {
    final Uri emailLaunchUri = Uri(
      scheme: 'mailto',
      path: 'support@amour.app',
    );
    try {
      if (await canLaunchUrl(emailLaunchUri)) {
        await launchUrl(emailLaunchUri);
      } else {
        AppHelpers.showError("Khong the mo ung dung email");
      }
    } catch (e) {
      AppHelpers.showError("Loi: $e");
    }
  }
}

class FaqItem {
  final String question;
  final String answer;
  FaqItem(this.question, this.answer);
}
