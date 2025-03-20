import 'package:get/get_navigation/src/routes/get_route.dart';
import 'package:get/get_navigation/src/routes/transitions_type.dart';
import 'package:thi_massage/view/auth/forgetPassword/otp_verification_page.dart';
import 'package:thi_massage/view/auth/forgetPassword/reset_password.dart';
import 'package:thi_massage/view/auth/signup/page/sign_up.dart';
import 'package:thi_massage/view/home/page/home_page.dart';
import 'package:thi_massage/view/home/page/notification_page.dart';
import 'package:thi_massage/view/profile/pages/change_password_page.dart';
import 'package:thi_massage/view/profile/pages/invite_friend_page.dart';
import 'package:thi_massage/view/profileSetup/pages/add_card_page.dart';
import 'package:thi_massage/view/welcome/pages/welcome_page.dart';
import '../view/auth/forgetPassword/forget_password.dart';
import '../view/auth/login/login_page.dart';
import '../view/profile/pages/edite_profile_page.dart';
import '../view/profileSetup/pages/profile_setup.dart';

class Routes {
  static const String initial = "/";
  static const String logIn = "/logIn";
  static const String signUp = "/signUp";
  static const String forgetPassword = "/forgetPassword";
  static const String otpVerification = "/otpVerification";
  static const String resetPassword = "/resetPassword";
  static const String profileSetup = "/profileSetup";
  static const String addCard = "/addCard";
  static const String homePage = "/homePage";
  static const String notificationsPage = "/notificationsPage";
  static const String editProfile = "/editProfile";
  static const String changePassword = "/changePassword";
  static const String inviteFriendPage = "/inviteFriendPage";



}

class AppPages {
  static final routes = [
    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Welcome<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.initial, page: () => WelcomePage(), transition: Transition.zoom),
    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Auth   <<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.logIn, page: () => LoginPage(), transition: Transition.size),
    GetPage(name: Routes.signUp, page: () => SignUpPage(), transition: Transition.size),
    GetPage(name: Routes.forgetPassword, page: () => ForgotPasswordPage(), transition: Transition.rightToLeft),
    GetPage(name: Routes.otpVerification, page: () => OTPVerificationPage(), transition: Transition.rightToLeft),
    GetPage(name: Routes.resetPassword, page: () => ResetPasswordPage(), transition: Transition.rightToLeft),
   ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ProfileSetup<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.profileSetup, page: () => ProfileSetupPage(), transition: Transition.size),
    GetPage(name: Routes.addCard, page: () => AddCardPage(), transition: Transition.size),
    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>HomePage<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.homePage, page: () => HomeScreen(), transition: Transition.fadeIn),
    GetPage(name: Routes.notificationsPage, page: () => NotificationsPage(), transition: Transition.fadeIn),
    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ProfilePage<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.editProfile, page: () => EditProfilePage(), transition: Transition.fadeIn),
    GetPage(name: Routes.changePassword, page: () => ChangePasswordPage(), transition: Transition.fadeIn),
    GetPage(name: Routes.inviteFriendPage, page: () => InviteFriendPage(), transition: Transition.fadeIn),

  ];

}
