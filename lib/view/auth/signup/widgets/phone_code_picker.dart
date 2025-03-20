import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../themes/colors.dart';

class PhoneNumberField extends StatefulWidget {
  const PhoneNumberField({super.key});

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  // Manually defining a list of common countries
  final List<Country> _allCountries = [
    CountryPickerUtils.getCountryByIsoCode('US'), // United States
    CountryPickerUtils.getCountryByIsoCode('IN'), // India
    CountryPickerUtils.getCountryByIsoCode('GB'), // United Kingdom
    CountryPickerUtils.getCountryByIsoCode('CA'), // Canada
    CountryPickerUtils.getCountryByIsoCode('AU'), // Australia
    CountryPickerUtils.getCountryByIsoCode('DE'), // Germany
    CountryPickerUtils.getCountryByIsoCode('FR'), // France
    CountryPickerUtils.getCountryByIsoCode('JP'), // Japan
    CountryPickerUtils.getCountryByIsoCode('BR'), // Brazil
    CountryPickerUtils.getCountryByIsoCode('ZA'), // South Africa
    CountryPickerUtils.getCountryByIsoCode('CN'), // China
  ];

  Country _selectedCountry = CountryPickerUtils.getCountryByIsoCode('US'); // Default to US

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w,vertical: 3.h),
      decoration: BoxDecoration(
        color: textFieldColor,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color:borderColor.withAlpha(40),width: 1.5.w),
      ),
      child: Row(
        children: [
          // Country Picker Dropdown
          GestureDetector(
            onTap: () {
              _showCountryPicker();
            },
            child: Row(
              children: [
                CountryPickerUtils.getDefaultFlagImage(_selectedCountry),
                SizedBox(width: 5.w),
                Text("+${_selectedCountry.phoneCode}",
                    style: TextStyle(fontSize: 14.sp, color: Colors.black)),
                Icon(Icons.arrow_drop_down, color: Colors.black54),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Phone Number Input Field
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: "Enter phone number",
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.phone,
              autofocus: true,
            ),
          ),
        ],
      ),
    );
  }

  // Show Scrollable Bottom Sheet for Country Selection
  void _showCountryPicker() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SizedBox(
          height: 400.h,
          child: Column(
            children: [
              Padding(
                padding: EdgeInsets.all(12.w),
                child: Text(
                  "Select Country",
                  style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.bold),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: _allCountries.length,
                  itemBuilder: (context, index) {
                    final country = _allCountries[index];
                    return ListTile(
                      leading: CountryPickerUtils.getDefaultFlagImage(country),
                      title: Text("${country.name} (+${country.phoneCode})"),
                      onTap: () {
                        setState(() {
                          _selectedCountry = country;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
