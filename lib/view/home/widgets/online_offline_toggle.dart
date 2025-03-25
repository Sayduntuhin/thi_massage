import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class OnlineOfflineToggle extends StatefulWidget {
  final bool initialOnline;
  final ValueChanged<bool> onChanged;

  const OnlineOfflineToggle({
    super.key,
    required this.initialOnline,
    required this.onChanged,
  });

  @override
  State<OnlineOfflineToggle> createState() => _OnlineOfflineToggleState();
}

class _OnlineOfflineToggleState extends State<OnlineOfflineToggle> {
  late bool isOnline;

  @override
  void initState() {
    super.initState();
    isOnline = widget.initialOnline;
  }

  void toggleStatus() {
    setState(() {
      isOnline = !isOnline;
      widget.onChanged(isOnline);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleStatus,
      child: Container(
        width: 0.35.sw,
        height: 0.035.sh,
        padding: EdgeInsets.all(4.r),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30.r),
          border: Border.all(color: isOnline ? const Color(0xFF28B446) : Colors.red, width: 1),
        ),
        child: Row(
          children: [
            _buildSide("online", isOnline, const Color(0xFF28B446)),
            _buildSide("offline", !isOnline, Colors.red),
          ],
        ),
      ),
    );
  }

  Widget _buildSide(String label, bool active, Color activeColor) {
    return Expanded(
      child: Container(
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: active ? activeColor : Colors.transparent,
          borderRadius: BorderRadius.circular(30.r),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black45,
            fontSize: 14.sp,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}
