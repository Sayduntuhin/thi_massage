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
        child: LoadingAnimationWidget.discreteCircle(
          color: primaryColor,
          size: 0.12.sw,
        ),
      ),
    );
  }
}
class LoadingManager {
  static bool _isLoading = false;

  static void showLoading() {
    if (!_isLoading) {
      _isLoading = true;
      Get.dialog(
        const MinimalLoadingScreen(),
        barrierDismissible: false,
        barrierColor: Colors.black.withAlpha(50),
      );
    }
  }

  static void hideLoading() {
    if (_isLoading) {
      _isLoading = false;
      Get.back();
    }
  }
}