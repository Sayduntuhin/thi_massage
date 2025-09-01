import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:thi_massage/view/widgets/app_logger.dart';

class MyRewardsController extends GetxController with GetSingleTickerProviderStateMixin {
  late TabController tabController;
  final ApiService apiService = ApiService();
  final RxMap<String, List<Map<String, dynamic>>> pointsData = RxMap({
    'All': <Map<String, dynamic>>[],
    'Earned': <Map<String, dynamic>>[],
    'Used': <Map<String, dynamic>>[],
    'Expired': <Map<String, dynamic>>[],
  });
  final RxDouble dollarWorth = 0.0.obs;
  final RxInt balancePoints = 0.obs;
  final RxBool isLoading = true.obs;
  final RxString errorMessage = ''.obs;

  @override
  void onInit() {
    super.onInit();
    tabController = TabController(length: pointsData.keys.length, vsync: this);
    fetchRewardsData();
  }

  @override
  void onClose() {
    tabController.dispose();
    super.onClose();
  }

  Future<void> fetchRewardsData() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final data = await apiService.getLoyaltyRewards();
      processApiData(data);
      AppLogger.debug('Rewards data loaded: balancePoints=$balancePoints, dollarWorth=$dollarWorth');
    } catch (e) {
      errorMessage.value = 'Error: $e';
      AppLogger.error('Error fetching rewards data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  String formatDate(String dateString) {
    final date = DateTime.parse(dateString);
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void processApiData(Map<String, dynamic> data) {
    balancePoints.value = data['balance_points'] as int;
    dollarWorth.value = data['dollar_worth'] as double;
    final history = data['history'] as List<dynamic>;

    pointsData.clear();
    pointsData['All'] = [];
    pointsData['Earned'] = [];
    pointsData['Used'] = [];
    pointsData['Expired'] = [];

    for (var item in history) {
      final pointItem = {
        'title': item['description'],
        'date': formatDate(item['created_at']),
        'expired': item['expired_at'] != null ? 'Expired ${formatDate(item['expired_at'])}' : null,
        'points': item['point_type'] == 'used' ? -(item['points'] as int) : item['points'] as int,
      };

      pointsData['All']!.add(pointItem);
      // Explicitly use StringExtension.capitalize to avoid conflict with GetStringUtils
      pointsData[StringExtension(item['point_type'].toString()).capitalize()]!.add(pointItem);
    }
  }
}

// Extension to capitalize string (e.g., 'earned' -> 'Earned')
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}