import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class ChatDetailScreen extends StatelessWidget {
  const ChatDetailScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Row(
          children: [
            const CircleAvatar(backgroundImage: AssetImage('assets/images/therapist.png')),
            SizedBox(width: 8.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Smith Mathew", style: TextStyle(color: Colors.black, fontWeight: FontWeight.w600, fontSize: 14.sp)),
                Text("Active now", style: TextStyle(fontSize: 11.sp, color: Colors.green)),
              ],
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.call, color: Colors.black)),
        ],
        leading: const BackButton(color: Colors.black),
      ),
      backgroundColor: const Color(0xffF8F6F1),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16.w),
              children: [
                _chatBubble("Hi, are you available?", isMe: true),
                _chatBubble("Hello, yes!", isMe: false),
                _voiceBubble(isMe: true),
                _daySeparator("Thursday 24, 2025"),
                _voiceBubble(isMe: false),
                _chatBubble("Ok!", isMe: false),
                _voiceBubble(isMe: true),
              ],
            ),
          ),
          _messageInput(),
        ],
      ),
    );
  }

  Widget _chatBubble(String text, {required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xffF8E5B8) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isMe ? 16.r : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16.r),
          ),
        ),
        child: Text(text, style: TextStyle(fontSize: 14.sp)),
      ),
    );
  }

  Widget _voiceBubble({required bool isMe}) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(top: 8.h),
        padding: EdgeInsets.all(10.w),
        decoration: BoxDecoration(
          color: isMe ? const Color(0xffF8E5B8) : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(16.r),
            topRight: Radius.circular(16.r),
            bottomLeft: Radius.circular(isMe ? 16.r : 0),
            bottomRight: Radius.circular(isMe ? 0 : 16.r),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.play_arrow, size: 24.sp, color: Colors.grey),
            SizedBox(width: 8.w),
            Image.asset(
              isMe
                  ? 'assets/images/voice_wave_yellow.png'
                  : 'assets/images/voice_wave_grey.png',
              width: 80.w,
              height: 20.h,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  Widget _daySeparator(String date) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        child: Text(date, style: TextStyle(color: Colors.grey, fontSize: 12.sp)),
      ),
    );
  }

  Widget _messageInput() {
    return SafeArea(
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  hintText: "Send Message",
                  border: InputBorder.none,
                ),
              ),
            ),
            IconButton(onPressed: () {}, icon: Icon(Icons.attachment, color: Colors.grey)),
            IconButton(
              onPressed: () {},
              icon: CircleAvatar(
                radius: 20.r,
                backgroundColor: const Color(0xffB48D3C),
                child: const Icon(Icons.mic, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
