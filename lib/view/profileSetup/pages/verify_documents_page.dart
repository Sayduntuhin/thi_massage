import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_gradientButton.dart';
import '../widgets/step_progress_indicator.dart';

class VerifyDocumentsPage extends StatefulWidget {
  const VerifyDocumentsPage({super.key});

  @override
  State<VerifyDocumentsPage> createState() => _VerifyDocumentsPageState();
}

class _VerifyDocumentsPageState extends State<VerifyDocumentsPage> {
  final Color _borderColor = const Color(0xFFD0A12D);
  Map<String, Map<String, String>> uploadedFiles = {};

  // List of documents with their expanded state and type
  final List<Map<String, dynamic>> documents = [
    {'title': 'ID Document', 'isExpanded': true, 'type': 'dropdown'}, // Initially expanded
    {'title': 'SSN or ITIN', 'isExpanded': false, 'type': 'dropdown'},
    {'title': 'Driver\'s License', 'isExpanded': false, 'type': 'dropdown'},
    {'title': 'Liability Insurance', 'isExpanded': false, 'type': 'dropdown'},
    {'title': 'Background Check', 'isExpanded': false, 'type': 'button'},
    {'title': 'Additional Documents', 'isExpanded': false, 'type': 'text'},
    {'title': 'Therapists Agreement', 'isExpanded': false, 'type': 'dropdown'},
    {'title': '1099 Tax Forms', 'isExpanded': false, 'type': 'dropdown'},
  ];

  // Function to toggle the expanded state of a document
  void _toggleExpanded(int index) {
    setState(() {
      // Collapse all other dropdown fields
      for (int i = 0; i < documents.length; i++) {
        if (i != index && documents[i]['type'] == 'dropdown') {
          documents[i]['isExpanded'] = false;
        }
      }
      // Toggle the tapped field (if it's a dropdown)
      if (documents[index]['type'] == 'dropdown') {
        documents[index]['isExpanded'] = !documents[index]['isExpanded'];
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomAppBar(), // Back Button + Logo
              SizedBox(height: 20.h),

              // Title
              Text(
                "Verify Documents",
                style: TextStyle(
                  fontSize: 30.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: "PlayfairDisplay",
                  color: primaryTextColor,
                ),
              ),
              SizedBox(height: 6.h),

              Text(
                "Please upload the below mentioned documents",
                style: TextStyle(fontSize: 14.sp, color: Colors.black54),
              ),
              SizedBox(height: 18.h),

              const StepProgressIndicator(currentStep: 2),
              SizedBox(height: 20.h),

              Expanded(
                child: ListView.builder(
                  itemCount: documents.length,
                  itemBuilder: (context, index) {
                    final document = documents[index];
                    final String title = document['title'] as String;
                    final bool isExpanded = document['isExpanded'] as bool;
                    final String type = document['type'] as String;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (type == 'dropdown') ...[
                          _buildArrowTile(
                            title: title,
                            isExpanded: isExpanded,
                            onTap: () => _toggleExpanded(index),
                          ),
                          if (isExpanded) ...[
                            _buildUploadCard(title: title),
                          ],
                        ] else if (type == 'button') ...[
                          _buildButton(title: title),
                        ] else if (type == 'text') ...[
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 14.h),
                            child: Text(
                              title,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                                color: const Color(0xFF666561),
                              ),
                            ),
                          ),
                        ],
                        if (index < documents.length - 1) // Add divider except for the last item
                          Divider(height: 1, thickness: 0.7, color: Colors.grey.shade300),
                      ],
                    );
                  },
                ),
              ),

              // Submit Button
              CustomGradientButton(
                text: "Submit for Review",
                onPressed: () {
                  // Handle submit action
                  Get.toNamed('/reviewSubmitPage'); // or dashboard
                },
              ),
              SizedBox(height: 20.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUploadCard({required String title}) {
    final uploadedFile = uploadedFiles[title];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (uploadedFile == null)
          Container(
            padding: EdgeInsets.all(16.r),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12.r),
              border: Border.all(color: _borderColor, width: 1.2),
              color: const Color(0xFFFDF7E8),
            ),
            child: Column(
              children: [
                Icon(Icons.folder_open_outlined, color: _borderColor, size: 40.sp),
                SizedBox(height: 8.h),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text("Upload your $title ", style: TextStyle(fontSize: 14.sp)),
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          uploadedFiles[title] = {
                            'name': "${title.toLowerCase().replaceAll(' ', '_')}.pdf",
                            'size': "18 kb",
                          };
                        });
                      },
                      child: Text(
                        "browse",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _borderColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline, // Added underline
                          decorationColor: _borderColor, // Match underline color to text color
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text(
                  "Supported format: JPG, PNG, PDF",
                  style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                ),
              ],
            ),
          )
        else
          Container(
            padding: EdgeInsets.all(14.r),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF7E8),
              border: Border.all(color: _borderColor, width: 1.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Row(
              children: [
                Icon(Icons.insert_drive_file_outlined, color: _borderColor),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        uploadedFile['name'] ?? '',
                        style: TextStyle(fontSize: 13.sp, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        uploadedFile['size'] ?? '',
                        style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.check_circle, color: Colors.green, size: 20.sp),
              ],
            ),
          ),
        SizedBox(height: 20.h),
      ],
    );
  }

  Widget _buildArrowTile({
    required String title,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600),
      ),
      trailing: Icon(
        isExpanded ? Icons.expand_less : Icons.chevron_right,
        color: Colors.black,
      ),
      onTap: onTap,
    );
  }

  Widget _buildButton({required String title}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 14.h),
      child: ThaiMassageButton(
        text: title,
        isPrimary: true,
        onPressed: () {
          // Background check logic
          print('Background Check button tapped');
        },
      ),
    );
  }
}