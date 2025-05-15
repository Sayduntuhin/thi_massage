import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:logger/logger.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/api/auth_service.dart';
import 'package:thi_massage/controller/auth_controller.dart';
import 'package:thi_massage/controller/user_type_controller.dart';
import 'package:thi_massage/routers/app_router.dart';
import 'package:thi_massage/firebase_options.dart';
import 'package:toastification/toastification.dart';
import 'controller/coustomer_preferences_controller.dart';

void main() async {
  var logger = Logger();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await GetStorage.init(); // Initialize GetStorage

  // Initialize controllers in correct order
  Get.put(ApiService());
  Get.put(AuthService());
  Get.put(UserTypeController(), permanent: true); // Register UserTypeController before AuthController
  Get.put(AuthController());
  Get.put(CustomerPreferencesController());

  // Check authentication state
  final AuthController authController = Get.find<AuthController>();
  await authController.checkSession();
  final String initialRoute = authController.isLoggedIn.value ? Routes.homePage : Routes.initial;

  debugPrint('--------------main: Initialized UserTypeController');
  debugPrint('main: Initial route set to $initialRoute');

  runApp(ThaiMassageApp(initialRoute: initialRoute));
}

class ThaiMassageApp extends StatelessWidget {
  final String initialRoute;

  const ThaiMassageApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return ToastificationWrapper(
      child: ScreenUtilInit(
        designSize: const Size(390, 844),
        builder: (context, child) {
          return GetMaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'Thai Massage',
            theme: ThemeData(
              fontFamily: "Urbanist",
              scaffoldBackgroundColor: Colors.white,
              primaryColor: const Color(0xFFAD7E23),
              appBarTheme: const AppBarTheme(
                scrolledUnderElevation: 0,
              ),
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFAD7E23)),
              useMaterial3: true,
            ),
            initialRoute: initialRoute,
            getPages: AppPages.routes,
          );
        },
      ),
    );
  }
}