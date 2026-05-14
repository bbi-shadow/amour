import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';
import '../controllers/auth_controller.dart';
import '../utils/app_constants.dart';

class RegisterController extends GetxController {
  static RegisterController get to => Get.find();

  final RxList<String> cities = <String>[].obs;
  final RxBool isLoadingCities = true.obs;
  final RxString selectedCity = ''.obs;
  final RxString gender = 'Nam'.obs;
  final RxInt age = 18.obs;
  final RxBool obscurePass = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadCities();
  }

  Future<void> loadCities() async {
    isLoadingCities.value = true;
    final fallbackCities = [
      'Hà Nội',
      'TP. Hồ Chí Minh',
      'Đà Nẵng',
      'Cần Thơ',
      'Hải Phòng',
      'Nha Trang',
      'Huế',
      'Vũng Tàu',
      'Đà Lạt',
      'Buôn Ma Thuột',
    ];

    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colCities)
          .orderBy('name')
          .get();

      final loaded = snap.docs
          .map((d) => d.data()['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();

      if (loaded.isNotEmpty) {
        cities.value = loaded;
      } else {
        print("Firestore cities collection is empty, using robust fallback list.");
        cities.value = fallbackCities;
      }
    } catch (e) {
      print("Error loading cities from Firestore: $e");
      print("Automatically injecting fallback cities list due to missing composite index or permission rules.");
      cities.value = fallbackCities;
    } finally {
      isLoadingCities.value = false;
      // Tự động chọn thành phố đầu tiên làm mặc định để form luôn hợp lệ
      if (selectedCity.value.isEmpty && cities.isNotEmpty) {
        selectedCity.value = cities.first;
      }
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String bio,
  }) async {
    if (name.trim().isEmpty || email.trim().isEmpty || password.isEmpty) {
      AppHelpers.showError("Vui lòng nhập đầy đủ thông tin bắt buộc");
      return;
    }
    if (!AppHelpers.isValidEmail(email.trim())) {
      AppHelpers.showError("Email không hợp lệ");
      return;
    }
    if (password.length < 6) {
      AppHelpers.showError("Mật khẩu tối thiểu 6 ký tự");
      return;
    }
    if (selectedCity.value.isEmpty) {
      AppHelpers.showError("Vui lòng chọn thành phố");
      return;
    }

    final result = await AuthController.to.registerWithEmail(
      name: name.trim(),
      email: email.trim(),
      password: password,
      age: age.value,
      gender: gender.value,
      city: selectedCity.value,
      bio: bio.trim(),
    );

    if (result.isFailure) {
      AppHelpers.showError(result.error!);
    }
  }

  void toggleObscure() => obscurePass.value = !obscurePass.value;
  void updateGender(String g) => gender.value = g;
  void setCity(String c) => selectedCity.value = c;
  void incrementAge() { if (age.value < 99) age.value++; }
  void decrementAge() { if (age.value > 18) age.value--; }
}
