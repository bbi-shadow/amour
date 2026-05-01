import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// ══════════════════════════════════════════════════════════════
/// BaseRepository — Lớp nền trừu tượng cho toàn bộ Repository
///
/// Mọi repository kế thừa từ đây để:
///   • Truy cập Firestore & Auth nhất quán
///   • Có `currentUid` và `currentUidOrThrow` sẵn
///   • Dùng `safeRun` để bắt lỗi tập trung
/// ══════════════════════════════════════════════════════════════
abstract class BaseRepository {
  final FirebaseFirestore db;
  final FirebaseAuth auth;

  BaseRepository({FirebaseFirestore? db, FirebaseAuth? auth})
      : db = db ?? FirebaseFirestore.instance,
        auth = auth ?? FirebaseAuth.instance;

  /// UID user hiện tại, null nếu chưa đăng nhập
  String? get currentUid => auth.currentUser?.uid;

  /// UID user hiện tại, ném lỗi nếu chưa đăng nhập
  String get currentUidOrThrow {
    final uid = currentUid;
    if (uid == null || uid.isEmpty) throw Exception('User chưa đăng nhập');
    return uid;
  }

  /// Wrapper bắt lỗi chung — trả về null nếu thất bại
  Future<T?> safeRun<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (e, stack) {
      _logError(e, stack);
      return null;
    }
  }

  /// Wrapper bắt lỗi — trả về default value nếu thất bại
  Future<T> safeRunOr<T>(Future<T> Function() action, T fallback) async {
    try {
      return await action();
    } catch (e, stack) {
      _logError(e, stack);
      return fallback;
    }
  }

  void _logError(Object e, StackTrace stack) {
    // Trong production thay bằng Firebase Crashlytics
    // ignore: avoid_print
    print('[${runtimeType}] Error: $e\n$stack');
  }
}
