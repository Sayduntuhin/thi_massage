import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';

class CustomerPreferencesScreen extends StatefulWidget {
  const CustomerPreferencesScreen({super.key});

  @override
  State<CustomerPreferencesScreen> createState() => _CustomerPreferencesScreenState();
}

class _CustomerPreferencesScreenState extends State<CustomerPreferencesScreen> {
  final List<String> preferences = const [
    "Preferred Modality",
    "Preferred Pressure",
    "Reasons for Massage",
    "Moisturizer Preferences",
    "Music Preference",
    "Conversation Preferences",
    "Pregnancy (Female customers)"
  ];

  late final List<TextEditingController> controllers;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(preferences.length, (_) => TextEditingController());
  }

  @override
  void dispose() {
    for (var controller in controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: SecondaryAppBar(title: "Customer Preferences"),
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                        TextField(
                          controller: controllers[index],
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
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
