import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../controller/coustomer_preferences_controller.dart';
import '../../../themes/colors.dart';

class CustomerPreferencesScreen extends StatelessWidget {
  const CustomerPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomerPreferencesController controller = Get.find<CustomerPreferencesController>();
    final bool isTherapistMode = Get.arguments != null && Get.arguments['preferences'] != null;
    AppLogger.info('isTherapistMode: $isTherapistMode');
    AppLogger.info('Get.arguments: ${Get.arguments}');

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: isTherapistMode ? "View Customer Preferences" : "Customer Preferences"),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          child: isTherapistMode
              ? FutureBuilder(
            future: Future(() {
              print('Manually calling _loadApiPreferences');
              controller.loadApiPreferences(Get.arguments['preferences']);
            }),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(child: CircularProgressIndicator());
              }
              AppLogger.info('Initial preferences: ${controller.preferences}');
              return Obx(
                    () => controller.preferences.values.every((v) => v.isEmpty)
                    ? Center(
                  child: Text(
                    'No preferences available for this customer.',
                    style: TextStyle(fontSize: 16.sp, color: Colors.black54),
                  ),
                )
                    : buildPreferencesList(context,controller, isTherapistMode),
              );
            },
          )
              : buildPreferencesList(context,controller, isTherapistMode),
        ),
      ),
    );
  }

  Widget buildPreferencesList(BuildContext context, CustomerPreferencesController controller, bool isTherapistMode) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            itemCount: CustomerPreferencesController.preferenceKeys.length,
            separatorBuilder: (_, __) => SizedBox(height: 24.h),
            itemBuilder: (context, index) {
              final preference = CustomerPreferencesController.preferenceKeys[index];
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preference,
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Obx(
                        () => isTherapistMode
                        ? Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 12.w),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Text(
                        controller.preferences[preference]?.isNotEmpty == true
                            ? controller.preferences[preference]!
                            : 'N/A',
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: Colors.black54,
                          fontWeight: FontWeight.w400,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    )
                        : TextFormField(
                      initialValue: controller.preferences[preference] ?? '',
                      onChanged: (value) {
                        controller.updatePreference(preference, value);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 8.h),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: primaryColor),
                        ),
                      ),
                      style: TextStyle(fontSize: 14.sp),
                      maxLines: 2,
                    ),
                  ),
                ],
              );
            },
          ),
        ),
        if (!isTherapistMode)
          Padding(
            padding: EdgeInsets.symmetric(vertical: 10.h),
            child: Obx(
                  () => ElevatedButton(
                onPressed: controller.isLoading.value || controller.preferences.isEmpty
                    ? null
                    : () => controller.savePreferences(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  minimumSize: Size(double.infinity, 48.h),
                ),
                child: controller.isLoading.value
                    ? CircularProgressIndicator(color: Colors.white, strokeWidth: 2.w)
                    : Text(
                  'Save Preferences',
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
      ],
    );
  }
}