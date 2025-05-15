import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:thi_massage/controller/auth_controller.dart';

class InitialPage extends StatelessWidget {
  const InitialPage({super.key});

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authController = Get.find<AuthController>();
      await authController.checkSession();
    });

    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}