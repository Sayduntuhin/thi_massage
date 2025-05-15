import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logger/logger.dart';
import 'package:thi_massage/api/api_service.dart';
import 'package:crypto/crypto.dart';
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

  /// Login with email and password
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await _apiService.login({
        "email": email,
        "password": password,
      });
      _logger.d('AuthService: Login successful for $email');

      // Store tokens and user role
      await _storeAuthData(response);

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
      _logger.d('AuthService: Social login successful for $email ($authProvider)');

      // Store tokens and user role
      await _storeAuthData(response);

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

  /// Helper to store auth data including role
  Future<void> _storeAuthData(Map<String, dynamic> response) async {
    if (response['access'] != null) {
      await _storage.write(key: 'access_token', value: response['access']);
    }

    if (response['refresh'] != null) {
      await _storage.write(key: 'refresh_token', value: response['refresh']);
    }

    if (response['profile_data'] != null && response['profile_data']['user'] != null) {
      await _storage.write(key: 'user_id', value: response['profile_data']['user'].toString());

      // Store the user role - this is the key addition
      if (response['profile_data']['role'] != null) {
        await _storage.write(key: 'user_role', value: response['profile_data']['role']);
        _logger.d('AuthService: Stored user role: ${response['profile_data']['role']}');
      }
    }
  }

  /// Google Sign-In
  Future<Map<String, dynamic>> googleSignIn({required bool isTherapist}) async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
        clientId: '1048463216573-xyz123.apps.googleusercontent.com',
        serverClientId: '1048463216573-68qmf5ml28m1f8uol09cstfno4jb33gk.apps.googleusercontent.com',
      );

      // Sign out to ensure fresh login
      await googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      _logger.d('AuthService: Cleared previous Google sessions');

      // Sign in with Google
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        _logger.w('AuthService: Google Sign-In canceled by user');
        throw Exception('Google Sign-In canceled');
      }

      // Get authentication details
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      if (googleAuth.idToken == null) {
        throw Exception('Google Sign-In: No ID token received');
      }

      // Create Firebase credential
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase
      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null || firebaseUser.email == null) {
        throw Exception('Google Sign-In: Failed to retrieve user data');
      }

      _logger.d('AuthService: Google Firebase user: ${firebaseUser.email}');

      // Call social login
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

  /// Facebook Sign-In
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

  /// Sign up with email, password, and role
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
      _logger.d('AuthService: Sign up successful for $email');

      // Store tokens and user role
      await _storeAuthData(response);

      return response;
    } catch (e) {
      _logger.e('AuthService: Sign up failed: $e');
      rethrow;
    }
  }

  /// Generate a random nonce for Apple Sign-In
  String _generateNonce([int length = 32]) {
    const charset = '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random();
    return List.generate(length, (_) => charset[random.nextInt(charset.length)]).join();
  }

  /// Check if session is valid
  Future<bool> isSessionValid() async {
    final accessToken = await _storage.read(key: 'access_token');
    if (accessToken == null) {
      _logger.d('AuthService: No access token found');
      return false;
    }
    _logger.d('AuthService: Session valid with access token');
    return true;
  }

  /// Get stored user role
  Future<String> getUserRole() async {
    final role = await _storage.read(key: 'user_role');
    _logger.d('AuthService: Retrieved user role: $role');
    return role ?? 'client'; // Default to client if role not found
  }

  /// Logout
  Future<void> logout() async {
    try {
      await _storage.delete(key: 'access_token');
      await _storage.delete(key: 'refresh_token');
      await _storage.delete(key: 'user_id');
      await _storage.delete(key: 'user_role'); // Also clear role
      await FirebaseAuth.instance.signOut();
      await GoogleSignIn().signOut();
      await FacebookAuth.instance.logOut();
      _logger.d('AuthService: Logout successful');
    } catch (e) {
      _logger.e('AuthService: Logout failed: $e');
      rethrow;
    }
  }

  /// Get stored user ID
  Future<String?> getUserId() async {
    return await _storage.read(key: 'user_id');
  }

  /// Get user profile
  Future<Map<String, dynamic>> getUserProfile() async {
    try {
      final response = await _apiService.getClientProfile();

      // Manually add role from storage if it exists but not in the response
      if (!response.containsKey('role')) {
        final storedRole = await getUserRole();
        response['role'] = storedRole;
      }

      _logger.d('AuthService: Fetched user profile with role: ${response['role']}');
      return response;
    } catch (e) {
      _logger.e('AuthService: Failed to fetch user profile: $e');

      // If API fails, try to return at least the stored role
      try {
        final role = await getUserRole();
        _logger.d('AuthService: Returning fallback role from storage: $role');
        return {'role': role};
      } catch (innerException) {
        _logger.e('AuthService: Failed to get role from storage: $innerException');
        rethrow;
      }
    }
  }
}