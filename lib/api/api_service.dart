import 'dart:io';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

class ApiService {
  static const String baseUrl = "http://192.168.20.201:1233";
  final http.Client _client;
  final _storage = const FlutterSecureStorage();
  final Logger _logger;

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


  ///-----------------------SetUp Client Profile method-----------------------///
  Future<Map<String, dynamic>> setupClientProfile(
      int userId, {
        required int profileId,
        File? image,
        String? phone,
        String? dateOfBirth,
      }) async {
    final String endpoint = '/api/clients/$userId/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    try {
      final request = http.MultipartRequest('PATCH', uri);
      request.headers['Authorization'] = 'Bearer $accessToken';

      // Add fields to the request
      request.fields['id'] = profileId.toString();
      request.fields['user'] = userId.toString();
      if (phone != null && phone.isNotEmpty) {
        request.fields['phone'] = phone;
      }
      if (dateOfBirth != null && dateOfBirth.isNotEmpty) {
        request.fields['date_of_birth'] = dateOfBirth;
      }

      // Add image file if provided
      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
            contentType: MediaType('image', 'jpeg'), // Adjust based on image type
          ),
        );
      }

      if (kDebugMode) {
        _logger.d('API Request Update Client Profile: PATCH $uri');
        _logger.d('Request Headers: {"Authorization": "Bearer $accessToken"}');
        _logger.d('Request Fields: ${request.fields}');
        _logger.d('Request Files: ${image != null ? image.path : 'No image'}');
      }

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();

      if (kDebugMode) {
        _logger.d('API Response Status Update Client Profile: ${response.statusCode}');
        _logger.d('API Response Body Update Client Profile: $responseBody');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          return jsonDecode(responseBody) as Map<String, dynamic>;
        case 400:
          String errorMessage = 'Failed to update profile.';
          try {
            final errorBody = jsonDecode(responseBody) as Map<String, dynamic>;
            if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            } else if (errorBody.containsKey('phone') && errorBody['phone'] is List && errorBody['phone'].isNotEmpty) {
              errorMessage = errorBody['phone'][0];
            } else if (errorBody.containsKey('date_of_birth') &&
                errorBody['date_of_birth'] is List &&
                errorBody['date_of_birth'].isNotEmpty) {
              errorMessage = errorBody['date_of_birth'][0];
            } else if (errorBody.containsKey('image') && errorBody['image'] is List && errorBody['image'].isNotEmpty) {
              errorMessage = errorBody['image'][0];
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
          throw ApiException('Failed to update profile: $responseBody', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Profile Update Error: $e');
      throw ApiException('Failed to update profile: $e');
    }
  }

  ///------------------------------------API Auth------------------------------------///

  Future<Map<String, dynamic>> login(Map<String, dynamic> data) async {
    const String endpoint = '/auth/login/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

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

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
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
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    if (kDebugMode) {
      _logger.d('API Request Sign Up: POST $uri');
      _logger.d('Request Headers Sign Up: {"Content-Type": "application/json"}');
      _logger.d('Request Body Sign Up: ${jsonEncode(data)}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(data),
      );

      if (kDebugMode) {
        _logger.d('API Response Status Sign Up: ${response.statusCode}');
        _logger.d('API Response Headers Sign Up: ${response.headers}');
        _logger.d('API Response Body Sign Up: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
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
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
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
    final Uri uri = Uri.parse('$baseUrl$endpoint');

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

      switch (response.statusCode) {
        case 200:
        case 201:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
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
          throw NotFoundException('Social sign-in endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
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

  Future<Map<String, dynamic>> verifyOtp(String email, String otp) async {
    const String endpoint = '/auth/verify_otp/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

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
    final Uri uri = Uri.parse('$baseUrl$endpoint');

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
    const String endpoint = '/users/password/reset-request/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    if (kDebugMode) {
      _logger.d('API Request: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json"}');
      _logger.d('Request Body: {"email": "$email"}');
    }

    try {
      final response = await _client.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (kDebugMode) {
        _logger.d('API Response Status: ${response.statusCode}');
        _logger.d('API Response Headers: ${response.headers}');
        _logger.d('API Response Body: ${response.body}');
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
          throw NotFoundException('Reset password endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to request password reset: ${response.body}', response.statusCode);
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
      throw ApiException("No user found with the provided email address.");
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }

  Future<Map<String, dynamic>> resetPasswordActivate(String email, String otp) async {
    const String endpoint = '/users/password/reset-activate/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final data = {
      "email": email,
      "otp": otp,
    };

    if (kDebugMode) {
      _logger.d('API Request: POST $uri');
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
        _logger.d('API Response Status: ${response.statusCode}');
        _logger.d('API Response Headers: ${response.headers}');
        _logger.d('API Response Body: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          return jsonDecode(response.body) as Map<String, dynamic>;
        case 400:
          String errorMessage = 'Invalid OTP or email.';
          try {
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
              errorMessage = errorBody;
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
            errorMessage = response.body;
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
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (kDebugMode) {
        _logger.e('Unexpected Error: $e');
      }
      throw ApiException('You Input Wrong OTP');
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }

  Future<String> resetPassword(String newPassword, String? accessToken) async {
    const String endpoint = '/users/password/reset/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final data = {
      "new_password": newPassword,
    };

    if (kDebugMode) {
      _logger.d('API Request: POST $uri');
      _logger.d('Request Headers: {"Content-Type": "application/json", "Authorization": "Bearer $accessToken"}');
      _logger.d('Request Body: ${jsonEncode(data)}');
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
        _logger.d('API Response Status: ${response.statusCode}');
        _logger.d('API Response Headers: ${response.headers}');
        _logger.d('API Response Body: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
        case 201:
          return response.body.replaceAll('"', '');
        case 400:
          String errorMessage = 'Invalid request.';
          try {
            final errorBody = jsonDecode(response.body);
            if (errorBody is Map<String, dynamic> && errorBody.containsKey('detail')) {
              errorMessage = errorBody['detail'];
            } else if (errorBody is Map<String, dynamic> && errorBody.containsKey('new_password') && errorBody['new_password'] is List && errorBody['new_password'].isNotEmpty) {
              errorMessage = errorBody['new_password'][0];
            } else if (errorBody is String) {
              errorMessage = errorBody;
            }
          } catch (e) {
            _logger.e('Failed to parse 400 response body: $e\nRaw body: ${response.body}');
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
        _logger.e('Network Error: $e');
      }
      throw NetworkException('Check your network connection');
    } catch (e) {
      if (e is! BadRequestException && e is! UnauthorizedException && e is! ForbiddenException && e is! NotFoundException && e is! ServerException && e is! ApiException) {
        if (kDebugMode) {
          _logger.e('Unexpected Error: $e');
        }
        throw ApiException('An unexpected error occurred: $e');
      }
      rethrow;
    } finally {
      if (kDebugMode) {
        _logger.d('API Call Completed: $endpoint');
      }
    }
  }

  ///------------------------------------Booking----------------------------------///
  Future<Map<String, dynamic>> createBooking(Map<String, dynamic> payload) async {
    const String endpoint = '/api/bookings/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

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
          String errorMessage = 'Invalid booking data.';
          try {
            final errorBody = jsonDecode(response.body) as Map<String, dynamic>;
            if (errorBody.containsKey('age_range') && errorBody['age_range'] is List && errorBody['age_range'].isNotEmpty) {
              errorMessage = 'Please select a valid age range.';
            } else if (errorBody.containsKey('error') && errorBody['error'] is String) {
              errorMessage = errorBody['error'];
            } else if (errorBody.isNotEmpty) {
              errorMessage = errorBody.entries.first.value is List ? errorBody.entries.first.value[0] : errorBody.entries.first.value.toString();
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
          throw NotFoundException('Booking endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to create booking: ${response.body}', response.statusCode);
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
    const String endpoint = '/api/bookings/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

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
  ///------------------------------------Therapist----------------------------------///
  Future<List<Map<String, dynamic>>> getTherapists() async {
    const String endpoint = '/api/therapists/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Therapists: GET $uri');
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
        _logger.d('API Response Status Get Therapists: ${response.statusCode}');
        _logger.d('API Response Headers Get Therapists: ${response.headers}');
        _logger.d('API Response Body Get Therapists: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as List<dynamic>;
          _logger.d('Therapists fetched successfully: $responseData');
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
          throw ApiException('Failed to fetch therapists: ${response.body}', response.statusCode);
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

  ///-----------------------Get Client Profile Details method-----------------------///
  Future<Map<String, dynamic>> getClientProfile() async {
    const String endpoint = '/api/client/profile/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
      throw UnauthorizedException('No access token found', 401);
    }

    if (kDebugMode) {
      _logger.d('API Request Get Client Profile: GET $uri');
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
        _logger.d('API Response Status Get Client Profile: ${response.statusCode}');
        _logger.d('API Response Headers Get Client Profile: ${response.headers}');
        _logger.d('API Response Body Get Client Profile: ${response.body}');
      }

      switch (response.statusCode) {
        case 200:
          final responseData = jsonDecode(response.body) as Map<String, dynamic>;
          // Adjust image URL to include /api/
          if (responseData['image'] != null && responseData['image'] != '/media/documents/default.jpg') {
            if (!responseData['image'].startsWith('/api/')) {
              responseData['image'] = '/api${responseData['image']}';
            }
          }
          _logger.d('Client profile fetched successfully: $responseData');
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
          throw NotFoundException('Client profile endpoint not found: $uri', response.statusCode);
        case 500:
          throw ServerException('Server error: ${response.body}', response.statusCode);
        default:
          throw ApiException('Failed to fetch client profile: ${response.body}', response.statusCode);
      }
    } on http.ClientException catch (e) {
      _logger.e('Network Error: $e');
      throw NetworkException('Check your network connection');
    } catch (e) {
      _logger.e('Unexpected Error: $e');
      throw ApiException('Failed to fetch client profile: $e');
    }
  }
  ///-----------------------Update Client Profile Details method-----------------------///
  Future<Map<String, dynamic>> updateClientProfile(Map<String, dynamic> fields, {File? image}) async {
    const String endpoint = '/api/client/profile/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.e('No access token found');
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

      // Add edited fields
      fields.forEach((key, value) {
        if (value != null && value.toString().isNotEmpty) {
          request.fields[key] = value.toString();
        }
      });

      // Add image if provided
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
  ///-----------------------Get Favorite Therapists method-----------------------///
  Future<List<Map<String, dynamic>>> getFavoriteTherapists() async {
    const String endpoint = '/api/love-therapists/';
    final Uri uri = Uri.parse('$baseUrl$endpoint');

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