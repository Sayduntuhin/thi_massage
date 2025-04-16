
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class CustomSnackBar {
  static void show(BuildContext context, String message, {ToastificationType type = ToastificationType.info}) {
    toastification.show(
      context: context,
      title: Text(message),
      type: type,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 5),
      alignment: Alignment.topCenter,
    );
  }
}