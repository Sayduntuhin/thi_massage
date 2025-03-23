import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:thi_massage/themes/colors.dart';
import 'package:thi_massage/view/widgets/custom_gradientButton.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(5, 50); // Start range from $5
  String _selectedGender = "Any";
  String? _selectedRating;
  List<String> selectedTimes = [];

  List<String> times = ["10:00 am", "1:00 pm", "12:00 pm", "2:00 pm", "03:00 pm", "05:00 pm"];
  List<Map<String, dynamic>> ratings = [
    {"value": "5.0"},
    {"value": "4.0"},
    {"value": "3.0"},
    {"value": "2.0"},
    {"value": "1.0"},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
      decoration: BoxDecoration(
        color: Colors.white, // Beige background color
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 70.w,
              height: 5.h,
              decoration: BoxDecoration(
                color: Color(0xff8F5E0A).withAlpha(50),
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
          ),
          SizedBox(height: 20.h),

          // Ratings Section
          Text(
            "Ratings",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: ratings.map((rating) {
              bool isSelected = _selectedRating == rating["value"];
              return InkWell(
                onTap: () {
                  setState(() {
                    _selectedRating = rating["value"];
                  });
                },
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
                  decoration: BoxDecoration(
                    color: isSelected ? boxColor : Colors.white,
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected ? borderColor.withAlpha(100) : Color(0xffE0E0E0),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, color: Color(0xffFCB205), size: 14.sp),
                      SizedBox(width: 4.w),
                      Text(
                        rating["value"],
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w500,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),

          // Price Range Section
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Price Range",
                style: TextStyle(
                  fontSize: 20.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.r),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  "\$${_priceRange.start.toInt()}-\$${_priceRange.end.toInt()}",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w700,
                    color: primaryTextColor.withAlpha(200),
                  ),
                ),
              ),
            ],
          ),

          SliderTheme(
            data: SliderThemeData(
              showValueIndicator: ShowValueIndicator.onlyForContinuous,
              activeTrackColor: const Color(0xFFB39654), // Golden color
              inactiveTrackColor: Colors.grey.shade300,
              thumbColor: Colors.white,
              overlayColor: const Color(0xffEDEDED),
              thumbShape: RoundSliderThumbShape(enabledThumbRadius: 50.r),
              trackHeight: 8.h,
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 5, // Start from $5
              max: 100,
              labels: RangeLabels(
                "\$${_priceRange.start.toInt()}",
                "\$${_priceRange.end.toInt()}",
              ),
              onChanged: (values) {
                setState(() {
                  _priceRange = values;
                });
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "\$5",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color: Color(0xffA0A0A0)
                ),
              ),
              Text(
                "\$100",
                style: TextStyle(
                  fontSize: 15.sp,
                  fontWeight: FontWeight.w500,
                  color:  Color(0xffA0A0A0),
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),

          // Gender Section
          Text(
            "Gender",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.start,
            children: ["Any", "Male", "Female"].map((gender) {
              bool isSelected = _selectedGender == gender;
              return Padding(
                padding: EdgeInsets.only(right: 10.w),
                child: InkWell(
                  onTap: () {
                    setState(() {
                      _selectedGender = gender;
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
                    decoration: BoxDecoration(
                      color: isSelected ? boxColor : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected ? borderColor.withAlpha(100) : Color(0xffE0E0E0),
                      ),
                    ),
                    child: Text(
                      gender,
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.w500,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),

          // Availability Section
          Text(
            "Availability",
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 10.h),
          Wrap(
            spacing: 10.w,
            runSpacing: 10.h,
            children: times.map((time) {
              bool isSelected = selectedTimes.contains(time);
              return InkWell(
                onTap: () {
                  setState(() {
                    isSelected ? selectedTimes.remove(time) : selectedTimes.add(time);
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
                  child: Text(
                    time,
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          SizedBox(height: 20.h),

          // Reset & Apply Buttons
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(
                width: 0.4.sw,
                child: TextButton(
                  onPressed: () {
                    setState(() {
                      _priceRange = const RangeValues(5, 50); // Reset to start from $5
                      _selectedGender = "Any";
                      _selectedRating = null;
                      selectedTimes.clear();
                    });
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.grey.shade700,
                  ),
                  child: Text(
                    "Reset all",
                    style: TextStyle(
                      fontSize: 18.sp,
                      color: primaryButtonColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: CustomGradientButton(text:"Apply", onPressed: (){
                  Get.back();}),
              )
            ],
          ),
        ],
      ),
    );
  }
}