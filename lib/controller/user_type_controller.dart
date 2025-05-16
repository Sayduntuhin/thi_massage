import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class UserTypeController extends GetxController {
  var isTherapist = false.obs; // false by default (Client)
  var hasSelectedUserType = false.obs; // Flag to track if user has made a selection
  var clientId = RxnInt(); // Optional integer to store client ID
  var therapistId = RxnInt(); // Optional integer to store therapist ID
  var role = RxString(''); // To store the user role (client/therapist)
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
    if (box.read('clientId') != null) {
      clientId.value = box.read('clientId');
    }
    if (box.read('therapistId') != null) {
      therapistId.value = box.read('therapistId');
    }
    if (box.read('role') != null) {
      role.value = box.read('role');
    }
  }

  void setUserType(bool isTherapist) {
    this.isTherapist.value = isTherapist;
    hasSelectedUserType.value = true;
    // Save to storage
    box.write('isTherapist', isTherapist);
    box.write('hasSelectedUserType', true);
  }

  Future<void> setUserIds({int? clientId, int? therapistId, String? role}) async {
    if (clientId != null) {
      this.clientId.value = clientId;
      box.write('clientId', clientId);
    }

    if (therapistId != null) {
      this.therapistId.value = therapistId;
      box.write('therapistId', therapistId);
    }

    if (role != null) {
      this.role.value = role;
      box.write('role', role);

      // Update isTherapist based on role for consistency
      isTherapist.value = role == 'therapist';
      box.write('isTherapist', isTherapist.value);
    }
  }

  void resetUserType() {
    isTherapist.value = false;
    hasSelectedUserType.value = false;
    clientId.value = null;
    therapistId.value = null;
    role.value = '';

    // Remove from storage
    box.remove('isTherapist');
    box.remove('hasSelectedUserType');
    box.remove('clientId');
    box.remove('therapistId');
    box.remove('role');
  }
}