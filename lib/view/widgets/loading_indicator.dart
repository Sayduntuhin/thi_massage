import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:thi_massage/themes/colors.dart';
class MinimalLoadingScreen extends StatelessWidget {
  const MinimalLoadingScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return  Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: LoadingAnimationWidget.hexagonDots(
          color: primaryColor,
          size: 0.10.sw,
        ),
      ),
    );
  }
}
class LoadingManager {
  static bool isLoading = false;

  static void showLoading() {
    if (!isLoading) {
      isLoading = true;
      Get.dialog(
        const MinimalLoadingScreen(),
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha(50),
      );
    }
  }

  static void hideLoading() {
    if (isLoading) {
      isLoading = false;
      Get.back();
    }
  }
}