import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class ChatListController extends GetxController {
  static ChatListController get to => Get.find();

  // -- States --
  final RxList<QueryDocumentSnapshot> allConversations = <QueryDocumentSnapshot>[].obs;
  final RxList<QueryDocumentSnapshot> filteredConversations = <QueryDocumentSnapshot>[].obs;
  final RxMap<String, UserModel> userCache = <String, UserModel>{}.obs;
  final RxBool isLoading = true.obs;
  final RxString searchQuery = ''.obs;
  final RxBool isSearching = false.obs;

  StreamSubscription? _convSub;
  final String _uid = AuthController.to.currentUid ?? '';

  @override
  void onInit() {
    super.onInit();
    if (_uid.isNotEmpty) {
      subscribeConversations();
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
        .listen((snap) {
      allConversations.value = snap.docs;
      _prefetchMissingUsers(snap.docs);
      applyFilters();
      isLoading.value = false;
    });
  }

  void _prefetchMissingUsers(List<QueryDocumentSnapshot> docs) {
    for (final doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final otherUid = _getOtherUid(data);
      if (otherUid.isNotEmpty && !userCache.containsKey(otherUid)) {
        _fetchAndCacheUser(otherUid);
      }
    }
  }

  Future<void> _fetchAndCacheUser(String uid) async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colUsers)
          .doc(uid)
          .get();
      if (snap.exists) {
        userCache[uid] = UserModel.fromFirestore(snap);
      }
    } catch (e) {
      print("Error caching user $uid: $e");
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

  UserModel? getCachedUser(String otherUid) => userCache[otherUid];

  String getOtherUidFromDoc(QueryDocumentSnapshot doc) {
    return _getOtherUid(doc.data() as Map<String, dynamic>);
  }
}
