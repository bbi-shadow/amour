import 'package:flutter/material.dart';
import '../models/user_model.dart';
import 'match_dialog.dart';

class MatchPopup {
  static void show(
    BuildContext context, {
    required UserModel matchedUser,
    required String matchId,
    required String currentUserName,
    String? currentUserPhotoUrl,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.9),
      builder: (_) => MatchDialog(
        matchedUser: matchedUser,
        matchId: matchId,
        currentUserName: currentUserName,
        currentUserPhotoUrl: currentUserPhotoUrl,
      ),
    );
  }
}
