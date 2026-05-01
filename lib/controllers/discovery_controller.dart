import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../models/user_model.dart';
import '../services/firestore_service.dart';

class DiscoveryController extends GetxController with GetSingleTickerProviderStateMixin {
  static DiscoveryController get to => Get.find();

  late TabController tabController;

  // -- States (Reactive) --
  final RxList<UserModel> allProfiles = <UserModel>[].obs;
  final RxList<UserModel> filteredProfiles = <UserModel>[].obs;
  final RxBool isLoading = true.obs;

  // -- Filter States --
  final RxString filterGender = 'Tất cả'.obs;
  final Rx<RangeValues> ageRange = const RangeValues(18, 45).obs;
  final RxList<String> filterInterests = <String>[].obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: 2, vsync: this);
    loadProfiles();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> loadProfiles() async {
    isLoading.value = true;
    try {
      final list = await FirestoreService.getDiscoveryProfiles();
      allProfiles.assignAll(list);
      applyFilters();
    } catch (e) {
      debugPrint("Error loading discovery: $e");
    } finally {
      isLoading.value = false;
    }
  }

  void applyFilters() {
    var result = List<UserModel>.from(allProfiles);

    if (filterGender.value != 'Tất cả') {
      result = result.where((u) => u.gender == filterGender.value).toList();
    }
    
    result = result.where((u) =>
        u.age >= ageRange.value.start && u.age <= ageRange.value.end).toList();

    if (filterInterests.isNotEmpty) {
      result = result.where((u) =>
          u.interests.any((i) => filterInterests.contains(i))).toList();
    }

    if (searchQuery.value.isNotEmpty) {
      final q = searchQuery.value.toLowerCase();
      result = result.where((u) =>
          u.name.toLowerCase().contains(q) ||
          u.city.toLowerCase().contains(q)).toList();
    }

    filteredProfiles.assignAll(result);
  }

  void updateFilters(String gender, RangeValues ages, List<String> interests) {
    filterGender.value = gender;
    ageRange.value = ages;
    filterInterests.assignAll(interests);
    applyFilters();
  }

  void updateSearch(String query) {
    searchQuery.value = query;
    applyFilters();
  }

  void clearFilters() {
    filterGender.value = 'Tất cả';
    ageRange.value = const RangeValues(18, 45);
    filterInterests.clear();
    searchQuery.value = '';
    applyFilters();
  }

  List<UserModel> getTrendingProfiles() {
    final trending = List<UserModel>.from(allProfiles);
    trending.sort((a, b) => b.likeCount.compareTo(a.likeCount));
    return trending;
  }
}
