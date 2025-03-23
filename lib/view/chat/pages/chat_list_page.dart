import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'chat_details_page.dart';

class ChatListScreen extends StatefulWidget {
  const ChatListScreen({super.key});

  @override
  State<ChatListScreen> createState() => _ChatListScreenState();
}

class _ChatListScreenState extends State<ChatListScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: Colors.black),
      ),
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(16.w),
            child: TextField(
              decoration: InputDecoration(
                hintText: "search",
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: const Color(0xffF8F6F1),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30.r), borderSide: BorderSide.none),
              ),
            ),
          ),
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xffB48D3C),
            unselectedLabelColor: Colors.grey,
            indicatorColor: const Color(0xffB48D3C),
            indicatorWeight: 2.5,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp),
            tabs: const [
              Tab(text: "Chats"),
              Tab(text: "Calls"),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _chatListView(),
                const Center(child: Text("Calls")),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _chatListView() {
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 12.h),
      itemCount: 4,
      itemBuilder: (context, index) {
        return ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatDetailScreen()));
          },
          leading: const CircleAvatar(
            backgroundImage: AssetImage('assets/images/therapist.png'),
          ),
          title: Row(
            children: [
              Text("Smith Mathew", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.sp)),
              if (index == 0) ...[
                SizedBox(width: 4.w),
                const Icon(Icons.verified, size: 16, color: Color(0xffB48D3C)),
              ]
            ],
          ),
          subtitle: const Text("Hi, David. Hope you're doing..."),
          trailing: Text("1${9 - index} feb", style: TextStyle(fontSize: 12.sp, color: Colors.grey)),
        );
      },
    );
  }
}
