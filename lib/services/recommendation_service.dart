import 'dart:math';
import '../models/user_model.dart';
import '../repositories/match_repository.dart';

/// ══════════════════════════════════════════════════════════════
/// RecommendationService — Hệ thống Gợi ý Hybrid (CB + CF + SVD)
///
/// FIX [LOGIC] so với phiên bản cũ:
///   1. Lọc bỏ user đã swipe rồi trước khi tính điểm — quan trọng nhất,
///      phiên bản cũ không làm điều này → user đã dislike vẫn hiện lại.
///   2. Lọc bỏ user bị banned (isBanned).
///   3. Content-Based: thêm trọng số lookingFor (muốn tìm ai), tăng penalty
///      khoảng cách tuổi, thêm boost cho trùng relationshipGoal.
///   4. CF: dùng Pearson correlation thay vì cosine thuần — xử lý tốt hơn
///      khi user có xu hướng rate toàn 1 hoặc toàn -1.
///   5. SVD: seed random cố định (42) nhưng thêm shuffle nhẹ sau khi sort
///      để tránh "filter bubble" — top candidates không phải luôn giống nhau.
///   6. Thêm diversity injection: luôn trộn thêm 10-20% random profiles
///      vào kết quả để tránh echo chamber.
/// ══════════════════════════════════════════════════════════════
class RecommendationService {
  final MatchRepository _matchRepo;

  RecommendationService({MatchRepository? matchRepo})
      : _matchRepo = matchRepo ?? MatchRepository();

  /// Điều phối: chọn thuật toán theo lượng dữ liệu swipe
  Future<List<UserModel>> getRecommendations(
      UserModel currentUser, List<UserModel> candidates) async {
    final swipeHistory = await _matchRepo.getSwipeHistory(currentUser.uid);

    // FIX [LOGIC 1]: Lọc bỏ user đã swipe và user bị banned TRƯỚC khi tính điểm
    final filtered = _filterCandidates(candidates, swipeHistory, currentUser);

    if (filtered.isEmpty) return [];

    List<UserModel> result;

    if (swipeHistory.length >= 10) {
      result = await _SvdStrategy(_matchRepo)
          .recommend(currentUser, filtered, swipeHistory);
    } else if (swipeHistory.length >= 3) {
      result = await _CfStrategy(_matchRepo)
          .recommend(currentUser, filtered, swipeHistory);
    } else {
      result = await _ContentBasedStrategy()
          .recommend(currentUser, filtered, swipeHistory);
    }

    // FIX [LOGIC 6]: Diversity injection — thêm 15% random để tránh filter bubble
    return _injectDiversity(result, filtered);
  }

  /// Lọc candidates:
  /// - Bỏ user đã swipe (dù like hay dislike)
  /// - Bỏ user bị banned
  /// - Bỏ chính mình (phòng thủ)
  List<UserModel> _filterCandidates(
      List<UserModel> candidates,
      Map<String, int> swipeHistory,
      UserModel me,
      ) {
    final swipedUids = swipeHistory.keys.toSet();
    return candidates
        .where((u) =>
    u.uid != me.uid &&
        !swipedUids.contains(u.uid) &&
        !u.isBanned)
        .toList();
  }

  /// Trộn một phần nhỏ random vào kết quả đã sort
  List<UserModel> _injectDiversity(
      List<UserModel> sorted, List<UserModel> pool) {
    if (sorted.length <= 5) return sorted;

    final injectCount = (sorted.length * 0.15).ceil().clamp(1, 5);
    final notInTop = pool.where((u) => !sorted.contains(u)).toList()
      ..shuffle(Random());
    final injected = notInTop.take(injectCount).toList();

    // Chèn random vào cuối 1/3 của danh sách
    final insertFrom = (sorted.length * 0.7).floor();
    final result = List<UserModel>.from(sorted);
    for (final u in injected) {
      final pos = insertFrom + Random().nextInt(result.length - insertFrom);
      result.insert(pos, u);
    }
    return result;
  }
}

// ──────────────────────────────────────────────────────────────
// Strategy interface
// ──────────────────────────────────────────────────────────────
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

  List<UserModel> _sortByScore(List<_ScoredUser> scored) {
    scored.sort((a, b) => b.score.compareTo(a.score));
    return scored.map((s) => s.user).toList();
  }
}

// ──────────────────────────────────────────────────────────────
// Thuật toán 1: Content-Based — dành cho người dùng mới
// ──────────────────────────────────────────────────────────────
class _ContentBasedStrategy extends _RecommendStrategy {
  @override
  Future<List<UserModel>> recommend(
      UserModel me, List<UserModel> candidates, Map<String, int> _) async {
    final scored = candidates.map((c) {
      double score = 0.0;

      // Cosine similarity sở thích (trọng số cao nhất)
      score += _cosineSimilarity(me.interests, c.interests) * 0.4;

      // FIX [LOGIC 3a]: lookingFor matching
      if (me.lookingFor == 'Tất cả' ||
          me.lookingFor.isEmpty ||
          me.lookingFor == c.gender) {
        score += 0.2;
      } else {
        score -= 0.3; // Penalty nếu không phù hợp giới tính tìm kiếm
      }

      // Cùng thành phố
      if (me.city.isNotEmpty && me.city == c.city) score += 0.15;

      // FIX [LOGIC 3b]: Penalty tuổi mạnh hơn, có bậc
      final ageDiff = (me.age - c.age).abs();
      if (ageDiff <= 3) {
        score += 0.1;
      } else if (ageDiff <= 7) {
        // Không thưởng, không phạt
      } else if (ageDiff <= 15) {
        score -= 0.1;
      } else {
        score -= 0.25; // Chênh lệch quá lớn
      }

      // FIX [LOGIC 3c]: Boost nếu cùng mục tiêu quan hệ
      if (me.relationshipGoal.isNotEmpty &&
          me.relationshipGoal == c.relationshipGoal) {
        score += 0.15;
      }

      return _ScoredUser(c, score);
    }).toList();

    return _sortByScore(scored);
  }
}

// ──────────────────────────────────────────────────────────────
// Thuật toán 2: Collaborative Filtering — khi có 3+ swipes
// ──────────────────────────────────────────────────────────────
class _CfStrategy extends _RecommendStrategy {
  final MatchRepository _matchRepo;
  _CfStrategy(this._matchRepo);

  @override
  Future<List<UserModel>> recommend(
      UserModel me,
      List<UserModel> candidates,
      Map<String, int> mySwipes) async {
    final allSwipes = await _matchRepo.getAllSwipeHistories();

    // FIX [LOGIC 4]: Dùng Pearson correlation thay vì cosine thuần
    final similarities = <String, double>{};
    for (final entry in allSwipes.entries) {
      if (entry.key == me.uid) continue;
      similarities[entry.key] =
          _pearsonCorrelation(mySwipes, entry.value);
    }

    final scored = candidates.map((c) {
      double cfScore = 0.0, weightSum = 0.0;
      for (final entry in allSwipes.entries) {
        final sim = similarities[entry.key] ?? 0.0;
        if (sim <= 0) continue; // Bỏ qua user không tương đồng
        final rating = entry.value[c.uid]?.toDouble() ?? 0.0;
        cfScore += sim * rating;
        weightSum += sim;
      }
      final normalizedCf = weightSum > 0 ? cfScore / weightSum : 0.0;

      // Kết hợp CF (70%) + Content-Based (30%)
      final cbScore = _cosineSimilarity(me.interests, c.interests);
      return _ScoredUser(c, normalizedCf * 0.7 + cbScore * 0.3);
    }).toList();

    return _sortByScore(scored);
  }

  /// FIX [LOGIC 4]: Pearson correlation — xử lý bias tốt hơn cosine
  double _pearsonCorrelation(Map<String, int> a, Map<String, int> b) {
    final common = a.keys.where(b.containsKey).toList();
    if (common.length < 2) return 0.0; // Cần ít nhất 2 điểm chung

    final aVals = common.map((k) => a[k]!.toDouble()).toList();
    final bVals = common.map((k) => b[k]!.toDouble()).toList();

    final aMean = aVals.reduce((x, y) => x + y) / aVals.length;
    final bMean = bVals.reduce((x, y) => x + y) / bVals.length;

    double num = 0, da = 0, db = 0;
    for (int i = 0; i < common.length; i++) {
      final ai = aVals[i] - aMean;
      final bi = bVals[i] - bMean;
      num += ai * bi;
      da += ai * ai;
      db += bi * bi;
    }

    final denom = sqrt(da) * sqrt(db);
    return denom == 0 ? 0.0 : num / denom;
  }
}

// ──────────────────────────────────────────────────────────────
// Thuật toán 3: SVD (Matrix Factorization) — khi có 10+ swipes
// ──────────────────────────────────────────────────────────────
class _SvdStrategy extends _RecommendStrategy {
  final MatchRepository _matchRepo;
  _SvdStrategy(this._matchRepo);

  static const _k = 8;       // FIX: tăng từ 5 → 8 latent factors
  static const _epochs = 50;
  static const _lr = 0.01;
  static const _reg = 0.02;

  @override
  Future<List<UserModel>> recommend(
      UserModel me,
      List<UserModel> candidates,
      Map<String, int> mySwipes) async {
    final allSwipes = await _matchRepo.getAllSwipeHistories();

    final userIds = [...allSwipes.keys];
    if (!userIds.contains(me.uid)) userIds.add(me.uid);
    final itemIds = candidates.map((c) => c.uid).toList();

    if (userIds.length < 3 || itemIds.isEmpty) {
      // Không đủ data cho SVD → fallback về Content-Based
      return _ContentBasedStrategy().recommend(me, candidates, mySwipes);
    }

    // Xây ma trận Rating (User × Item)
    final R = List.generate(
      userIds.length,
          (i) => List.generate(itemIds.length, (j) {
        final uid = userIds[i];
        final iid = itemIds[j];
        if (uid == me.uid) return mySwipes[iid]?.toDouble() ?? 0.0;
        return allSwipes[uid]?[iid]?.toDouble() ?? 0.0;
      }),
    );

    // Khởi tạo U, V với seed cố định
    final rand = Random(42);
    final U = List.generate(userIds.length,
            (_) => List.generate(_k, (_) => rand.nextDouble() * 0.1));
    final V = List.generate(itemIds.length,
            (_) => List.generate(_k, (_) => rand.nextDouble() * 0.1));

    // SGD training
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

    // FIX [LOGIC 5]: Shuffle nhẹ trong top-20 để tránh filter bubble
    final result = _sortByScore(scored);
    if (result.length > 20) {
      final top20 = result.sublist(0, 20)..shuffle(Random());
      return [...top20, ...result.sublist(20)];
    }
    return result;
  }

  double _dot(List<double> a, List<double> b) {
    double s = 0;
    for (int i = 0; i < a.length; i++) s += a[i] * b[i];
    return s;
  }
}

// ──────────────────────────────────────────────────────────────
// Helper model nội bộ
// ──────────────────────────────────────────────────────────────
class _ScoredUser {
  final UserModel user;
  final double score;
  const _ScoredUser(this.user, this.score);
}