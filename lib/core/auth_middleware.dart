import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class AdminMiddleware extends GetMiddleware {
  @override
  RouteSettings? redirect(String? route) {
    final auth = AuthController.to;
    
    // Neu chua load xong profile hoac khong phai admin thi duoi ra ngoai
    // Luu y: logic nay kiem tra dua tren du lieu local da load tu Firestore
    if (auth.currentUser.value == null) {
      return const RouteSettings(name: AppRoutes.login);
    }

    return null; 
  }

  // Ham thuc thi sau khi vao trang
  @override
  GetPageBuilder? onPageBuildStart(GetPageBuilder? page) {
    // Kiem tra quyen admin thuc su tu Firestore
    _verifyAdmin();
    return page;
  }

  Future<void> _verifyAdmin() async {
    final auth = AuthController.to;
    final uid = auth.currentUid;
    if (uid == null) return;

    bool isAdmin = await auth.checkIsAdmin(uid);
    if (!isAdmin) {
      Get.offAllNamed(AppRoutes.home);
      AppHelpers.showError("Ban khong co quyen truy cap vao trang nay!");
    }
  }
}
