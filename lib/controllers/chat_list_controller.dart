import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class ChatListController extends GetxController {
  static ChatListController get to => Get.find();

  final RxList<QueryDocumentSnapshot> allConversations = <QueryDocumentSnapshot>[].obs;
  final RxList<QueryDocumentSnapshot> filteredConversations = <QueryDocumentSnapshot>[].obs;
  final RxMap<String, UserModel> userCache = <String, UserModel>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  StreamSubscription? _convSub;
  // Track uid đang fetch để tránh duplicate request
  final Set<String> _fetchingUids = {};

  String get _uid => AuthController.to.currentUid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (_uid.isNotEmpty) {
      subscribeConversations();
    } else {
      ever(AuthController.to.firebaseUser, (user) {
        if (user != null && _convSub == null) {
          subscribeConversations();
        }
      });
    }
  }

  @override
  void onClose() {
    _convSub?.cancel();
    super.onClose();
  }

  void subscribeConversations() {
    _convSub = FirebaseFirestore.instance
        .collection(AppConstants.colConversations)
        .where('participants', arrayContains: _uid)
        .orderBy('lastMessageTime', descending: true)
        .snapshots()
        .listen((snap) async {
      // Fetch tất cả user còn thiếu TRƯỚC khi cập nhật list
      await _prefetchMissingUsers(snap.docs);

      allConversations.value = snap.docs;
      applyFilters();
      isLoading.value = false;
    });
  }

  /// Await tất cả fetch song song, đảm bảo cache đầy đủ trước khi UI build
  Future<void> _prefetchMissingUsers(List<QueryDocumentSnapshot> docs) async {
    final futures = <Future>[];

    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final otherUid = _getOtherUid(data);
      if (otherUid.isNotEmpty &&
          !userCache.containsKey(otherUid) &&
          !_fetchingUids.contains(otherUid)) {
        _fetchingUids.add(otherUid);
        futures.add(_fetchAndCacheUser(otherUid));
      }
    }

    if (futures.isNotEmpty) {
      await Future.wait(futures);
    }
  }

  Future<void> _fetchAndCacheUser(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();
      if (snap.exists) {
        // ✅ Dùng addAll để trigger RxMap reactive update
        userCache.addAll({uid: UserModel.fromFirestore(snap)});
      }
    } catch (e) {
      debugPrint("Error caching user $uid: $e");
    } finally {
      _fetchingUids.remove(uid);
    }
  }

  String _getOtherUid(Map<String, dynamic> data) {
    final parts = List<String>.from(data['participants'] ?? []);
    return parts.firstWhere((p) => p != _uid, orElse: () => '');
  }

  void updateSearch(String query) {
    searchQuery.value = query.toLowerCase();
    applyFilters();
  }

  void applyFilters() {
    if (searchQuery.value.isEmpty) {
      filteredConversations.assignAll(allConversations);
      return;
    }

    final result = allConversations.where((doc) {
      final otherUid = _getOtherUid(doc.data() as Map<String, dynamic>);
      final user = userCache[otherUid];
      if (user == null) return false;
      return user.name.toLowerCase().contains(searchQuery.value);
    }).toList();

    filteredConversations.assignAll(result);
  }

  void toggleSearch() {
    isSearching.value = !isSearching.value;
    if (!isSearching.value) {
      updateSearch('');
    }
  }

  /// Gọi từ UI khi user chưa có trong cache (fallback)
  void fetchUserIfNeeded(String uid) {
    if (uid.isEmpty || userCache.containsKey(uid) || _fetchingUids.contains(uid)) return;
    _fetchingUids.add(uid);
    _fetchAndCacheUser(uid);
  }

  UserModel? getCachedUser(String uid) => userCache[uid];

  String getOtherUidFromDoc(QueryDocumentSnapshot doc) {
    return _getOtherUid(doc.data() as Map<String, dynamic>);
  }
}