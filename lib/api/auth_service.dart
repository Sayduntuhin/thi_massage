import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:thi_massage/api/api_service.dart';
import 'dart:math';

class AuthService {
  final ApiService _apiService;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  AuthService({ApiService? apiService}) : _apiService = apiService ?? ApiService();

  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.login({
        "email": email,
        "password": password,
      });
      _logger.d('AuthService: Login response: $response');
      await _storeAuthData(response);
      await debugStoredData();
      _logger.d('AuthService: Login successful for $email');
      return response;
    } catch (e) {
      if (e is PendingApprovalException) {
        _logger.w('AuthService: Account pending admin approval for $email');
      } else {
        _logger.e('AuthService: Login failed: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> socialLogin({
    required String email,
    required String fullName,
    required String role,
    required String authProvider,
  }) async {
    try {
      final response = await _apiService.socialSignUpSignIn({
        "email": email,
        "full_name": fullName,
        "role": role,
        "auth_provider": authProvider,
      });
      _logger.d('AuthService: Social login response: $response');
      await _storeAuthData(response);
      await debugStoredData();
      _logger.d('AuthService: Social login successful for $email ($authProvider)');
      return response;
    } catch (e) {
      if (e is PendingApprovalException) {
        _logger.w('AuthService: Account pending admin approval for $email ($authProvider)');
      } else {
        _logger.e('AuthService: Social login failed ($authProvider): $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> googleSignIn({required bool isTherapist}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: '1048463216573-xyz123.apps.googleusercontent.com',
        serverClientId: '1048463216573-68qmf5ml28m1f8uol09cstfno4jb33gk.apps.googleusercontent.com',
      );

      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      _logger.d('AuthService: Cleared previous Google sessions');

      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w('AuthService: Google Sign-In canceled by user');
        throw Exception('Google Sign-In canceled');
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Google Sign-In: No ID token received');
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null || firebaseUser.email == null) {
        throw Exception('Google Sign-In: Failed to retrieve user data');
      }

      _logger.d('AuthService: Google Firebase user: ${firebaseUser.email}');

      return await socialLogin(
        email: firebaseUser.email!,
        fullName: firebaseUser.displayName ?? 'Google User',
        role: isTherapist ? 'therapist' : 'client',
        authProvider: 'google',
      );
    } catch (e) {
      _logger.e('AuthService: Google Sign-In failed: $e');
      rethrow;
    }
  }

  Future<Map<String, dynamic>> facebookSignIn({required bool isTherapist}) async {
    try {
      final LoginResult result = await FacebookAuth.instance.login(
        permissions: ['email', 'public_profile'],
      );

      if (result.status != LoginStatus.success) {
        String message;
        switch (result.status) {
          case LoginStatus.cancelled:
            message = 'Facebook Sign-In canceled';
            break;
          case LoginStatus.failed:
            message = 'Facebook Sign-In failed: ${result.message}';
            break;
          default:
            message = 'Unknown error during Facebook Sign-In';
        }
        _logger.w('AuthService: $message');
        throw Exception(message);
      }

      final userData = await FacebookAuth.instance.getUserData(
        fields: 'email,name',
      );

      final String? email = userData['email'];
      final String? fullName = userData['name'];

      if (email == null || fullName == null) {
        throw Exception('Facebook Sign-In: Failed to retrieve user data');
      }

      _logger.d('AuthService: Facebook user: $email, $fullName');

      return await socialLogin(
        email: email,
        fullName: fullName,
        role: isTherapist ? 'therapist' : 'client',
        authProvider: 'facebook',
      );
    } catch (e) {
      if (e is PendingApprovalException) {
        _logger.w('AuthService: Account pending admin approval for Facebook Sign-In');
      } else {
        _logger.e('AuthService: Facebook Sign-In failed: $e');
      }
      rethrow;
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String fullName,
    required String phoneNumber,
    required String role,
  }) async {
    try {
      final response = await _apiService.signUp({
        "email": email,
        "password": password,
        "full_name": fullName,
        "phone_number": phoneNumber,
        "role": role,
      });
      _logger.d('AuthService: Sign up response: $response');
      await _storeAuthData(response);
      await debugStoredData();
      _logger.d('AuthService: Sign up successful for $email');
      return response;
    } catch (e) {
      _logger.e('AuthService: Sign up failed: $e');
      rethrow;
    }
  }

  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  Future<bool> isSessionValid() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.d('AuthService: No access token found');
      return false;
    }
    _logger.d('AuthService: Session valid with access token');
    return true;
  }

  Future<String> getUserRole() async {
    final role = await _storage.read(key: 'user_role');
    if (role == null) {
      _logger.w('AuthService: No role in storage, attempting to fetch from API');
      try {
        final profile = await getUserProfile();
        final fetchedRole = profile['role'];
        if (fetchedRole != null) {
          await _storage.write(key: 'user_role', value: fetchedRole);
          _logger.d('AuthService: Fetched and stored role: $fetchedRole');
          return fetchedRole;
        }
      } catch (e) {
        _logger.e('AuthService: Failed to fetch role from API: $e');
      }
    }
    return role ?? 'client';
  }

  Future<void> logout() async {
    try {
      await _storage.deleteAll(); // Clear all storage
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
      _logger.d('AuthService: Logout successful, all storage cleared');
    } catch (e) {
      _logger.e('AuthService: Logout failed: $e');
      rethrow;
    }
  }

  Future<String?> getUserId() async {
    final userId = await _storage.read(key: 'user_id');
    _logger.d('AuthService: Retrieved user ID: $userId');
    return userId;
  }

  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final role = await getUserRole();
      Map<String, dynamic> response;

      if (role == 'therapist') {
        response = await _apiService.getTherapistOwnProfile();
      } else {
        response = await _apiService.getClientProfile();
      }

      if (!response.containsKey('role')) {
        response['role'] = role;
      }

      _logger.d('AuthService: Fetched user profile: $response');
      return response;
    } catch (e) {
      _logger.e('AuthService: Failed to fetch user profile: $e');
      final role = await _storage.read(key: 'user_role');
      return {'role': role ?? 'client'};
    }
  }

  Future<void> _storeAuthData(Map<String, dynamic> response) async {
    try {
      if (response['access'] != null) {
        await _storage.write(key: 'access_token', value: response['access']);
        _logger.d('AuthService: Stored access token');
      } else {
        _logger.w('AuthService: No access token in response: ${response.keys.toList()}');
      }

      if (response['refresh'] != null) {
        await _storage.write(key: 'refresh_token', value: response['refresh']);
        _logger.d('AuthService: Stored refresh token');
      }

      String? userRole;
      String? userId;

      if (response['user_profile'] != null) {
        final userProfile = response['user_profile'];
        if (userProfile['user'] != null) {
          userId = userProfile['user'].toString();
        } else if (userProfile['id'] != null) {
          userId = userProfile['id'].toString();
        } else if (userProfile['user_id'] != null) {
          userId = userProfile['user_id'].toString();
        }

        if (userProfile['role'] != null) {
          userRole = userProfile['role'];
        } else if (userProfile['user_role'] != null) {
          userRole = userProfile['user_role'];
        } else if (userProfile['user_type'] != null) {
          userRole = userProfile['user_type'];
        }
      } else if (response['profile_data'] != null) {
        final profileData = response['profile_data'];
        if (profileData['user'] != null) {
          userId = profileData['user'].toString();
        } else if (profileData['id'] != null) {
          userId = profileData['id'].toString();
        } else if (profileData['user_id'] != null) {
          userId = profileData['user_id'].toString();
        }

        if (profileData['role'] != null) {
          userRole = profileData['role'];
        } else if (profileData['user_role'] != null) {
          userRole = profileData['user_role'];
        } else if (profileData['user_type'] != null) {
          userRole = profileData['user_type'];
        }
      } else {
        if (response['user'] != null) {
          userId = response['user'].toString();
        } else if (response['id'] != null) {
          userId = response['id'].toString();
        } else if (response['user_id'] != null) {
          userId = response['user_id'].toString();
        }

        if (response['role'] != null) {
          userRole = response['role'];
        } else if (response['user_role'] != null) {
          userRole = response['user_role'];
        } else if (response['user_type'] != null) {
          userRole = response['user_type'];
        }
      }

      if (userId != null) {
        await _storage.write(key: 'user_id', value: userId);
        _logger.d('AuthService: Stored user ID: $userId');
      } else {
        _logger.w('AuthService: No user ID found in response: ${response.keys.toList()}');
      }

      if (userRole != null) {
        await _storage.write(key: 'user_role', value: userRole);
        _logger.d('AuthService: Stored user role: $userRole');
      } else {
        _logger.w('AuthService: No user role found in response: ${response.keys.toList()}');
        if (response['user_profile'] != null) {
          _logger.w('AuthService: user_profile keys: ${response['user_profile'].keys.toList()}');
        }
        if (response['profile_data'] != null) {
          _logger.w('AuthService: profile_data keys: ${response['profile_data'].keys.toList()}');
        }
      }
    } catch (e) {
      _logger.e('AuthService: Error storing auth data: $e');
      rethrow;
    }
  }

  Future<void> debugStoredData() async {
    final accessToken = await _storage.read(key: 'access_token');
    final refreshToken = await _storage.read(key: 'refresh_token');
    final userId = await _storage.read(key: 'user_id');
    final userRole = await _storage.read(key: 'user_role');

    _logger.d('=== STORED AUTH DATA DEBUG ===');
    _logger.d('Access Token: ${accessToken != null ? 'Present' : 'Missing'}');
    _logger.d('Refresh Token: ${refreshToken != null ? 'Present' : 'Missing'}');
    _logger.d('User ID: $userId');
    _logger.d('User Role: $userRole');
    _logger.d('===============================');
  }
}