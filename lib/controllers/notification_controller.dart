import 'dart:async';
import 'package:get/get.dart';
import '../models/notification_model.dart';
import '../services/firestore_service.dart';
import '../utils/app_constants.dart';

class NotificationController extends GetxController {
  static NotificationController get to => Get.find();

  final RxList<NotificationModel> notifications = <NotificationModel>[].obs;
  final RxBool isLoading = true.obs;
  StreamSubscription? _notifSub;

  @override
  void onInit() {
    super.onInit();
    listenToNotifications();
  }

  @override
  void onClose() {
    _notifSub?.cancel();
    super.onClose();
  }

  void listenToNotifications() {
    _notifSub = FirestoreService.getNotificationsStream().listen((snap) {
      notifications.value = snap.docs.map((doc) => NotificationModel.fromFirestore(doc)).toList();
      isLoading.value = false;
    }, onError: (e) {
      print("Error listening to notifications: $e");
      isLoading.value = false;
    });
  }

  Future<void> markAsRead(String id) async {
    await FirestoreService.markNotificationRead(id);
  }

  Future<void> markAllAsRead() async {
    try {
      await FirestoreService.markAllNotificationsRead();
      AppHelpers.showSuccess("Da doc tat ca thong bao");
    } catch (e) {
      AppHelpers.showError("Loi khi cap nhat");
    }
  }
}
