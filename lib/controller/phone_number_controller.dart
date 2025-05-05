import 'package:country_pickers/countries.dart';
import 'package:country_pickers/country.dart';
import 'package:country_pickers/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../themes/colors.dart';
import '../view/widgets/app_logger.dart';

class PhoneNumberFieldController extends ChangeNotifier {
  Country _selectedCountry = CountryPickerUtils.getCountryByIsoCode('US');
  Country get selectedCountry => _selectedCountry;

  set selectedCountry(Country country) {
    _selectedCountry = country;
    notifyListeners();
  }

  String getFullPhoneNumber(String phoneNumber) {
    return "+${_selectedCountry.phoneCode}${phoneNumber.trim()}";
  }

  String getCountryCode() {
    return "+${_selectedCountry.phoneCode}";
  }
}

class PhoneNumberField extends StatefulWidget {
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final String? initialCountryCode;
  final bool readOnly;
  final PhoneNumberFieldController? phoneFieldController;

  const PhoneNumberField({
    super.key,
    this.controller,
    this.onChanged,
    this.initialCountryCode,
    this.readOnly = false,
    this.phoneFieldController,
  });

  @override
  State<PhoneNumberField> createState() => _PhoneNumberFieldState();
}

class _PhoneNumberFieldState extends State<PhoneNumberField> {
  final List<Country> _allCountries = countryList;
  late PhoneNumberFieldController _controller;
  late TextEditingController _internalController;

  @override
  void initState() {
    super.initState();
    _internalController = widget.controller ?? TextEditingController();
    _controller = widget.phoneFieldController ?? PhoneNumberFieldController();

    if (widget.initialCountryCode != null) {
      final cleanCode = widget.initialCountryCode!.replaceFirst('+', '');
      final country = _allCountries.firstWhere(
            (c) => c.phoneCode == cleanCode && (cleanCode == '880' ? c.isoCode == 'BD' : true),
        orElse: () {
          AppLogger.warning("Country code $cleanCode not found, defaulting to US (+1)");
          return CountryPickerUtils.getCountryByIsoCode('US');
        },
      );
      _controller.selectedCountry = country;
      AppLogger.debug("Selected country: ${country.name}, Phone code: +${country.phoneCode}");
    }
  }

  @override
  void dispose() {
    if (widget.controller == null) {
      _internalController.dispose();
    }
    if (widget.phoneFieldController == null) {
      _controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 3.h),
      decoration: BoxDecoration(
        color: widget.readOnly ? Colors.grey.shade200 : textFieldColor,
        borderRadius: BorderRadius.circular(25.r),
        border: Border.all(color: borderColor.withAlpha(40), width: 1.5.w),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: widget.readOnly ? null : _showCountryPicker,
            child: Row(
              children: [
                CountryPickerUtils.getDefaultFlagImage(_controller.selectedCountry),
                SizedBox(width: 5.w),
                Text(
                  "+${_controller.selectedCountry.phoneCode}",
                  style: TextStyle(fontSize: 14.sp, color: Colors.black),
                ),
                Icon(
                  Icons.arrow_drop_down,
                  color: widget.readOnly ? Colors.black26 : Colors.black54,
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: TextField(
              controller: _internalController,
              onChanged: widget.readOnly ? null : widget.onChanged,
              readOnly: widget.readOnly,
              decoration: InputDecoration(
                hintText: "Enter phone number",
                hintStyle: TextStyle(fontSize: 14.sp, color: Colors.black54),
                border: InputBorder.none,
              ),
              keyboardType: TextInputType.phone,
              autofocus: false,
            ),
          ),
        ],
      ),
    );
  }

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
                          _controller.selectedCountry = country;
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