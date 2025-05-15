import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import '../../../controller/coustomer_preferences_controller.dart';

class CustomerPreferencesScreen extends StatelessWidget {
  const CustomerPreferencesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final CustomerPreferencesController controller = Get.find<CustomerPreferencesController>();
    final Map<String, dynamic> arguments = Get.arguments as Map<String, dynamic>? ?? {};
    final Map<String, dynamic> preferencesData = arguments['preferences'] ?? {};

    // Map API keys to display labels
    final Map<String, String> preferenceMap = {
      'preferred_modality': 'Preferred Modality',
      'preferred_pressure': 'Preferred Pressure',
      'reason_for_massage': 'Reasons for Massage',
      'moisturizer': 'Moisturizer Preferences',
      'music_preference': 'Music Preference',
      'conversation_preference': 'Conversation Preferences',
      'pregnancy': 'Pregnancy (Female customers)',
    };

    // Initialize controller with API data
    preferenceMap.forEach((key, label) {
      controller.updatePreference(label, preferencesData[key]?.toString() ?? '');
    });

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "Customer Preferences"),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: ListView.separated(
            itemCount: preferenceMap.values.length,
            separatorBuilder: (_, __) => SizedBox(height: 24.h),
            itemBuilder: (context, index) {
              final label = preferenceMap.values.elementAt(index);
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 10.h),
                  Obx(
                        () => TextFormField(
                      initialValue: controller.preferences[label] ?? '',
                      readOnly: true, // Make fields read-only for therapist view
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