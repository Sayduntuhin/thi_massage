import 'package:get/get.dart';
import 'package:thi_massage/view/auth/forgetPassword/otp_verification_page.dart';
import 'package:thi_massage/view/auth/forgetPassword/reset_password.dart';
import 'package:thi_massage/view/auth/signup/page/sign_up.dart';
import 'package:thi_massage/view/booking/pages/appinment_request_page.dart';
import 'package:thi_massage/view/booking/pages/appoinment_details_page.dart';
import 'package:thi_massage/view/booking/pages/appointment_payment_page.dart';
import 'package:thi_massage/view/booking/pages/appointment_page.dart';
import 'package:thi_massage/view/chat/pages/chat_details_page.dart';
import 'package:thi_massage/view/home/page/home_page.dart';
import 'package:thi_massage/view/home/page/notification_page.dart';
import 'package:thi_massage/view/profile/pages/change_password_page.dart';
import 'package:thi_massage/view/profile/pages/invite_friend_page.dart';
import 'package:thi_massage/view/profileSetup/pages/add_card_page.dart';
import 'package:thi_massage/view/profileSetup/pages/review_submitted_page.dart';
import 'package:thi_massage/view/profileSetup/pages/verify_documents_page.dart';
import 'package:thi_massage/view/wallet/pages/new_payout_page.dart';
import 'package:thi_massage/view/wallet/pages/payment_history_page.dart';
import 'package:thi_massage/view/welcome/pages/welcome_page.dart';
import '../view/auth/forgetPassword/forget_password.dart';
import '../view/auth/login/login_page.dart';
import '../view/booking/pages/cutomer_preferences_page.dart';
import '../view/booking/pages/live_treaking_page.dart';
import '../view/booking/pages/terms_and_conditions.dart';
import '../view/home/page/therapist_page.dart';
import '../view/home/widgets/search_page.dart';
import '../view/profile/pages/edite_profile_page.dart';
import '../view/profile/pages/favorite_therapist.dart';
import '../view/profile/pages/support_page.dart';
import '../view/profileSetup/pages/profile_setup.dart';
import '../view/wallet/pages/funds_Withdraw_Page.dart';

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
  static const String  reviewSubmitPage= "/reviewSubmitPage";
  static const String  newPayoutPage = "/newPayoutPage";
  static const String  fundsWithdrawPage = "/fundsWithdrawPage";
  static const String  paymentHistoryPage = "/paymentHistoryPage";
  static const String  appointmentRequestPage = "/appointmentRequestPage";
}

class AppPages {
  static const bool isTherapist = true;

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
    GetPage(name: Routes.verifyDocumentsPage, page: () => VerifyDocumentsPage(), transition: Transition.size),
    GetPage(name: Routes.reviewSubmitPage, page: () => ReviewSubmittedPage(), transition: Transition.size),
    GetPage(name: Routes.addCard, page: () => AddCardPage(), transition: Transition.size),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ChatPage<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.chatDetailsPage, page: () => ChatDetailScreen(), transition: Transition.fadeIn),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>HomePage<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.homePage, page: () => HomeScreen(), transition: Transition.fadeIn),
    GetPage(name: Routes.notificationsPage, page: () => NotificationsPage(), transition: Transition.fadeIn),
    GetPage(name: Routes.searchPage, page: () => SearchPage(), transition: Transition.fadeIn),
    GetPage(name: Routes.therapistPage, page: () => TherapistProfileScreen(), transition: Transition.fadeIn),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>BookingPage<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.appointmentPage, page: () => AppointmentScreen(), transition: Transition.fadeIn),
    GetPage(name: Routes.customerPreferencesPage, page: () => CustomerPreferencesScreen(), transition: Transition.fadeIn),
    GetPage(name: Routes.appointmentPaymentPage, page: () => AppointmentPaymentScreen(), transition: Transition.fadeIn),
    GetPage(name: Routes.termsAndConditions, page: () => TermsAndConditionsScreen(), transition: Transition.fadeIn),
    GetPage(name: Routes.appointmentDetailsPage, page: () => AppointmentDetailScreen(), transition: Transition.fadeIn),
    GetPage(name: Routes.liveTrackingPage, page: () => LiveTrackingScreen (), transition: Transition.fadeIn),
    GetPage(name: Routes.appointmentRequestPage, page: () => AppointmentRequestPage (), transition: Transition.fadeIn),

    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>Wallet<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.editProfile, page: () => EditProfilePage(), transition: Transition.fadeIn),
    GetPage(name: Routes.fundsWithdrawPage, page: () => FundsWithdrawPage(selectedBank: Get.arguments['selectedBank'],), transition: Transition.fadeIn),
    GetPage(name: Routes.paymentHistoryPage, page: () => PayoutHistoryPage(), transition: Transition.fadeIn),
    GetPage(name: Routes.newPayoutPage, page: () => NewPayoutPage(), transition: Transition.fadeIn),


    ///>>>>>>>>>>>>>>>>>>>>>>>>>>>>>ProfilePage<<<<<<<<<<<<<<<<<<<
    GetPage(name: Routes.editProfile, page: () => EditProfilePage(), transition: Transition.fadeIn),
    GetPage(name: Routes.changePassword, page: () => ChangePasswordPage(), transition: Transition.fadeIn),
    GetPage(name: Routes.inviteFriendPage, page: () => InviteFriendPage(), transition: Transition.fadeIn),
    GetPage(name: Routes.supportPage, page: () => SupportPage(), transition: Transition.fadeIn),
    GetPage(name: Routes.favoriteTherapist, page: () => FavoriteTherapistPage(), transition: Transition.fadeIn),
  ];

}
