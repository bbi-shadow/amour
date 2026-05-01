import 'package:cloud_firestore/cloud_firestore.dart';

class PostModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String content;
  final String? imageUrl;
  final List<String> likes;
  final List<String> reposts;
  final List<String> bookmarks;
  final int commentCount;
  final DateTime createdAt;

  PostModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.content,
    this.imageUrl,
    this.likes = const [],
    this.reposts = const [],
    this.bookmarks = const [],
    this.commentCount = 0,
    required this.createdAt,
  });

  factory PostModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return PostModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Người dùng',
      authorPhoto: data['authorPhoto'] ?? '',
      content: data['content'] ?? '',
      imageUrl: data['imageUrl'],
      likes: List<String>.from(data['likes'] ?? []),
      reposts: List<String>.from(data['reposts'] ?? []),
      bookmarks: List<String>.from(data['bookmarks'] ?? []),
      commentCount: data['commentCount'] ?? 0,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class CommentModel {
  final String id;
  final String authorId;
  final String authorName;
  final String authorPhoto;
  final String content;
  final List<String> likes;
  final DateTime createdAt;

  CommentModel({
    required this.id,
    required this.authorId,
    required this.authorName,
    required this.authorPhoto,
    required this.content,
    this.likes = const [],
    required this.createdAt,
  });

  factory CommentModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return CommentModel(
      id: doc.id,
      authorId: data['authorId'] ?? '',
      authorName: data['authorName'] ?? 'Người dùng',
      authorPhoto: data['authorPhoto'] ?? '',
      content: data['content'] ?? '',
      likes: List<String>.from(data['likes'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
