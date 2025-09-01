import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import '../view/widgets/app_logger.dart';

class UserTypeController extends GetxController {
  var isTherapist = false.obs;
  var hasSelectedUserType = false.obs;
  var clientId = RxnInt();
  var therapistId = RxnInt();
  var role = RxString('');
  final box = GetStorage();

  @override
  void onInit() {
    super.onInit();
    if (box.read('isTherapist') != null) {
      isTherapist.value = box.read('isTherapist');
      AppLogger.debug("UserTypeController: Loaded isTherapist=${isTherapist.value}");
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
      AppLogger.debug("UserTypeController: Loaded role=${role.value}");
    }
  }

  void setUserType(bool isTherapist) {
    this.isTherapist.value = isTherapist;
    hasSelectedUserType.value = true;
    role.value = isTherapist ? 'therapist' : 'client';
    box.write('isTherapist', isTherapist);
    box.write('hasSelectedUserType', true);
    box.write('role', role.value);
    AppLogger.debug("UserTypeController: Set isTherapist=$isTherapist, role=${role.value}");
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
      isTherapist.value = role == 'therapist';
      box.write('isTherapist', isTherapist.value);
      AppLogger.debug("UserTypeController: Set role=$role, isTherapist=${isTherapist.value}");
    }
  }

  void resetUserType() {
    isTherapist.value = false;
    hasSelectedUserType.value = false;
    clientId.value = null;
    therapistId.value = null;
    role.value = '';
    box.remove('isTherapist');
    box.remove('hasSelectedUserType');
    box.remove('clientId');
    box.remove('therapistId');
    box.remove('role');
    AppLogger.debug("UserTypeController: Reset to isTherapist=false, role=''");
  }
}