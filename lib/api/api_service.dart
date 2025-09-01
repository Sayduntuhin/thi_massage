import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import '../view/widgets/app_logger.dart';
import 'auth_service.dart';

class ApiService {
 static const String _baseUrl = "https://backend.thaimassagesnearmeapp.com";
 // static const String _baseUrl = "http://10.10.13.75:3333";
  final http.Client _client;
  http.Client get client => _client;

  final _storage = const FlutterSecureStorage();
  final Logger _logger;
  static String get baseUrl => _baseUrl;


  ApiService({http.Client? client})
      : _client = client ?? http.Client(),
        _logger = Logger(
          printer: PrettyPrinter(
            methodCount: 0,
            errorMethodCount: 5,
            lineLength: 80,
            colors: true,
            printEmojis: true,
            printTime: true,
          ),
        );

  Future<Map<String, dynamic>> _authenticatedRequest({
    required String method,
    required Uri uri,
    Map<String, String>? headers,
    String? body,
  }) async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    headers = headers ?? {};
    headers['Authorization'] = 'Bearer $accessToken';
    headers['Content-Type'] = 'application/json';

    if (kDebugMode) {
      _logger.d('API Request: $method $uri');
      _logger.d('Request Headers: $headers');
      if (body != null) {
        _logger.d('Request Body: $body');
      }
    }

    http.Response response;
    switch (method.toUpperCase()) {
      case 'GET':
        response = await _client.get(uri, headers: headers);
        break;
      case 'POST':
        response = await _client.post(uri, headers: headers, body: body);
        break;
      case 'PATCH':
        response = await _client.patch(uri, headers: headers, body: body);
        break;
      case 'DELETE':
        response = await _client.delete(uri, headers: headers, body: body);
        break;
      default:
        throw ApiException('Unsupported HTTP method: $method', 0);
    }

    if (kDebugMode) {
      _logger.d('API Response Status: ${response.statusCode}');
      _logger.d('API Response Body: ${response.body}');
    }

    if (response.statusCode == 401) {
      Map<String, dynamic>? responseData;
      try {
        responseData = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        _logger.e('Failed to parse 401 response body: $e\nRaw body: ${response.body}');
      }

      if (responseData != null &&
          responseData['code'] == 'token_not_valid' &&
          responseData['messages']?.any((msg) => msg['message'] == 'Token is expired') == true) {
        _logger.w('API: Token expired, triggering logout');
        try {
          // Check if AuthService is available
          if (Get.isRegistered<AuthService>()) {
            final authService = Get.find<AuthService>();
            await authService.logout();
            Get.snackbar('Session Expired', 'Your session has expired. Please log in again.');
            Get.offAllNamed('/login');
          } else {
            _logger.e('AuthService not registered, cannot logout');
            Get.snackbar('Error', 'Session expired, but logout failed. Please restart the app.');
            Get.offAllNamed('/login');
          }
          throw TokenExpiredException('Token is expired', 401);
        } catch (e) {
          _logger.e('Failed to trigger logout: $e');
          throw TokenExpiredException('Token is expired', 401);
        }
      }
      throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
    }

    return {
      'statusCode': response.statusCode,
      'body': response.body,
      'headers': response.headers,
    };
  }
  ///------------------------------------API Auth------------------------------------///
  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    const String endpoint = '/auth/login/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    if (kDebugMode) {
      _logger.d('API Request Login: POST $uri');
      _logger.d('Request Headers Login: {"Content-Type": "application/json"}');
      _logger.d('Request Body Login: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Login: ${response.statusCode}');
        _logger.d('API Response Headers Login: ${response.headers}');
        _logger.d('API Response Body Login: ${response.body}');
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;

      switch (response.statusCode) {
        case 200:
        case 201: // Handle 201 for pending approval
        // Check for pending approval
          if (responseData['access'] == null &&
              responseData['message']?.contains('Awaiting admin approval') == true) {
            throw PendingApprovalException(
              'Your account is awaiting admin approval. Please try again later.',
              response.statusCode,
            );
          }
          // Store tokens if present
          if (responseData.containsKey('access')) {
            await _storage.write(key: 'access_token', value: responseData['access']);
          }
          if (responseData.containsKey('refresh')) {
            await _storage.write(key: 'refresh_token', value: responseData['refresh']);
          }
          if (responseData.containsKey('profile_data') && responseData['profile_data']['user'] != null) {
            await _storage.write(key: 'user_id', value: responseData['profile_data']['user'].toString());
          }
          return responseData;
        case 400:
          String errorMessage = 'Incorrect email or password.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('non_field_errors') &&
                errorBody['non_field_errors'] is List &&
                errorBody['non_field_errors'].isNotEmpty) {
              errorMessage = errorBody['non_field_errors'][0];
            } else if (errorBody.containsKey('email') &&
                errorBody['email'] is List &&
                errorBody['email'].isNotEmpty) {
              errorMessage = errorBody['email'][0];
            } else if (errorBody.containsKey('password') &&
                errorBody['password'] is List &&
                errorBody['password'].isNotEmpty) {
              errorMessage = errorBody['password'][0];
            } else if (errorBody.containsKey('error') &&
                errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Invalid email or password.', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Login endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to login: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<Map<String, dynamic>> signUp(Map<String, dynamic> data) async {
    const String endpoint = '/auth/normal_signup/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    if (kDebugMode) {
      _logger.d('API Request SignUp: POST $uri');
      _logger.d('Request Headers SignUp: {"Content-Type": "application/json"}');
      _logger.d('Request Body SignUp: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        _logger.d('API Response Status SignUp: ${response.statusCode}');
        _logger.d('API Response Headers SignUp: ${response.headers}');
        _logger.d('API Response Body SignUp: ${response.body}');
      }

      Map<String, dynamic>? responseData;
      if (response.headers['content-type']?.contains('application/json') == true) {
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          _logger.e('Failed to parse JSON response: $e\nRaw body: ${response.body}');
          throw ServerException('Invalid server response format', response.statusCode);
        }
      } else {
        _logger.w('Non-JSON response received: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          if (responseData == null) {
            throw ServerException('Empty response body', response.statusCode);
          }
          if (responseData['access'] == null &&
              responseData['message']?.contains('Awaiting admin approval') == true) {
            throw PendingApprovalException(
              'Your account is awaiting admin approval. Please try again later.',
              response.statusCode,
            );
          }
          if (responseData.containsKey('access')) {
            await _storage.write(key: 'access_token', value: responseData['access']);
          }
          if (responseData.containsKey('refresh')) {
            await _storage.write(key: 'refresh_token', value: responseData['refresh']);
          }
          if (responseData.containsKey('profile_data') && responseData['profile_data']['user'] != null) {
            await _storage.write(key: 'user_id', value: responseData['profile_data']['user'].toString());
          }
          return responseData;
        case 400:
          String errorMessage = 'Sign-up failed. Please try again.';
          if (responseData != null) {
            if (responseData.containsKey('email') && responseData['email'] is List && responseData['email'].isNotEmpty) {
              errorMessage = responseData['email'][0];
            } else if (responseData.containsKey('error') && responseData['error'] is String) {
              errorMessage = responseData['error'];
            }
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Sign-up endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException(
            responseData?['detail']?.toString() ?? 'Server error. Please try again later.',
            response.statusCode,
          );
        default:
          throw ApiException('Failed to sign up: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<Map<String, dynamic>> socialSignUpSignIn(Map<String, dynamic> data) async {
    const String endpoint = '/auth/social_signup_signin/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    if (kDebugMode) {
      _logger.d('API Request Social SignUp/SignIn: POST $uri');
      _logger.d('Request Headers Social: {"Content-Type": "application/json"}');
      _logger.d('Request Body Social: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Social SignUp/SignIn: ${response.statusCode}');
        _logger.d('API Response Headers Social SignUp/SignIn: ${response.headers}');
        _logger.d('API Response Body Social SignUp/SignIn: ${response.body}');
      }

      Map<String, dynamic>? responseData;
      // Check if response is JSON
      if (response.headers['content-type']?.contains('application/json') == true) {
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          _logger.e('Failed to parse JSON response: $e\nRaw body: ${response.body}');
          throw ServerException('Invalid server response format', response.statusCode);
        }
      } else {
        _logger.w('Non-JSON response received: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          if (responseData == null) {
            throw ServerException('Empty response body', response.statusCode);
          }
          if (responseData['access'] == null &&
              responseData['message']?.contains('Awaiting admin approval') == true) {
            throw PendingApprovalException(
              'Your account is awaiting admin approval. Please try again later.',
              response.statusCode,
            );
          }
          final requestedRole = data['role'];
          final returnedRole = responseData['profile_data']?['role'];
          if (returnedRole != null && returnedRole != requestedRole) {
            throw BadRequestException(
              'This email is already registered as a $returnedRole. Please use the correct role.',
              response.statusCode,
            );
          }
          if (responseData.containsKey('access')) {
            await _storage.write(key: 'access_token', value: responseData['access']);
          }
          if (responseData.containsKey('refresh')) {
            await _storage.write(key: 'refresh_token', value: responseData['refresh']);
          }
          if (responseData.containsKey('profile_data') && responseData['profile_data']['user'] != null) {
            await _storage.write(key: 'user_id', value: responseData['profile_data']['user'].toString());
          }
          return responseData;
        case 400:
          String errorMessage = 'Social sign-in failed. Please try again.';
          if (responseData != null) {
            if (responseData.containsKey('email') && responseData['email'] is List && responseData['email'].isNotEmpty) {
              errorMessage = responseData['email'][0];
            } else if (responseData.containsKey('error') && responseData['error'] is String) {
              errorMessage = responseData['error'];
            }
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Social sign-in endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException(
            responseData?['detail']?.toString() ?? 'Server error. Please try again later.',
            response.statusCode,
          );
        default:
          throw ApiException('Failed to sign in: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<Map<String, dynamic>> verifyOtpForSignUp(String email, String otp) async {
    const String endpoint = '/auth/verify_otp/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final data = {
      "email": email,
      "otp": otp,
    };

    if (kDebugMode) {
      _logger.d('API Request Verify OTP: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Verify OTP: ${response.statusCode}');
        _logger.d('API Response Headers Verify OTP: ${response.headers}');
        _logger.d('API Response Body Verify OTP: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          return jsonDecode(response.body) as Map<String, dynamic>;
        case 400:
          String errorMessage = 'Invalid OTP or email.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('otp') && errorBody['otp'] is List && errorBody['otp'].isNotEmpty) {
              errorMessage = errorBody['otp'][0];
            } else if (errorBody.containsKey('email') && errorBody['email'] is List && errorBody['email'].isNotEmpty) {
              errorMessage = errorBody['email'][0];
            } else if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Verify OTP endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to verify OTP: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Unexpected Error: $e');
      }
      throw ApiException('An error occurred while verifying OTP: $e');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<Map<String, dynamic>> verifyOtpForForgetPassword(String email, String otp) async {
    const String endpoint = '/auth/verify-otp/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final data = {
      "email": email,
      "otp": otp,
    };

    if (kDebugMode) {
      _logger.d('API Request Verify OTP: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Verify OTP: ${response.statusCode}');
        _logger.d('API Response Headers Verify OTP: ${response.headers}');
        _logger.d('API Response Body Verify OTP: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          return jsonDecode(response.body) as Map<String, dynamic>;
        case 400:
          String errorMessage = 'Invalid OTP or email.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('otp') && errorBody['otp'] is List && errorBody['otp'].isNotEmpty) {
              errorMessage = errorBody['otp'][0];
            } else if (errorBody.containsKey('email') && errorBody['email'] is List && errorBody['email'].isNotEmpty) {
              errorMessage = errorBody['email'][0];
            } else if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Verify OTP endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to verify OTP: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Unexpected Error: $e');
      }
      throw ApiException('An error occurred while verifying OTP: $e');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<Map<String, dynamic>> resendOtp(String email) async {
    const String endpoint = '/auth/resend_otp/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final data = {"email": email};

    if (kDebugMode) {
      _logger.d('API Request Resend OTP: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Resend OTP: ${response.statusCode}');
        _logger.d('API Response Headers Resend OTP: ${response.headers}');
        _logger.d('API Response Body Resend OTP: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          return jsonDecode(response.body) as Map<String, dynamic>;
        case 400:
          String errorMessage = 'Invalid email provided.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('email') && errorBody['email'] is List && errorBody['email'].isNotEmpty) {
              errorMessage = errorBody['email'][0];
            } else if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Resend OTP endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to resend OTP: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Unexpected Error: $e');
      }
      throw ApiException('An error occurred while resending OTP: $e');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<Map<String, dynamic>> resetPasswordRequest(String email) async {
    const String endpoint = '/auth/forgot-password/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');
    final data = {"email": email};

    if (kDebugMode) {
      _logger.d('API Request Reset Password: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        _logger.e('Request timed out');
        throw NetworkException('Request timed out');
      });

      if (kDebugMode) {
        _logger.d('API Response Status Reset Password: ${response.statusCode}');
        _logger.d('API Response Headers Reset Password: ${response.headers}');
        _logger.d('API Response Body Reset Password: ${response.body}');
      }

      Map<String, dynamic>? responseData;
      if (response.headers['content-type']?.contains('application/json') == true) {
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          _logger.e('Failed to parse JSON response: $e\nRaw body: ${response.body}');
          throw ServerException('Invalid server response format', response.statusCode);
        }
      } else {
        _logger.w('Non-JSON response received: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          if (responseData == null) {
            throw ServerException('Empty response body', response.statusCode);
          }
          return responseData;
        case 400:
        case 404: // Handle 404 as a validation error
          String errorMessage = 'Invalid email provided.';
          if (responseData != null) {
            if (responseData.containsKey('email') && responseData['email'] is List && responseData['email'].isNotEmpty) {
              errorMessage = responseData['email'][0];
            } else if (responseData.containsKey('error') && responseData['error'] is String) {
              errorMessage = responseData['error']; // Extract "Invalid email."
            }
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          String errorMessage = 'Failed to request password reset.';
          if (responseData != null && responseData.containsKey('error') && responseData['error'] is String) {
            errorMessage = responseData['error'];
          } else if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
          throw ApiException(errorMessage, response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<Map<String, dynamic>> resetPassword(String email, String password) async {
    const String endpoint = '/auth/reset-password/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');
    final data = {"email": email, "password": password};

    if (kDebugMode) {
      _logger.d('API Request Reset Password: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        _logger.e('Request timed out');
        throw NetworkException('Request timed out');
      });

      if (kDebugMode) {
        _logger.d('API Response Status Reset Password: ${response.statusCode}');
        _logger.d('API Response Headers Reset Password: ${response.headers}');
        _logger.d('API Response Body Reset Password: ${response.body}');
      }

      Map<String, dynamic>? responseData;
      if (response.headers['content-type']?.contains('application/json') == true) {
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          _logger.e('Failed to parse JSON response: $e\nRaw body: ${response.body}');
          throw ServerException('Invalid server response format', response.statusCode);
        }
      } else {
        _logger.w('Non-JSON response received: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          if (responseData == null) {
            throw ServerException('Empty response body', response.statusCode);
          }
          if (responseData['message'] == 'Password reset successful.') {
            return responseData;
          } else {
            throw ApiException('Unexpected response: ${response.body}', response.statusCode);
          }
        case 400:
        case 404:
          String errorMessage = 'Failed to reset password.';
          if (responseData != null && responseData.containsKey('error')) {
            errorMessage = responseData['error'];
          } else if (responseData != null && responseData.containsKey('detail')) {
            errorMessage = responseData['detail'];
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to reset password: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e, stackTrace) {
      _logger.e('Unexpected Error: $e\nStackTrace: $stackTrace');
      throw ApiException('An error occurred while resetting password: $e');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }

  Future<void> changePassword(Map<String, String> payload) async {
    const String endpoint = '/auth/change-password/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Change Password: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json", "Authorization": "Bearer $accessToken"}');
      _logger.d('Request Body: ${jsonEncode(payload)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      ).timeout(const Duration(seconds: 30), onTimeout: () {
        _logger.e('Request timed out');
        throw NetworkException('Request timed out');
      });

      if (kDebugMode) {
        _logger.d('API Response Status Change Password: ${response.statusCode}');
        _logger.d('API Response Headers Change Password: ${response.headers}');
        _logger.d('API Response Body Change Password: ${response.body}');
      }

      Map<String, dynamic>? responseData;
      if (response.headers['content-type']?.contains('application/json') == true) {
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          _logger.e('Failed to parse JSON response: $e\nRaw body: ${response.body}');
          throw ServerException('Invalid server response format', response.statusCode);
        }
      } else {
        _logger.w('Non-JSON response received: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          if (responseData == null) {
            throw ServerException('Empty response body', response.statusCode);
          }
          return; // Success, no return value needed
        case 400:
          String errorMessage = 'Invalid input data.';
          if (responseData != null) {
            if (responseData.containsKey('current_password') && responseData['current_password'] is List && responseData['current_password'].isNotEmpty) {
              errorMessage = responseData['current_password'][0];
            } else if (responseData.containsKey('new_password') && responseData['new_password'] is List && responseData['new_password'].isNotEmpty) {
              errorMessage = responseData['new_password'][0];
            } else if (responseData.containsKey('error') && responseData['error'] is String) {
              errorMessage = responseData['error'];
            }
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Change password endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          String errorMessage = 'Failed to change password.';
          if (responseData != null && responseData.containsKey('error') && responseData['error'] is String) {
            errorMessage = responseData['error'];
          } else if (response.body.isNotEmpty) {
            errorMessage = response.body;
          }
          throw ApiException(errorMessage, response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }



  ///------------------------------------Booking----------------------------------///
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> payload) async {
    const String endpoint = '/client/bookings/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Create Booking: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json", "Authorization": "Bearer $accessToken"}');
      _logger.d('Request Body: ${jsonEncode(payload)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(payload),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Create Booking: ${response.statusCode}');
        _logger.d('API Response Headers Create Booking: ${response.headers}');
        _logger.d('API Response Body Create Booking: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          _logger.d('Booking created successfully: $responseData');
          return responseData;
        case 400:
          _logger.d('400 response body: ${response.body}');
          throw BadRequestException(response.body, response.statusCode); // Pass raw JSON body
        case 409: // Add case for Conflict
          _logger.d('409 response body: ${response.body}');
          throw BadRequestException(response.body, response.statusCode); // Pass raw JSON body
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Booking endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to create booking: ${response.body}', response.statusCode); // Use response.body for better context
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        _logger.e('No internet connection: $e');
      }
      throw NetworkException('No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Network error occurred. Please check your connection and try again.');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  ///-----------------------Get Bookings method-----------------------///
  Future<List<Map<String, dynamic>>> getBookings() async {
    const String endpoint = '/client/bookings/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Bookings: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Get Bookings: ${response.statusCode}');
        _logger.d('API Response Headers Get Bookings: ${response.headers}');
        _logger.d('API Response Body Get Bookings: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as List<dynamic>;
          _logger.d('Bookings fetched successfully: $responseData');
          return responseData.cast<Map<String, dynamic>>();
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Bookings endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to fetch bookings: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch bookings: $e');
    }
  }

  ///-----------------------Cancel Booking method-----------------------///
  Future<Map<String, dynamic>> cancelBooking(int bookingId) async {
    const String endpoint = '/client/bookings/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint$bookingId/cancel/');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found for cancellation');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Cancel Booking: POST $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Cancel Booking: ${response.statusCode}');
        _logger.d('API Response Headers Cancel Booking: ${response.headers}');
        _logger.d('API Response Body Cancel Booking: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          _logger.d('Booking cancelled successfully: $responseData');
          return responseData; // Returns {"message": "Booking cancelled.", "refund_amount": 209.975, "cancelled_by": "client"}
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Cancellation endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error try again}', response.statusCode);
        default:
          throw ApiException('Failed to cancel booking}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to cancel booking Something went wrong');
    }
  }

  ///------------------------------------Get Therapists by Massage Type method----------------------------------///
  Future<List<Map<String, dynamic>>> getTherapistsByMassageType(String massageType) async {
    const String endpoint = '/client/therapists-by-massage-type/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint?massage_type=$massageType');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Therapists by Massage Type: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Get Therapists by Massage Type: ${response.statusCode}');
        _logger.d('API Response Headers Get Therapists by Massage Type: ${response.headers}');
        _logger.d('API Response Body Get Therapists by Massage Type: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as List<dynamic>;
          _logger.d('Therapists by massage type fetched successfully: $responseData');
          return responseData.cast<Map<String, dynamic>>();
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Therapists endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to fetch therapists by massage type: ${response.body}', response.statusCode);
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        _logger.e('No internet connection: $e');
      }
      throw NetworkException('No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Network error occurred. Please check your connection and try again.');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  ///------------------------------------Get Massage Types method----------------------------------///
  Future<List<Map<String, dynamic>>> getMassageTypes() async {
    const String endpoint = '/api/massage-types/';
    String url = '$baseUrl$endpoint?limit=100'; // Use high limit to minimize requests
    List<Map<String, dynamic>> allMassageTypes = [];

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Massage Types: GET $url');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      while (url.isNotEmpty) {
        final uri = Uri.parse(url);
        final response = await _client.get(
          uri,
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Accept': 'application/json',
          },
        );

        if (kDebugMode) {
          _logger.d('API Response Status Get Massage Types: ${response.statusCode}');
          _logger.d('API Response Headers Get Massage Types: ${response.headers}');
          _logger.d('API Response Body Get Massage Types: ${response.body}');
        }

        switch (response.statusCode) {
          case 200:
            final responseBody = jsonDecode(response.body);

            // Handle both response formats
            if (responseBody is List) {
              // API returns array directly: [{"id": 1, ...}, {"id": 2, ...}]
              allMassageTypes.addAll(responseBody.cast<Map<String, dynamic>>());
              url = ''; // No pagination when returning array directly
              if (kDebugMode) {
                _logger.d('Fetched ${responseBody.length} massage types (direct array)');
              }
            } else if (responseBody is Map<String, dynamic>) {
              // API returns paginated response: {"results": [...], "next": "..."}
              final List<dynamic> results = responseBody['results'] ?? [];
              allMassageTypes.addAll(results.cast<Map<String, dynamic>>());
              // Check for next page
              url = responseBody['next']?.toString() ?? '';
              if (kDebugMode) {
                _logger.d('Fetched ${results.length} massage types, next URL: $url');
              }
            } else {
              throw ApiException('Unexpected response format: ${responseBody.runtimeType}', 200);
            }
            break;
          case 401:
            throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
          case 403:
            throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
          case 404:
            throw NotFoundException('Massage types endpoint not found: $uri', response.statusCode);
          case 500:
            throw ServerException('Server error: ${response.body}', response.statusCode);
          default:
            throw ApiException('Failed to fetch massage types: ${response.body}', response.statusCode);
        }
      }

      if (kDebugMode) {
        _logger.d('Massage types fetched successfully: $allMassageTypes');
      }
      return allMassageTypes;
    } on SocketException catch (e) {
      if (kDebugMode) {
        _logger.e('No internet connection: $e');
      }
      throw NetworkException('No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Network error occurred. Please check your connection and try again.');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }

  ///------------------------------------Get Therapist Own Profile method----------------------------------///
  Future<Map<String, dynamic>> getTherapistOwnProfile() async {
    const String endpoint = '/therapist/therapists/profile/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final result = await _authenticatedRequest(method: 'GET', uri: uri);
      final responseBody = result['body'];
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      switch (result['statusCode']) {
        case 200:
          if (responseData['image'] != null && responseData['image'] is String && !responseData['image'].startsWith('http')) {
            responseData['image'] = '$_baseUrl/therapist${responseData['image']}';
          }
          _logger.d('Therapist own profile fetched successfully: $responseData');
          return responseData;
        case 400:
          throw BadRequestException('Invalid request: $responseBody', result['statusCode']);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', result['statusCode']);
        case 404:
          throw NotFoundException('Therapist profile not found: $uri', result['statusCode']);
        case 500:
          throw ServerException(
            responseData['detail']?.toString() ?? 'Server error. Please try again later.',
            result['statusCode'],
          );
        default:
          throw ApiException('Failed to fetch therapist profile: $responseBody', result['statusCode']);
      }
    } on TokenExpiredException {
      rethrow; // Let controllers handle logout
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch therapist profile: $e', 0);
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<void> patchTherapistLocation({required String latitude, required String longitude}) async {
    const String endpoint = '/therapist/therapists/profile/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');
    final body = jsonEncode({
      'latitude': latitude,
      'longitude': longitude,
    });

    try {
      final result = await _authenticatedRequest(method: 'PATCH', uri: uri, body: body);
      final responseBody = result['body'];
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      switch (result['statusCode']) {
        case 200:
        case 201:
          _logger.d('Therapist profile updated successfully: $responseData');
          return;
        case 400:
          throw ApiException(
            responseData['detail']?.toString() ?? 'Invalid data provided: $responseBody',
            result['statusCode'],
          );
        case 403:
          throw ForbiddenException('Access denied: $responseBody', result['statusCode']);
        case 404:
          throw NotFoundException('Therapist profile not found: $uri', result['statusCode']);
        case 500:
          throw ServerException(
            responseData['detail']?.toString() ?? 'Server error. Please try again later.',
            result['statusCode'],
          );
        default:
          throw ApiException('Failed to update therapist profile: $responseBody', result['statusCode']);
      }
    } on TokenExpiredException {
      rethrow;
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }  Future<void> updateTherapistAvailability(bool availability) async {
    const String endpoint = '/therapist/therapists/profile/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }
    _logger.d('API Request Update Therapist Availability: PATCH $uri');
    _logger.d('Request Body: {"availability": $availability}');
    try {
      final response = await _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'availability': availability}),
      );
      _logger.d('API Response Status Update Therapist Availability: ${response.statusCode}');
      _logger.d('API Response Body Update Therapist Availability: ${response.body}');
      if (response.statusCode != 200) {
        throw ApiException('Failed to update availability: ${response.body}', response.statusCode);
      }
    } catch (e) {
      _logger.e('Failed to update therapist availability: $e');
      rethrow;
    } finally {
      _logger.d('API Call Completed: $endpoint');
    }
  }
  Future<void> updateTherapistProfile({
    required int userId,
    required int profileId,
    File? image,
    String? fullName,
    String? phone,
    String? dateOfBirth,
    String? about,
    int? experience,
    List<String>? techniques,
  }) async {
    const String endpoint = '/therapist/therapists/profile/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      throw UnauthorizedException('No access token found', 401);
    }

    var request = http.MultipartRequest('PATCH', uri)
      ..headers['Authorization'] = 'Bearer $accessToken';

    // Add fields if provided
    if (fullName != null) request.fields['full_name'] = fullName;
    if (phone != null) request.fields['phone'] = phone;
    if (dateOfBirth != null) request.fields['date_of_birth'] = dateOfBirth;
    if (about != null) request.fields['about'] = about;
    if (experience != null) request.fields['experience'] = experience.toString();
    if (techniques != null) request.fields['techniques'] = jsonEncode(techniques);

    // Add image if provided
    if (image != null) {
      request.files.add(await http.MultipartFile.fromPath('image', image.path));
    }

    AppLogger.debug('API Request Update Therapist Profile: PATCH $uri');
    AppLogger.debug('Request Fields: ${request.fields}');
    if (image != null) AppLogger.debug('Request Image: ${image.path}');

    try {
      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      AppLogger.debug('API Response Status Update Therapist Profile: ${response.statusCode}');
      AppLogger.debug('API Response Body Update Therapist Profile: $responseBody');

      if (response.statusCode != 200) {
        throw ApiException('Failed to update profile: $responseBody', response.statusCode);
      }
    } catch (e) {
      _logger.e('Failed to update therapist profile: $e');
      rethrow;
    } finally {
      AppLogger.debug('API Call Completed: $endpoint');
    }
  }
  ///-----------------------Get Client Profile Details method-----------------------///
  Future<Map<String, dynamic>> getClientProfile() async {
    const String endpoint = '/client/client/profile/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final result = await _authenticatedRequest(method: 'GET', uri: uri);
      final responseBody = result['body'];
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      switch (result['statusCode']) {
        case 200:
          _logger.d('Client profile fetched successfully: $responseData');
          return responseData;
        case 400:
          throw BadRequestException('Invalid request: $responseBody', result['statusCode']);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', result['statusCode']);
        case 404:
          throw NotFoundException('Client profile not found: $uri', result['statusCode']);
        case 500:
          throw ServerException(
            responseData['detail']?.toString() ?? 'Server error. Please try again later.',
            result['statusCode'],
          );
        default:
          throw ApiException('Failed to fetch client profile: $responseBody', result['statusCode']);
      }
    } on TokenExpiredException {
      rethrow;
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch client profile: $e', 0);
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }


  ///-----------------------Update Client Profile Details method-----------------------///
  Future<Map<String, dynamic>> updateClientProfile(
      Map<String, dynamic> fields, {
        File? image,
      }) async {
    const String endpoint = '/client/client/profile/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found for client profile update');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Update Client Profile: PATCH $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
      _logger.d('Request Fields: $fields');
      if (image != null) {
        _logger.d('Request Image: ${image.path}, Size: ${await image.length()} bytes');
      }
    }

    try {
      final request = http.MultipartRequest('PATCH', uri)
        ..headers['Authorization'] = 'Bearer $accessToken';

      fields.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType('image', image.path.split('.').last),
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        _logger.d('API Response Status Update Client Profile: ${response.statusCode}');
        _logger.d('API Response Body Update Client Profile: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Client profile updated successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Client profile endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to update client profile: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to update client profile: $e');
    }
  }

  /// Update Client Profile (with role, used by ProfileSetupPage)
  Future<Map<String, dynamic>> updateClientProfileWithRole(
      Map<String, dynamic> fields, {
        File? image,
        required bool isTherapist,
      }) async {
    const String endpoint = '/client/client/profile/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    String? accessToken;
    if (!isTherapist) {
      accessToken = await _storage.read(key: 'access_token');
      if (accessToken == null) {
        _logger.e('No access token found for client profile setup');
        throw UnauthorizedException('No access token found for client', 401);
      }
    }

    if (kDebugMode) {
      _logger.d('API Request Update Client Profile: PATCH $uri (isTherapist: $isTherapist)');
      _logger.d('Request Headers: ${isTherapist ? {} : {"Authorization": "Bearer $accessToken"}}');
      _logger.d('Request Fields: $fields');
      if (image != null) {
        _logger.d('Request Image: ${image.path}, Size: ${await image.length()} bytes');
      }
    }

    try {
      final request = http.MultipartRequest('PATCH', uri);
      if (!isTherapist && accessToken != null) {
        request.headers['Authorization'] = 'Bearer $accessToken';
      }

      fields.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      if (image != null) {
        request.files.add(await http.MultipartFile.fromPath(
          'image',
          image.path,
          contentType: MediaType('image', image.path.split('.').last),
        ));
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        _logger.d('API Response Status Update Client Profile: ${response.statusCode}');
        _logger.d('API Response Body Update Client Profile: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Profile updated successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Client profile endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to update client profile: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to update client profile: $e');
    }
  }
  ///-----------------------Filter Therapists method-----------------------///
  Future<List<Map<String, dynamic>>> filterTherapists({
    double? rating,
    int? minPrice,
    int? maxPrice,
    String? gender,
    String? availability,
    String? search,
  }) async {
    const String endpoint = '/client/filter-therapists/';
    final queryParams = <String, String>{};
    if (rating != null) queryParams['rating'] = rating.toString();
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (gender != null && gender.toLowerCase() != 'any') {
      queryParams['gender'] = gender.toLowerCase();
    }
    if (availability != null) {
      // Convert availability to 24-hour format (e.g., "04:00 pm" -> "16:00")
      try {
        final time = TimeOfDay.fromDateTime(
          DateFormat.jm().parse(availability),
        );
        final hours = time.hour.toString().padLeft(2, '0');
        final minutes = time.minute.toString().padLeft(2, '0');
        queryParams['availability'] = '$hours:$minutes';
      } catch (e) {
        _logger.e('Invalid availability format: $availability, Error: $e');
      }
    }
    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }

    final Uri uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: queryParams);

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Filter Therapists: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Filter Therapists: ${response.statusCode}');
        _logger.d('API Response Headers Filter Therapists: ${response.headers}');
        _logger.d('API Response Body Filter Therapists: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(response.body);
          if (data is Map && data.containsKey('results')) {
            final results = data['results'] as List;
            _logger.d('Therapists filtered successfully: $results');
            return results.cast<Map<String, dynamic>>();
          } else {
            throw ApiException(
                'Unexpected response format: Expected a map with results', 200);
          }
        case 401:
          throw UnauthorizedException(
              'Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException(
              'Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException(
              'Filter therapists endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException(
              'Failed to filter therapists: ${response.body}', response.statusCode);
      }
    } on SocketException catch (e) {
      if (kDebugMode) {
        _logger.e('No internet connection: $e');
      }
      throw NetworkException(
          'No internet connection. Please check your network and try again.');
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        _logger.e('Network Error: $e');
      }
      throw NetworkException(
          'Network error occurred. Please check your connection and try again.');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  /// Setup Client Profile (used by ProfileSetupPage)
  Future<Map<String, dynamic>> setupClientProfile(
      int userId, {
        required int profileId,
        File? image,
        String? fullName,
        String? phone,
        String? dateOfBirth,
        required bool isTherapist,
      }) async {
    final fields = <String, dynamic>{
      'full_name': fullName,
      'phone': phone,
      'date_of_birth': dateOfBirth,
    };

    fields.removeWhere((key, value) => value == null || value.toString().isEmpty);

    if (kDebugMode) {
      _logger.d('Calling updateClientProfileWithRole: userId=$userId, profileId=$profileId, isTherapist=$isTherapist');
    }

    return await updateClientProfileWithRole(fields, image: image, isTherapist: isTherapist);
  }

  ///-----------------------Get Therapist Profile Details method-----------------------///
  Future<Map<String, dynamic>> getTherapistProfileforBooking(int therapistId) async {
    final String endpoint = '/client/therapist/$therapistId/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Therapist Profile: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Get Therapist Profile: ${response.statusCode}');
        _logger.d('API Response Headers Get Therapist Profile: ${response.headers}');
        _logger.d('API Response Body Get Therapist Profile: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          // Adjust image URLs to include base URL if necessary
          if (responseData['therapist'] != null && responseData['therapist']['image'] != null) {
            final image = responseData['therapist']['image'];
            if (image is String && !image.startsWith('http') && image != '/media/documents/default.jpg') {
              responseData['therapist']['image'] = '/client$image';
            }
          }
          if (responseData['reviews'] != null && responseData['reviews'] is List) {
            for (var review in responseData['reviews']) {
              if (review['client_image'] != null && review['client_image'] is String && !review['client_image'].startsWith('http')) {
                review['client_image'] = '/client${review['client_image']}';
              }
            }
          }
          _logger.d('Therapist profile fetched successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Therapist profile endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to fetch therapist profile: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch therapist profile: $e');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  ///-----------------------Get Favorite Therapists method-----------------------///
  Future<List<Map<String, dynamic>>> getFavoriteTherapists() async {
    const String endpoint = '/client/love-therapists/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Favorite Therapists: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Get Favorite Therapists: ${response.statusCode}');
        _logger.d('API Response Headers Get Favorite Therapists: ${response.headers}');
        _logger.d('API Response Body Get Favorite Therapists: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as List<dynamic>;
          _logger.d('Favorite therapists fetched successfully: $responseData');
          return responseData.cast<Map<String, dynamic>>();
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Favorite therapists endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to fetch favorite therapists: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch favorite therapists: $e');
    }
  }
  ///-----------------------Get Near Therapist method-----------------------///
  Future<Map<String, dynamic>> updateLocation(Map<String, dynamic> fields) async {
    const String endpoint = '/api/update-location/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Update Location: PATCH $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
      _logger.d('Request Fields: $fields');
    }

    try {
      final response = await _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(fields),
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('API Response Status Update Location: ${response.statusCode}');
        _logger.d('API Response Body Update Location: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Location updated successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Location update endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to update location: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to update location: $e');
    }
  }
  ///-----------------------Get Upcoming Appointments method-----------------------///
  Future<List<Map<String, dynamic>>> getUpcomingAppointments() async {
    const String endpoint = '/therapist/upcoming-appointments/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final result = await _authenticatedRequest(method: 'GET', uri: uri);
      final responseBody = result['body'];
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      switch (result['statusCode']) {
        case 200:
          final appointments = List<Map<String, dynamic>>.from(responseData['upcoming_appointments'] ?? []);
          _logger.d('Upcoming appointments fetched successfully: $appointments');
          return appointments;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, result['statusCode']);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', result['statusCode']);
        case 404:
          throw NotFoundException('Upcoming appointments endpoint not found: $uri', result['statusCode']);
        case 500:
          throw ServerException('Server error: $responseBody', result['statusCode']);
        default:
          throw ApiException('Failed to fetch upcoming appointments: $responseBody', result['statusCode']);
      }
    } on TokenExpiredException {
      rethrow;
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch upcoming appointments: $e', 0);
    }
  }
  ///-----------------------Get Appointments Requests method-----------------------///
  Future<List<Map<String, dynamic>>> getAppointmentRequests() async {
    const String endpoint = '/therapist/appointment-requests/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    try {
      final result = await _authenticatedRequest(method: 'GET', uri: uri);
      final responseBody = result['body'];
      final responseData = jsonDecode(responseBody) as Map<String, dynamic>;

      switch (result['statusCode']) {
        case 200:
          final appointments = List<Map<String, dynamic>>.from(responseData['appointment_requests'] ?? []);
          _logger.d('Appointment requests fetched successfully: $appointments');
          return appointments;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, result['statusCode']);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', result['statusCode']);
        case 404:
          throw NotFoundException('Appointment requests endpoint not found: $uri', result['statusCode']);
        case 500:
          throw ServerException('Server error: $responseBody', result['statusCode']);
        default:
          throw ApiException('Failed to fetch appointment requests: $responseBody', result['statusCode']);
      }
    } on TokenExpiredException {
      rethrow;
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch appointment requests: $e', 0);
    }
  }
  ///-----------------------Get Bookings by Date method-----------------------///
  Future<List<Map<String, dynamic>>> getBookingsByDate(String date) async      {
    final String endpoint = '/therapist/bookings/date?date=$date';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Bookings by Date: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('API Response Status Get Bookings by Date: ${response.statusCode}');
        _logger.d('API Response Body Get Bookings by Date: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final bookings = List<Map<String, dynamic>>.from(jsonDecode(responseBody));
          _logger.d('Bookings fetched successfully for date $date: $bookings');
          return bookings;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Bookings endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to fetch bookings: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch bookings: $e');
    }
  }
  ///-----------------------Get Payment Summary method-----------------------///
  Future<Map<String, dynamic>> getPaymentSummary(int bookingId, [String? promoCode, bool? redeem]) async {
    final queryParameters = {
      if (promoCode != null) 'promo_code': promoCode,
      if (redeem != null) 'redeem': redeem.toString(),
    };
    final uri = Uri.parse('${baseUrl}/client/payment_summary_view/$bookingId/').replace(queryParameters: queryParameters);

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Payment Summary: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('Payment Summary API Response Status: ${response.statusCode}');
        _logger.d('Payment Summary API Response Body: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Payment Summary fetched successfully for booking $bookingId: $data');
          return data;
        case 400:
          String errorMessage = 'Invalid request or promo code.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Payment summary endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to fetch payment summary: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch payment summary: $e', 0);
    }
  }
  ///-----------------------Get Booking Details method-----------------------///
  Future<Map<String, dynamic>> getBookingDetails(int bookingId) async {
    final uri = Uri.parse('$baseUrl/client/client_booking_detail_view/$bookingId/');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Booking Details: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('Booking Details API Response Status: ${response.statusCode}');
        _logger.d('Booking Details API Response Body: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Booking Details fetched successfully for booking $bookingId: $data');
          return data;
        case 400:
          String errorMessage = 'Invalid booking ID.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Booking details endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to fetch booking details: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch booking details: $e', 0);
    }
  }
 ///-----------------------Get Booking Details by Therapist method-----------------------///
  Future<Map<String, dynamic>> getBookingDetailsbByTherapist(dynamic bookingId) async {
    final uri = Uri.parse('$baseUrl/therapist/bookings/$bookingId/');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.i('API Request Get Booking Details: GET $uri');
      _logger.i('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.i('Booking Details API Response Status: ${response.statusCode}');
        _logger.i('Booking Details API Response Body: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.i('Booking details fetched successfully for booking $bookingId: $data');
          return data;
        case 400:
          String errorMessage = 'Invalid booking ID.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Booking not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to fetch booking details: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch booking details: $e', 0);
    }
  }
  ///-----------------------Update Booking Status method-----------------------///
  Future<Map<String, dynamic>> updateBookingStatus(dynamic bookingId, String status) async {
    final action = status == 'accepted' ? 'accept_appointment' : 'reject_appointment';
    final uri = Uri.parse('$baseUrl/therapist/$action/$bookingId/');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.i('API Request Update Booking Status: PATCH $uri');
      _logger.i('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
    }

    try {
      final response = await _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.i('Update Booking Status API Response Status: ${response.statusCode}');
        _logger.i('Update Booking Status API Response Body: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.i('Booking status updated to $status for booking $bookingId: $data');
          return data;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Booking not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to update booking status: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to update booking status: $e', 0);
    }
  }
  ///-----------------------Get Chat Room method-----------------------///
  Future<Map<String, dynamic>> initializeChatRoom(Map<String, dynamic>? arguments) async {
    try {
      // Get current user ID
      final userIdStr = await _storage.read(key: 'user_id');
      if (userIdStr == null) {
        AppLogger.error('No user ID found in storage');
        throw UnauthorizedException('Please log in to continue', 401);
      }
      final currentUserId = int.tryParse(userIdStr);
      if (currentUserId == null) {
        AppLogger.error('Invalid user ID format: $userIdStr');
        throw BadRequestException('Invalid user ID', 400);
      }

      // Safely extract targetId
      int? targetId;
      if (arguments != null) {
        AppLogger.debug('Received arguments: $arguments');
        final therapistId = arguments['therapist_user_id'];
        final clientId = arguments['client_id'];

        if (therapistId != null) {
          targetId = therapistId is int
              ? therapistId
              : int.tryParse(therapistId.toString());
        } else if (clientId != null) {
          targetId = clientId is int
              ? clientId
              : int.tryParse(clientId.toString());
        }
      } else {
        AppLogger.error('Arguments are null');
      }

      if (targetId == null) {
        AppLogger.error('No valid client or therapist ID provided in arguments: $arguments');
        throw BadRequestException('Invalid user details', 400);
      }
      AppLogger.debug('targetId: $targetId');

      // Call API to get or create chat room
      final token = await _storage.read(key: 'access_token') ?? '';
      if (token.isEmpty) {
        AppLogger.error('No token found in storage');
        throw UnauthorizedException('Authentication required', 401);
      }

      final response = await _client.get(
        Uri.parse('$baseUrl/api/chat/get-or-create-room/$targetId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.i('Chat Room API Response Status: ${response.statusCode}');
        _logger.i('Chat Room API Response Body: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          AppLogger.debug('Chat room response: $data');
          final chatRoomId = data['id'] as int?;
          final user1Id = data['user1'] as int?;
          final user2Id = data['user2'] as int?;

          if (chatRoomId == null || user1Id == null || user2Id == null) {
            AppLogger.error('Invalid chat room data: $data');
            throw BadRequestException('Invalid chat room response', 400);
          }

          return {
            'chatRoomId': chatRoomId,
            'user1Id': user1Id,
            'user2Id': user2Id,
            'currentUserId': currentUserId,
            'token': token,
          };
        case 400:
          throw BadRequestException('Invalid request: $responseBody', response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Chat room not found: $responseBody', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to initialize chat room: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to initialize chat room: $e', 0);
    }
  }
 ///-----------------------Get Chat Inbox method-----------------------///
 Future<List<Map<String, dynamic>>> fetchChatInbox({Map<String, String>? queryParams}) async {
   final token = await _storage.read(key: 'access_token');
   if (token == null) {
     AppLogger.error('No access token found for inbox');
     throw Exception('Authentication required');
   }

   try {
     final uri = Uri.parse('$baseUrl/api/chat/inbox/').replace(queryParameters: queryParams);
     final response = await http.get(
       uri,
       headers: {
         'Authorization': 'Bearer $token',
         'Content-Type': 'application/json',
         'Cache-Control': 'no-cache', // Prevent caching
       },
     );

     if (response.statusCode == 200) {
       final List<dynamic> data = jsonDecode(response.body);
       AppLogger.debug('Inbox response: $data');
       return data.cast<Map<String, dynamic>>();
     } else {
       AppLogger.error('Failed to fetch inbox: ${response.body}');
       throw Exception('Failed to fetch inbox: ${response.statusCode}');
     }
   } catch (e) {
     AppLogger.error('Error fetching inbox: $e');
     throw Exception('Error fetching inbox: $e');
   }
 }
  ///-----------------------Get Message History method-----------------------///
  Future<List<Map<String, dynamic>>> fetchMessageHistory(int chatRoomId, String token) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/chat/messages/$chatRoomId/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        AppLogger.debug('Message history response: $data');
        return data.cast<Map<String, dynamic>>();
      } else {
        AppLogger.error('Failed to fetch message history: ${response.body}');
        throw Exception('Failed to fetch message history: ${response.statusCode}');
      }
    } catch (e) {
      AppLogger.error('Error fetching message history: $e');
      throw Exception('Error fetching message history: $e');
    }
  }
  ///-----------------------Get Therapist Working Hours method-----------------------///
  Future<Map<String, dynamic>> getWorkingHours() async {
    final uri = Uri.parse('$baseUrl/therapist/working-hours/detail/');
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.i('API Request Get Working Hours: GET $uri');
      _logger.i('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.i('Get Working Hours API Response Status: ${response.statusCode}');
        _logger.i('Get Working Hours API Response Body: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.i('Working hours fetched: $data');
          return data;
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Working hours not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to fetch working hours: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch working hours: $e', 0);
    }
  }
  ///-----------------------Update Therapist Working Hours method-----------------------///
  Future<Map<String, dynamic>> updateWorkingHours(Map<String, dynamic> data) async {
    final uri = Uri.parse('$baseUrl/therapist/working-hours/update/');
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.i('API Request Update Working Hours: PATCH $uri');
      _logger.i('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
      _logger.i('Request Body: $data');
    }

    try {
      final response = await _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.i('Update Working Hours API Response Status: ${response.statusCode}');
        _logger.i('Update Working Hours API Response Body: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.i('Working hours updated: $data');
          return data;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Working hours endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to update working hours: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to update working hours: $e', 0);
    }
  }
  ///-----------------------Get Navigation Data method-----------------------///
  Future<Map<String, dynamic>> getNavigationData(int bookingId, bool isTherapist) async {
    final String endpoint = isTherapist
        ? '/therapist/navigation/$bookingId/'
        : '/client/client_booking_navigation/$bookingId/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Navigation Data: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('API Response Status Navigation Data: ${response.statusCode}');
        _logger.d('API Response Body Navigation Data: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Navigation data fetched successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Navigation endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to fetch navigation data: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch navigation data: $e');
    }
  }
///-----------------------Get Loyalty Rewards method-----------------------///
  Future<Map<String, dynamic>> getLoyaltyRewards() async {
    final uri = Uri.parse('$baseUrl/client/loyalty/rewards/');
    final accessToken = await _storage.read(key: 'access_token');

    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.i('API Request Get Loyalty Rewards: GET $uri');
      _logger.i('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.i('Get Loyalty Rewards API Response Status: ${response.statusCode}');
        _logger.i('Get Loyalty Rewards API Response Body: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
          final data = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.i('Loyalty rewards fetched: $data');
          return data;
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Loyalty rewards not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to fetch loyalty rewards: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch loyalty rewards: $e', 0);
    }
  }

  ///-----------------------Add Favorite Therapist method-----------------------///
  Future<Map<String, dynamic>> addFavoriteTherapist(int therapistId) async {
    const String endpoint = '/client/love-therapists/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    final payload = {
      'therapist': therapistId,
    };

    if (kDebugMode) {
      _logger.d('API Request Add Favorite Therapist: POST $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(payload)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('API Response Status Add Favorite Therapist: ${response.statusCode}');
        _logger.d('API Response Body Add Favorite Therapist: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Therapist added to favorites successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Favorite therapist endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to add favorite therapist: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to add favorite therapist: $e', 0);
    }
  }

  ///-----------------------Remove Favorite Therapist method-----------------------///
  Future<void> removeFavoriteTherapist(int therapistId) async {
    const String endpoint = '/client/love-therapists/update/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    final payload = {
      'therapist_id': therapistId,
    };

    if (kDebugMode) {
      _logger.d('API Request Remove Favorite Therapist: DELETE $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(payload)}');
    }

    try {
      final response = await _client.delete(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('API Response Status Remove Favorite Therapist: ${response.statusCode}');
        _logger.d('API Response Body Remove Favorite Therapist: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
        case 204:
          _logger.d('Therapist removed from favorites successfully');
          return;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Favorite therapist endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to remove favorite therapist: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to remove favorite therapist: $e', 0);
    }
  }
  ///-----------------------Apply or Remove Loyalty Points-----------------------///
  Future<Map<String, dynamic>> applyLoyaltyPoints(int bookingId, bool applyPoints) async {
    const String endpoint = '/client/apply-loyalty-points/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    final payload = {
      'booking_id': bookingId,
      'apply_points': applyPoints,
    };

    if (kDebugMode) {
      _logger.d('API Request Apply Loyalty Points: POST $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(payload)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('API Response Status Apply Loyalty Points: ${response.statusCode}');
        _logger.d('API Response Body Apply Loyalty Points: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Loyalty points applied/removed successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Loyalty points endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to apply loyalty points: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to apply loyalty points: $e', 0);
    }
  }

  ///-----------------------Submit Medical Questionnaire-----------------------///
  Future<void> submitMedicalQuestionnaire(int bookingId, Map<String, dynamic> payload) async {
    final String endpoint = '/AI/bookings/$bookingId/symptom-check/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Submit Medical Questionnaire: POST $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
      _logger.d('Request Body: ${jsonEncode(payload)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(payload),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Submit Medical Questionnaire: ${response.statusCode}');
        _logger.d('API Response Headers Submit Medical Questionnaire: ${response.headers}');
        _logger.d('API Response Body Submit Medical Questionnaire: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          _logger.d('Medical questionnaire submitted successfully for booking $bookingId');
          return;
        case 400:
          String errorMessage = 'Invalid questionnaire data.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            } else if (errorBody.containsKey('detail') && errorBody['detail'] is String) {
              errorMessage = errorBody['detail'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Questionnaire endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to submit medical questionnaire: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to submit medical questionnaire: $e', 0);
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }

  ///-----------------------Initiate Payment method-----------------------///
  Future<Map<String, dynamic>> initiatePayment(int bookingId) async {
    final String endpoint = '/client/bookings/$bookingId/pay/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Initiate Payment: POST $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken", "Content-Type": "application/json"}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      final responseBody = response.body;

      if (kDebugMode) {
        _logger.d('API Response Status Initiate Payment: ${response.statusCode}');
        _logger.d('API Response Headers Initiate Payment: ${response.headers}');
        _logger.d('API Response Body Initiate Payment: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(responseBody) as Map<String, dynamic>;
          _logger.d('Payment initiated successfully for booking $bookingId: $responseData');
          return responseData; // Expected: {"session_url": "...", "payment_id": ...}
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: $responseBody');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: $responseBody', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: $responseBody', response.statusCode);
        case 404:
          throw NotFoundException('Payment endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: $responseBody', response.statusCode);
        default:
          throw ApiException('Failed to initiate payment: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to initiate payment: $e', 0);
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<List<Map<String, dynamic>>> getNotificationMessages(int roomId) async {
    final String endpoint = '/api/notification/messages/$roomId/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Notification Messages: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Get Notification Messages: ${response.statusCode}');
        _logger.d('API Response Body Get Notification Messages: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          final notifications = List<Map<String, dynamic>>.from(responseData['notifications'] ?? []);
          _logger.d('Notification messages fetched successfully: $notifications');
          return notifications;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Notification messages endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to fetch notification messages: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch notification messages: $e', 0);
    }
  }

 Future<Map<String, dynamic>> setupTherapistProfile(
     int userId, {
       File? image,
       String? fullName,
       String? phone,
       String? dateOfBirth,
       int? profileId,
     }) async {
   final String endpoint = '/therapist/therapist/setup/$userId/';
   final Uri uri = Uri.parse('$_baseUrl$endpoint');

   final payload = <String, dynamic>{
     if (fullName != null) 'full_name': fullName,
     if (phone != null) 'phone': phone,
     if (dateOfBirth != null) 'date_of_birth': dateOfBirth,
     if (profileId != null) 'profile_id': profileId,
   };

   if (kDebugMode) {
     _logger.d('API Request Setup Therapist Profile: PATCH $uri');
     _logger.d('Request Headers: {"Content-Type": "multipart/form-data"}');
     _logger.d('Request Body: ${jsonEncode(payload)}');
     if (image != null) {
       _logger.d('Image size: ${image.lengthSync()} bytes');
     }
   }

   try {
     http.MultipartRequest request = http.MultipartRequest('PATCH', uri)
       ..headers.addAll({
         'Content-Type': 'multipart/form-data',
       })
       ..fields.addAll({
         for (var entry in payload.entries) entry.key: entry.value.toString(),
       });

     if (image != null) {
       request.files.add(await http.MultipartFile.fromPath('image', image.path));
     }

     final streamedResponse = await request.send();
     final response = await http.Response.fromStream(streamedResponse);

     if (kDebugMode) {
       _logger.d('API Response Status Setup Therapist Profile: ${response.statusCode}');
       _logger.d('API Response Body Setup Therapist Profile: ${response.body}');
     }

     Map<String, dynamic>? responseData;
     if (response.headers['content-type']?.contains('application/json') == true) {
       try {
         responseData = jsonDecode(response.body) as Map<String, dynamic>;
       } catch (e) {
         _logger.e('Failed to parse JSON response: $e\nRaw body: ${response.body}');
         throw ServerException('Invalid server response format', response.statusCode);
       }
     }

     switch (response.statusCode) {
       case 200:
       case 201:
         if (responseData == null) {
           throw ServerException('Empty response body', response.statusCode);
         }
         _logger.d('Therapist profile setup successful: $responseData');
         return responseData;
       case 400:
         String errorMessage = 'Invalid input data.';
         if (responseData != null && responseData.containsKey('error')) {
           errorMessage = responseData['error'];
         }
         throw BadRequestException(errorMessage, response.statusCode);
       case 404:
         throw NotFoundException('Profile setup endpoint not found: $uri', response.statusCode);
       case 413:
         throw BadRequestException('Image size too large. Please select a smaller image.', response.statusCode);
       case 500:
         throw ServerException('Server error: ${response.body}', response.statusCode);
       default:
         throw ApiException('Failed to setup therapist profile: ${response.body}', response.statusCode);
     }
   } on http.ClientException catch (e) {
     _logger.e('Network Error: $e');
     throw NetworkException('Check your network connection');
   } catch (e) {
     _logger.e('Unexpected Error: $e');
     throw ApiException('Failed to setup therapist profile: $e', 0);
   } finally {
     if (kDebugMode) {
       _logger.d('API Call Completed: $endpoint');
     }
   }
 }
  /// Verify Documents
  Future<Map<String, dynamic>?> submitDocuments(Map<String, dynamic> payload) async {
    final String endpoint = '/therapist/documents/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    if (kDebugMode) {
      _logger.d('API Request Submit Documents: POST $uri');
      _logger.d('Request Payload: ${jsonEncode(payload)}');
    }

    try {
      var request = http.MultipartRequest('POST', uri);

      // Add user_id field - ensure it's converted to String
      request.fields['user_id'] = payload['user_id'].toString();

      // Add each document as a file if present
      const allFields = [
        'id_document',
        'ssn_or_ittn',
        'drivers_license',
        'liability_insurance',
        'certifications',
        'therapist_agreement',
        'tax_form'
      ];

      for (var field in allFields) {
        final fieldData = payload[field];
        if (fieldData != null && fieldData is Map<String, dynamic>) {
          final fileContent = fieldData['file'];
          final fileName = fieldData['name'];

          if (fileContent != null && fileName != null) {
            try {
              // Decode base64 back to bytes
              final bytes = base64Decode(fileContent as String);
              request.files.add(http.MultipartFile.fromBytes(
                field,
                bytes,
                filename: fileName as String,
              ));
            } catch (e) {
              _logger.e('Error processing file for field $field: $e');
              throw BadRequestException('Invalid file data for $field', 400);
            }
          }
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (kDebugMode) {
        _logger.d('API Response Status Submit Documents: ${response.statusCode}');
        _logger.d('API Response Body Submit Documents: ${response.body}');
      }

      Map<String, dynamic>? responseData;
      if (response.headers['content-type']?.contains('application/json') == true) {
        try {
          responseData = jsonDecode(response.body) as Map<String, dynamic>;
        } catch (e) {
          _logger.e('Failed to parse JSON response: $e\nRaw body: ${response.body}');
          throw ServerException('Invalid server response format', response.statusCode);
        }
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          if (responseData == null) {
            throw ServerException('Empty response body', response.statusCode);
          }
          _logger.d('Documents submitted successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid input data.';
          if (responseData != null && responseData.containsKey('error')) {
            errorMessage = responseData['error'].toString();
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 404:
          throw NotFoundException('Submit documents endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to submit documents: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to submit documents: $e', 0);
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }
  Future<Map<String, dynamic>> getTherapistReviews() async {
    const String endpoint = '/therapist/reviews/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Therapist Reviews: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Get Therapist Reviews: ${response.statusCode}');
        _logger.d('API Response Body Get Therapist Reviews: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          _logger.d('Therapist reviews fetched successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Therapist reviews endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to fetch therapist reviews: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch therapist reviews: $e', 0);
    }
  }
  Future<Map<String, dynamic>> submitReviewResponse(int reviewId, String response) async {
    final String endpoint = '/therapist/reviews/$reviewId/response/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Submit Review Response: PATCH $uri');
      _logger.d('Request Body: {"response": "$response"}');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final httpResponse = await _client.patch(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'response': response}),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Submit Review Response: ${httpResponse.statusCode}');
        _logger.d('API Response Body Submit Review Response: ${httpResponse.body}');
      }

      switch (httpResponse.statusCode) {
        case 200:
          final responseData = jsonDecode(httpResponse.body) as Map<String, dynamic>;
          _logger.d('Review response submitted successfully: $responseData');
          return responseData;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(httpResponse.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${httpResponse.body}');
          }
          throw BadRequestException(errorMessage, httpResponse.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${httpResponse.body}', httpResponse.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${httpResponse.body}', httpResponse.statusCode);
        case 404:
          throw NotFoundException('Review response endpoint not found: $uri', httpResponse.statusCode);
        case 500:
          throw ServerException('Server error: ${httpResponse.body}', httpResponse.statusCode);
        default:
          throw ApiException('Failed to submit review response: ${httpResponse.body}', httpResponse.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to submit review response: $e', 0);
    }
  }
  Future<List<Map<String, dynamic>>> getTherapistEarnings(String period) async {
    const String endpoint = '/therapist/therapist_earnings/';
    final Uri uri = Uri.parse('$baseUrl$endpoint?period=$period');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Therapist Earnings: GET $uri');
      _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
    }

    try {
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (kDebugMode) {
        _logger.d('API Response Status Get Therapist Earnings: ${response.statusCode}');
        _logger.d('API Response Body Get Therapist Earnings: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as List<dynamic>;
          final earningsList = responseData.map((item) => item as Map<String, dynamic>).toList();
          _logger.d('Therapist earnings fetched successfully: $earningsList');
          return earningsList;
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Therapist earnings endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to fetch therapist earnings: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch therapist earnings: $e', 0);
    }
  }
  Future<List<Map<String, dynamic>>> getDisputeSettings() async {
   const String endpoint = '/dispute/dispute-settings/';
   final Uri uri = Uri.parse('$_baseUrl$endpoint');

   if (kDebugMode) {
     _logger.d('API Request Get Dispute Settings: GET $uri');
   }

   try {
     final response = await _authenticatedRequest(method: 'GET', uri: uri);

     if (kDebugMode) {
       _logger.d('API Response Status Get Dispute Settings: ${response['statusCode']}');
       _logger.d('API Response Body Get Dispute Settings: ${response['body']}');
     }

     switch (response['statusCode']) {
       case 200:
         final responseData = jsonDecode(response['body']) as List<dynamic>;
         final disputeSettings = responseData.map((item) => item as Map<String, dynamic>).toList();
         _logger.d('Dispute settings fetched successfully: $disputeSettings');
         return disputeSettings;
       case 400:
         String errorMessage = 'Invalid request.';
         try {
           final errorBody = jsonDecode(response['body']) as Map<String, dynamic>;
           if (errorBody.containsKey('error') && errorBody['error'] is String) {
             errorMessage = errorBody['error'];
           }
         } catch (e) {
           _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response['body']}');
         }
         throw BadRequestException(errorMessage, response['statusCode']);
       case 401:
         throw UnauthorizedException('Authentication failed: ${response['body']}', response['statusCode']);
       case 403:
         throw ForbiddenException('Access denied: ${response['body']}', response['statusCode']);
       case 404:
         throw NotFoundException('Dispute settings endpoint not found: $uri', response['statusCode']);
       case 500:
         throw ServerException('Server error: ${response['body']}', response['statusCode']);
       default:
         throw ApiException('Failed to fetch dispute settings: ${response['body']}', response['statusCode']);
     }
   } on http.ClientException catch (e) {
     _logger.e('Network Error: $e');
     throw NetworkException('Check your network connection');
   } catch (e) {
     _logger.e('Unexpected Error: $e');
     throw ApiException('Failed to fetch dispute settings: $e', 0);
   }
 }
 Future<Map<String, dynamic>> postReview(Map<String, dynamic> data) async {
   const String endpoint = '/client/client/reviews/';
   final Uri uri = Uri.parse('$baseUrl$endpoint');

   final accessToken = await _storage.read(key: 'access_token');
   if (accessToken == null) {
     _logger.e('No access token found');
     throw UnauthorizedException('No access token found', 401);
   }

   if (kDebugMode) {
     _logger.d('API Request Post Review: POST $uri');
     _logger.d('Request Body: $data');
     _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
   }

   try {
     final response = await _client.post(
       uri,
       headers: {
         'Authorization': 'Bearer $accessToken',
         'Content-Type': 'application/json',
       },
       body: jsonEncode(data),
     );

     if (kDebugMode) {
       _logger.d('API Response Status Post Review: ${response.statusCode}');
       _logger.d('API Response Body Post Review: ${response.body}');
     }

     switch (response.statusCode) {
       case 200:
       case 201:
         final responseData = jsonDecode(response.body) as Map<String, dynamic>;
         _logger.d('Review posted successfully: $responseData');
         return responseData;
       case 400:
         String errorMessage = 'Invalid review data.';
         try {
           final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
           if (errorBody.containsKey('error') && errorBody['error'] is String) {
             errorMessage = errorBody['error'];
           }
         } catch (e) {
           _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
         }
         throw BadRequestException(errorMessage, response.statusCode);
       case 401:
         throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
       case 403:
         throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
       case 404:
         throw NotFoundException('Review endpoint not found: $uri', response.statusCode);
       case 500:
         throw ServerException('Server error: ${response.body}', response.statusCode);
       default:
         throw ApiException('Failed to post review: ${response.body}', response.statusCode);
     }
   } on http.ClientException catch (e) {
     _logger.e('Network Error: $e');
     throw NetworkException('Check your network connection');
   } catch (e) {
     _logger.e('Unexpected Error: $e');
     throw ApiException('Failed to post review: $e', 0);
   }
 }

 // New method to post dispute
 Future<Map<String, dynamic>> postDispute(Map<String, dynamic> data) async {
   const String endpoint = '/dispute/disputes/create/';
   final Uri uri = Uri.parse('$baseUrl$endpoint');

   final accessToken = await _storage.read(key: 'access_token');
   if (accessToken == null) {
     _logger.e('No access token found');
     throw UnauthorizedException('No access token found', 401);
   }

   if (kDebugMode) {
     _logger.d('API Request Post Dispute: POST $uri');
     _logger.d('Request Body: $data');
     _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
   }

   try {
     final response = await _client.post(
       uri,
       headers: {
         'Authorization': 'Bearer $accessToken',
         'Content-Type': 'application/json',
       },
       body: jsonEncode(data),
     );

     if (kDebugMode) {
       _logger.d('API Response Status Post Dispute: ${response.statusCode}');
       _logger.d('API Response Body Post Dispute: ${response.body}');
     }

     switch (response.statusCode) {
       case 200:
       case 201:
         final responseData = jsonDecode(response.body) as Map<String, dynamic>;
         _logger.d('Dispute posted successfully: $responseData');
         return responseData;
       case 400:
         String errorMessage = 'Invalid dispute data.';
         try {
           final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
           if (errorBody.containsKey('error') && errorBody['error'] is String) {
             errorMessage = errorBody['error'];
           }
         } catch (e) {
           _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
         }
         throw BadRequestException(errorMessage, response.statusCode);
       case 401:
         throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
       case 403:
         throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
       case 404:
         throw NotFoundException('Dispute endpoint not found: $uri', response.statusCode);
       case 500:
         throw ServerException('Server error: ${response.body}', response.statusCode);
       default:
         throw ApiException('Failed to post dispute: ${response.body}', response.statusCode);
     }
   } on http.ClientException catch (e) {
     _logger.e('Network Error: $e');
     throw NetworkException('Check your network connection');
   } catch (e) {
     _logger.e('Unexpected Error: $e');
     throw ApiException('Failed to post dispute: $e', 0);
   }
 }

}

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}';
}
class NoDataException extends ApiException {
  NoDataException(String message) : super(message, 404);
}
class BadRequestException extends ApiException {
  BadRequestException(super.message, int super.statusCode);
}
class UnauthorizedException extends ApiException {
  UnauthorizedException(super.message, int super.statusCode);
}
class ForbiddenException extends ApiException {
  ForbiddenException(super.message, int super.statusCode);
}
class NotFoundException extends ApiException {
  NotFoundException(super.message, int super.statusCode);
}
class ServerException extends ApiException {
  ServerException(super.message, int super.statusCode);
}
class NetworkException extends ApiException {
  NetworkException(super.message);
}
class PendingApprovalException implements Exception {
  final String message;
  final int statusCode;

  PendingApprovalException(this.message, [this.statusCode = 201]);

  @override
  String toString() => 'PendingApprovalException: $message (Status: $statusCode)';
}
class TokenExpiredException extends ApiException {
  TokenExpiredException(String message, int statusCode) : super(message, statusCode);
}