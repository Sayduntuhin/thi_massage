import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/controller/user_type_controller.dart';
import 'package:thi_massage/routers/app_router.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';
import 'package:thi_massage/view/widgets/custom_snackbar.dart';
import 'package:toastification/toastification.dart';

class ChatListController extends GetxController {
  final UserTypeController userTypeController = Get.find<UserTypeController>();
  final RxList<Map<String, dynamic>> chatList = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredChatList = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = true.obs;
  final ApiService apiService = ApiService();
  final TextEditingController searchController = TextEditingController();
  int _retryCount = 0;
  static const int maxRetries = 3;

  @override
  void onInit() {
    super.onInit();
    // Delay initial fetch to ensure UI is ready
    WidgetsBinding.instance.addPostFrameCallback((_) {
      fetchChatList();
    });
    searchController.addListener(filterChatList);
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }

  Future<void> fetchChatList({bool isRetry = false}) async {
    if (!isRetry) {
      isLoading.value = true;
      chatList.clear();
      filteredChatList.clear();
      _retryCount = 0;
    }

    try {
      // Fetch chats from server with cache-busting query parameter
      final serverChats = await apiService.fetchChatInbox(
        queryParams: {'t': DateTime.now().millisecondsSinceEpoch.toString()},
      );
      AppLogger.debug('Raw API response: $serverChats');

      // Validate and normalize server data
      final validatedChats = serverChats.where((chat) {
        final hasRequiredFields = chat['chat_room_id'] != null &&
            chat['name'] != null &&
            chat['latest_timestamp'] != null;
        if (!hasRequiredFields) {
          AppLogger.error('Invalid chat data: $chat');
        }
        return hasRequiredFields;
      }).map((chat) {
        // Normalize timestamp to 'dd MMM' for consistency
        final timestamp = chat['latest_timestamp']?.toString();
        final normalizedTimestamp = timestamp != null ? _normalizeTimestamp(timestamp) : null;
        return {
          ...chat,
          'latest_timestamp': normalizedTimestamp ?? DateFormat('dd MMM').format(DateTime.now()),
          'latest_message': chat['latest_message']?.toString() ?? 'No messages yet',
          'unread_count': (chat['unread_count'] is int) ? chat['unread_count'] : 0,
        };
      }).toList();

      // Sort chats by latest_timestamp
      validatedChats.sort((a, b) {
        final aTimestamp = _parseTimestamp(a['latest_timestamp']);
        final bTimestamp = _parseTimestamp(b['latest_timestamp']);
        AppLogger.debug('Sorting: ${a['name']} ($aTimestamp) vs ${b['name']} ($bTimestamp)');
        return bTimestamp.compareTo(aTimestamp); // Most recent first
      });

      chatList.assignAll(validatedChats);
      filterChatList(); // Ensure sorted filtered list
      AppLogger.debug('Processed chats: ${validatedChats.map((c) => {'name': c['name'], 'timestamp': c['latest_timestamp'], 'message': c['latest_message']}).toList()}');
      _retryCount = 0; // Reset retry count on success
    } catch (e) {
      AppLogger.error('Error fetching chat list: $e');
      if (_retryCount < maxRetries) {
        _retryCount++;
        AppLogger.debug('Retrying fetchChatList, attempt $_retryCount');
        await Future.delayed(Duration(seconds: 2));
        return fetchChatList(isRetry: true);
      } else {
        AppLogger.error('Max retries reached for fetchChatList');
        CustomSnackBar.show(
          Get.context!,
          'Error loading chats: $e',
          type: ToastificationType.error,
        );
      }
    } finally {
      if (!isRetry || _retryCount >= maxRetries) {
        isLoading.value = false;
      }
    }
  }

  String _normalizeTimestamp(String timestamp) {
    try {
      // Parse common timestamp formats
      final parsedDate = DateTime.tryParse(timestamp) ??
          DateFormat('dd MMM').parse(timestamp, true) ??
          DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp, true) ??
          DateFormat('yyyy-MM-dd').parse(timestamp, true);
      return DateFormat('dd MMM').format(parsedDate);
    } catch (e) {
      AppLogger.debug('Error normalizing timestamp $timestamp: $e');
      // Fallback to current date to prioritize recent chats
      return DateFormat('dd MMM').format(DateTime.now());
    }
  }

  DateTime _parseTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) {
      AppLogger.debug('Empty or null timestamp, using current time');
      return DateTime.now();
    }
    try {
      // Try parsing ISO 8601, 'dd MMM', or other common formats
      return DateTime.tryParse(timestamp) ??
          DateFormat('dd MMM').parse(timestamp, true) ??
          DateFormat('yyyy-MM-dd HH:mm:ss').parse(timestamp, true) ??
          DateFormat('yyyy-MM-dd').parse(timestamp, true);
    } catch (e) {
      AppLogger.debug('Error parsing timestamp $timestamp: $e');
      return DateTime.now(); // Use current time to prioritize recent chats
    }
  }

  String formatTimestamp(String? timestamp) {
    if (timestamp == null || timestamp.isEmpty) return '';
    try {
      final parsedDate = _parseTimestamp(timestamp);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final messageDate = DateTime(parsedDate.year, parsedDate.month, parsedDate.day);

      if (messageDate == today) {
        return 'Today';
      } else {
        return DateFormat('dd MMM').format(parsedDate);
      }
    } catch (e) {
      AppLogger.debug('Error formatting timestamp $timestamp: $e');
      return timestamp;
    }
  }

  void filterChatList() {
    final query = searchController.text.trim().toLowerCase();
    List<Map<String, dynamic>> tempList;
    if (query.isEmpty) {
      tempList = List.from(chatList);
    } else {
      tempList = chatList.where((chat) {
        final name = chat['name']?.toString().toLowerCase() ?? '';
        return name.contains(query);
      }).toList();
    }

    // Sort by latest_timestamp in descending order
    tempList.sort((a, b) {
      final aTimestamp = _parseTimestamp(a['latest_timestamp']);
      final bTimestamp = _parseTimestamp(b['latest_timestamp']);
      return bTimestamp.compareTo(aTimestamp);
    });

    filteredChatList.assignAll(tempList);
    AppLogger.debug('Filtered and sorted chat list: ${filteredChatList.length} chats, sorted: ${filteredChatList.map((c) => {'name': c['name'], 'timestamp': c['latest_timestamp']}).toList()}');
  }

  void navigateToChatDetail(int index) {
    filteredChatList[index]['unread_count'] = 0;
    filteredChatList.refresh();
    Get.toNamed(
      Routes.chatDetailsPage,
      arguments: {
        'chat_room_id': filteredChatList[index]['chat_room_id'],
        'therapist_user_id': filteredChatList[index]['user_id'],
        'name': filteredChatList[index]['name'],
        'image': getProfileImage(filteredChatList[index]['profile_image']),
      },
    );
  }

  String getProfileImage(String? profileImage) {
    if (profileImage == null) return 'assets/images/therapist.png';
    return profileImage.startsWith('/')
        ? '${ApiService.baseUrl}/api$profileImage'
        : profileImage;
  }
}