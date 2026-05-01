import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/base_repository.dart';
import '../core/result.dart';
import '../models/user_model.dart';
import '../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// UserRepository — Quản lý toàn bộ thao tác dữ liệu người dùng
///
/// Trách nhiệm duy nhất (Single Responsibility):
///   Đọc / Ghi / Stream dữ liệu UserModel từ/lên Firestore.
///   Không chứa logic UI, không điều hướng màn hình.
/// ══════════════════════════════════════════════════════════════
class UserRepository extends BaseRepository {
  UserRepository({super.db, super.auth});

  CollectionReference<Map<String, dynamic>> get _col =>
      db.collection(AppConstants.colUsers);

  // ── READ ────────────────────────────────────────────────────

  /// Lấy một user theo uid, trả về null nếu không tồn tại
  Future<UserModel?> getById(String uid) async {
    if (uid.isEmpty) return null;
    return safeRun<UserModel?>(() async {
      final doc = await _col.doc(uid).get();
      return doc.exists ? UserModel.fromFirestore(doc) : null;
    });
  }

  /// Lấy user hiện tại đang đăng nhập
  Future<UserModel?> getCurrentUser() async {
    final uid = currentUid;
    if (uid == null) return null;
    return getById(uid);
  }

  /// Stream để lắng nghe thay đổi real-time của một user
  Stream<UserModel?> watchUser(String uid) {
    return _col.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserModel.fromFirestore(doc);
    });
  }

  /// Stream toàn bộ users (dùng cho admin)
  Stream<List<UserModel>> watchAllUsers() {
    return _col.snapshots().map((snap) =>
        snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // ── WRITE ───────────────────────────────────────────────────

  /// Cập nhật các trường tùy chọn của user
  Future<Result<void>> update(String uid, Map<String, dynamic> data) async {
    return safeRunOr(
      () async {
        await _col.doc(uid).update(data);
        return Result.success(null);
      },
      Result.failure('Không thể cập nhật hồ sơ'),
    );
  }

  /// Cập nhật trạng thái online/offline
  Future<void> setOnlineStatus({required bool isOnline}) async {
    final uid = currentUid;
    if (uid == null) return;
    await safeRun(() => _col.doc(uid).update({
          'isOnline': isOnline,
          'lastSeen': FieldValue.serverTimestamp(),
        }));
  }

  /// Tạo mới user document (dùng khi đăng ký)
  Future<Result<void>> create(UserModel user) async {
    return safeRunOr(
      () async {
        await _col.doc(user.uid).set(user.toMap());
        return Result.success(null);
      },
      Result.failure('Không thể tạo tài khoản'),
    );
  }

  // ── QUERY ───────────────────────────────────────────────────

  /// Lấy danh sách ứng viên cho discovery (tối đa 50)
  Future<List<UserModel>> getCandidates({int limit = 50}) async {
    return safeRunOr(
      () async {
        final uid = currentUid ?? '';
        final snap = await _col.limit(limit).get();
        return snap.docs
            .where((d) => d.id != uid)
            .map((d) => UserModel.fromFirestore(d))
            .toList();
      },
      [],
    );
  }

  /// Kiểm tra user có tồn tại không
  Future<bool> exists(String uid) async {
    final doc = await safeRun(() => _col.doc(uid).get());
    return doc?.exists ?? false;
  }

  /// Kiểm tra admin
  Future<bool> isAdmin(String uid) async {
    final doc = await safeRun(
      () => db.collection(AppConstants.colAdmins).doc(uid).get(),
    );
    return doc?.exists ?? false;
  }
}
