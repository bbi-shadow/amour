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
    try {
      final snap = await FirebaseFirestore.instance
          .collection(AppConstants.colCities)
          .orderBy('name')
          .get();

      cities.value = snap.docs
          .map((d) => d.data()['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList();
    } catch (e) {
      print("Error loading cities: $e");
    } finally {
      isLoadingCities.value = false;
    }
  }

  Future<void> register({
    required String name,
    required String email,
    required String password,
    required String bio,
  }) async {
    if (selectedCity.value.isEmpty) {
      AppHelpers.showError("Vui lòng chọn thành phố");
      return;
    }

    final result = await AuthController.to.registerWithEmail(
      name: name,
      email: email,
      password: password,
      age: age.value,
      gender: gender.value,
      city: selectedCity.value,
      bio: bio,
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
