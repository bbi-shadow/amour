import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/user_model.dart';

/// ══════════════════════════════════════════════════════
/// RecommendationService — Hybrid RS
/// Content-Based → CF (3+ swipes) → SVD (10+ swipes)
/// ══════════════════════════════════════════════════════
class RecommendationService {
  static final _firestore = FirebaseFirestore.instance;

  static String get _uid => FirebaseAuth.instance.currentUser!.uid;

  // ── Điểm vào chính: tự chọn phương pháp ──
  static Future<List<UserModel>> getRecommendations(
      UserModel currentUser, List<UserModel> candidates) async {

    final swipeHistory = await _getSwipeHistory(_uid);

    if (swipeHistory.length >= 10) {
      return _svdRecommend(currentUser, candidates, swipeHistory);
    } else if (swipeHistory.length >= 3) {
      return _cfRecommend(currentUser, candidates, swipeHistory);
    } else {
      return _contentBasedRecommend(currentUser, candidates);
    }
  }

  // ══════════════════════════════════════════
  // 1. CONTENT-BASED FILTERING
  // ══════════════════════════════════════════
  static List<UserModel> _contentBasedRecommend(
      UserModel currentUser, List<UserModel> candidates) {
    final scored = candidates.map((c) {
      double score = _cosineSimilarity(currentUser.interests, c.interests);
      if (currentUser.location == c.location) score += 0.1;
      if ((currentUser.age - c.age).abs() > 10) score -= 0.1;
      return _ScoredUser(c, score);
    }).toList();
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.user).toList();
  }

  // ══════════════════════════════════════════
  // 2. COLLABORATIVE FILTERING
  // ══════════════════════════════════════════
  static Future<List<UserModel>> _cfRecommend(
      UserModel currentUser,
      List<UserModel> candidates,
      Map<String, int> mySwipes) async {
    final allSwipes = await _getAllSwipeHistories();

    final userSimilarities = <String, double>{};
    allSwipes.forEach((otherUid, theirSwipes) {
      if (otherUid == _uid) return;
      userSimilarities[otherUid] = _swipeSimilarity(mySwipes, theirSwipes);
    });

    final scored = candidates.map((c) {
      double cfScore = 0.0, weightSum = 0.0;
      allSwipes.forEach((otherUid, theirSwipes) {
        final sim = userSimilarities[otherUid] ?? 0.0;
        final rating = theirSwipes[c.uid]?.toDouble() ?? 0.0;
        cfScore += sim * rating;
        weightSum += sim.abs();
      });
      final normalized = weightSum > 0 ? cfScore / weightSum : 0.0;
      final cbScore = _cosineSimilarity(currentUser.interests, c.interests);
      return _ScoredUser(c, normalized * 0.7 + cbScore * 0.3);
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.user).toList();
  }

  // ══════════════════════════════════════════
  // 3. SVD — MATRIX FACTORIZATION
  //    R ≈ U × Σ × Vᵀ
  // ══════════════════════════════════════════
  static Future<List<UserModel>> _svdRecommend(
      UserModel currentUser,
      List<UserModel> candidates,
      Map<String, int> mySwipes) async {
    final allSwipes = await _getAllSwipeHistories();

    final userIds = allSwipes.keys.toList();
    if (!userIds.contains(_uid)) userIds.add(_uid);
    final itemIds = candidates.map((c) => c.uid).toList();

    // Build R matrix
    final R = List.generate(userIds.length, (i) =>
        List.generate(itemIds.length, (j) {
          final uid = userIds[i];
          final iid = itemIds[j];
          if (uid == _uid) return mySwipes[iid]?.toDouble() ?? 0.0;
          return allSwipes[uid]?[iid]?.toDouble() ?? 0.0;
        }));

    // SGD for matrix factorization
    const k = 5, epochs = 50;
    const lr = 0.01, reg = 0.02;
    final rand = Random(42);
    final U = List.generate(userIds.length, (_) =>
        List.generate(k, (_) => rand.nextDouble() * 0.1));
    final V = List.generate(itemIds.length, (_) =>
        List.generate(k, (_) => rand.nextDouble() * 0.1));

    for (int ep = 0; ep < epochs; ep++) {
      for (int i = 0; i < userIds.length; i++) {
        for (int j = 0; j < itemIds.length; j++) {
          if (R[i][j] == 0) continue;
          final e = R[i][j] - _dot(U[i], V[j]);
          for (int f = 0; f < k; f++) {
            final uif = U[i][f], vjf = V[j][f];
            U[i][f] += lr * (2 * e * vjf - reg * uif);
            V[j][f] += lr * (2 * e * uif - reg * vjf);
          }
        }
      }
    }

    final myIdx = userIds.indexOf(_uid);
    final scored = candidates.asMap().entries.map((entry) {
      final j = itemIds.indexOf(entry.value.uid);
      if (j == -1) return _ScoredUser(entry.value, 0.0);
      return _ScoredUser(entry.value, _dot(U[myIdx], V[j]));
    }).toList();

    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((e) => e.user).toList();
  }

  // ══════════════════════════════════════════
  // HELPERS
  // ══════════════════════════════════════════
  static double _cosineSimilarity(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersection = a.toSet().intersection(b.toSet()).length;
    final denom = sqrt(a.length * b.length.toDouble());
    return denom == 0 ? 0.0 : intersection / denom;
  }

  static double _swipeSimilarity(Map<String, int> a, Map<String, int> b) {
    final common = a.keys.where((k) => b.containsKey(k)).toList();
    if (common.isEmpty) return 0.0;
    double dot = 0, na = 0, nb = 0;
    for (final k in common) {
      dot += a[k]! * b[k]!;
      na += a[k]! * a[k]!;
      nb += b[k]! * b[k]!;
    }
    final d = sqrt(na) * sqrt(nb);
    return d == 0 ? 0.0 : dot / d;
  }

  static double _dot(List<double> a, List<double> b) {
    double s = 0;
    for (int i = 0; i < a.length; i++) s += a[i] * b[i];
    return s;
  }

  // ── Ghi swipe + auto check match ──
// ✅ Trả về true nếu có match
  static Future<bool> recordSwipe({
    required String targetUid,
    required bool isLike,
  }) async {
    await _firestore
        .collection('swipes').doc(_uid)
        .collection('actions').doc(targetUid)
        .set({
      'rating': isLike ? 1 : -1,
      'timestamp': FieldValue.serverTimestamp()
    });

    if (isLike) {
      return await _checkMatch(targetUid); // ✅ trả về kết quả
    }
    return false;
  }

// ✅ Trả về true nếu match
  static Future<bool> _checkMatch(String targetUid) async {
    final doc = await _firestore
        .collection('swipes').doc(targetUid)
        .collection('actions').doc(_uid).get();

    if (doc.exists && doc['rating'] == 1) {
      final matchId = ([_uid, targetUid]..sort()).join('_');
      await _firestore.collection('matches').doc(matchId).set({
        'users': [_uid, targetUid],
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true)); // ✅ merge tránh overwrite
      return true;
    }
    return false;
  }

  static Future<Map<String, int>> _getSwipeHistory(String uid) async {
    final snap = await _firestore
        .collection('swipes').doc(uid).collection('actions').get();
    return {for (final d in snap.docs) d.id: d['rating'] as int};
  }

  static Future<Map<String, Map<String, int>>> _getAllSwipeHistories() async {
    final snap = await _firestore.collection('swipes').get();
    final result = <String, Map<String, int>>{};
    for (final u in snap.docs) {
      final acts = await u.reference.collection('actions').get();
      result[u.id] = {for (final a in acts.docs) a.id: a['rating'] as int};
    }
    return result;
  }
}

class _ScoredUser {
  final UserModel user;
  final double score;
  _ScoredUser(this.user, this.score);
}