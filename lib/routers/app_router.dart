import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:thi_massage/controller/auth_controller.dart';
import 'package:thi_massage/view/auth/forgetPassword/forget_password.dart';
import 'package:thi_massage/view/auth/forgetPassword/otp_verification_page.dart';
import 'package:thi_massage/view/auth/forgetPassword/reset_password.dart';
import 'package:thi_massage/view/auth/login/login_page.dart';
import 'package:thi_massage/view/auth/signup/page/sign_up.dart';
import 'package:thi_massage/view/booking/pages/client_appointment_page.dart';
import 'package:thi_massage/view/booking/pages/client_appointment_payment_page.dart';
import 'package:thi_massage/view/booking/pages/client_cutomer_preferences_page.dart';
import 'package:thi_massage/view/booking/pages/client_live_treaking_page.dart';
import 'package:thi_massage/view/booking/pages/terms_and_conditions.dart';
import 'package:thi_massage/view/booking/pages/therepist_appinment_request_page.dart';
import 'package:thi_massage/view/booking/pages/appoinment_details_page.dart';
import 'package:thi_massage/view/chat/pages/chat_details_page.dart';
import 'package:thi_massage/view/client_profile/pages/client_edite_profile_page.dart';
import 'package:thi_massage/view/client_profile/pages/favorite_therapist.dart';
import 'package:thi_massage/view/client_profile/pages/invite_friend_page.dart';
import 'package:thi_massage/view/client_profile/pages/support_page.dart';
import 'package:thi_massage/view/home/page/home_page.dart';
import 'package:thi_massage/view/home/page/notification_page.dart';
import 'package:thi_massage/view/home/widgets/therapist_profile_view_by_client_page.dart';
import 'package:thi_massage/view/home/widgets/search_page.dart';
import 'package:thi_massage/view/profileSetup/pages/add_card_page.dart';
import 'package:thi_massage/view/profileSetup/pages/profile_setup.dart';
import 'package:thi_massage/view/profileSetup/pages/review_submitted_page.dart';
import 'package:thi_massage/view/profileSetup/pages/verify_documents_page.dart';
import 'package:thi_massage/view/wallet/pages/funds_Withdraw_Page.dart';
import 'package:thi_massage/view/wallet/pages/new_payout_page.dart';
import 'package:thi_massage/view/wallet/pages/payment_history_page.dart';
import 'package:thi_massage/view/welcome/pages/welcome_page.dart';
import 'package:thi_massage/view/auth/forgetPassword/change_password_page.dart';

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
  static const String searchPage = "/searchPage";
  static const String notificationsPage = "/notificationsPage";
  static const String editProfile = "/editProfile";
  static const String changePassword = "/changePassword";
  static const String inviteFriendPage = "/inviteFriendPage";
  static const String supportPage = "/supportPage";
  static const String favoriteTherapist = "/favoriteTherapist";
  static const String appointmentPage = "/appointmentPage";
  static const String appointmentPaymentPage = "/appointmentPaymentPage";
  static const String termsAndConditions = "/termsAndConditions";
  static const String appointmentDetailsPage = "/appointmentDetailsPage";
  static const String liveTrackingPage = "/liveTrackingPage";
  static const String chatDetailsPage = "/chatDetailsPage";
  static const String therapistPage = "/therapistPage";
  static const String customerPreferencesPage = "/customerPreferencesPage";
  static const String verifyDocumentsPage = "/verifyDocumentsPage";
  static const String reviewSubmitPage = "/reviewSubmitPage";
  static const String newPayoutPage = "/newPayoutPage";
  static const String fundsWithdrawPage = "/fundsWithdrawPage";
  static const String paymentHistoryPage = "/paymentHistoryPage";
  static const String appointmentRequestPage = "/appointmentRequestPage";
}

class AppPages {
  static const bool isTherapist = true;

  // Custom middleware for authentication
  static final AuthMiddleware authMiddleware = AuthMiddleware();

  static final routes = [
    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Welcome<<<<<<<<<<<<<<<<<<<
    GetPage(
      name: Routes.initial,
      page: () => WelcomePage(),
      transition: Transition.zoom,
    ),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Auth<<<<<<<<<<<<<<<<<<<
    GetPage(
      name: Routes.logIn,
      page: () => LoginPage(),
      transition: Transition.size,
    ),
    GetPage(
      name: Routes.signUp,
      page: () => SignUpPage(),
      transition: Transition.size,
    ),
    GetPage(
      name: Routes.forgetPassword,
      page: () => ForgotPasswordPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.otpVerification,
      page: () => OTPVerificationPage(),
      transition: Transition.rightToLeft,
    ),
    GetPage(
      name: Routes.resetPassword,
      page: () => ResetPasswordPage(),
      transition: Transition.rightToLeft,
    ),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ProfileSetup<<<<<<<<<<<<<<<<<<<
    GetPage(
      name: Routes.profileSetup,
      page: () => ProfileSetupPage(),
      transition: Transition.size,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.verifyDocumentsPage,
      page: () => VerifyDocumentsPage(),
      transition: Transition.size,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.reviewSubmitPage,
      page: () => ReviewSubmittedPage(),
      transition: Transition.size,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.addCard,
      page: () => AddCardPage(),
      transition: Transition.size,
      middlewares: [authMiddleware],
    ),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ChatPage<<<<<<<<<<<<<<<<<<<
    GetPage(
      name: Routes.chatDetailsPage,
      page: () => ChatDetailScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>HomePage<<<<<<<<<<<<<<<<<<<
    GetPage(
      name: Routes.homePage,
      page: () => HomeScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.notificationsPage,
      page: () => NotificationsPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.searchPage,
      page: () => SearchPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.therapistPage,
      page: () => TherapistProfileScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>BookingPage<<<<<<<<<<<<<<<<<<<
    GetPage(
      name: Routes.appointmentPage,
      page: () => AppointmentScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.customerPreferencesPage,
      page: () => CustomerPreferencesScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.appointmentPaymentPage,
      page: () => AppointmentPaymentScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.termsAndConditions,
      page: () => TermsAndConditionsScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.appointmentDetailsPage,
      page: () => AppointmentDetailScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.liveTrackingPage,
      page: () => LiveTrackingScreen(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.appointmentRequestPage,
      page: () => AppointmentRequestPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Wallet<<<<<<<<<<<<<<<<<<<
    GetPage(
      name: Routes.fundsWithdrawPage,
      page: () => FundsWithdrawPage(selectedBank: Get.arguments['selectedBank']),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.paymentHistoryPage,
      page: () => PayoutHistoryPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.newPayoutPage,
      page: () => NewPayoutPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ProfilePage<<<<<<<<<<<<<<<<<<<
    GetPage(
      name: Routes.editProfile,
      page: () => EditProfilePage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.changePassword,
      page: () => ChangePasswordPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.inviteFriendPage,
      page: () => InviteFriendPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.supportPage,
      page: () => SupportPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
    GetPage(
      name: Routes.favoriteTherapist,
      page: () => FavoriteTherapistPage(),
      transition: Transition.fadeIn,
      middlewares: [authMiddleware],
    ),
  ];
}

// Custom middleware class for authentication
class AuthMiddleware extends GetMiddleware {
  @override
  int? get priority => 1;

  @override
  RouteSettings? redirect(String? route) {
    final authController = Get.find<AuthController>();
    if (!authController.isLoggedIn.value) {
      return const RouteSettings(name: Routes.logIn);
    }
    return null;
  }
}