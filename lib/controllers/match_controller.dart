import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:confetti/confetti.dart';

class MatchController extends GetxController with GetSingleTickerProviderStateMixin {
  late ConfettiController confettiController;
  late AnimationController animCtrl;
  late Animation<double> scaleAnim;

  @override
  void onInit() {
    super.onInit();
    confettiController = ConfettiController(duration: const Duration(seconds: 2));
    confettiController.play();

    animCtrl = AnimationController(
      vsync: this, 
      duration: const Duration(milliseconds: 600)
    );
    // Đã sửa từ backOut thành easeOutBack
    scaleAnim = CurvedAnimation(parent: animCtrl, curve: Curves.easeOutBack);
    animCtrl.forward();
  }

  @override
  void onClose() {
    confettiController.dispose();
    animCtrl.dispose();
    super.onClose();
  }
}
