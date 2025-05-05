import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../controller/coustomer_preferences_controller.dart';
class CustomerPreferencesScreen extends StatelessWidget {
  const CustomerPreferencesScreen({super.key});
  @override
  Widget build(BuildContext context) {
    // Initialize controller (assuming initialized in main.dart)
    final CustomerPreferencesController controller = Get.find<CustomerPreferencesController>();

    final List<String> preferences = const [
      "Preferred Modality",
      "Preferred Pressure",
      "Reasons for Massage",
      "Moisturizer Preferences",
      "Music Preference",
      "Conversation Preferences",
      "Pregnancy (Female customers)",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "Customer Preferences"),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: ListView.separated(
            itemCount: preferences.length,
            separatorBuilder: (_, __) => SizedBox(height: 24.h),
            itemBuilder: (context, index) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    preferences[index],
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Obx(
                        () => TextFormField(
                      initialValue: controller.preferences[preferences[index]] ?? '',
                      onChanged: (value) {
                        controller.updatePreference(preferences[index], value);
                      },
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: EdgeInsets.symmetric(vertical: 8.h),
                        enabledBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black26),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.brown),
                        ),
                      ),
                      style: TextStyle(fontSize: 14.sp),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}