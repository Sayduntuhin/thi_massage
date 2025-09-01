import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import 'package:thi_massage/controller/client_booking_controller.dart';
import 'package:thi_massage/view/widgets/custom_button.dart';
import 'package:intl/intl.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:thi_massage/view/widgets/loading_indicator.dart';
import 'package:thi_massage/view/widgets/payment_options_sheet.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:toastification/toastification.dart';

import '../../../models/therapist_model.dart';
import '../../home/widgets/category_item.dart';

class AppointmentScreen extends StatelessWidget {
  const AppointmentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ClientBookingController());

    return Scaffold(
      appBar: SecondaryAppBar(title: "Appointment"),
      body: Obx(() => SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                Text(
                'Massage Type',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),

          SizedBox(height: 12.h),
          Obx(() => controller.isLoading.value
              ?  Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(
                const Color(0xFFB28D28), // Match CategoryItem theme
              ),
              strokeWidth: 2.w,
            ),
          )
              : controller.messageTypes.isEmpty
              ? const Center(child: Text('No massage types available'))
              : SizedBox(
            height: 0.18.sh,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: controller.messageTypes.length,
              itemBuilder: (context, index) {
                final messageType = controller.messageTypes[index];
                final title = (messageType['title'] as String).trim();
                final isSelected = controller.selectedMessageType.value
                    .trim()
                    .toLowerCase() ==
                    title.toLowerCase();
                AppLogger.debug(
                    'Rendering messageType: $title, isSelected: $isSelected, selectedMessageType: ${controller.selectedMessageType.value}');
                return Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w),
                  child: CategoryItem(
                    key: ValueKey(title),
                    title: title,
                    image: messageType['image']!,
                    isSelected: isSelected,
                    onTap: () {
                      AppLogger.debug('Tapped massage type: $title');
                      controller.selectedMessageType.value = title;
                      controller.selectedTherapist.value = null;
                      AppLogger.debug(
                          'New selectedMessageType: ${controller.selectedMessageType.value}');
                    },
                  ),
                );
              },
            ),
          )),
                  if (controller.errorMessage.value != null) ...[
                    SizedBox(height: 12.h),
                    Center(
                      child: Text(
                        controller.errorMessage.value!,
                        style: TextStyle(fontSize: 14.sp, color: Colors.red),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
              ]),
            ),
            _buildExpandableSection(
              'Customer Preferences',
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Select your age range',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w600)),
                    Obx(() => RangeSlider(
                      values: controller.ageRange.value,
                      min: 18,
                      max: 70,
                      divisions: 52,
                      labels: RangeLabels(
                          controller.ageRange.value.start.round().toString(),
                          controller.ageRange.value.end.round().toString()),
                      onChanged: (values) => controller.ageRange.value = values,
                    )),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('${controller.ageRange.value.start.round()}',
                            style: TextStyle(fontSize: 14.sp)),
                        Text('${controller.ageRange.value.end.round()}',
                            style: TextStyle(fontSize: 14.sp)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Massage Preference',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      _buildTextOption('Single', isSelected: !controller.isBackToBack.value),
                      SizedBox(width: 12.w),
                      _buildTextOption('Back to Back', isSelected: controller.isBackToBack.value),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text('Select number of people',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8.h),
                  Obx(() => Row(
                    children: [
                      IconButton(
                          icon: Icon(Icons.remove_circle_outline, size: 24.sp),
                          onPressed: controller.numberOfPeople.value > 1
                              ? () => controller.numberOfPeople.value--
                              : null),
                      Text('${controller.numberOfPeople.value}',
                          style: TextStyle(
                              fontSize: 16.sp, fontWeight: FontWeight.bold)),
                      IconButton(
                          icon: Icon(Icons.add_circle_outline, size: 24.sp),
                          onPressed: controller.numberOfPeople.value < 5
                              ? () => controller.numberOfPeople.value++
                              : null),
                    ],
                  )),
                  SizedBox(height: 20.h),
                  Text('Duration',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12.h),
                  Obx(() => Wrap(
                    spacing: 8.w,
                    runSpacing: 8.h,
                    children: controller.availableDurations.map((duration) {
                      final isSelected = controller.selectedDuration.value == duration;
                      return InkWell(
                        onTap: () {
                          controller.selectedDuration.value = duration;
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryButtonColor : Colors.white,
                            borderRadius: BorderRadius.circular(20.r),
                            border: Border.all(
                              color: isSelected ? primaryButtonColor : Colors.grey[300]!,
                            ),
                          ),
                          child: Text(
                            duration,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  )),
                  SizedBox(height: 20.h),
                  Text('Provider Gender Preference',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12.h),
                  Obx(() => _buildDropdownField(
                    label: "Select Gender Preference",
                    value: controller.providerGenderPreference.value,
                    items: ['Any Available', 'Male', 'Female'],
                    onChanged: (value) => controller.providerGenderPreference.value = value!,
                  )),
                  SizedBox(height: 20.h),
                  Text('Therapist',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 20.h),
                  InkWell(
                    onTap: () => _showTherapistDialog(context, controller),
                    child: Row(
                      children: [
                        if (controller.selectedTherapist.value != null &&
                            controller.selectedTherapist.value!.image.isNotEmpty &&
                            controller.selectedTherapist.value!.name.isNotEmpty) ...[
                          CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(controller.selectedTherapist.value!.image),
                            radius: 20.r,
                            onBackgroundImageError: (error, stackTrace) {
                              AppLogger.error('Therapist image load error: ${error.toString()}, URL: ${controller.selectedTherapist.value!.image}');
                            },
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                controller.selectedTherapist.value!.name,
                                style: TextStyle(fontWeight: FontWeight.w500, fontSize: 16.sp),
                              ),
                              Text(
                                controller.selectedTherapist.value!.assignRole,
                                style: TextStyle(fontSize: 12.sp, color: Colors.grey),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ] else ...[
                          Icon(Icons.add, color: Colors.amber, size: 24.sp),
                          SizedBox(width: 12.w),
                          Text('Add', style: TextStyle(fontSize: 16.sp)),
                          const Spacer(),
                        ],
                        if (controller.selectedTherapist.value != null)
                          Text('Change',
                              style: TextStyle(
                                  color: primaryTextColor,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.sp)),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Text('Schedule',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ThaiMassageButton(
                          width: 0.35.sw,
                          fontsize: 14,
                          height: .045.sh,
                          text: 'Instant',
                          backgroundColor: !controller.isScheduleSelected.value ? primaryButtonColor : Colors.white,
                          textColor: !controller.isScheduleSelected.value ? Colors.white : Colors.black54,
                          borderColor: !controller.isScheduleSelected.value ? primaryButtonColor : primaryButtonColor,
                          onPressed: () => controller.isScheduleSelected.value = false,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ThaiMassageButton(
                          width: 0.35.sw,
                          fontsize: 14,
                          height: .045.sh,
                          text: 'Schedule',
                          backgroundColor: controller.isScheduleSelected.value ? primaryButtonColor : Colors.white,
                          textColor: controller.isScheduleSelected.value ? Colors.white : Colors.black54,
                          borderColor: controller.isScheduleSelected.value ? primaryButtonColor : primaryButtonColor,
                          onPressed: () => controller.isScheduleSelected.value = true,
                        ),
                      ),
                    ],
                  ),
                  if (controller.isScheduleSelected.value) ...[
                    SizedBox(height: 20.h),
                    Text('Select Date & Time Slot',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 20.h),
                    TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime(2100),
                      focusedDay: controller.selectedDateTime.value ?? DateTime.now(),
                      selectedDayPredicate: (day) => isSameDay(day, controller.selectedDateTime.value),
                      onDaySelected: (selected, focused) {
                        controller.selectedDateTime.value = selected;
                      },
                      headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                          rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor)),
                      calendarStyle: CalendarStyle(
                        selectedDecoration: BoxDecoration(color: primaryColor, shape: BoxShape.circle),
                        todayDecoration: BoxDecoration(color: primaryColor.withAlpha(50), shape: BoxShape.circle),
                      ),
                    ),
                    SizedBox(height: 12.h),
                    Obx(() => Wrap(
                      spacing: 8.w,
                      runSpacing: 8.h,
                      children: ClientBookingController.timeSlots.map((slot) {
                        final isSelected = controller.selectedDateTime.value != null &&
                            DateFormat('h:mm a').format(controller.selectedDateTime.value!) == slot.split(' - ')[0];
                        return InkWell(
                          onTap: () {
                            final selectedDate = controller.selectedDateTime.value ?? DateTime.now();
                            final timeParts = slot.split(' - ')[0].split(' ');
                            final time = timeParts[0].split(':');
                            int hour = int.parse(time[0]);
                            final minute = int.parse(time[1]);
                            final isPM = timeParts[1].toLowerCase() == 'pm';
                            if (isPM && hour != 12) hour += 12;
                            if (!isPM && hour == 12) hour = 0;
                            controller.selectedDateTime.value = DateTime(
                                selectedDate.year, selectedDate.month, selectedDate.day, hour, minute);
                          },
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                            decoration: BoxDecoration(
                              color: isSelected ? primaryButtonColor : Colors.white,
                              borderRadius: BorderRadius.circular(20.r),
                              border: Border.all(
                                color: isSelected ? primaryButtonColor : Colors.grey[300]!,
                              ),
                            ),
                            child: Text(
                              slot,
                              style: TextStyle(
                                color: isSelected ? Colors.white : Colors.black87,
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    )),
                  ],
                  SizedBox(height: 20.h),
                  Text('Location',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: _buildLocationOption('Home', isSelected: controller.location.value == 'Home')),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildLocationOption('Office', isSelected: controller.location.value == 'Office')),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildLocationOption('Hotel', isSelected: controller.location.value == 'Hotel')),
                    ],
                  ),
                  SizedBox(height: 20.h),
                  Text('Location Detail',
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  SizedBox(height: 12.h),
                  _buildTextInput("Customer Address", controller.customerAddress),
                  SizedBox(height: 12.h),
                  _buildTextInput("Customer Phone Number", controller.customerPhoneNumber, keyboardType: TextInputType.phone),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: _buildTextInput("Number of floors", controller.numberOfFloors)),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildDropdownField(
                          label: "Elevator/Escalator",
                          value: controller.elevatorSelection.value,
                          items: ['Yes', 'No'],
                          onChanged: (value) => controller.elevatorSelection.value = value,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildDropdownField(
                          label: "Parking type",
                          value: controller.parkingSelection.value,
                          items: ['Street', 'Garage', 'None'],
                          onChanged: (value) => controller.parkingSelection.value = value,
                        ),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildDropdownField(
                          label: "Any pets",
                          value: controller.petsSelection.value,
                          items: ['Yes', 'No'],
                          onChanged: (value) => controller.petsSelection.value = value,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40.h),
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: CustomGradientButton(
                      text: "Proceed to Pay",
                      onPressed: controller.createBooking,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      )),
    );
  }

  void _showAddOnsBottomSheet(BuildContext context, ClientBookingController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.6,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
          child: Column(
            children: [
              Container(
                margin: EdgeInsets.only(top: 12.h),
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: Text(
                  'Add-ons',
                  style: TextStyle(
                    fontSize: 20.sp,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  child: Wrap(
                    spacing: 12.w,
                    runSpacing: 12.h,
                    children: ClientBookingController.addOnsList.map((addOn) {
                      final isSelected = controller.selectedAddOns.contains(addOn);
                      return GestureDetector(
                        onTap: () {
                          setModalState(() {
                            if (isSelected) {
                              controller.selectedAddOns.remove(addOn);
                            } else {
                              controller.selectedAddOns.add(addOn);
                            }
                          });
                        },
                        child: Container(
                          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 5.h),
                          decoration: BoxDecoration(
                            color: isSelected ? primaryButtonColor : Colors.white,
                            border: Border.all(color: isSelected ? primaryButtonColor : borderColor, width: 1.5),
                            borderRadius: BorderRadius.circular(25.r),
                          ),
                          child: Text(
                            addOn,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.black87,
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.w),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryButtonColor,
                      padding: EdgeInsets.symmetric(vertical: 16.h),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(25.r)),
                      elevation: 0,
                    ),
                    child: Text(
                      'Done',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showTherapistDialog(BuildContext context, ClientBookingController controller) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Therapist', style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              SizedBox(
                height: 300.h,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: controller.apiService.getTherapistsByMassageType(controller.selectedMessageType.value),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          snapshot.error.toString().contains('NetworkException')
                              ? 'No internet connection. Please check your network.'
                              : 'Failed to load therapists: ${snapshot.error}',
                          style: TextStyle(fontSize: 14.sp, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      );
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(child: Text('No therapists available for ${controller.selectedMessageType.value}', style: TextStyle(fontSize: 14.sp)));
                    }

                    final therapists = snapshot.data!.map((json) => Therapist.fromJson(json)).toList();

                    return ListView.builder(
                      itemCount: therapists.length,
                      itemBuilder: (context, index) {
                        final therapist = therapists[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage: CachedNetworkImageProvider(therapist.image),
                            radius: 20.r,
                            onBackgroundImageError: (_, stackTrace) {
                              AppLogger.error('Therapist image error: ${therapist.image}');
                            },
                          ),
                          title: Text(therapist.name.isNotEmpty ? therapist.name : 'Unknown Therapist', style: TextStyle(fontSize: 16.sp)),
                          subtitle: Row(
                            children: [
                              Icon(Icons.star, size: 16.sp, color: Colors.amber),
                              Text(' ${therapist.rating.toStringAsFixed(1)} (${therapist.reviewCount} reviews)', style: TextStyle(fontSize: 14.sp)),
                            ],
                          ),
                          onTap: () {
                            controller.selectedTherapist.value = therapist;
                            Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Cancel', style: TextStyle(fontSize: 16.sp)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckboxOption(String title, bool value, Function(bool?) onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 22.h,
          child: Checkbox(value: value, onChanged: onChanged, activeColor: primaryButtonColor),
        ),
        Text(title, style: TextStyle(fontSize: 16.sp)),
      ],
    );
  }

  Widget _buildExpandableSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Get.toNamed('/customerPreferencesPage'),
          child: Container(
            color: secounderyBorderColor.withAlpha(40),
            height: 55.h,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Text(title, style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios_sharp, size: 20.sp),
                ],
              ),
            ),
          ),
        ),
        content,
      ],
    );
  }

  Widget _buildTextOption(String title, {required bool isSelected}) {
    return InkWell(
      onTap: () => Get.find<ClientBookingController>().isBackToBack.value = title == 'Back to Back',
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: isSelected ? boxColor : Colors.white,
          border: Border.all(color: isSelected ? borderColor.withAlpha(100) : Color(0xffE0E0E0)),
        ),
        child: Text(title, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14.sp)),
      ),
    );
  }

  Widget _buildLocationOption(String title, {required bool isSelected}) {
    return InkWell(
      onTap: () => Get.find<ClientBookingController>().location.value = title,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? boxColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(color: isSelected ? borderColor.withAlpha(100) : Colors.grey.shade300),
        ),
        child: Center(
            child: Text(title, style: TextStyle(color: Colors.black, fontWeight: FontWeight.w500, fontSize: 14.sp))),
      ),
    );
  }

  Widget _buildDropdownField({required String label, required String? value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(color: Colors.white, border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8.r)),
      child: DropdownButton<String>(
        value: value,
        hint: Text(label, style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        isExpanded: true,
        underline: SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, size: 16.sp),
        items: items.map((String item) {
          return DropdownMenuItem<String>(value: item, child: Text(item, style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14.sp, color: Colors.black)));
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildTextInput(String label, RxString controller, {TextInputType keyboardType = TextInputType.text}) {
    return TextFormField(
      onChanged: (value) => controller.value = value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8.r), borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      keyboardType: keyboardType,
    );
  }
}