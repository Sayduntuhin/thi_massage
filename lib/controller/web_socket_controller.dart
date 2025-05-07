import 'dart:convert';
import 'package:get/get.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../view/widgets/app_logger.dart';

class WebSocketController extends GetxController {
  final _webSocketUrl = 'ws://192.168.10.139:3333/ws/location/';
  WebSocketChannel? _webSocketChannel;
  final nearbyTherapists = <Map<String, dynamic>>[].obs;
  final isTherapistsLoading = true.obs;
  final errorMessage = Rx<String?>(null);

  @override
  void onInit() {
    super.onInit();
    connect();
  }

  @override
  void onClose() {
    _webSocketChannel?.sink.close();
    AppLogger.debug('WebSocket closed');
    super.onClose();
  }

  void connect() {
    try {
      _webSocketChannel = WebSocketChannel.connect(Uri.parse(_webSocketUrl));
      AppLogger.debug('WebSocket connected to $_webSocketUrl');

      _webSocketChannel!.stream.listen(
            (message) {
          final data = jsonDecode(message);
          AppLogger.debug('WebSocket received: $data');
          if (data.containsKey('nearby_users')) {
            nearbyTherapists.value = List<Map<String, dynamic>>.from(data['nearby_users'] ?? []);
            isTherapistsLoading.value = false;
            errorMessage.value = null;
            AppLogger.debug('Updated nearbyTherapists: ${nearbyTherapists.value}');
          } else {
            AppLogger.debug('Ignoring non-therapist message: $data');
          }
        },
        onError: (error) {
          AppLogger.error('WebSocket error: $error');
          errorMessage.value = 'Failed to load nearby therapists';
          isTherapistsLoading.value = false;
        },
        onDone: () {
          AppLogger.debug('WebSocket closed');
          isTherapistsLoading.value = false;
        },
      );
    } catch (e) {
      AppLogger.error('WebSocket connection error: $e');
      errorMessage.value = 'Failed to connect to location service';
      isTherapistsLoading.value = false;
    }
  }

  Future<void> reconnect() async {
    _webSocketChannel?.sink.close();
    await Future.delayed(const Duration(milliseconds: 1000)); // Increased delay
    connect();
  }
}