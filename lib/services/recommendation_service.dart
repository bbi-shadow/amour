import 'dart:math';
import '../models/user_model.dart';
import '../repositories/match_repository.dart';

/// ══════════════════════════════════════════════════════════════
/// RecommendationService — Hệ thống Gợi ý Hybrid (CF + SVD + CB)
///
/// Cải tiến so với phiên bản cũ (static methods):
///   • Dùng instance + inject MatchRepository → testable
///   • Tách 3 thuật toán thành Strategy Pattern (_RecommendStrategy)
///     → thêm/đổi thuật toán không ảnh hưởng interface ngoài
///   • _ScoredUser đã promoted lên top-level class
/// ══════════════════════════════════════════════════════════════
class RecommendationService {
  final MatchRepository _matchRepo;

  RecommendationService({MatchRepository? matchRepo})
      : _matchRepo = matchRepo ?? MatchRepository();

  /// Điều phối: chọn thuật toán theo lượng dữ liệu swipe
  Future<List<UserModel>> getRecommendations(
      UserModel currentUser, List<UserModel> candidates) async {
    final swipeHistory = await _matchRepo.getSwipeHistory(currentUser.uid);

    if (swipeHistory.length >= 10) {
      // Đủ dữ liệu: dùng SVD (Matrix Factorization)
      return _SvdStrategy(_matchRepo)
          .recommend(currentUser, candidates, swipeHistory);
    } else if (swipeHistory.length >= 3) {
      // Vừa đủ: dùng Collaborative Filtering
      return _CfStrategy(_matchRepo)
          .recommend(currentUser, candidates, swipeHistory);
    } else {
      // Người mới: dùng Content-Based (sở thích + vị trí + tuổi)
      return _ContentBasedStrategy()
          .recommend(currentUser, candidates, swipeHistory);
    }
  }
}

/// ──────────────────────────────────────────────────────────────
/// Strategy interface — mọi thuật toán phải implement
/// ──────────────────────────────────────────────────────────────
abstract class _RecommendStrategy {
  Future<List<UserModel>> recommend(
    UserModel me,
    List<UserModel> candidates,
    Map<String, int> mySwipes,
  );

  /// Cosine similarity giữa 2 danh sách sở thích
  double _cosineSimilarity(List<String> a, List<String> b) {
    if (a.isEmpty || b.isEmpty) return 0.0;
    final intersection = a.toSet().intersection(b.toSet()).length;
    final denom = sqrt(a.length * b.length.toDouble());
    return denom == 0 ? 0.0 : intersection / denom;
  }

  /// Sort theo score giảm dần
  List<UserModel> _sortByScore(List<_ScoredUser> scored) {
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.user).toList();
  }
}

/// ──────────────────────────────────────────────────────────────
/// Thuật toán 1: Content-Based — dành cho người dùng mới
/// ──────────────────────────────────────────────────────────────
class _ContentBasedStrategy extends _RecommendStrategy {
  @override
  Future<List<UserModel>> recommend(
      UserModel me, List<UserModel> candidates, Map<String, int> _) async {
    final scored = candidates.map((c) {
      double score = _cosineSimilarity(me.interests, c.interests);
      if (me.city == c.city) score += 0.1;
      if ((me.age - c.age).abs() > 10) score -= 0.1;
      return _ScoredUser(c, score);
    }).toList();

    return _sortByScore(scored);
  }
}

/// ──────────────────────────────────────────────────────────────
/// Thuật toán 2: Collaborative Filtering — khi có 3+ swipes
/// ──────────────────────────────────────────────────────────────
class _CfStrategy extends _RecommendStrategy {
  final MatchRepository _matchRepo;
  _CfStrategy(this._matchRepo);

  @override
  Future<List<UserModel>> recommend(
      UserModel me, List<UserModel> candidates, Map<String, int> mySwipes) async {
    final allSwipes = await _matchRepo.getAllSwipeHistories();

    // Tính độ tương đồng với từng user khác
    final similarities = <String, double>{};
    for (final entry in allSwipes.entries) {
      if (entry.key == me.uid) continue;
      similarities[entry.key] = _swipeSimilarity(mySwipes, entry.value);
    }

    final scored = candidates.map((c) {
      double cfScore = 0.0, weightSum = 0.0;
      for (final entry in allSwipes.entries) {
        final sim = similarities[entry.key] ?? 0.0;
        final rating = entry.value[c.uid]?.toDouble() ?? 0.0;
        cfScore += sim * rating;
        weightSum += sim.abs();
      }
      final normalized = weightSum > 0 ? cfScore / weightSum : 0.0;
      final cbScore = _cosineSimilarity(me.interests, c.interests);
      return _ScoredUser(c, normalized * 0.7 + cbScore * 0.3);
    }).toList();

    return _sortByScore(scored);
  }

  double _swipeSimilarity(Map<String, int> a, Map<String, int> b) {
    final common = a.keys.where(b.containsKey).toList();
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
}

/// ──────────────────────────────────────────────────────────────
/// Thuật toán 3: SVD (Matrix Factorization) — khi có 10+ swipes
/// ──────────────────────────────────────────────────────────────
class _SvdStrategy extends _RecommendStrategy {
  final MatchRepository _matchRepo;
  _SvdStrategy(this._matchRepo);

  static const _k = 5;       // Số latent factor
  static const _epochs = 50; // Vòng lặp huấn luyện SGD
  static const _lr = 0.01;   // Learning rate
  static const _reg = 0.02;  // Regularization

  @override
  Future<List<UserModel>> recommend(
      UserModel me, List<UserModel> candidates, Map<String, int> mySwipes) async {
    final allSwipes = await _matchRepo.getAllSwipeHistories();

    final userIds = [...allSwipes.keys];
    if (!userIds.contains(me.uid)) userIds.add(me.uid);
    final itemIds = candidates.map((c) => c.uid).toList();

    // Xây dựng ma trận Rating (User × Item)
    final R = List.generate(
      userIds.length,
      (i) => List.generate(itemIds.length, (j) {
        final uid = userIds[i];
        final iid = itemIds[j];
        if (uid == me.uid) return mySwipes[iid]?.toDouble() ?? 0.0;
        return allSwipes[uid]?[iid]?.toDouble() ?? 0.0;
      }),
    );

    // Khởi tạo ma trận ẩn U (user) và V (item) ngẫu nhiên
    final rand = Random(42);
    final U = List.generate(
        userIds.length, (_) => List.generate(_k, (_) => rand.nextDouble() * 0.1));
    final V = List.generate(
        itemIds.length, (_) => List.generate(_k, (_) => rand.nextDouble() * 0.1));

    // Huấn luyện bằng SGD
    for (int ep = 0; ep < _epochs; ep++) {
      for (int i = 0; i < userIds.length; i++) {
        for (int j = 0; j < itemIds.length; j++) {
          if (R[i][j] == 0) continue;
          final e = R[i][j] - _dot(U[i], V[j]);
          for (int f = 0; f < _k; f++) {
            final uif = U[i][f], vjf = V[j][f];
            U[i][f] += _lr * (2 * e * vjf - _reg * uif);
            V[j][f] += _lr * (2 * e * uif - _reg * vjf);
          }
        }
      }
    }

    final myIdx = userIds.indexOf(me.uid);
    final scored = candidates.map((c) {
      final j = itemIds.indexOf(c.uid);
      if (j == -1) return _ScoredUser(c, 0.0);
      return _ScoredUser(c, _dot(U[myIdx], V[j]));
    }).toList();

    return _sortByScore(scored);
  }

  double _dot(List<double> a, List<double> b) {
    double s = 0;
    for (int i = 0; i < a.length; i++) s += a[i] * b[i];
    return s;
  }
}

/// Helper model nội bộ
class _ScoredUser {
  final UserModel user;
  final double score;
  const _ScoredUser(this.user, this.score);
}
