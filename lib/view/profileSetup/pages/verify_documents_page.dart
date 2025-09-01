import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:file_picker/file_picker.dart';
import 'package:toastification/toastification.dart';
import 'dart:io';
import 'dart:convert'; // For base64Encode
import '../../../api/api_service.dart';
import '../../../themes/colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_gradientButton.dart';
import '../../widgets/custom_snackBar.dart';
import '../widgets/step_progress_indicator.dart';
import '../../../view/widgets/app_logger.dart'; // Import AppLogger

class VerifyDocumentsPage extends StatefulWidget {
  const VerifyDocumentsPage({super.key});

  @override
  State<VerifyDocumentsPage> createState() => _VerifyDocumentsPageState();
}

class _VerifyDocumentsPageState extends State<VerifyDocumentsPage> {
  final Color _borderColor = const Color(0xFFD0A12D);
  Map<String, Map<String, dynamic>> uploadedFiles = {}; // Tracks file data and IDs
  bool _isLoading = false; // Loading state for uploads and submit

  final List<Map<String, dynamic>> documents = [
    {'title': 'id_document', 'isExpanded': true, 'type': 'dropdown'},
    {'title': 'ssn_or_ittn', 'isExpanded': false, 'type': 'dropdown'},
    {'title': 'drivers_license', 'isExpanded': false, 'type': 'dropdown'},
    {'title': 'liability_insurance', 'isExpanded': false, 'type': 'dropdown'},
    {'title': 'certifications', 'isExpanded': false, 'type': 'dropdown'},
    {'title': 'therapist_agreement', 'isExpanded': false, 'type': 'dropdown'},
    {'title': 'tax_form', 'isExpanded': false, 'type': 'dropdown'},
  ];

  @override
  void initState() {
    super.initState();
  }

  void _toggleExpanded(int index) {
    setState(() {
      for (int i = 0; i < documents.length; i++) {
        if (i != index && documents[i]['type'] == 'dropdown') {
          documents[i]['isExpanded'] = false;
        }
      }
      if (documents[index]['type'] == 'dropdown') {
        documents[index]['isExpanded'] = !documents[index]['isExpanded'];
      }
    });
  }

  Future<void> _pickAndUploadFile(String title) async {
    if (!mounted) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        AppLogger.debug('Selected file: ${file.name}, Size: ${file.size} bytes');

        if (file.path == null) {
          if (mounted) {
            CustomSnackBar.show(context, 'Invalid file path. Please try again.', type: ToastificationType.error);
          }
          return;
        }

        if (mounted) {
          setState(() {
            uploadedFiles[title] = {
              'name': file.name,
              'size': '${(file.size / 1024).toStringAsFixed(2)} kb',
              'file': File(file.path!),
              'id': null, // Initialize id as null
            };
          });
          AppLogger.debug('State updated - uploadedFiles[$title]: ${uploadedFiles[title]}');
        }
      }
    } catch (e) {
      AppLogger.error('Error picking file: $e');
      if (mounted) {
        CustomSnackBar.show(context, 'Error picking file. Please try again.', type: ToastificationType.error);
      }
    }
  }

  Future<void> _submitForReview() async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
    });

    final apiService = ApiService();
    final userId = Get.arguments?['user_id'] as int? ?? 0;
    AppLogger.debug('Attempting submit with userId: $userId');

    if (userId == 0) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(context, 'Invalid user ID. Please ensure user is logged in.', type: ToastificationType.error);
      }
      return;
    }

    // Validate that the first 4 documents are uploaded
    const requiredDocuments = ['id_document', 'ssn_or_ittn', 'drivers_license', 'liability_insurance'];
    bool allRequiredUploaded = true;
    for (var doc in requiredDocuments) {
      if (!uploadedFiles.containsKey(doc) || uploadedFiles[doc]?['file'] == null) {
        allRequiredUploaded = false;
        break;
      }
    }

    if (!allRequiredUploaded) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        CustomSnackBar.show(context, 'Please upload all required documents (ID, SSN/ITIN, Driver\'s License, Liability Insurance) before submitting.', type: ToastificationType.error);
      }
      return;
    }

    try {
      // Prepare payload with base64-encoded files
      final Map<String, dynamic> payload = {
        'user_id': userId, // Keep as int, let the API service handle conversion
      };

      const allFields = ['id_document', 'ssn_or_ittn', 'drivers_license', 'liability_insurance', 'certifications', 'therapist_agreement', 'tax_form'];

      // Process files and encode to base64
      for (var field in allFields) {
        final fileData = uploadedFiles[field];
        if (fileData != null && fileData['file'] != null) {
          try {
            final File file = fileData['file'] as File;
            final bytes = await file.readAsBytes();
            final base64String = base64Encode(bytes);

            payload[field] = {
              'name': fileData['name'] as String,
              'file': base64String,
            };

            AppLogger.debug('Processed file for $field: ${fileData['name']}, size: ${bytes.length} bytes');
          } catch (e) {
            AppLogger.error('Error processing file for $field: $e');
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
              CustomSnackBar.show(context, 'Error processing file: ${fileData['name']}. Please try again.', type: ToastificationType.error);
            }
            return;
          }
        }
      }

      AppLogger.debug('Submit payload prepared with ${payload.length} fields');

      final response = await apiService.submitDocuments(payload);

      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        AppLogger.debug('API response: $response');

        if (response != null && response.containsKey('id')) {
          AppLogger.info('Documents submitted successfully: $response');

          // Update the uploadedFiles with the document record ID
          final documentRecordId = response['id'];
          AppLogger.debug('Document record created with ID: $documentRecordId');

          // Update file paths from response if provided
          const allFields = ['id_document', 'ssn_or_ittn', 'drivers_license', 'liability_insurance', 'certifications', 'therapist_agreement', 'tax_form'];
          for (var field in allFields) {
            if (response.containsKey(field) && response[field] != null && uploadedFiles.containsKey(field)) {
              setState(() {
                uploadedFiles[field]!['server_path'] = response[field];
                uploadedFiles[field]!['record_id'] = documentRecordId;
              });
            }
          }

          AppLogger.debug('Updated uploadedFiles with server paths');
          Get.toNamed('/reviewSubmittedPage');
        } else {
          final errorMessage = response?['message'] ?? response?['error'] ?? 'Failed to submit documents. Please try again.';
          AppLogger.debug('Submission failed: $response');
          CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
        }
      }
    } catch (e) {
      AppLogger.error('Error submitting documents: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });

        String errorMessage = 'An error occurred. Please try again.';

        // Provide more specific error messages based on exception type
        if (e.toString().contains('NetworkException')) {
          errorMessage = 'Network error. Please check your connection and try again.';
        } else if (e.toString().contains('BadRequestException')) {
          errorMessage = 'Invalid file format or data. Please check your documents and try again.';
        } else if (e.toString().contains('ServerException')) {
          errorMessage = 'Server error. Please try again later.';
        }

        CustomSnackBar.show(context, errorMessage, type: ToastificationType.error);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLogger.debug('Building VerifyDocumentsPage - uploadedFiles: $uploadedFiles');
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const CustomAppBar(),
              SizedBox(height: 20.h),
              Text("Verify Documents", style: TextStyle(fontSize: 30.sp, fontWeight: FontWeight.bold, fontFamily: "PlayfairDisplay", color: primaryTextColor)),
              SizedBox(height: 6.h),
              Text("Please upload the below mentioned documents", style: TextStyle(fontSize: 14.sp, color: Colors.black54)),
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
                        if (index < documents.length - 1)
                          Divider(height: 1, thickness: 0.7, color: Colors.grey.shade300),
                      ],
                    );
                  },
                ),
              ),
              if (_isLoading)
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 10.h),
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_borderColor),
                    minHeight: 4.h,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                ),
              CustomGradientButton(
                text: "Submit for Review",
                onPressed: _submitForReview,
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
    AppLogger.debug('Rendering _buildUploadCard for $title, uploadedFile: $uploadedFile');

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
                      onTap: () => _pickAndUploadFile(title),
                      child: Text(
                        "browse",
                        style: TextStyle(
                          fontSize: 14.sp,
                          color: _borderColor,
                          fontWeight: FontWeight.bold,
                          decoration: TextDecoration.underline,
                          decorationColor: _borderColor,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 4.h),
                Text("Supported format: JPG, PNG, PDF", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
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
                _isLoading
                    ? SizedBox(
                  width: 20.sp,
                  height: 20.sp,
                  child: LinearProgressIndicator(
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(_borderColor),
                    minHeight: 4.h,
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                )
                    : GestureDetector(
                  onTap: () => _pickAndUploadFile(title), // Re-upload to change file
                  child: Text(
                    "Change",
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: _borderColor,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                      decorationColor: _borderColor,
                    ),
                  ),
                ),
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
          AppLogger.debug('Background Check button tapped');
        },
      ),
    );
  }
}