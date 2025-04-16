import 'package:country_pickers/countries.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../themes/colors.dart';

class PhoneNumberField extends StatefulWidget {
  final TextEditingController? controller; // Controller for phone number input
  final ValueChanged<String>? onChanged; // Optional callback for input changes

  const PhoneNumberField({
    super.key,
    this.controller,
    this.onChanged,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  final List<Country> _allCountries = countryList;
  Country _selectedCountry = CountryPickerUtils.getCountryByIsoCode('US'); // Default to US
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    // Use provided controller or create an internal one
    _internalController = widget.controller ?? TextEditingController();
  }

  @override
  void dispose() {
    // Dispose internal controller only if widget.controller is null
    if (widget.controller == null) {
      _internalController.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: textFieldColor,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: borderColor.withAlpha(40), width: 1.5.w),
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
                Text(
                  "+${_selectedCountry.phoneCode}",
                  style: TextStyle(fontSize: 14.sp, color: Colors.black),
                ),
                Icon(Icons.arrow_drop_down, color: Colors.black54),
              ],
            ),
          ),
          SizedBox(width: 10.w),

          // Phone Number Input Field
          Expanded(
            child: TextField(
              controller: _internalController,
              onChanged: widget.onChanged,
              decoration: InputDecoration(
                hintText: "Enter phone number",
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.phone,
              autofocus: false, // Changed to false to avoid focus conflicts
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
        return Container(
          height: 400.h,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(20.r),
              topRight: Radius.circular(20.r),
            ),
          ),
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

  // Helper method to get full phone number with country code
  String getFullPhoneNumber() {
    return "+${_selectedCountry.phoneCode}${_internalController.text.trim()}";
  }
}