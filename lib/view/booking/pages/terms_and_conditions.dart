import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';

class TermsAndConditionsScreen extends StatelessWidget {
  const TermsAndConditionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Terms and Conditions"),
      backgroundColor: Colors.white,
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Terms & Conditions of Use",
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8.h),
            RichText(
              text: TextSpan(
                text: "Effective Date: ",
                style: TextStyle(fontSize: 14.sp, color: Colors.black),
                children: [
                  TextSpan(
                    text: "March 2025",
                    style: TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(fontSize: 14.sp, color: Colors.black),
                    children: [
                      TextSpan(
                        text: "General; Use of this Site\n",
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                          color: Colors.deepOrange,
                        ),
                        recognizer: TapGestureRecognizer()
                          ..onTap = () {
                            // Handle link tap (optional)
                          },
                      ),
                      const TextSpan(text: "\n"),
                      TextSpan(
                        text:
                        "These terms and conditions set forth in this website (\"this Site\") and any related mobile applications (\"Apps\") constitute an agreement (\"this agreement\") between you (\"you\" or \"Customer\") and Thai Massage Near Me (\"we\" or \"This Massage Near Me\"). This agreement governs your access to and use of www.thaimassagenearme.com and any Thai Massage Near Me software, Apps, and services (collectively the \"Services\").\n\n",
                      ),
                      TextSpan(
                        text:
                        "We reserve the right to change the terms and conditions of this agreement or to modify or discontinue the Services offered by us at any time. Those changes will go into effect on the effective date shown in any revised agreement. If we change this agreement, we will give you notice by posting the revised agreement on the applicable website(s) or app(s) and/or by sending an email notice to you using the contact information provided by you. Therefore, you agree to keep your contact information up to date, and that notice sent to the last email address you provided shall be considered effective. We also encourage you to check this agreement from time to time to see if it has been updated.\n\n",
                      ),
                      TextSpan(
                        text:
                        "We may require you to affirmatively acknowledge the updated agreement before further use of the Services is permitted. However, by continuing to use any Services after...",
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
