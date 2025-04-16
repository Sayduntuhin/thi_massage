import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
class ApiService {
  static const String _baseUrl = "http://192.168.20.201:1235";
  final http.Client _client;
  final _storage = const FlutterSecureStorage();
  ApiService({http.Client? client}) : _client = client ?? http.Client();
  ///----------------------Login method-------------------------///
  ///----------------------Login method-------------------------///
  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    const String endpoint = '/auth/login/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    if (kDebugMode) {
      debugPrint('-------------------------API Request Login: POST $uri');
      debugPrint('-------------------------Request Headers Login: {"Content-Type": "application/json"}');
      debugPrint('-------------------------Request Body Login: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        debugPrint('----------------API Response Status Login---------------: ${response.statusCode}');
        debugPrint('----------------API Response Headers Login--------------: ${response.headers}');
        debugPrint('----------------API Response Body Login------------------: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          // Store tokens
          if (responseData.containsKey('access')) {
            await _storage.write(key: 'access_token', value: responseData['access']);
          }
          if (responseData.containsKey('refresh')) {
            await _storage.write(key: 'refresh_token', value: responseData['refresh']);
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
            debugPrint('Failed to parse 400 response body: $e - Raw body: ${response.body}');
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
        debugPrint('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        debugPrint('API Call Completed: $endpoint');
      }
    }
  }  ///-----------------------SignUp method-----------------------///
  Future<Map<String, dynamic>> signUp(Map<String, dynamic> data) async {
    const String endpoint = '/auth/normal_signup/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    if (kDebugMode) {
      debugPrint('-------------------------API Request Sign Up: POST $uri');
      debugPrint('-------------------------Request Headers Sign Up: {"Content-Type": "application/json"}');
      debugPrint('-------------------------Request Body Sign Up: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        debugPrint('----------------API Response Status Sign Up---------------: ${response.statusCode}');
        debugPrint('----------------API Response Headers Sign Up--------------: ${response.headers}');
        debugPrint('----------------API Response Body Sign Up------------------: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          // Store tokens
          if (responseData.containsKey('access')) {
            await _storage.write(key: 'access_token', value: responseData['access']);
          }
          if (responseData.containsKey('refresh')) {
            await _storage.write(key: 'refresh_token', value: responseData['refresh']);
          }
          return responseData;
        case 400:
          String errorMessage = 'Something went wrong. Please try again.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('email') && errorBody['email'] is List && errorBody['email'].isNotEmpty) {
              errorMessage = errorBody['email'][0];
              if (errorMessage == 'user with this email already exists.') {
                errorMessage = 'This email already exists.';
              }
            } else if (errorBody.containsKey('phone_number') && errorBody['phone_number'] is List && errorBody['phone_number'].isNotEmpty) {
              errorMessage = errorBody['phone_number'][0];
            } else if (errorBody.containsKey('password') && errorBody['password'] is List && errorBody['password'].isNotEmpty) {
              errorMessage = errorBody['password'][0];
            } else if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            debugPrint('Failed to parse 400 response body: $e - Raw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to sign up: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        debugPrint('API Call Completed: $endpoint');
      }
    }
  }

  ///-----------------------Social SignUp/SignIn method-----------------------///
  Future<Map<String, dynamic>> socialSignUpSignIn(Map<String, dynamic> data) async {
    const String endpoint = '/auth/social_signup_signin/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    if (kDebugMode) {
      debugPrint('-------------------------API Request Social SignUp/SignIn: POST $uri');
      debugPrint('-------------------------Request Headers Social: {"Content-Type": "application/json"}');
      debugPrint('-------------------------Request Body Social: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        debugPrint('----------------API Response Status Social SignUp/SignIn---------------: ${response.statusCode}');
        debugPrint('----------------API Response Headers Social SignUp/SignIn--------------: ${response.headers}');
        debugPrint('----------------API Response Body Social SignUp/SignIn------------------: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          // Check for role conflict
          final requestedRole = data['role'];
          final returnedRole = responseData['user_profile']?['role'];
          if (returnedRole != null && returnedRole != requestedRole) {
            throw BadRequestException(
              'This email is already registered as a $returnedRole. Please use the correct role.',
              response.statusCode,
            );
          }
          // Store tokens
          if (responseData.containsKey('access')) {
            await _storage.write(key: 'access_token', value: responseData['access']);
          }
          if (responseData.containsKey('refresh')) {
            await _storage.write(key: 'refresh_token', value: responseData['refresh']);
          }
          return responseData;
        case 400:
          String errorMessage = 'Social sign-in failed. Please try again.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('email') && errorBody['email'] is List && errorBody['email'].isNotEmpty) {
              errorMessage = errorBody['email'][0];
            } else if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            }
          } catch (e) {
            debugPrint('Failed to parse 400 response body: $e - Raw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Social sign-in endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to sign in: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } finally {
      if (kDebugMode) {
        debugPrint('API Call Completed: $endpoint');
      }
    }
  }

  ///-----------------------Verify OTP method----------------------///
  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    const String endpoint = '/auth/verify_otp/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final data = {
      "email": email,
      "otp": otp,
    };

    if (kDebugMode) {
      debugPrint('------------------------API Request Verify OTP: POST $uri');
      debugPrint('------------------------Request Headers: {"Content-Type": "application/json"}');
      debugPrint('------------------------Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        debugPrint('----------------API Response Status Verify OTP---------------: ${response.statusCode}');
        debugPrint('----------------API Response Headers Verify OTP--------------: ${response.headers}');
        debugPrint('----------------API Response Body Verify OTP------------------: ${response.body}');
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
            debugPrint('Failed to parse 400 response body: $e - Raw body: ${response.body}');
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
        debugPrint('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected Error: $e');
      }
      throw ApiException('An error occurred while verifying OTP: $e');
    } finally {
      if (kDebugMode) {
        debugPrint('API Call Completed: $endpoint');
      }
    }
  }

  ///-----------------------Resend OTP method----------------------///
  Future<Map<String, dynamic>> resendOtp(String email) async {
    const String endpoint = '/auth/resend_otp/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final data = {"email": email};

    if (kDebugMode) {
      debugPrint('------------------------API Request Resend OTP: POST $uri');
      debugPrint('------------------------Request Headers: {"Content-Type": "application/json"}');
      debugPrint('------------------------Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        debugPrint('----------------API Response Status Resend OTP---------------: ${response.statusCode}');
        debugPrint('----------------API Response Headers Resend OTP--------------: ${response.headers}');
        debugPrint('----------------API Response Body Resend OTP------------------: ${response.body}');
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
            debugPrint('Failed to parse 400 response body: $e - Raw body: ${response.body}');
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
        debugPrint('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected Error: $e');
      }
      throw ApiException('An error occurred while resending OTP: $e');
    } finally {
      if (kDebugMode) {
        debugPrint('API Call Completed: $endpoint');
      }
    }
  }
  ///-----------------------Password Reset Request method----------------------///
  Future<Map<String, dynamic>> resetPasswordRequest(String email) async {
    const String endpoint = '/users/password/reset-request/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    if (kDebugMode) {
      debugPrint('------------------------API Request: POST $uri');
      debugPrint('------------------------Request Headers: {"Content-Type": "application/json"}');
      debugPrint('------------------------Request Body: {"email": "$email"}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (kDebugMode) {
        debugPrint('----------------API Response Status---------------: ${response.statusCode}');
        debugPrint('----------------API Response Headers--------------: ${response.headers}');
        debugPrint('----------------API Response Body------------------: ${response.body}');
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
            debugPrint('Failed to parse 400 response body: $e - Raw body: ${response.body}');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Reset password endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to request password reset: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected Error: $e');
      }
      throw ApiException("No user found with the provided email address.");
    } finally {
      if (kDebugMode) {
        debugPrint('API Call Completed: $endpoint');
      }
    }
  }
  ///-----------------------Password Reset Activate method----------------------///
  Future<Map<String, dynamic>> resetPasswordActivate(String email, String otp) async {
    const String endpoint = '/users/password/reset-activate/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final data = {
      "email": email,
      "otp": otp,
    };

    if (kDebugMode) {
      debugPrint('------------------------API Request: POST $uri');
      debugPrint('------------------------Request Headers: {"Content-Type": "application/json"}');
      debugPrint('------------------------Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        debugPrint('----------------API Response Status---------------: ${response.statusCode}');
        debugPrint('----------------API Response Headers--------------: ${response.headers}');
        debugPrint('----------------API Response Body------------------: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          return jsonDecode(response.body) as Map<String, dynamic>;
        case 400:
          String errorMessage = 'Invalid OTP or email.';
          try {
            // Try parsing as a map first
            final errorBody = jsonDecode(response.body);
            if (errorBody is Map<String, dynamic>) {
              if (errorBody.containsKey('otp') && errorBody['otp'] is List && errorBody['otp'].isNotEmpty) {
                errorMessage = errorBody['otp'][0];
              } else if (errorBody.containsKey('email') && errorBody['email'] is List && errorBody['email'].isNotEmpty) {
                errorMessage = errorBody['email'][0];
              } else if (errorBody.containsKey('error') && errorBody['error'] is String) {
                errorMessage = errorBody['error'];
              }
            } else if (errorBody is String) {
              // Handle case where response is a plain string
              errorMessage = errorBody;
            }
          } catch (e) {
            // If parsing fails, use the raw body as the error message
            debugPrint('Failed to parse 400 response body: $e - Raw body: ${response.body}');
            errorMessage = response.body; // Use raw string response
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Reset activate endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to activate password reset: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Unexpected Error: $e');
      }
      throw ApiException('You Input Wrong OTP');
    } finally {
      if (kDebugMode) {
        debugPrint('API Call Completed: $endpoint');
      }
    }
  }
  ///-----------------------Password Change method----------------------///
  Future<String> resetPassword(String newPassword, String? accessToken) async {
    const String endpoint = '/users/password/reset/';
    final Uri uri = Uri.parse('$_baseUrl$endpoint');

    final data = {
      "new_password": newPassword,
    };

    if (kDebugMode) {
      debugPrint('------------------------API Request: POST $uri');
      debugPrint('------------------------Request Headers: {"Content-Type": "application/json", "Authorization": "Bearer $accessToken"}');
      debugPrint('------------------------Request Body: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (accessToken != null) 'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        debugPrint('----------------API Response Status---------------: ${response.statusCode}');
        debugPrint('----------------API Response Headers--------------: ${response.headers}');
        debugPrint('----------------API Response Body------------------: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          return response.body.replaceAll('"', ''); // Remove quotes from string
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody is Map<String, dynamic> && errorBody.containsKey('detail')) {
              errorMessage = errorBody['detail']; // Extract "detail" field
            } else if (errorBody is Map<String, dynamic> && errorBody.containsKey('new_password') && errorBody['new_password'] is List && errorBody['new_password'].isNotEmpty) {
              errorMessage = errorBody['new_password'][0];
            } else if (errorBody is String) {
              errorMessage = errorBody;
            }
          } catch (e) {
            debugPrint('Failed to parse 400 response body: $e - Raw body: ${response.body}');
            errorMessage = response.body.replaceAll('"', '');
          }
          throw BadRequestException(errorMessage, response.statusCode);
        case 401:
          throw UnauthorizedException('Authentication failed: ${response.body}', response.statusCode);
        case 403:
          throw ForbiddenException('Access denied: ${response.body}', response.statusCode);
        case 404:
          throw NotFoundException('Reset password endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to reset password: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      if (kDebugMode) {
        debugPrint('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (e is! BadRequestException && e is! UnauthorizedException && e is! ForbiddenException && e is! NotFoundException && e is! ServerException && e is! ApiException) {
        if (kDebugMode) {
          debugPrint('Unexpected Error: $e');
        }
        throw ApiException('An unexpected error occurred: $e');
      }
      // Rethrow the original exception if it's one of our custom exceptions
      rethrow;
    } finally {
      if (kDebugMode) {
        debugPrint('API Call Completed: $endpoint');
      }
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