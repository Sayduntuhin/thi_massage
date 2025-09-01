import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:thi_massage/routers/app_router.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import '../../widgets/custom_appbar.dart';
import '../../../api/api_service.dart';
import 'package:toastification/toastification.dart';
import '../widgets/loading_indicator.dart'; // Import LoadingManager

class MedicalQuestionnaireScreen extends StatefulWidget {
  const MedicalQuestionnaireScreen({super.key});

  @override
  State<MedicalQuestionnaireScreen> createState() => _MedicalQuestionnaireScreenState();
}

class _MedicalQuestionnaireScreenState extends State<MedicalQuestionnaireScreen> {
  // Question 1 - Where are you feeling pain?
  bool q1Head = false;
  bool q1Neck = false;
  bool q1Shoulder = false;
  bool q1Others = false;
  TextEditingController q1OthersController = TextEditingController();

  // Question 2 - What kind of pain are you feeling?
  bool q2Yourself = false;
  bool q2Outside = false;
  bool q2Sharp = false;
  bool q2Others = false;
  TextEditingController q2OthersController = TextEditingController();

  // Question 3 - How severe is the pain? (0-10)
  double painSeverity = 5.0;

  // Question 4 - How long have you been feeling this pain?
  String painDuration = '';

  // Question 5 - Have you had massage or any treatment for this pain before?
  String previousTreatment = '';
  TextEditingController previousTreatmentController = TextEditingController();

  // Question 6 - What do you hope to get from today's massage?
  bool q6ReduceStress = false;
  bool q6Rejuvenated = false;
  bool q6MentalRelaxation = false;
  bool q6BetterSleep = false;
  bool q6Others = false;
  TextEditingController q6OthersController = TextEditingController();

  // Question 7 - What is your daily lifestyle like?
  bool q7ComputerWork = false;
  bool q7Construction = false;
  bool q7HeavyObjects = false;
  bool q7LongHours = false;

  // Question 8 - Have you ever been told by a doctor about muscle or bone-related problems?
  String doctorAdvice = '';
  TextEditingController doctorAdviceController = TextEditingController();

  // Question 9 - Is there anything else you would like to tell your therapist?
  TextEditingController additionalInfoController = TextEditingController();

  // Terms and conditions
  bool agreeTerms = false;

  // API Service and booking ID
  final ApiService apiService = ApiService();
  late final int? bookingId;

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    bookingId = arguments?['booking_id'] as int? ?? 0;
    AppLogger.debug('Medical Questionnaire Screen initialized with booking_id: $bookingId');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Medical Questionnaire"),
      body: SingleChildScrollView(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10.r,
                offset: Offset(0, 2.h),
              ),
            ],
          ),
          padding: EdgeInsets.all(24.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Please answer the questions below so we can make your massage more effective',
                style: TextStyle(
                  color: buttonTextColor,
                  fontSize: 14.sp,
                  height: 1.5,
                ),
              ),
              SizedBox(height: 15.h),

              // Q1: Where are you feeling pain?
              _buildQuestion(
                'Q1. Where are you feeling pain?',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckboxOption('Head', q1Head, (value) => setState(() => q1Head = value!)),
                    _buildCheckboxOption('Neck', q1Neck, (value) => setState(() => q1Neck = value!)),
                    _buildCheckboxOption('Shoulder', q1Shoulder, (value) => setState(() => q1Shoulder = value!)),
                    _buildCheckboxOption('Others', q1Others, (value) => setState(() => q1Others = value!)),
                    if (q1Others) ...[
                      SizedBox(height: 8.h),
                      Text('If others, please specify:', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp)),
                      SizedBox(height: 8.h),
                      _buildTextInput(q1OthersController),
                    ],
                  ],
                ),
              ),

              // Q2: What kind of pain are you feeling?
              _buildQuestion(
                'Q2. What kind of pain are you feeling?',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckboxOption('Tight/Stiff', q2Yourself, (value) => setState(() => q2Yourself = value!)),
                    _buildCheckboxOption('Dull ache', q2Outside, (value) => setState(() => q2Outside = value!)),
                    _buildCheckboxOption('Sharp', q2Sharp, (value) => setState(() => q2Sharp = value!)),
                    _buildCheckboxOption('Others', q2Others, (value) => setState(() => q2Others = value!)),
                    if (q2Others) ...[
                      SizedBox(height: 8.h),
                      Text('If others, please specify:', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp)),
                      SizedBox(height: 8.h),
                      _buildTextInput(q2OthersController),
                    ],
                  ],
                ),
              ),

              // Q3: How severe is the pain? (0-10)
              _buildQuestion(
                'Q3. How severe is the pain? (0-10)',
                Column(
                  children: [
                    Slider(
                      value: painSeverity,
                      min: 0,
                      max: 10,
                      divisions: 10,
                      label: painSeverity.round().toString(),
                      activeColor: buttonTextColor,
                      onChanged: (value) => setState(() => painSeverity = value),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 20.w),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('0', style: TextStyle(color: Colors.grey[600], fontSize: 12.sp)),
                          Text('10', style: TextStyle(color: Colors.grey[600], fontSize: 12.sp)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Q4: How long have you been feeling this pain?
              _buildQuestion(
                'Q4. How long have you been feeling this pain?',
                Column(
                  children: [
                    _buildRadioOption('1-3 days', painDuration, (value) => setState(() => painDuration = value!)),
                    _buildRadioOption('3-7 days', painDuration, (value) => setState(() => painDuration = value!)),
                    _buildRadioOption('More than 1 week', painDuration, (value) => setState(() => painDuration = value!)),
                    _buildRadioOption('Chronic', painDuration, (value) => setState(() => painDuration = value!)),
                  ],
                ),
              ),

              // Q5: Have you had massage or any treatment for this pain before?
              _buildQuestion(
                'Q5. Have you had massage or any treatment for this pain before?',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildRadioButton('Yes', previousTreatment, (value) => setState(() => previousTreatment = value!)),
                        SizedBox(width: 30.w),
                        _buildRadioButton('No', previousTreatment, (value) => setState(() => previousTreatment = value!)),
                      ],
                    ),
                    if (previousTreatment == 'Yes') ...[
                      SizedBox(height: 15.h),
                      Text('If yes, how?', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp)),
                      SizedBox(height: 8.h),
                      _buildTextInput(previousTreatmentController),
                    ],
                  ],
                ),
              ),

              // Q6: What do you hope to get from today's massage?
              _buildQuestion(
                'Q6. What do you hope to get from today\'s massage?',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildCheckboxOption('Release tension', q6ReduceStress, (value) => setState(() => q6ReduceStress = value!)),
                    _buildCheckboxOption('Pain relief', q6Rejuvenated, (value) => setState(() => q6Rejuvenated = value!)),
                    _buildCheckboxOption('Mental relaxation', q6MentalRelaxation, (value) => setState(() => q6MentalRelaxation = value!)),
                    _buildCheckboxOption('Better sleep', q6BetterSleep, (value) => setState(() => q6BetterSleep = value!)),
                    _buildCheckboxOption('Others', q6Others, (value) => setState(() => q6Others = value!)),
                    if (q6Others) ...[
                      SizedBox(height: 8.h),
                      Text('If others, please specify:', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp)),
                      SizedBox(height: 8.h),
                      _buildTextInput(q6OthersController),
                    ],
                  ],
                ),
              ),

              // Q7: What is your daily lifestyle like?
              _buildQuestion(
                'Q7. What is your daily lifestyle like?',
                Column(
                  children: [
                    _buildCheckboxOption('Desk/computer work', q7ComputerWork, (value) => setState(() => q7ComputerWork = value!)),
                    _buildCheckboxOption('Construction', q7Construction, (value) => setState(() => q7Construction = value!)),
                    _buildCheckboxOption('Lifting heavy objects', q7HeavyObjects, (value) => setState(() => q7HeavyObjects = value!)),
                    _buildCheckboxOption('Working long hours', q7LongHours, (value) => setState(() => q7LongHours = value!)),
                  ],
                ),
              ),

              // Q8: Have you ever been told by a doctor about muscle or bone-related problems?
              _buildQuestion(
                'Q8. Have you ever been told by a doctor about muscle or bone-related problems?',
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        _buildRadioButton('Yes', doctorAdvice, (value) => setState(() => doctorAdvice = value!)),
                        SizedBox(width: 30.w),
                        _buildRadioButton('No', doctorAdvice, (value) => setState(() => doctorAdvice = value!)),
                      ],
                    ),
                    if (doctorAdvice == 'Yes') ...[
                      SizedBox(height: 15.h),
                      Text('If yes, how?', style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp)),
                      SizedBox(height: 8.h),
                      _buildTextInput(doctorAdviceController),
                    ],
                  ],
                ),
              ),

              // Q9: Is there anything else you would like to tell your therapist?
              _buildQuestion(
                'Q9. Is there anything else you would like to tell your therapist?',
                _buildTextInput(additionalInfoController, maxLines: 4),
              ),

              SizedBox(height: 15.h),

              // Terms and conditions
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 25.w,
                    height: 20.h,
                    child: Checkbox(
                      value: agreeTerms,
                      onChanged: (value) => setState(() => agreeTerms = value!),
                      activeColor: buttonTextColor,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'I agree all the terms & conditions',
                      style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp),
                    ),
                  ),
                ],
              ),

              SizedBox(height: 10.h),

              Text(
                'I acknowledge that this is an agreement result service and not medical advice',
                style: TextStyle(color: Color(0xffB28D28), fontSize: 12.sp, fontWeight: FontWeight.w400),
              ),

              SizedBox(height: 30.h),

              // Submit button
              GestureDetector(
                onTap: () {
                  if (!agreeTerms) {
                    CustomSnackBar.show(
                      context,
                      'Please agree to the terms and conditions',
                      type: ToastificationType.error,
                    );
                    return;
                  }
                  _submitForm();
                },
                child: CustomGradientButton(
                  text: "Submit",
                  onPressed: agreeTerms ? _submitForm : () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuestion(String title, Widget content) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: buttonTextColor,
              fontSize: 20.sp,
            ),
          ),
          SizedBox(height: 12.h),
          content,
        ],
      ),
    );
  }

  Widget _buildCheckboxOption(String text, bool value, Function(bool?) onChanged) {
    return Row(
      children: [
        Checkbox(
          value: value,
          onChanged: onChanged,
          activeColor: buttonTextColor,
        ),
        Text(
          text,
          style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildRadioOption(String text, String groupValue, Function(String?) onChanged) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      child: Row(
        children: [
          Radio<String>(
            value: text,
            groupValue: groupValue,
            onChanged: onChanged,
            activeColor: buttonTextColor,
          ),
          Text(
            text,
            style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp),
          ),
        ],
      ),
    );
  }

  Widget _buildRadioButton(String text, String groupValue, Function(String?) onChanged) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Radio<String>(
          value: text,
          groupValue: groupValue,
          onChanged: onChanged,
          activeColor: buttonTextColor,
        ),
        Text(
          text,
          style: TextStyle(color: Color(0xFF1F1F1F), fontSize: 14.sp),
        ),
      ],
    );
  }

  Widget _buildTextInput(TextEditingController controller, {int maxLines = 1}) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        decoration: InputDecoration(
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(12.w),
          hintText: 'Type here',
          hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14.sp),
        ),
        style: TextStyle(fontSize: 14.sp),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (bookingId == null || bookingId == 0) {
      CustomSnackBar.show(
        context,
        'Invalid booking ID',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }

    // Validate required fields
    if (!q1Head && !q1Neck && !q1Shoulder && !q1Others) {
      CustomSnackBar.show(
        context,
        'Please select at least one pain location for Q1',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (q1Others && q1OthersController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context,
        'Please specify the "Others" pain location for Q1',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (!q2Yourself && !q2Outside && !q2Sharp && !q2Others) {
      CustomSnackBar.show(
        context,
        'Please select at least one pain type for Q2',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (q2Others && q2OthersController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context,
        'Please specify the "Others" pain type for Q2',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (painDuration.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please select a pain duration for Q4',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (previousTreatment.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please answer Q5 about previous treatment',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (previousTreatment == 'Yes' && previousTreatmentController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context,
        'Please provide details for previous treatment in Q5',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (!q6ReduceStress && !q6Rejuvenated && !q6MentalRelaxation && !q6BetterSleep && !q6Others) {
      CustomSnackBar.show(
        context,
        'Please select at least one massage goal for Q6',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (q6Others && q6OthersController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context,
        'Please specify the "Others" massage goal for Q6',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (!q7ComputerWork && !q7Construction && !q7HeavyObjects && !q7LongHours) {
      CustomSnackBar.show(
        context,
        'Please select at least one lifestyle factor for Q7',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (doctorAdvice.isEmpty) {
      CustomSnackBar.show(
        context,
        'Please answer Q8 about diagnosed conditions',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }
    if (doctorAdvice == 'Yes' && doctorAdviceController.text.trim().isEmpty) {
      CustomSnackBar.show(
        context,
        'Please provide details for diagnosed conditions in Q8',
        type: ToastificationType.error,
      );
      LoadingManager.hideLoading(); // Ensure loading is hidden
      return;
    }

    try {
      LoadingManager.showLoading(); // Show loading indicator
      AppLogger.debug('Starting form submission for booking_id: $bookingId');

      final painLocations = <String>[];
      if (q1Head) painLocations.add('Head');
      if (q1Neck) painLocations.add('Neck');
      if (q1Shoulder) painLocations.add('Shoulder');

      final painTypes = <String>[];
      if (q2Yourself) painTypes.add('Tight/Stiff');
      if (q2Outside) painTypes.add('Dull ache');
      if (q2Sharp) painTypes.add('Sharp');

      final massageGoals = <String>[];
      if (q6ReduceStress) massageGoals.add('Release tension');
      if (q6Rejuvenated) massageGoals.add('Pain relief');
      if (q6MentalRelaxation) massageGoals.add('Mental relaxation');
      if (q6BetterSleep) massageGoals.add('Better sleep');

      final lifestyleFactors = <String>[];
      if (q7ComputerWork) lifestyleFactors.add('Desk/computer work');
      if (q7Construction) lifestyleFactors.add('Construction');
      if (q7HeavyObjects) lifestyleFactors.add('Lifting heavy objects');
      if (q7LongHours) lifestyleFactors.add('Working long hours');

      final formData = {
        'pain_locations': painLocations,
        'other_pain_location': q1Others ? q1OthersController.text.trim() : null,
        'pain_types': painTypes,
        'other_pain_type': q2Others ? q2OthersController.text.trim() : null,
        'pain_severity': painSeverity.round(),
        'pain_duration': painDuration.isNotEmpty ? painDuration : null,
        'previous_treatment': previousTreatment == 'Yes',
        'previous_treatment_details': previousTreatment == 'Yes' ? previousTreatmentController.text.trim() : null,
        'massage_goals': massageGoals,
        'other_massage_goal': q6Others ? q6OthersController.text.trim() : null,
        'lifestyle_factors': lifestyleFactors,
        'diagnosed_condition': doctorAdvice == 'Yes',
        'diagnosed_condition_details': doctorAdvice == 'Yes' ? doctorAdviceController.text.trim() : null,
        'additional_notes': additionalInfoController.text.trim().isNotEmpty ? additionalInfoController.text.trim() : null,
        'agreed_to_terms': agreeTerms,
      };

      AppLogger.debug('Submitting form data to API: $formData');
      await apiService.submitMedicalQuestionnaire(bookingId!, formData);
      AppLogger.debug('Form submission successful for booking_id: $bookingId');

      // Ensure loading is hidden before navigation
      LoadingManager.hideLoading();
      CustomSnackBar.show(
        context,
        'Form submitted successfully!',
        type: ToastificationType.success,
      );

      // Navigate with timeout and error handling
      AppLogger.debug('Attempting navigation to /liveTrackingPage with booking_id: $bookingId');
      try {
        await Get.toNamed('/liveTrackingPage', arguments: {'booking_id': bookingId});
        AppLogger.debug('Navigation to /liveTrackingPage successful');
      } catch (e) {
        AppLogger.error('Navigation error: $e');
        CustomSnackBar.show(
          context,
          'Navigation failed: $e',
          type: ToastificationType.error,
        );
      }
    } catch (e) {
      AppLogger.error('Form submission error: $e');
      String errorMessage = 'Failed to submit form: $e';
      if (e is NetworkException) {
        errorMessage = 'Network error: Please check your internet connection.';
      } else if (e is UnauthorizedException) {
        errorMessage = 'Authentication failed: Please log in again.';
      } else if (e is ServerException) {
        errorMessage = 'Server error: Please try again later.';
      } else if (e is BadRequestException) {
        errorMessage = e.message;
      }
      CustomSnackBar.show(
        context,
        errorMessage,
        type: ToastificationType.error,
      );
    } finally {
      // Ensure loading is hidden even if an error occurs
      LoadingManager.hideLoading();
      AppLogger.debug('Loading indicator hidden');
    }
  }

  @override
  void dispose() {
    q1OthersController.dispose();
    q2OthersController.dispose();
    q6OthersController.dispose();
    previousTreatmentController.dispose();
    doctorAdviceController.dispose();
    additionalInfoController.dispose();
    super.dispose();
  }
}