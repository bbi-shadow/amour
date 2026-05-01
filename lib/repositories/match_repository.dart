import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/base_repository.dart';
import '../core/result.dart';
import '../utils/app_constants.dart';

/// ══════════════════════════════════════════════════════════════
/// MatchRepository — Quản lý Swipe, Like, Match
///
/// Fix lỗi logic từ code cũ:
///   • MatchService & RecommendationService._checkMatch bị TRÙNG LẶP
///     cùng tạo match nhưng dùng 2 collection khác nhau ('likes' vs 'swipes').
///     Repository này hợp nhất về 1 collection 'swipes' duy nhất.
///   • MatchService dùng instance method (non-static) còn
///     RecommendationService dùng static — không nhất quán.
///     Repository này dùng instance method chuẩn OOP.
/// ══════════════════════════════════════════════════════════════
class MatchRepository extends BaseRepository {
  MatchRepository({super.db, super.auth});

  CollectionReference<Map<String, dynamic>> get _swipes =>
      db.collection(AppConstants.colSwipes);

  CollectionReference<Map<String, dynamic>> get _matches =>
      db.collection(AppConstants.colMatches);

  // ── SWIPE ───────────────────────────────────────────────────

  /// Ghi nhận swipe phải (like). Trả về true nếu có match mới.
  Future<Result<bool>> swipeRight(String targetUid) async {
    final uid = currentUid;
    if (uid == null) return Result.failure('Chưa đăng nhập');

    return safeRunOr(
      () async {
        // Ghi lại action của mình
        await _swipes
            .doc(uid)
            .collection('actions')
            .doc(targetUid)
            .set({
          'rating': 1,
          'timestamp': FieldValue.serverTimestamp(),
        });

        // Kiểm tra đối phương đã like mình chưa
        final theirDoc = await _swipes
            .doc(targetUid)
            .collection('actions')
            .doc(uid)
            .get();

        if (theirDoc.exists && theirDoc['rating'] == 1) {
          await _createMatch(uid, targetUid);
          return Result.success(true); // Có match!
        }

        return Result.success(false); // Chưa match
      },
      Result.failure('Không thể swipe'),
    );
  }

  /// Ghi nhận swipe trái (dislike)
  Future<void> swipeLeft(String targetUid) async {
    final uid = currentUid;
    if (uid == null) return;

    await safeRun(() => _swipes
        .doc(uid)
        .collection('actions')
        .doc(targetUid)
        .set({
      'rating': -1,
      'timestamp': FieldValue.serverTimestamp(),
    }));
  }

  // ── MATCH ───────────────────────────────────────────────────

  /// Kiểm tra 2 user đã match chưa
  Future<bool> isMatched(String targetUid) async {
    final uid = currentUid;
    if (uid == null) return false;

    final matchId = _buildMatchId(uid, targetUid);
    final doc = await safeRun(() => _matches.doc(matchId).get());
    return doc?.exists ?? false;
  }

  /// Lấy lịch sử swipe của một user (uid → rating)
  Future<Map<String, int>> getSwipeHistory(String uid) async {
    return safeRunOr(
      () async {
        final snap = await _swipes.doc(uid).collection('actions').get();
        return {
          for (final d in snap.docs)
            d.id: (d['rating'] as num?)?.toInt() ?? 0
        };
      },
      {},
    );
  }

  /// Lấy toàn bộ lịch sử swipe cho Collaborative Filtering
  Future<Map<String, Map<String, int>>> getAllSwipeHistories() async {
    return safeRunOr(
      () async {
        final snap = await _swipes.get();
        final result = <String, Map<String, int>>{};
        for (final u in snap.docs) {
          final acts = await u.reference.collection('actions').get();
          result[u.id] = {
            for (final a in acts.docs)
              a.id: (a['rating'] as num?)?.toInt() ?? 0
          };
        }
        return result;
      },
      {},
    );
  }

  // ── PRIVATE ─────────────────────────────────────────────────

  /// Tạo match document (idempotent — có thể gọi nhiều lần an toàn)
  Future<void> _createMatch(String uid1, String uid2) async {
    final matchId = _buildMatchId(uid1, uid2);
    await _matches.doc(matchId).set({
      'users': [uid1, uid2],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  /// matchId duy nhất: sort 2 uid để tránh trùng lặp
  String _buildMatchId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
