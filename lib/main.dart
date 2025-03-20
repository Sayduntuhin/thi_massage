import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get_navigation/src/root/get_material_app.dart';
import 'package:thi_massage/routers/app_router.dart';

void main() {
  runApp(const ThaiMassageApp());
}

class ThaiMassageApp extends StatelessWidget {
  const ThaiMassageApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(390, 844),
      builder: (context, child) {
        return GetMaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Thai Massage',
          theme: ThemeData(
            fontFamily: "Urbanist",
            scaffoldBackgroundColor: Colors.white,
            primaryColor: const Color(0xFFAD7E23),
            colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFAD7E23)),
            useMaterial3: true,
          ),
          initialRoute: Routes.initial, // ✅ Use class-based route names
          getPages: AppPages.routes,
        );
      },
    );
  }
}


