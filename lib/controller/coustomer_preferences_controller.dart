import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

class CustomerPreferencesController extends GetxController {
  final RxMap<String, String> preferences = <String, String>{}.obs;
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
  final Logger _logger;

  CustomerPreferencesController()
      : _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      printTime: true,
    ),
  );

  @override
  void onInit() async {
    super.onInit();
    _logger.d('CustomerPreferencesController Initialized');
    await _loadPreferences();
    logAllPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      _logger.d('Loading Preferences from Storage...');
      for (var key in preferenceKeys) {
        final sanitizedKey = _sanitizeKey(key);
        final value = await _storage.read(key: sanitizedKey) ?? '';
        _logger.d('Loaded: $key (Storage Key: $sanitizedKey) = $value');
        preferences[key] = value;
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
}