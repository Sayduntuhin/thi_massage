import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:toastification/toastification.dart';
import '../view/widgets/custom_snackBar.dart';

class CustomerPreferencesController extends GetxController {
  final RxMap<String, String> preferences = <String, String>{}.obs;
  final isLoading = false.obs;
  static const List<String> preferenceKeys = [
    "Preferred Modality",
    "Preferred Pressure",
    "Reasons for Massage",
    "Moisturizer Preferences",
    "Music Preference",
    "Conversation Preferences",
    "Pregnancy (Female customers)",
  ];
  final _storage = const FlutterSecureStorage();
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
    level: Level.debug,
    output: ConsoleOutput(),
  );



  @override
  void onInit() {
    super.onInit();
    _logger.d('CustomerPreferencesController Initialized');
    if (Get.arguments != null && Get.arguments['preferences'] != null) {
      _logger.d('Therapist mode: Loading API preferences');
      loadApiPreferences(Get.arguments['preferences']);
    } else {
      _logger.d('Client mode: Loading stored preferences');
      _loadPreferences();
    }
    logAllPreferences();
  }

  void loadApiPreferences(Map<String, dynamic> apiPreferences) {
    try {
      _logger.d('Loading API Preferences: $apiPreferences');
      final newPreferences = <String, String>{};
      newPreferences['Preferred Modality'] = apiPreferences['preferred_modality']?.toString() ?? '';
      newPreferences['Preferred Pressure'] = apiPreferences['preferred_pressure']?.toString() ?? '';
      newPreferences['Reasons for Massage'] = apiPreferences['reason_for_massage']?.toString() ?? '';
      newPreferences['Moisturizer Preferences'] = apiPreferences['moisturizer']?.toString() ?? '';
      newPreferences['Music Preference'] = apiPreferences['music_preference']?.toString() ?? '';
      newPreferences['Conversation Preferences'] = apiPreferences['conversation_preference']?.toString() ?? '';
      newPreferences['Pregnancy (Female customers)'] = apiPreferences['pregnancy']?.toString() ?? '';
      preferences.assignAll(newPreferences);
      _logger.d('API Preferences Loaded: $preferences');
    } catch (e) {
      _logger.e('Error in _loadApiPreferences: $e');
    }
  }

  Future<void> _loadPreferences() async {
    try {
      _logger.d('Loading Preferences from Storage...');
      for (var key in preferenceKeys) {
        final sanitizedKey = _sanitizeKey(key);
        final value = await _storage.read(key: sanitizedKey) ?? '';
        preferences[key] = value;
        _logger.d('Loaded: $key (Storage Key: $sanitizedKey) = $value');
      }
      _logger.d('Preferences Loaded Successfully');
    } catch (e) {
      _logger.e('Error Loading Preferences: $e');
    }
  }

  void updatePreference(String key, String value) async {
    try {
      preferences[key] = value;
      final sanitizedKey = _sanitizeKey(key);
      await _storage.write(key: sanitizedKey, value: value);
      _logger.d('Preference Updated: $key (Storage Key: $sanitizedKey) = $value');
    } catch (e) {
      _logger.e('Error Updating Preference $key: $e');
    }
  }

  Map<String, String> getAllPreferences() {
    return Map<String, String>.from(preferences);
  }

  void clearPreferences() async {
    try {
      for (var key in preferenceKeys) {
        preferences[key] = '';
        final sanitizedKey = _sanitizeKey(key);
        await _storage.delete(key: sanitizedKey);
        _logger.d('Preference Cleared: $key (Storage Key: $sanitizedKey)');
      }
      _logger.d('All Preferences Cleared');
      logAllPreferences();
    } catch (e) {
      _logger.e('Error Clearing Preferences: $e');
    }
  }

  String _sanitizeKey(String key) {
    return key.replaceAll(' ', '_').replaceAll('(', '').replaceAll(')', '');
  }

  void logAllPreferences() {
    _logger.d('Current Preferences: ${Map<String, String>.from(preferences)}');
  }

  Future<void> savePreferences(BuildContext context) async {
    isLoading.value = true;
    try {
      _logger.d('Saving Preferences to Storage...');
      for (var key in preferenceKeys) {
        final sanitizedKey = _sanitizeKey(key);
        final value = preferences[key] ?? '';
        await _storage.write(key: sanitizedKey, value: value);
        _logger.d('Saved: $key (Storage Key: $sanitizedKey) = $value');
      }
      CustomSnackBar.show(
        context,
        'Preferences saved successfully',
        type: ToastificationType.success,
      );
      _logger.d('Preferences Saved Successfully');
      if (Get.arguments == null || Get.arguments['preferences'] == null) {
        _logger.d('Navigating back');
        Get.back();
      }
    } catch (e) {
      CustomSnackBar.show(
        context,
        'Failed to save preferences: $e',
        type: ToastificationType.error,
      );
      _logger.e('Error Saving Preferences: $e');
    } finally {
      isLoading.value = false;
    }
  }
}