import 'package:get/get.dart';
import 'package:lyrics/Service/user_service.dart';

class ProfileController extends GetxController {
  final RxBool isPremium = false.obs;

  @override
  void onInit() {
    super.onInit();
    refreshStatus();
  }

  Future<void> refreshStatus() async {
    final status = await UserService.getIsPremium();
    isPremium.value = (status == '1');
  }
}
