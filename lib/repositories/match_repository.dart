import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/base_repository.dart';
import '../core/result.dart';
import '../utils/app_constants.dart';

class MatchRepository extends BaseRepository {
  MatchRepository({super.db, super.auth});

  CollectionReference<Map<String, dynamic>> get _swipes =>
      db.collection(AppConstants.colSwipes);

  CollectionReference<Map<String, dynamic>> get _matches =>
      db.collection(AppConstants.colMatches);

  // ── SWIPE ───────────────────────────────────────────────────

  Future<Result<bool>> swipeRight(String targetUid) async {
    final uid = currentUid;
    if (uid == null) return Result.failure('Chưa đăng nhập');

    return safeRunOr(
      () async {
        await _swipes.doc(uid).collection('actions').doc(targetUid).set({
          'rating': 1,
          'timestamp': FieldValue.serverTimestamp(),
        });

        final theirDoc = await _swipes.doc(targetUid).collection('actions').doc(uid).get();

        if (theirDoc.exists && theirDoc['rating'] == 1) {
          await _createMatch(uid, targetUid);
          return Result.success(true); 
        }

        return Result.success(false);
      },
      Result.failure('Không thể swipe'),
    );
  }

  Future<void> swipeLeft(String targetUid) async {
    final uid = currentUid;
    if (uid == null) return;

    await safeRun(() => _swipes.doc(uid).collection('actions').doc(targetUid).set({
      'rating': -1,
      'timestamp': FieldValue.serverTimestamp(),
    }));
  }

  // ── MATCH ───────────────────────────────────────────────────

  Future<bool> isMatched(String targetUid) async {
    final uid = currentUid;
    if (uid == null) return false;
    final matchId = _buildMatchId(uid, targetUid);
    final doc = await safeRun(() => _matches.doc(matchId).get());
    return doc?.exists ?? false;
  }

  Future<Map<String, int>> getSwipeHistory(String uid) async {
    if (uid.isEmpty) return {};
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

  /// TỐI ƯU HÓA: Sử dụng Future.wait để thực hiện truy vấn song song (Fix lỗi treo app)
  /// Giới hạn số lượng người dùng để đảm bảo App phản hồi ngay lập tức.
  Future<Map<String, Map<String, int>>> getAllSwipeHistories() async {
    return safeRunOr(
      () async {
        // Chỉ lấy 20 người dùng có hoạt động mới nhất để tính gợi ý nhanh
        final snap = await _swipes.limit(20).get();
        final result = <String, Map<String, int>>{};
        
        // Tạo danh sách các tác vụ lấy hành động song song
        final futures = snap.docs.map((uDoc) async {
          if (uDoc.id == currentUid) return null;
          
          final acts = await uDoc.reference.collection('actions').limit(50).get();
          if (acts.docs.isNotEmpty) {
            return MapEntry(uDoc.id, {
              for (final a in acts.docs)
                a.id: (a['rating'] as num?)?.toInt() ?? 0
            });
          }
          return null;
        });

        // Chờ tất cả hoàn thành cùng lúc
        final entries = await Future.wait(futures);
        for (var entry in entries) {
          if (entry != null) result[entry.key] = entry.value;
        }
        
        return result;
      },
      {},
    );
  }

  Future<void> _createMatch(String uid1, String uid2) async {
    final matchId = _buildMatchId(uid1, uid2);
    await _matches.doc(matchId).set({
      'users': [uid1, uid2],
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  String _buildMatchId(String uid1, String uid2) {
    final sorted = [uid1, uid2]..sort();
    return '${sorted[0]}_${sorted[1]}';
  }
}
