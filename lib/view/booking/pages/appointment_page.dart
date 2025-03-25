import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import '../../../models/therapist_model.dart';
import '../../../routers/app_router.dart';
import '../../home/widgets/category_item.dart';
import '../../widgets/custom_button.dart';
import 'package:intl/intl.dart';
import '../../widgets/payment_options_sheet.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  String _selectedMessageType = 'Thai Massage';
  bool _isReturningCustomer = false;
  bool _hasOwnMassageTable = false;
  RangeValues _ageRange = const RangeValues(18, 40);
  String _selectedDuration = '60 min';
  int _numberOfPeople = 1;
  bool _isBackToBack = false;
  String _location = 'Home';
  Therapist? _selectedTherapist;
  DateTime? _selectedDateTime;

  final List<Map<String, String>> messageTypes = [
    {"title": "Thai Massage", "image": "assets/images/thi_massage.png"},
    {"title": "Swedish Massage", "image": "assets/images/swedish.png"},
    {"title": "Deep Tissue", "image": "assets/images/deep.png"},
  ];

  final List<Therapist> _therapists = [
    Therapist(
      id: 1,
      name: 'Nicci Martinez',
      image: 'https://randomuser.me/api/portraits/men/32.jpg',
      rating: 4.8,
      reviewCount: 120,
    ),
    Therapist(
      id: 2,
      name: 'Sarah Johnson',
      image: 'https://randomuser.me/api/portraits/women/44.jpg',
      rating: 4.9,
      reviewCount: 85,
    ),
    Therapist(
      id: 3,
      name: 'David Wilson',
      image: 'https://randomuser.me/api/portraits/men/64.jpg',
      rating: 4.7,
      reviewCount: 92,
    ),
  ];

  void _showTherapistDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.r),
        ),
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select Therapist',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16.h),
              SizedBox(
                height: 300.h,
                child: ListView.builder(
                  itemCount: _therapists.length,
                  itemBuilder: (context, index) {
                    final therapist = _therapists[index];
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(therapist.image),
                        radius: 20.r,
                      ),
                      title: Text(
                        therapist.name,
                        style: TextStyle(fontSize: 16.sp),
                      ),
                      subtitle: Row(
                        children: [
                          Icon(Icons.star, size: 16.sp, color: Colors.amber),
                          Text(
                            ' ${therapist.rating} (${therapist.reviewCount} reviews)',
                            style: TextStyle(fontSize: 14.sp),
                          ),
                        ],
                      ),
                      onTap: () {
                        setState(() {
                          _selectedTherapist = therapist;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Cancel',
                  style: TextStyle(fontSize: 16.sp),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDateTimePickerModal() {
    DateTime selectedDate = DateTime.now();

    final hourController = TextEditingController(
      text: (TimeOfDay.now().hourOfPeriod == 0 ? 12 : TimeOfDay.now().hourOfPeriod).toString(),
    );

    final minuteController = TextEditingController(
      text: TimeOfDay.now().minute.toString().padLeft(2, '0'),
    );

    bool isAm = TimeOfDay.now().period == DayPeriod.am;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      /// Calendar
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime(2100),
                        focusedDay: selectedDate,
                        selectedDayPredicate: (day) => isSameDay(day, selectedDate),
                        onDaySelected: (selected, focused) {
                          setModalState(() => selectedDate = selected);
                        },
                        headerStyle: HeaderStyle(
                          formatButtonVisible: false,
                          titleCentered: true,
                          leftChevronIcon: Icon(Icons.chevron_left, color: primaryColor),
                          rightChevronIcon: Icon(Icons.chevron_right, color: primaryColor),
                        ),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                            color: primaryColor,
                            shape: BoxShape.circle,
                          ),
                          todayDecoration: BoxDecoration(
                            color: primaryColor.withAlpha(50),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),

                      /// Time input
                      Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Time",
                          style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w500),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          // Time input container
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 5.w, vertical: 5.h),
                            decoration: BoxDecoration(
                              color: Color(0xffF0F3F7),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                SizedBox(
                                  width: 25.w,
                                  child: TextField(
                                    controller: hourController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 2,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                ),
                                Text(" : ", style: TextStyle(fontSize: 16.sp)),
                                SizedBox(
                                  width: 25.w,
                                  child: TextField(
                                    controller: minuteController,
                                    keyboardType: TextInputType.number,
                                    maxLength: 2,
                                    decoration: InputDecoration(
                                      counterText: '',
                                      border: InputBorder.none,
                                      isDense: true,
                                    ),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),

                          // AM/PM toggle
                          Container(
                            height: 40.h,
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            decoration: BoxDecoration(
                              color: const Color(0xffF0F3F7),
                              borderRadius: BorderRadius.circular(12.r),
                            ),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setModalState(() => isAm = true),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: isAm ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      "AM",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () => setModalState(() => isAm = false),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                      color: !isAm ? Colors.white : Colors.transparent,
                                      borderRadius: BorderRadius.circular(8.r),
                                    ),
                                    child: Text(
                                      "PM",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w500,
                                        color: Colors.black,
                                        fontSize: 14.sp,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),

                          // Done button
                          ThaiMassageButton(
                            height: 0.04.sh,
                            width: 0.25.sw,
                            fontsize: 12,
                            backgroundColor: primaryColor,
                            text: "Done",
                            onPressed: () {
                              int hour = int.tryParse(hourController.text) ?? 0;
                              int minute = int.tryParse(minuteController.text) ?? 0;

                              // Validate input
                              if (hour < 1 || hour > 12 || minute < 0 || minute > 59) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Please enter a valid time")),
                                );
                                return;
                              }

                              // Convert to 24-hour format
                              final convertedHour = isAm
                                  ? (hour == 12 ? 0 : hour)
                                  : (hour == 12 ? 12 : hour + 12);

                              // Combine the selected date and time into a DateTime object
                              final selectedDateTime = DateTime(
                                selectedDate.year,
                                selectedDate.month,
                                selectedDate.day,
                                convertedHour,
                                minute,
                              );

                              // Update the state with the selected DateTime
                              setState(() {
                                _selectedDateTime = selectedDateTime;
                              });

                              Navigator.pop(context);
                            },
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SecondaryAppBar(title: "Appointment"),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Message Type
            Padding(
              padding: EdgeInsets.all(16.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Message Type',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  SizedBox(
                    height: 0.18.sh,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: messageTypes.length,
                      itemBuilder: (context, index) {
                        final messageType = messageTypes[index];
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.w),
                          child: CategoryItem(
                            title: messageType["title"]!,
                            image: messageType["image"]!,
                            isSelected: _selectedMessageType == messageType["title"],
                            onTap: () {
                              setState(() {
                                _selectedMessageType = messageType["title"]!;
                              });
                              // Navigation removed from here; will happen on "Proceed to Pay"
                            },
                          ),
                        );
                      },
                    ),
                  ),

                  // Customer Type Checkboxes
                  _buildCheckboxOption(
                    'I am a returning customer',
                    _isReturningCustomer,
                        (value) => setState(() => _isReturningCustomer = value!),
                  ),
                  SizedBox(height: 12.h),
                  _buildCheckboxOption(
                    'I have my own massage table',
                    _hasOwnMassageTable,
                        (value) => setState(() => _hasOwnMassageTable = value!),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 50),
                    child: Text(
                      "\$10 Discount if you have Massage Table",
                      style: TextStyle(fontSize: 10.sp, color: Color(0xff808080)),
                    ),
                  ),
                  SizedBox(height: 5.h),
                ],
              ),
            ),

            // Customer Preferences Section
            _buildExpandableSection(
              'Customer Preferences',
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Select your age range',
                      style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                    ),
                    RangeSlider(
                      values: _ageRange,
                      min: 18,
                      max: 70,
                      divisions: 52,
                      labels: RangeLabels(
                        _ageRange.start.round().toString(),
                        _ageRange.end.round().toString(),
                      ),
                      onChanged: (values) {
                        setState(() {
                          _ageRange = values;
                        });
                      },
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '${_ageRange.start.round()}',
                          style: TextStyle(fontSize: 14.sp),
                        ),
                        Text(
                          '${_ageRange.end.round()}',
                          style: TextStyle(fontSize: 14.sp),
                        ),
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
                  // Message Preference
                  Text(
                    'Message Preference',
                    style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      _buildTextOption('Single', isSelected: !_isBackToBack),
                      SizedBox(width: 12.w),
                      _buildTextOption('Back to Back', isSelected: _isBackToBack),
                    ],
                  ),
                  if (_selectedTherapist == null)
                    SizedBox(height: 20.h)
                  else
                    SizedBox(height: 12.h),

                  // Number of people (only show if _selectedTherapist is not null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Select number of people',
                        style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.w600),
                      ),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, size: 24.sp),
                            onPressed: _numberOfPeople > 1
                                ? () => setState(() => _numberOfPeople--)
                                : null,
                          ),
                          Text(
                            '$_numberOfPeople',
                            style: TextStyle(
                              fontSize: 16.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, size: 24.sp),
                            onPressed: _numberOfPeople < 5
                                ? () => setState(() => _numberOfPeople++)
                                : null,
                          ),
                        ],
                      ),
                      SizedBox(height: 20.h),
                    ],
                  ),
                  // Duration
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Duration',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        _selectedDuration,
                        style: TextStyle(
                          fontSize: 16.sp,
                          fontWeight: FontWeight.w600,
                          color: primaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 16),
                          activeTrackColor: primaryTextColor,
                          inactiveTrackColor: Colors.grey[200],
                          thumbColor: Colors.white,
                          overlayColor: boxColor,
                          trackHeight: 8.0.h,
                          valueIndicatorColor: secounderyBorderColor,
                          valueIndicatorTextStyle: TextStyle(
                            color: Colors.black,
                            fontSize: 14.sp,
                          ),
                        ),
                        child: Slider(
                          value: double.parse(_selectedDuration.split(' ')[0]),
                          min: 30,
                          max: 120,
                          divisions: 90,
                          label: _selectedDuration,
                          onChanged: (value) {
                            setState(() {
                              _selectedDuration = '${value.round()} min';
                            });
                          },
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '30 min',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                          Text(
                            '120 min',
                            style: TextStyle(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w400,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Therapist
                  Text(
                    'Therapist',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  InkWell(
                    onTap: _showTherapistDialog,
                    child: Row(
                      children: [
                        if (_selectedTherapist != null) ...[
                          CircleAvatar(
                            backgroundImage: NetworkImage(_selectedTherapist!.image),
                            radius: 20.r,
                          ),
                          SizedBox(width: 12.w),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedTherapist!.name,
                                style: TextStyle(
                                  fontWeight: FontWeight.w500,
                                  fontSize: 16.sp,
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                        ] else ...[
                          Icon(Icons.add, color: Colors.amber, size: 24.sp),
                          SizedBox(width: 12.w),
                          Text(
                            'Add',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          const Spacer(),
                        ],
                        if (_selectedTherapist != null)
                          Text(
                            'Change',
                            style: TextStyle(
                              color: primaryTextColor,
                              fontWeight: FontWeight.w500,
                              fontSize: 16.sp,
                            ),
                          ),
                      ],
                    ),
                  ),
                  SizedBox(height: 20.h),

                  // Instant appointment
                  Text(
                    'Do you want instant appointment?',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ThaiMassageButton(
                          width: 0.35.sw,
                          fontsize: 14,
                          height: .045.sh,
                          text: 'Yes',
                          isPrimary: false,
                          onPressed: () {
                            debugPrint('Yes button pressed');
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ThaiMassageButton(
                          width: 0.35.sw,
                          fontsize: 14,
                          height: .045.sh,
                          text: 'Schedule',
                          isPrimary: true,
                          onPressed: () {
                            debugPrint('Schedule button pressed');
                          },
                        ),
                      ),
                    ],
                  ),

                  if (_selectedTherapist != null) ...[
                    Text(
                      'Date & Time',
                      style: TextStyle(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 20.h),
                    // Date & Time
                    GestureDetector(
                      onTap: _showDateTimePickerModal,
                      child: AbsorbPointer(
                        child: TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: _selectedDateTime != null
                                ? DateFormat('MMM d, yyyy h:mm a').format(_selectedDateTime!)
                                : null,
                          ),
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.calendar_month, color: primaryButtonColor),
                            hintText: _selectedDateTime == null ? "Select Date & Time" : null,
                            hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
                            filled: true,
                            fillColor: textFieldColor,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                              borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                              borderSide: BorderSide(color: borderColor.withAlpha(40), width: 1.5.w),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20.r),
                              borderSide: BorderSide(color: borderColor.withAlpha(40), width: 2.w),
                            ),
                            contentPadding: EdgeInsets.symmetric(vertical: 16.h),
                          ),
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 20.h),

                  // Location
                  Text(
                    'Location',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(
                        child: _buildLocationOption('Home', isSelected: _location == 'Home'),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildLocationOption('Office', isSelected: _location == 'Office'),
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: _buildLocationOption('Hotel', isSelected: _location == 'Hotel'),
                      ),
                    ],
                  ),
                  SizedBox(height: 20.h),

                  // Location Detail
                  Text(
                    'Location Detail',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: _buildTextInput("Number of floors")),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildDropdownField("Elevator/Escalator", "")),
                    ],
                  ),
                  SizedBox(height: 12.h),
                  Row(
                    children: [
                      Expanded(child: _buildDropdownField("Parking type", "")),
                      SizedBox(width: 12.w),
                      Expanded(child: _buildDropdownField("Any pets", "")),
                    ],
                  ),
                  SizedBox(height: 40.h),

                  // Proceed to Pay button
                  Padding(
                    padding: const EdgeInsets.all(15),
                    child: CustomGradientButton(
                      text: "Proceed to Pay",
                      onPressed: () {
                        // Find the selected message type's image and name
                        final selectedMessage = messageTypes.firstWhere(
                              (message) => message["title"] == _selectedMessageType,
                          orElse: () => {"title": "Thai Massage", "image": "assets/images/thi_massage.png"},
                        );

                        // Pass the selected message type's image and name to PaymentOptionsSheet
                        PaymentOptionsSheet.show(
                          context,
                          creditCardRoute: Routes.appointmentPaymentPage,
                          arguments: {
                            'image': selectedMessage["image"],
                            'name': selectedMessage["title"],
                            'dateTime': _selectedDateTime?.toIso8601String(),
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
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
          child: Checkbox(
            value: value,
            onChanged: onChanged,
            activeColor: primaryButtonColor,
          ),
        ),
        Text(
          title,
          style: TextStyle(fontSize: 16.sp),
        ),
      ],
    );
  }

  Widget _buildExpandableSection(String title, Widget content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: (){
            Get.toNamed('/customerPreferencesPage');
          },
          child: Container(
            color: secounderyBorderColor.withAlpha(40),
            height: 55.h,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Row(
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
      onTap: () {
        setState(() {
          _isBackToBack = title == 'Back to Back';
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: isSelected ? boxColor : Colors.white,
          border: Border.all(
            color: isSelected ? borderColor.withAlpha(100) : Color(0xffE0E0E0),
          ),
        ),
        child: Text(
          title,
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w500,
            fontSize: 14.sp,
          ),
        ),
      ),
    );
  }

  Widget _buildLocationOption(String title, {required bool isSelected}) {
    return InkWell(
      onTap: () {
        setState(() {
          _location = title;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? boxColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
            color: isSelected ? borderColor.withAlpha(100) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            title,
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField(String label, String value) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.sp,
            ),
          ),
          Icon(Icons.keyboard_arrow_down, size: 16.sp),
        ],
      ),
    );
  }

  Widget _buildTextInput(String label) {
    return TextFormField(
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: Colors.grey,
          fontSize: 14.sp,
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8.r),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
    );
  }
}
