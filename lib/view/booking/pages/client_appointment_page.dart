import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_appbar.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';
import '../../../api/api_service.dart';
import '../../../controller/coustomer_preferences_controller.dart';
import '../../../controller/location_controller.dart';
import '../../../models/therapist_model.dart';
import '../../../routers/app_router.dart';
import '../../home/widgets/category_item.dart';
import '../../widgets/custom_button.dart';
import 'package:intl/intl.dart';
import '../../widgets/custom_snackbar.dart';
import '../../widgets/loading_indicator.dart';
import '../../widgets/payment_options_sheet.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:toastification/toastification.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';

class AppointmentScreen extends StatefulWidget {
  const AppointmentScreen({super.key});

  @override
  State<AppointmentScreen> createState() => _AppointmentScreenState();
}

class _AppointmentScreenState extends State<AppointmentScreen> {
  String _selectedMessageType = 'Swedish Massage';
  bool _isReturningCustomer = false;
  bool _hasOwnMassageTable = false;
  RangeValues _ageRange = const RangeValues(18, 40);
  String _selectedDuration = '60 min';
  int _numberOfPeople = 1;
  bool _isBackToBack = false;
  String _location = 'Home';
  Therapist? _selectedTherapist;
  DateTime? _selectedDateTime;
  bool _isScheduleSelected = false;
  String? _elevatorSelection;
  String? _petsSelection;
  String? _parkingSelection;
  final TextEditingController _numberOfFloorsController =
      TextEditingController();
  final _storage = const FlutterSecureStorage();
  final ApiService apiService = ApiService();
  final LocationController locationController = Get.put(LocationController());
  List<Map<String, dynamic>> messageTypes = [];
  bool isLoading = true;
  String? errorMessage;

  String _cleanString(String input) {
    return input
        .replaceAll('\u00A0', ' ')
        .replaceAll('\u200B', '')
        .replaceAll('\u202F', ' ')
        .replaceAll(RegExp(r'[^\x20-\x7E]'), ' ');
  }

  @override
  void initState() {
    super.initState();
    final arguments = Get.arguments as Map<String, dynamic>?;
    AppLogger.debug('AppointmentScreen Arguments: $arguments');
    String? therapistRole;
    if (arguments != null && arguments.containsKey('therapist')) {
      final therapistData = arguments['therapist'] as Map<String, dynamic>;
      AppLogger.debug('Therapist Data: $therapistData');
      try {
        _selectedTherapist = Therapist.fromJson(therapistData);
        therapistRole = therapistData['role'] as String? ?? 'Swedish Massage';
        AppLogger.debug('Therapist Role: $therapistRole');
        AppLogger.debug('Selected Therapist: ${_selectedTherapist?.toJson()}');
      } catch (e) {
        AppLogger.error('Error creating Therapist: $e');
        WidgetsBinding.instance.addPostFrameCallback((_) {
          CustomSnackBar.show(
            context,
            'Failed to load therapist data: $e',
            type: ToastificationType.error,
          );
        });
      }
    }
    fetchMassageTypes(therapistRole: therapistRole);
  }

  Future<void> fetchMassageTypes({String? therapistRole}) async {
    try {
      final massageTypes = await apiService.getMassageTypes();
      AppLogger.debug('Massage Types API Response: $massageTypes');
      setState(() {
        messageTypes = massageTypes
            .where((type) => type['is_active'] == true)
            .map((type) => <String, dynamic>{
                  'title': _cleanString(type['name'] as String),
                  'image': type['image'].startsWith('/media') ||
                          type['image'].startsWith('/client/media')
                      ? '${ApiService.baseUrl}${type['image']}'
                      : type['image'] as String,
                })
            .toList();
        isLoading = false;
        if (therapistRole != null) {
          final matchingType = messageTypes.firstWhere(
            (type) => type['title']
                .toLowerCase()
                .contains(therapistRole.toLowerCase()),
            orElse: () => messageTypes.isNotEmpty
                ? messageTypes[0]
                : <String, dynamic>{
                    'title': 'Swedish Massage',
                    'image':
                        '${ApiService.baseUrl}/media/documents/default2.jpg'
                  },
          );
          _selectedMessageType = matchingType['title'] as String;
          AppLogger.debug('Auto-selected Massage Type: $_selectedMessageType');
        } else if (messageTypes.isNotEmpty) {
          _selectedMessageType = messageTypes[0]['title'] as String;
        }
        AppLogger.debug('Message Types: $messageTypes');
      });
    } catch (e) {
      AppLogger.error('Fetch Massage Types Error: $e');
      String detailedError = e.toString();
      if (e is NetworkException) {
        detailedError = 'Network error: Please check your internet connection.';
      } else if (e is UnauthorizedException) {
        detailedError = 'Authentication failed: Please log in again.';
      } else if (e is ServerException) {
        detailedError = 'Server error: Please try again later.';
      }
      setState(() {
        messageTypes = messageTypes.isNotEmpty
            ? messageTypes
            : [
                <String, dynamic>{
                  'title': 'Swedish Massage',
                  'image': '${ApiService.baseUrl}/media/documents/default2.jpg'
                },
              ];
        if (therapistRole != null &&
            !messageTypes.any((type) => type['title']
                .toLowerCase()
                .contains(therapistRole.toLowerCase()))) {
          messageTypes.add(<String, dynamic>{
            'title': therapistRole,
            'image': '${ApiService.baseUrl}/media/documents/default2.jpg'
          });
          _selectedMessageType = therapistRole;
        } else if (messageTypes.isNotEmpty && _selectedMessageType.isEmpty) {
          _selectedMessageType = messageTypes[0]['title'] as String;
        }
        errorMessage = detailedError;
        isLoading = false;
        AppLogger.debug('Fallback Message Types: $messageTypes');
        AppLogger.debug('Selected Message Type: $_selectedMessageType');
      });
      if (e is! TypeError) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          AppLogger.debug('Showing Error SnackBar with Retry');
          CustomSnackBar.show(
            context,
            errorMessage!,
            type: ToastificationType.error,
          );
        });
      }
    }
  }

  void _showTherapistDialog() {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
        backgroundColor: Colors.white,
        child: Container(
          padding: EdgeInsets.all(16.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Select Therapist',
                  style:
                      TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold)),
              SizedBox(height: 16.h),
              SizedBox(
                height: 300.h,
                child: FutureBuilder<List<Map<String, dynamic>>>(
                  future: apiService
                      .getTherapistsByMassageType(_selectedMessageType),
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
                      return Center(
                          child: Text(
                              'No therapists available for $_selectedMessageType',
                              style: TextStyle(fontSize: 14.sp)));
                    }

                    final therapists = snapshot.data!
                        .map((json) => Therapist.fromJson(json))
                        .toList();

                    return ListView.builder(
                      itemCount: therapists.length,
                      itemBuilder: (context, index) {
                        final therapist = therapists[index];
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundImage:
                                CachedNetworkImageProvider(therapist.image),
                            radius: 20.r,
                            onBackgroundImageError: (_, stackTrace) {
                              AppLogger.error(
                                  'Therapist image error: ${therapist.image}');
                            },
                          ),
                          title: Text(
                            therapist.name.isNotEmpty
                                ? therapist.name
                                : 'Unknown Therapist',
                            style: TextStyle(fontSize: 16.sp),
                          ),
                          subtitle: Row(
                            children: [
                              Icon(Icons.star,
                                  size: 16.sp, color: Colors.amber),
                              Text(
                                ' ${therapist.rating.toStringAsFixed(1)} (${therapist.reviewCount} reviews)',
                                style: TextStyle(fontSize: 14.sp),
                              ),
                            ],
                          ),
                          onTap: () {
                            setState(() => _selectedTherapist = therapist);
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

  void _showDateTimePickerModal() {
    DateTime selectedDate = DateTime.now();
    final hourController = TextEditingController(
        text: (TimeOfDay.now().hourOfPeriod == 0
                ? 12
                : TimeOfDay.now().hourOfPeriod)
            .toString());
    final minuteController = TextEditingController(
        text: TimeOfDay.now().minute.toString().padLeft(2, '0'));
    bool isAm = TimeOfDay.now().period == DayPeriod.am;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.r)),
          child: StatefulBuilder(
            builder: (context, setModalState) {
              return Padding(
                padding: EdgeInsets.all(16.w),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TableCalendar(
                        firstDay: DateTime.now(),
                        lastDay: DateTime(2100),
                        focusedDay: selectedDate,
                        selectedDayPredicate: (day) =>
                            isSameDay(day, selectedDate),
                        onDaySelected: (selected, focused) =>
                            setModalState(() => selectedDate = selected),
                        headerStyle: HeaderStyle(
                            formatButtonVisible: false,
                            titleCentered: true,
                            leftChevronIcon:
                                Icon(Icons.chevron_left, color: primaryColor),
                            rightChevronIcon:
                                Icon(Icons.chevron_right, color: primaryColor)),
                        calendarStyle: CalendarStyle(
                          selectedDecoration: BoxDecoration(
                              color: primaryColor, shape: BoxShape.circle),
                          todayDecoration: BoxDecoration(
                              color: primaryColor.withAlpha(50),
                              shape: BoxShape.circle),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Align(
                          alignment: Alignment.centerLeft,
                          child: Text("Time",
                              style: TextStyle(
                                  fontSize: 16.sp,
                                  fontWeight: FontWeight.w500))),
                      SizedBox(height: 8.h),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: 5.w, vertical: 5.h),
                            decoration: BoxDecoration(
                                color: Color(0xffF0F3F7),
                                borderRadius: BorderRadius.circular(12.r)),
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
                                        isDense: true),
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
                                        isDense: true),
                                    textAlign: TextAlign.center,
                                    style: TextStyle(fontSize: 16.sp),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          Container(
                            height: 40.h,
                            padding: EdgeInsets.symmetric(horizontal: 3.w),
                            decoration: BoxDecoration(
                                color: Color(0xffF0F3F7),
                                borderRadius: BorderRadius.circular(12.r)),
                            child: Row(
                              children: [
                                GestureDetector(
                                  onTap: () => setModalState(() => isAm = true),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                        color: isAm
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(8.r)),
                                    child: Text("AM",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                            fontSize: 14.sp)),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () =>
                                      setModalState(() => isAm = false),
                                  child: Container(
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 12.w, vertical: 6.h),
                                    decoration: BoxDecoration(
                                        color: !isAm
                                            ? Colors.white
                                            : Colors.transparent,
                                        borderRadius:
                                            BorderRadius.circular(8.r)),
                                    child: Text("PM",
                                        style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.black,
                                            fontSize: 14.sp)),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 8.w),
                          ThaiMassageButton(
                            height: 0.04.sh,
                            width: 0.25.sw,
                            fontsize: 12,
                            backgroundColor: primaryColor,
                            text: "Done",
                            onPressed: () {
                              int hour = int.tryParse(hourController.text) ?? 0;
                              int minute =
                                  int.tryParse(minuteController.text) ?? 0;
                              if (hour < 1 ||
                                  hour > 12 ||
                                  minute < 0 ||
                                  minute > 59) {
                                CustomSnackBar.show(
                                    context, "Please enter a valid time",
                                    type: ToastificationType.error);
                                return;
                              }
                              final convertedHour = isAm
                                  ? (hour == 12 ? 0 : hour)
                                  : (hour == 12 ? 12 : hour + 12);
                              final selectedDateTime = DateTime(
                                  selectedDate.year,
                                  selectedDate.month,
                                  selectedDate.day,
                                  convertedHour,
                                  minute);
                              setState(
                                  () => _selectedDateTime = selectedDateTime);
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
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Massage Type',
                        style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: Colors.black)),
                    SizedBox(height: 12.h),
                    isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : SizedBox(
                            height: 0.18.sh,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: messageTypes.length,
                              itemBuilder: (context, index) {
                                final messageType = messageTypes[index];
                                return Padding(
                                  padding:
                                      EdgeInsets.symmetric(horizontal: 8.w),
                                  child: CategoryItem(
                                    title: messageType['title']!,
                                    image: messageType['image']!,
                                    isSelected: _selectedMessageType ==
                                        messageType['title'],
                                    onTap: () => setState(() {
                                      _selectedMessageType =
                                          messageType['title']!;
                                      _selectedTherapist =
                                          null; // Reset therapist
                                    }),
                                  ),
                                );
                              },
                            ),
                          ),
                    if (errorMessage != null) ...[
                      SizedBox(height: 12.h),
                      Center(
                        child: Text(
                          errorMessage!,
                          style: TextStyle(fontSize: 14.sp, color: Colors.red),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                    _buildCheckboxOption(
                        'I am a returning customer',
                        _isReturningCustomer,
                        (value) =>
                            setState(() => _isReturningCustomer = value!)),
                    SizedBox(height: 12.h),
                    _buildCheckboxOption(
                        'I have my own massage table',
                        _hasOwnMassageTable,
                        (value) =>
                            setState(() => _hasOwnMassageTable = value!)),
                    Padding(
                        padding: const EdgeInsets.only(left: 50),
                        child: Text("\$10 Discount if you have Massage Table",
                            style: TextStyle(
                                fontSize: 10.sp, color: Color(0xff808080)))),
                    SizedBox(height: 5.h),
                  ],
                ),
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
                      RangeSlider(
                        values: _ageRange,
                        min: 18,
                        max: 70,
                        divisions: 52,
                        labels: RangeLabels(_ageRange.start.round().toString(),
                            _ageRange.end.round().toString()),
                        onChanged: (values) =>
                            setState(() => _ageRange = values),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_ageRange.start.round()}',
                              style: TextStyle(fontSize: 14.sp)),
                          Text('${_ageRange.end.round()}',
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
                        _buildTextOption('Single', isSelected: !_isBackToBack),
                        SizedBox(width: 12.w),
                        _buildTextOption('Back to Back',
                            isSelected: _isBackToBack),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text('Select number of people',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 8.h),
                    Row(
                      children: [
                        IconButton(
                            icon:
                                Icon(Icons.remove_circle_outline, size: 24.sp),
                            onPressed: _numberOfPeople > 1
                                ? () => setState(() => _numberOfPeople--)
                                : null),
                        Text('$_numberOfPeople',
                            style: TextStyle(
                                fontSize: 16.sp, fontWeight: FontWeight.bold)),
                        IconButton(
                            icon: Icon(Icons.add_circle_outline, size: 24.sp),
                            onPressed: _numberOfPeople < 5
                                ? () => setState(() => _numberOfPeople++)
                                : null),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Duration',
                            style: TextStyle(
                                fontSize: 18.sp, fontWeight: FontWeight.w600)),
                        Text(_selectedDuration,
                            style: TextStyle(
                                fontSize: 16.sp,
                                fontWeight: FontWeight.w600,
                                color: primaryTextColor)),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        thumbShape:
                            const RoundSliderThumbShape(enabledThumbRadius: 8),
                        overlayShape:
                            const RoundSliderOverlayShape(overlayRadius: 16),
                        activeTrackColor: primaryTextColor,
                        inactiveTrackColor: Colors.grey[200],
                        thumbColor: Colors.white,
                        overlayColor: boxColor,
                        trackHeight: 8.0.h,
                        valueIndicatorColor: secounderyBorderColor,
                        valueIndicatorTextStyle:
                            TextStyle(color: Colors.black, fontSize: 14.sp),
                      ),
                      child: Slider(
                        value: double.parse(_selectedDuration.split(' ')[0]),
                        min: 30,
                        max: 120,
                        divisions: 90,
                        label: _selectedDuration,
                        onChanged: (value) => setState(
                            () => _selectedDuration = '${value.round()} min'),
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('30 min',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600])),
                        Text('120 min',
                            style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w400,
                                color: Colors.grey[600])),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text('Therapist',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 20.h),
                    InkWell(
                      onTap: _showTherapistDialog,
                      child: Row(
                        children: [
                          if (_selectedTherapist != null &&
                              _selectedTherapist!.image.isNotEmpty &&
                              _selectedTherapist!.name.isNotEmpty) ...[
                            CircleAvatar(
                              backgroundImage: CachedNetworkImageProvider(
                                  _selectedTherapist!.image),
                              radius: 20.r,
                              onBackgroundImageError: (error, stackTrace) {
                                AppLogger.error(
                                    'Therapist image load error: ${error.toString()}, URL: ${_selectedTherapist!.image}');
                              },
                            ),
                            SizedBox(width: 12.w),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _selectedTherapist!.name,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      fontSize: 16.sp),
                                ),
                                Text(
                                  _selectedTherapist!.assignRole,
                                  style: TextStyle(
                                      fontSize: 12.sp, color: Colors.grey),
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
                          if (_selectedTherapist != null)
                            Text('Change',
                                style: TextStyle(
                                    color: primaryTextColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: 16.sp)),
                        ],
                      ),
                    ),
                    SizedBox(height: 20.h),
                    Text('Do you want instant appointment?',
                        style: TextStyle(
                            fontSize: 14.sp, fontWeight: FontWeight.w400)),
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
                            backgroundColor: _isScheduleSelected
                                ? Colors.white
                                : primaryButtonColor,
                            textColor: _isScheduleSelected
                                ? Colors.black54
                                : Colors.white,
                            borderColor: _isScheduleSelected
                                ? primaryButtonColor
                                : primaryButtonColor,
                            onPressed: () => setState(() {
                              _isScheduleSelected = false;
                              _selectedDateTime = null;
                            }),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: ThaiMassageButton(
                            width: 0.35.sw,
                            fontsize: 14,
                            height: .045.sh,
                            text: 'Schedule',
                            backgroundColor: _isScheduleSelected
                                ? primaryButtonColor
                                : Colors.white,
                            textColor: _isScheduleSelected
                                ? Colors.white
                                : Colors.black54,
                            borderColor: _isScheduleSelected
                                ? primaryButtonColor
                                : primaryButtonColor,
                            onPressed: () =>
                                setState(() => _isScheduleSelected = true),
                          ),
                        ),
                      ],
                    ),
                    if (_selectedTherapist != null && _isScheduleSelected) ...[
                      SizedBox(height: 20.h),
                      Text('Date & Time',
                          style: TextStyle(
                              fontSize: 18.sp, fontWeight: FontWeight.w600)),
                      SizedBox(height: 20.h),
                      GestureDetector(
                        onTap: _showDateTimePickerModal,
                        child: AbsorbPointer(
                          child: TextField(
                            readOnly: true,
                            controller: TextEditingController(
                              text: _selectedDateTime != null
                                  ? DateFormat('MMM d, yyyy h:mm a')
                                      .format(_selectedDateTime!)
                                  : null,
                            ),
                            decoration: InputDecoration(
                              prefixIcon: Icon(Icons.calendar_month,
                                  color: primaryButtonColor),
                              hintText: _selectedDateTime == null
                                  ? "Select Date & Time"
                                  : null,
                              hintStyle: TextStyle(
                                  fontSize: 14.sp, color: Colors.black54),
                              filled: true,
                              fillColor: textFieldColor,
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                  borderSide: BorderSide(
                                      color: borderColor.withAlpha(40),
                                      width: 1.5.w)),
                              enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                  borderSide: BorderSide(
                                      color: borderColor.withAlpha(40),
                                      width: 1.5.w)),
                              focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20.r),
                                  borderSide: BorderSide(
                                      color: borderColor.withAlpha(40),
                                      width: 2.w)),
                              contentPadding:
                                  EdgeInsets.symmetric(vertical: 16.h),
                            ),
                          ),
                        ),
                      ),
                    ],
                    SizedBox(height: 20.h),
                    Text('Location',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(
                            child: _buildLocationOption('Home',
                                isSelected: _location == 'Home')),
                        SizedBox(width: 12.w),
                        Expanded(
                            child: _buildLocationOption('Office',
                                isSelected: _location == 'Office')),
                        SizedBox(width: 12.w),
                        Expanded(
                            child: _buildLocationOption('Hotel',
                                isSelected: _location == 'Hotel')),
                      ],
                    ),
                    SizedBox(height: 20.h),
                    Text('Location Detail',
                        style: TextStyle(
                            fontSize: 18.sp, fontWeight: FontWeight.w600)),
                    SizedBox(height: 12.h),
                    Row(
                      children: [
                        Expanded(child: _buildTextInput("Number of floors")),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDropdownField(
                            label: "Elevator/Escalator",
                            value: _elevatorSelection,
                            items: ['Yes', 'No'],
                            onChanged: (value) =>
                                setState(() => _elevatorSelection = value),
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
                            value: _parkingSelection,
                            items: ['Street', 'Garage', 'None'],
                            onChanged: (value) =>
                                setState(() => _parkingSelection = value),
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: _buildDropdownField(
                            label: "Any pets",
                            value: _petsSelection,
                            items: ['Yes', 'No'],
                            onChanged: (value) =>
                                setState(() => _petsSelection = value),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 40.h),
                    Padding(
                      padding: const EdgeInsets.all(15),
                      child: CustomGradientButton(
                        text: "Proceed to Pay",
                        onPressed: () async {
                          // Show loading indicator immediately for better UX
                          LoadingManager.showLoading();

                          // Validation
                          if (_selectedTherapist == null ||
                              (_isScheduleSelected && _selectedDateTime == null)) {
                            LoadingManager.hideLoading();
                            CustomSnackBar.show(
                              context,
                              'Please select a therapist and date/time for scheduled appointments',
                              type: ToastificationType.error,
                            );
                            return;
                          }

                          // Fetch location
                          double? latitude;
                          double? longitude;
                          try {
                            // Check if a valid cached location is available
                            if (locationController.hasValidLocation &&
                                locationController.position.value != null) {
                              latitude = double.parse(
                                  locationController.position.value!.latitude.toStringAsFixed(6));
                              longitude = double.parse(
                                  locationController.position.value!.longitude.toStringAsFixed(6));
                              AppLogger.debug(
                                  'Using cached location: lat=$latitude, lon=$longitude');
                            } else {
                              // Fetch new location if cached location is invalid or unavailable
                              await locationController.fetchCurrentLocation();
                              if (!locationController.hasError.value &&
                                  locationController.position.value != null) {
                                latitude = double.parse(
                                    locationController.position.value!.latitude.toStringAsFixed(6));
                                longitude = double.parse(
                                    locationController.position.value!.longitude.toStringAsFixed(6));
                                AppLogger.debug(
                                    'Fetched new location: lat=$latitude, lon=$longitude');
                              } else {
                                LoadingManager.hideLoading();
                                CustomSnackBar.show(
                                  context,
                                  'Failed to get location: ${locationController.locationName.value}',
                                  type: ToastificationType.error,
                                );
                                return;
                              }
                            }
                          } catch (e) {
                            LoadingManager.hideLoading();
                            CustomSnackBar.show(
                              context,
                              'Failed to get location: $e',
                              type: ToastificationType.error,
                            );
                            return;
                          }

                          final preferencesController =
                          Get.find<CustomerPreferencesController>();
                          final preferences = preferencesController.getAllPreferences();

                          // Get user ID
                          final userId = await _storage.read(key: 'user_id');
                          if (userId == null) {
                            LoadingManager.hideLoading();
                            CustomSnackBar.show(
                              context,
                              'Please log in to create a booking',
                              type: ToastificationType.error,
                            );
                            return;
                          }

                          final selectedMessage = messageTypes.firstWhere(
                                (message) => message["title"] == _selectedMessageType,
                            orElse: () => <String, dynamic>{
                              "title": "Swedish Massage",
                              "image": "${ApiService.baseUrl}/media/documents/default2.jpg"
                            },
                          );

                          // Handle created_at and date_time
                          final now = DateTime.now();
                          final createdAt = _isScheduleSelected && _selectedDateTime != null
                              ? _selectedDateTime!
                              : now.add(Duration(minutes: 30));
                          final dateTime = _isScheduleSelected && _selectedDateTime != null
                              ? _selectedDateTime!
                              : now;

                          // Map massage type to API format
                          final massageTypeMap = messageTypes.asMap().map(
                                  (_, type) => MapEntry(
                                  type['title'],
                                  type['title']
                                      .toLowerCase()
                                      .replaceAll(' ', '_')
                                      .replaceAll(RegExp(r'[^\w_]'), '')));

                          // Build preference payload (only include non-empty values)
                          final preferencePayload = {
                            if (preferences['Preferred Modality']?.isNotEmpty ?? false)
                              'preferred_modality': preferences['Preferred Modality'],
                            if (preferences['Preferred Pressure']?.isNotEmpty ?? false)
                              'preferred_pressure': preferences['Preferred Pressure'],
                            if (preferences['Reasons for Massage']?.isNotEmpty ?? false)
                              'reason_for_massage': preferences['Reasons for Massage'],
                            if (preferences['Moisturizer Preferences']?.isNotEmpty ?? false)
                              'moisturizer': preferences['Moisturizer Preferences'],
                            if (preferences['Music Preference']?.isNotEmpty ?? false)
                              'music_preference': preferences['Music Preference'],
                            if (preferences['Conversation Preferences']?.isNotEmpty ?? false)
                              'conversation_preference': preferences['Conversation Preferences'],
                            if (preferences['Pregnancy (Female customers)']?.isNotEmpty ?? false)
                              'pregnancy': preferences['Pregnancy (Female customers)'],
                          };

                          // Build full payload
                          final payload = {
                            'name': _selectedMessageType,
                            'age_range_start': _ageRange.start.round(),
                            'age_range_end': _ageRange.end.round(),
                            'massage_preference': _isBackToBack ? 'back_to_back' : 'single',
                            'number_of_people': _numberOfPeople,
                            'duration': int.parse(_selectedDuration.split(' ')[0]),
                            'date_time': dateTime.toUtc().toIso8601String(),
                            'location_type': _location.toLowerCase(),
                            'number_of_floors':
                            int.tryParse(_numberOfFloorsController.text) ?? 0,
                            'elevator_or_escalator': _elevatorSelection == 'Yes',
                            'parking_type': _parkingSelection ?? 'None',
                            'any_pets': _petsSelection == 'Yes',
                            'massage_type': massageTypeMap[_selectedMessageType] ?? 'swedish_massage',
                            'instant_appointment': !_isScheduleSelected,
                            'created_at': createdAt.toUtc().toIso8601String(),
                            'user': int.parse(userId),
                            'therapist_input_user_id': _selectedTherapist!.user,
                            'i_am_returning_customer': _isReturningCustomer,
                            'have_own_massage_table': _hasOwnMassageTable,
                            'latitude': latitude,
                            'longitude': longitude,
                            ...preferencePayload, // Spread non-empty preferences
                          };

                          AppLogger.debug('Booking Payload: $payload');

                          try {
                            final response = await apiService.createBooking(payload);
                            preferencesController.clearPreferences();
                            CustomSnackBar.show(
                              context,
                              'Booking created successfully!',
                              type: ToastificationType.success,
                            );

                            // Proceed to PaymentOptionsSheet
                            await Future.delayed(Duration(
                                milliseconds: 500)); // Brief delay for UX (optional)
                            LoadingManager.hideLoading();

                            PaymentOptionsSheet.show(
                              context,
                              creditCardRoute: Routes.appointmentPaymentPage,
                              arguments: {
                                'image': selectedMessage["image"],
                                'name': selectedMessage["title"],
                                'dateTime': _selectedDateTime?.toIso8601String(),
                                'elevator': _elevatorSelection,
                                'parking': _parkingSelection,
                                'pets': _petsSelection,
                                'preferences': preferences,
                                'booking_id': response['id'],
                                'therapist_user_id': _selectedTherapist!.user,
                                'therapist_name': _selectedTherapist!.name,
                              },
                            );
                          } catch (e) {
                            LoadingManager.hideLoading();
                            String errorMessage = 'Failed to create booking: $e';
                            if (e.toString().contains('NetworkException')) {
                              errorMessage =
                              'No internet connection. Please check your network and try again.';
                            } else if (e.toString().contains('Please select a valid age range')) {
                              errorMessage = 'Please select a valid age range.';
                            } else if (e.toString().contains(
                                'Ensure that there are no more than 6 decimal places')) {
                              errorMessage =
                              'Location coordinates are too precise. Please try again.';
                            }
                            CustomSnackBar.show(
                              context,
                              errorMessage,
                              type: ToastificationType.error,
                            );
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ));
  }

  Widget _buildCheckboxOption(
      String title, bool value, Function(bool?) onChanged) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 22.h,
          child: Checkbox(
              value: value,
              onChanged: onChanged,
              activeColor: primaryButtonColor),
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
                  Text(title,
                      style: TextStyle(
                          fontSize: 18.sp, fontWeight: FontWeight.w600)),
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
      onTap: () => setState(() => _isBackToBack = title == 'Back to Back'),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 5.h),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20.r),
          color: isSelected ? boxColor : Colors.white,
          border: Border.all(
              color:
                  isSelected ? borderColor.withAlpha(100) : Color(0xffE0E0E0)),
        ),
        child: Text(title,
            style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w500,
                fontSize: 14.sp)),
      ),
    );
  }

  Widget _buildLocationOption(String title, {required bool isSelected}) {
    return InkWell(
      onTap: () => setState(() => _location = title),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
        decoration: BoxDecoration(
          color: isSelected ? boxColor : Colors.white,
          borderRadius: BorderRadius.circular(20.r),
          border: Border.all(
              color: isSelected
                  ? borderColor.withAlpha(100)
                  : Colors.grey.shade300),
        ),
        child: Center(
            child: Text(title,
                style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w500,
                    fontSize: 14.sp))),
      ),
    );
  }

  Widget _buildDropdownField(
      {required String label,
      required String? value,
      required List<String> items,
      required ValueChanged<String?> onChanged}) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(8.r)),
      child: DropdownButton<String>(
        value: value,
        hint:
            Text(label, style: TextStyle(color: Colors.grey, fontSize: 14.sp)),
        isExpanded: true,
        underline: SizedBox(),
        icon: Icon(Icons.keyboard_arrow_down, size: 16.sp),
        items: items.map((String item) {
          return DropdownMenuItem<String>(
              value: item,
              child: Text(item,
                  style: TextStyle(
                      fontWeight: FontWeight.w500,
                      fontSize: 14.sp,
                      color: Colors.black)));
        }).toList(),
        onChanged: onChanged,
        dropdownColor: Colors.white,
      ),
    );
  }

  Widget _buildTextInput(String label) {
    return TextFormField(
      controller: _numberOfFloorsController,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: Colors.grey, fontSize: 14.sp),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey.shade300)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8.r),
            borderSide: BorderSide(color: Colors.grey.shade300)),
      ),
      keyboardType: TextInputType.number,
    );
  }
}
