import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../utils/app_constants.dart';
import '../themes/app_theme.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Background FCM: ${message.notification?.title}');
}

class FCMService {
  static final _messaging = FirebaseMessaging.instance;
  static final _firestore = FirebaseFirestore.instance;

  static Future<void> init() async {
    if (kIsWeb) return;

    try {
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      await _saveToken();

      _messaging.onTokenRefresh.listen(_updateToken);
      FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
      FirebaseMessaging.onMessageOpenedApp.listen(_handleNotificationTap);

      final initialMessage = await _messaging.getInitialMessage();
      if (initialMessage != null) _handleNotificationTap(initialMessage);
    } catch (e) {
      debugPrint('FCM Init Error: $e');
    }
  }

  static Future<void> _saveToken() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    try {
      final token = await _messaging.getToken();
      if (token != null) await _updateToken(token);
    } catch (e) {
      debugPrint('Error getting token');
    }
  }

  static Future<void> _updateToken(String token) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    await _firestore.collection(AppConstants.colUsers).doc(uid).update({
      'fcmToken': token,
      'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
    });
  }

  static void _handleForegroundMessage(RemoteMessage message) {
    final notif = message.notification;
    if (notif == null) return;

    Get.snackbar(
      notif.title ?? 'Amour',
      notif.body ?? '',
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.white,
      colorText: const Color(0xFF1A1A1A),
      margin: const EdgeInsets.all(12),
      borderRadius: 14,
      icon: const Icon(Icons.favorite_rounded, color: AppColors.primary, size: 24),
      mainButton: TextButton(
        onPressed: () => _navigate(message.data),
        child: const Text('Xem', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700)),
      ),
    );
  }

  static void _handleNotificationTap(RemoteMessage message) {
    _navigate(message.data);
  }

  static void _navigate(Map<String, dynamic> data) {
    final type = data['type'] as String?;
    final targetId = data['targetId'] as String?;

    switch (type) {
      case 'match':
        Get.toNamed(AppRoutes.home);
        break;
      case 'message':
        if (targetId != null) {
          Get.toNamed(AppRoutes.chatDetail, arguments: {'conversationId': targetId});
        }
        break;
    }
  }
}
