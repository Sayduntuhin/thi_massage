import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:get/get.dart';
import 'package:thi_massage/themes/colors.dart';
import '../../../api/api_service.dart';
import '../../widgets/custom_appbar.dart';

class BookingInfoPage extends StatelessWidget {
  const BookingInfoPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Initialize ScreenUtil (ensure this is called at a higher level like main.dart in a real app)
    ScreenUtil.init(context, designSize: const Size(360, 800)); // Adjust designSize based on your design spec

    // Retrieve bookingDetails from Get.arguments
    final bookingDetails = Get.arguments as Map<String, dynamic>? ?? {};
    final client = bookingDetails['client'] ?? {};
    final location = bookingDetails['location'] ?? {};
    final preferences = bookingDetails['preferences'] ?? {};
    final addOns = bookingDetails['add_ons'] ?? [];
    final aiSymptomCheck = bookingDetails['ai_symptom_check'] ?? {};
    final aiAnalysis = aiSymptomCheck['ai_analysis_result'] ?? {};

    return Scaffold(
      appBar: SecondaryAppBar(title: "Client Booking Info"),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Client Information Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  CachedNetworkImage(
                    imageUrl: '${ApiService.baseUrl}/client${client['image'] ?? 'https://via.placeholder.com/150'}',
                    imageBuilder: (context, imageProvider) => CircleAvatar(
                      radius: 60.r,
                      backgroundImage: imageProvider,
                    ),
                    placeholder: (context, url) => CircleAvatar(
                      radius: 60.r,
                      child: Center(child: CircularProgressIndicator(color: primaryButtonColor)),
                    ),
                    errorWidget: (context, url, error) => CircleAvatar(
                      radius: 60.r,
                      child: Icon(Icons.error, color: Colors.red, size: 30.sp),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10.h),
                      Text(
                        '${client['name'] ?? 'Unknown'} ${client['gender'] == 'male' ? '♂' : '♀'}',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        'Age Not Specified', // Assuming age is not in the API response
                        textAlign: TextAlign.center,
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey),
                      ),
                      SizedBox(height: 8.h),
                      Container(
                        width: 0.35.sw, // Screen width percentage
                        decoration: BoxDecoration(
                          color: secounderyBorderColor.withAlpha(80),
                          borderRadius: BorderRadius.circular(10.r),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Text(
                            client['is_returning'] == true ? "Returning Customer" : "New Customer",
                            style: TextStyle(fontSize: 12.sp, color: buttonTextColor),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Appointment Details Section
            _buildSectionTitle('Appointment Details', Icons.favorite),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                children: [
                  // Massage Type and Duration Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Massage Type Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Massage Type',
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              bookingDetails['massage_type'] ?? 'N/A',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20.w),
                      // Duration Column
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Duration',
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              '${bookingDetails['duration_minutes'] ?? 0} minutes',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Date Row
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 18.sp, color: primaryButtonColor),
                      SizedBox(width: 8.w),
                      Text(
                        bookingDetails['date_scheduled'] ?? 'N/A',
                        style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  // Status Row
                  Row(
                    children: [
                      Text(
                        'Status',
                        style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                      ),
                      SizedBox(width: 15.w),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 4.h),
                        decoration: BoxDecoration(
                          color: Color(0xFFFEF9C3),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          'Pending', // Adjust if status is in the API response
                          style: TextStyle(fontSize: 12.sp, color: Colors.black, fontWeight: FontWeight.w500),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Location Details Section
            _buildSectionTitle('Locations Details', Icons.location_on),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Location Type
                  Text(
                    'Location Type',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    location['venue'] ?? 'N/A',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  SizedBox(height: 20.h),
                  // Address
                  Row(
                    children: [
                      Icon(Icons.location_on, size: 20.sp, color: primaryButtonColor),
                      SizedBox(width: 8.w),
                      Text(
                        'Coordinates: ${bookingDetails['map']['latitude'] ?? 'N/A'}, ${bookingDetails['map']['longitude'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16.sp, color: primaryButtonColor),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Floor and Elevator Row
                  Row(
                    children: [
                      // Floor
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.business, size: 20.sp, color: Colors.grey[600]),
                            SizedBox(width: 8.w),
                            Text(
                              'Floor: ',
                              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                            ),
                            Text(
                              '${location['number_of_floors'] ?? 'N/A'}',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      // Elevator
                      Row(
                        children: [
                          Icon(Icons.check_circle, size: 20.sp, color: location['elevator_or_escalator'] == true ? Colors.green : Colors.grey),
                          SizedBox(width: 8.w),
                          Text(
                            'Elevator',
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  // Parking and Pet Row
                  Row(
                    children: [
                      // Parking
                      Expanded(
                        child: Row(
                          children: [
                            Icon(Icons.directions_car, size: 20.sp, color: Colors.grey[600]),
                            SizedBox(width: 8.w),
                            Text(
                              'Parking: ',
                              style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                            ),
                            Text(
                              location['parking'] ?? 'N/A',
                              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      // Pet
                      Row(
                        children: [
                          Icon(Icons.pets, size: 20.sp, color: location['pet'] == true ? primaryButtonColor : Colors.grey),
                          SizedBox(width: 8.w),
                          Text(
                            'Pet: ',
                            style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                          ),
                          Text(
                            location['pet'] == true ? 'Yes' : 'No',
                            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500, color: location['pet'] == true ? primaryButtonColor : Colors.black),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Preferences & Needs Section
            _buildSectionTitle('Preferences & Needs', Icons.settings),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preferred Modality and Pressure Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Preferred Modality
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferred Modality',
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              preferences['preferred_modality'] ?? 'N/A',
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 20.w),
                      // Preferred Pressure
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Preferred Pressure',
                              style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                            ),
                            SizedBox(height: 8.h),
                            Text(
                              preferences['preferred_pressure'] ?? 'N/A',
                              style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  // Reason for Massage
                  Text(
                    'Reason for Massage',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    preferences['reason_for_massage'] ?? 'N/A',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  SizedBox(height: 20.h),
                  // Moisturizer
                  Text(
                    'Moisturizer',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    preferences['moisturizer'] ?? 'N/A',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  SizedBox(height: 20.h),
                  // Conversation Preferred
                  Text(
                    'Conversation Preferred',
                    style: TextStyle(fontSize: 14.sp, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 8.h),
                  Text(
                    preferences['conversation_preference'] ?? 'N/A',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600, color: Colors.black),
                  ),
                  SizedBox(height: 20.h),
                  // Music
                  Row(
                    children: [
                      Icon(Icons.music_note, size: 20.sp, color: primaryButtonColor),
                      SizedBox(width: 8.w),
                      Text(
                        'Music: ${preferences['music_preference'] ?? 'N/A'}',
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                  SizedBox(height: 15.h),
                  // Own massage table
                  Row(
                    children: [
                      Icon(Icons.close, size: 20.sp, color: location['massage_table'] != true ? Colors.red : Colors.grey),
                      SizedBox(width: 8.w),
                      Text(
                        'Own massage table',
                        style: TextStyle(fontSize: 16.sp, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Additional Services Section
            _buildSectionTitle('Additional Services', Icons.add_circle_outline),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 10.h),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: addOns.map<Widget>((addOn) => _buildServiceChip(addOn['name'] ?? 'N/A')).toList(),
                ),
              ),
            ),
            SizedBox(height: 10.h),
            // AI Symptom Analysis Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20.w),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF0E6D2),
                  borderRadius: BorderRadius.circular(12.r),
                ),
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.psychology, size: 20.sp, color: primaryButtonColor),
                        SizedBox(width: 8.w),
                        Text(
                          'AI Symptom Analysis',
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: primaryButtonColor),
                        ),
                      ],
                    ),
                    SizedBox(height: 15.h),
                    Text(
                      'Highlighted Muscle Groups:',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: primaryButtonColor),
                    ),
                    SizedBox(height: 8.h),
                    // Wrap for responsive layout
                    Wrap(
                      spacing: 8.w, // Horizontal space between chips
                      runSpacing: 4.h, // Vertical space between lines if wrapped
                      children: (aiAnalysis['highlighted_muscle_groups'] as List? ?? [])
                          .map<Widget>((muscle) => _buildMuscleGroupChip(muscle))
                          .toList(),
                    ),
                    SizedBox(height: 15.h),
                    Text(
                      'Suggested Techniques & Precautions:',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: primaryButtonColor),
                    ),
                    SizedBox(height: 8.h),
                    Text(
                      aiAnalysis['suggested_techniques_or_precautions'] ?? 'N/A',
                      style: TextStyle(fontSize: 12.sp, color: Color(0xFF6B4423)),
                      textAlign: TextAlign.justify,
                    ),
                    SizedBox(height: 15.h),
                    Text(
                      'Severity: ${aiAnalysis['severity_flag'] ?? 'N/A'}',
                      style: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.w600, color: primaryButtonColor),
                    ),
                    SizedBox(height: 10.h),
                    Row(
                      children: [
                        Icon(Icons.info_outline, size: 16.sp, color: Colors.grey[600]),
                        SizedBox(width: 5.w),
                        Text(
                          'This informational is not medical advice',
                          style: TextStyle(fontSize: 12.sp, color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData? icon) {
    return Container(
      width: double.infinity,
      height: 0.055.sh, // Screen height percentage
      decoration: BoxDecoration(
        color: secounderyBorderColor.withAlpha(80),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 10.h),
        child: Row(
          children: [
            Icon(icon, size: 16.sp, color: buttonTextColor),
            SizedBox(width: 5.w),
            Text(
              title,
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold, color: primaryButtonColor),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildServiceChip(String label) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 5.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
        decoration: BoxDecoration(
          border: Border.all(color: primaryButtonColor, width: 1),
          borderRadius: BorderRadius.circular(20.r),
        ),
        child: Text(
          label,
          style: TextStyle(fontSize: 14.sp, color: primaryButtonColor),
        ),
      ),
    );
  }

  Widget _buildMuscleGroupChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
      decoration: BoxDecoration(
        color: secounderyBorderColor.withAlpha(80),
        borderRadius: BorderRadius.circular(15.r),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 12.sp, color: primaryButtonColor, fontWeight: FontWeight.w500),
      ),
    );
  }
}