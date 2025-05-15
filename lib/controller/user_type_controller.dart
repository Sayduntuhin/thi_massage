import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserTypeController extends GetxController {
  var isTherapist = false.obs; // false by default (Client)
  var hasSelectedUserType = false.obs; // Flag to track if user has made a selection
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    // Load saved values on initialization
    if (box.read('isTherapist') != null) {
      isTherapist.value = box.read('isTherapist');
    }
    if (box.read('hasSelectedUserType') != null) {
      hasSelectedUserType.value = box.read('hasSelectedUserType');
    }
  }

  void setUserType(bool isTherapist) {
    this.isTherapist.value = isTherapist;
    hasSelectedUserType.value = true;
    // Save to storage
    box.write('isTherapist', isTherapist);
    box.write('hasSelectedUserType', true);
  }

  void resetUserType() {
    isTherapist.value = false;
    hasSelectedUserType.value = false;
    box.remove('isTherapist');
    box.remove('hasSelectedUserType');
  }
}