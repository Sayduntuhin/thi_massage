import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:toastification/toastification.dart';
import '../../../themes/colors.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_appbar.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../widgets/custom_snackBar.dart';

class SupportPage extends StatefulWidget {
  const SupportPage({super.key});

  @override
  State<SupportPage> createState() => _SupportPageState();
}


class _SupportPageState extends State<SupportPage> {
  Future<bool> launchPnMail(String schema, String path) async {

    Uri uri = Uri(scheme: schema, path: path);
    return await launchUrl(uri);
  }
  Future<void> _launchEmail() async {
    const String emailAddress = 'team.thaimassagenearme@gmail.com';

    try {
      bool canLaunch = await launchPnMail("mailto", emailAddress);
      bool launched = false;

      if (!canLaunch) {
        final List<Uri> emailUris = [
          // Gmail app intent
          Uri.parse('googlegmail://co?to=$emailAddress'),
          // Generic email intent
          Uri(scheme: 'mailto', path: emailAddress),
          // Gmail web interface
          Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=$emailAddress'),
          // Fallback to browser
          Uri.parse('https://gmail.com'),
        ];
        for (Uri uri in emailUris) {
          try {
            if (await canLaunchUrl(uri)) {
              await launchUrl(uri, mode: LaunchMode.externalApplication);
              launched = true;
              AppLogger.debug('Successfully launched email with URI: $uri');
              break;
            }
          } catch (e) {
            AppLogger.debug('Failed to launch with URI $uri: $e');
            continue;
          }
        }

        if (!launched) {
          // If all else fails, copy email to clipboard and show dialog
          _showEmailDialog();
        }
      }
    } catch (e) {
      _showErrorSnackbar('Error opening email: $e');
      AppLogger.error('Error launching email: $e');
      _showEmailDialog();
    }
  }
  void _showEmailDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Contact Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please contact us at:'),
              const SizedBox(height: 10),
              SelectableText(
                'team.thaimassagenearme@gmail.com',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                ),
              ),
              const SizedBox(height: 10),
              const Text('You can copy this email address and paste it into your email app.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyEmailToClipboard();
              },
              child: const Text('Copy Email'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

// Copy email to clipboard
  void _copyEmailToClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: 'team.thaimassagenearme@gmail.com'));
      _showSuccessSnackbar('Email address copied to clipboard!');
    } catch (e) {
      _showErrorSnackbar('Failed to copy email address');
    }
  }

// Function to launch phone call
  Future<void> _launchPhone() async {
    const String phoneNumber = '+16193217743';

    try {
      final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);

      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
        AppLogger.debug('Successfully launched phone dialer');
      } else {
        // Show dialog with phone number if dialer can't be opened
        _showPhoneDialog();
      }
    } catch (e) {
      _showErrorSnackbar('Error making phone call: $e');
      AppLogger.error('Error launching phone: $e');
      _showPhoneDialog();
    }
  }

// Show dialog with phone number
  void _showPhoneDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Call Support'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Please call us at:'),
              const SizedBox(height: 10),
              SelectableText(
                '+1(619)321-7743',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryTextColor,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 10),
              const Text('You can copy this number and dial it manually.'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _copyPhoneToClipboard();
              },
              child: const Text('Copy Number'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

// Copy phone number to clipboard
  void _copyPhoneToClipboard() async {
    try {
      await Clipboard.setData(const ClipboardData(text: '+1(619)321-7743'));
      _showSuccessSnackbar('Phone number copied to clipboard!');
    } catch (e) {
      _showErrorSnackbar('Failed to copy phone number');
    }
  }

// Helper function to show error messages
  void _showErrorSnackbar(String message) {
    CustomSnackBar.show(
      context,
      message,
      type: ToastificationType.error,
    );
  }

// Helper function to show success messages
  void _showSuccessSnackbar(String message) {
    CustomSnackBar.show(
      context,
      message,
      type: ToastificationType.success,
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
     appBar: SecondaryAppBar(title: "Support"),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 24.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 30.h),
            // Title
            Text(
              "Support",
              style: TextStyle(
                fontSize: 28.sp,
                fontWeight: FontWeight.bold,
                color: primaryTextColor,
                fontFamily: "PlayfairDisplay",
              ),
            ),

            SizedBox(height: 5.h),

            // Subtitle
            Text(
              "If you have any query or complaint, \nplease contact,",
              style: TextStyle(
                fontSize: 14.sp,
                color: secounderyTextColor,
                fontFamily: "Urbanist",
              ),
            ),

            SizedBox(height: 30.h),

            // Email Support
            _buildSupportItem(
              icon: Icons.email_outlined,
              text: "team.thaimassagenearme@gmail.com",
              onTap: _launchEmail, // Updated to call _launchEmail

            ),

            SizedBox(height: 20.h),

            // Phone Support
            _buildSupportItem(
              icon: Icons.phone,
              text: "+1(619)321-7743",
              onTap: _launchEmail, // Updated to call _launchEmail

            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportItem({required IconData icon, required String text, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40.w,
            height: 40.h,
            decoration: BoxDecoration(
              color: boxColor,
              shape: BoxShape.circle,
              border: Border.all(color: secounderyBorderColor.withAlpha(60), width: 1.5.w),
            ),
            child: Icon(icon, color: primaryTextColor, size: 22.sp),
          ),
          SizedBox(width: 10.w),
          Text(
            text,
            style: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w500,
              color: primaryTextColor,
              decoration: TextDecoration.underline,
            ),
          ),
        ],
      ),
    );
  }
}
