import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:toastification/toastification.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../widgets/app_logger.dart';
import '../../widgets/custom_snackBar.dart';

class PaymentWebViewPage extends StatefulWidget {
  final String sessionUrl;
  final int bookingId;
  final int paymentId;

  const PaymentWebViewPage({
    super.key,
    required this.sessionUrl,
    required this.bookingId,
    required this.paymentId,
  });

  @override
  State<PaymentWebViewPage> createState() => _PaymentWebViewPageState();
}

class _PaymentWebViewPageState extends State<PaymentWebViewPage> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setUserAgent("Mozilla/5.0 (Linux; Android 10; Mobile) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/91.0.4472.120 Mobile Safari/537.36")
      ..addJavaScriptChannel('Flutter', onMessageReceived: (JavaScriptMessage message) {
        AppLogger.debug('JavaScript message: ${message.message}');
      })
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (url) {
            setState(() => _isLoading = true);
            AppLogger.debug('WebView started loading: $url');
          },
          onPageFinished: (url) {
            setState(() => _isLoading = false);
            AppLogger.debug('WebView finished loading: $url');
          },
          onWebResourceError: (error) {
            setState(() => _isLoading = false);
           /* AppLogger.error('WebView error: ${error.description}');
            CustomSnackBar.show(
              context,
              'Failed to load payment page: ${error.description}',
              type: ToastificationType.error,
            );*/
          },
          onNavigationRequest: (request) {
            AppLogger.debug('WebView navigation request: ${request.url}');
            if (request.url.contains('success')) {
              Get.offNamed('/appointmentDetailsPage', arguments: {
                'booking_id': widget.bookingId,
                'payment_id': widget.paymentId,
              });
              return NavigationDecision.prevent;
            } else if (request.url.contains('cancel')) {
              Get.back();
              CustomSnackBar.show(
                context,
                'The payment was cancelled.',
                type: ToastificationType.warning,
              );
              return NavigationDecision.prevent;
            }
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.sessionUrl));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Complete Payment'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Get.back();
            CustomSnackBar.show(
              context,
              'You cancelled the payment process.',
              type: ToastificationType.warning,
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}