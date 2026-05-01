import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../controllers/theme_controller.dart';
import '../controllers/discovery_controller.dart';
import '../controllers/feed_controller.dart';
import '../controllers/profile_controller.dart';
import '../controllers/swipe_controller.dart';
import '../controllers/chat_list_controller.dart';
import '../controllers/register_controller.dart';
import '../controllers/admin_controller.dart';
import '../controllers/notification_controller.dart';
import '../controllers/edit_profile_controller.dart';
import '../controllers/premium_controller.dart';
import '../controllers/help_controller.dart';
import '../controllers/safety_controller.dart';
import '../controllers/onboarding_controller.dart';
import '../controllers/home_controller.dart';

class AppBindings extends Bindings {
  @override
  void dependencies() {
    // Controllers dùng chung xuyên suốt ứng dụng (permanent)
    Get.put(ThemeController(), permanent: true);
    Get.put(AuthController(), permanent: true);
    Get.put(HomeController(), permanent: true);
    
    // LazyPut cho các controllers màn hình (tự động giải phóng khi thoát màn hình)
    // fenix: true giúp khởi tạo lại controller khi quay lại màn hình đó
    Get.lazyPut(() => SwipeController(), fenix: true);
    Get.lazyPut(() => DiscoveryController(), fenix: true);
    Get.lazyPut(() => FeedController(), fenix: true);
    Get.lazyPut(() => ProfileController(), fenix: true);
    Get.lazyPut(() => ChatListController(), fenix: true);
    Get.lazyPut(() => AdminController(), fenix: true);
    Get.lazyPut(() => NotificationController(), fenix: true);
    Get.lazyPut(() => RegisterController(), fenix: true);
    Get.lazyPut(() => EditProfileController(), fenix: true);
    Get.lazyPut(() => PremiumController(), fenix: true);
    Get.lazyPut(() => HelpController(), fenix: true);
    Get.lazyPut(() => SafetyController(), fenix: true);
    Get.lazyPut(() => OnboardingController(), fenix: true);
  }
}
