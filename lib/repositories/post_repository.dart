import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/base_repository.dart';
import '../core/result.dart';
import '../models/post_model.dart';
import '../models/user_model.dart';

/// ══════════════════════════════════════════════════════════════
/// PostRepository — Quản lý Feed, Bài đăng, Bình luận
///
/// Cải tiến so với FirestoreService cũ:
///   • Tách riêng post logic khỏi user/chat logic
///   • Sort client-side nhất quán — không cần Firestore index
///   • getFollowingFeed giới hạn đúng 10 IDs (Firestore whereIn limit)
/// ══════════════════════════════════════════════════════════════
class PostRepository extends BaseRepository {
  static const _colPosts = 'posts';

  PostRepository({super.db, super.auth});

  CollectionReference<Map<String, dynamic>> get _posts =>
      db.collection(_colPosts);

  CollectionReference<Map<String, dynamic>> _comments(String postId) =>
      _posts.doc(postId).collection('comments');

  // ── FEED STREAMS ────────────────────────────────────────────

  /// Stream toàn bộ bài đăng, sort mới nhất lên đầu
  Stream<List<PostModel>> watchAllPosts() {
    return _posts.snapshots().map(_parsePosts).handleError((_) => <PostModel>[]);
  }

  /// Stream bài đăng của những người đang follow
  /// Firestore whereIn tối đa 10 phần tử — đã handle đúng
  Stream<List<PostModel>> watchFollowingFeed(List<String> followingIds) {
    if (followingIds.isEmpty) return Stream.value([]);

    final uid = currentUid ?? '';
    // Luôn bao gồm bài của chính mình, giới hạn đúng 10
    final ids = {...followingIds, uid}.take(10).toList();

    return _posts
        .where('authorId', whereIn: ids)
        .snapshots()
        .map(_parsePosts)
        .handleError((_) => <PostModel>[]);
  }

  // ── POST CRUD ───────────────────────────────────────────────

  /// Tạo bài đăng mới
  Future<Result<void>> createPost({
    required UserModel author,
    required String content,
    String? imageUrl,
  }) async {
    return safeRunOr(
      () async {
        await _posts.add({
          'authorId': author.uid,
          'authorName': author.name,
          'authorPhoto': author.photoUrl,
          'content': content,
          'imageUrl': imageUrl,
          'likes': <String>[],
          'reposts': <String>[],
          'bookmarks': <String>[],
          'commentCount': 0,
          'createdAt': FieldValue.serverTimestamp(),
        });
        return Result.success(null);
      },
      Result.failure('Không thể đăng bài'),
    );
  }

  /// Toggle like bài đăng. Trả về trạng thái liked mới.
  Future<Result<bool>> toggleLike(String postId, bool isCurrentlyLiked) async {
    final uid = currentUid;
    if (uid == null) return Result.failure('Chưa đăng nhập');

    return safeRunOr(
      () async {
        await _posts.doc(postId).update({
          'likes': isCurrentlyLiked
              ? FieldValue.arrayRemove([uid])
              : FieldValue.arrayUnion([uid]),
        });
        return Result.success(!isCurrentlyLiked);
      },
      Result.failure('Không thể thích bài'),
    );
  }

  /// Repost bài đăng
  Future<void> repost(String postId) async {
    final uid = currentUid;
    if (uid == null) return;
    await safeRun(() => _posts.doc(postId).update({
          'reposts': FieldValue.arrayUnion([uid]),
        }));
  }

  /// Toggle bookmark
  Future<void> toggleBookmark(String postId, {required bool isBookmarked}) async {
    final uid = currentUid;
    if (uid == null) return;
    await safeRun(() => _posts.doc(postId).update({
          'bookmarks': isBookmarked
              ? FieldValue.arrayRemove([uid])
              : FieldValue.arrayUnion([uid]),
        }));
  }

  // ── COMMENTS ────────────────────────────────────────────────

  /// Stream bình luận của một bài đăng
  Stream<List<CommentModel>> watchComments(String postId) {
    return _comments(postId)
        .snapshots()
        .map((snap) {
      final list = snap.docs
          .map((d) {
            try {
              return CommentModel.fromFirestore(d);
            } catch (_) {
              return null;
            }
          })
          .whereType<CommentModel>()
          .toList();
      list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return list;
    }).handleError((_) => <CommentModel>[]);
  }

  /// Thêm bình luận — dùng batch để tăng commentCount cùng lúc
  Future<Result<void>> addComment({
    required String postId,
    required UserModel author,
    required String content,
  }) async {
    return safeRunOr(
      () async {
        final batch = db.batch();

        final postRef = _posts.doc(postId);
        final commentRef = _comments(postId).doc();

        batch.set(commentRef, {
          'authorId': author.uid,
          'authorName': author.name,
          'authorPhoto': author.photoUrl,
          'content': content,
          'likes': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        });

        batch.update(postRef, {
          'commentCount': FieldValue.increment(1),
        });

        await batch.commit();
        return Result.success(null);
      },
      Result.failure('Không thể bình luận'),
    );
  }

  // ── PRIVATE ─────────────────────────────────────────────────

  List<PostModel> _parsePosts(QuerySnapshot snap) {
    final list = snap.docs
        .map((d) {
          try {
            return PostModel.fromFirestore(d);
          } catch (_) {
            return null;
          }
        })
        .whereType<PostModel>()
        .toList();
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return list;
  }
}
