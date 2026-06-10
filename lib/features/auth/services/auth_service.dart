import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../core/network/insforge_client.dart';
import '../../../core/models/user_profile.dart';
import '../../../core/models/technician_profile.dart';

class AuthService {
  final InsForgeClient _client = InsForgeClient();
  final _storage = const FlutterSecureStorage();

  /// Logs in a user with email and password
  /// Returns the userId on success, or null on failure.
  Future<String?> login(String email, String password) async {
    try {
      final response = await _client.post(
        '/api/auth/sessions?client_type=mobile',
        body: {
          'email': email,
          'password': password,
        },
        requireAuth: false, // Use anon key
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];
        final userId = data['user']['id'];

        await _client.saveTokens(accessToken, refreshToken);
        return userId;
      } else {
        debugPrint('Login Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during login: $e');
      return null;
    }
  }

  /// Registers a new user. Assigns role "usuario" natively in DB via trigger or manual insert if needed.
  /// The InsForge API assigns default role 'client', we can pass name if supported.
  Future<bool> register(String email, String password, {String name = 'Usuario'}) async {
    try {
      final response = await _client.post(
        '/api/auth/users?client_type=mobile',
        body: {
          'email': email,
          'password': password,
          'name': name,
        },
        requireAuth: false, // Use anon key
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        if (accessToken != null) {
          await _client.saveTokens(accessToken, refreshToken);
        }
        return true;
      } else {
        debugPrint('Register Error: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception during register: $e');
      return false;
    }
  }

  /// Verifies the user's email with the OTP code sent
  /// Returns the userId on success, or null on failure.
  Future<String?> verifyEmail(String email, String otp) async {
    try {
      final response = await _client.post(
        '/api/auth/email/verify?client_type=mobile',
        body: {
          'email': email,
          'otp': otp,
        },
        requireAuth: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        if (accessToken != null) {
          await _client.saveTokens(accessToken, refreshToken);
        }
        return data['user']['id'];
      } else {
        debugPrint('Verify Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during email verification: $e');
      return null;
    }
  }

  /// Resends the OTP verification code
  Future<bool> resendOtp(String email) async {
    try {
      final response = await _client.post(
        '/api/auth/email/send-verification',
        body: {'email': email},
        requireAuth: false,
      );
      return response.statusCode >= 200 && response.statusCode < 300;
    } catch (e) {
      debugPrint('Exception during resend OTP: $e');
      return false;
    }
  }

  /// Initiates Google OAuth flow
  Future<void> loginWithGoogle() async {
    // 1. Generate PKCE code verifier and challenge
    final random = Random.secure();
    final values = List<int>.generate(32, (i) => random.nextInt(256));
    final codeVerifier = base64UrlEncode(values).replaceAll('=', '');

    final bytes = utf8.encode(codeVerifier);
    final digest = sha256.convert(bytes);
    final codeChallenge = base64UrlEncode(digest.bytes).replaceAll('=', '');

    // Store codeVerifier in secure storage so we can use it in the callback
    await _storage.write(key: 'google_oauth_code_verifier', value: codeVerifier);

    final redirectUri = 'tokeplus://callback'; // You will need to configure Deep Links in your app
    final apiUrl = '/api/auth/oauth/google?redirect_uri=$redirectUri&code_challenge=$codeChallenge';

    try {
      final response = await _client.get(apiUrl, requireAuth: false);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final authUrl = data['authUrl'];

        final url = Uri.parse(authUrl);
        if (await canLaunchUrl(url)) {
          await launchUrl(url, mode: LaunchMode.externalApplication);
        } else {
          debugPrint('Could not launch $url');
        }
      } else {
        debugPrint('Error getting Google auth URL: ${response.body}');
      }
    } catch (e) {
      debugPrint('Exception during Google Auth: $e');
    }
  }

  /// Exchanges the OAuth authorization code for tokens
  /// Returns the complete response body on success, or null on failure.
  Future<Map<String, dynamic>?> exchangeOAuthCode(String code) async {
    try {
      final codeVerifier = await _storage.read(key: 'google_oauth_code_verifier');
      if (codeVerifier == null) {
        debugPrint('OAuth Exchange Error: No code verifier found in secure storage.');
        return null;
      }

      final response = await _client.post(
        '/api/auth/oauth/exchange?client_type=mobile',
        body: {
          'code': code,
          'code_verifier': codeVerifier,
        },
        requireAuth: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final accessToken = data['accessToken'];
        final refreshToken = data['refreshToken'];

        await _client.saveTokens(accessToken, refreshToken);
        // Clean up
        await _storage.delete(key: 'google_oauth_code_verifier');
        return data;
      } else {
        debugPrint('OAuth Exchange Error: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Exception during OAuth Exchange: $e');
      return null;
    }
  }

  /// Logs out the user
  Future<void> logout() async {
    try {
      await _client.post('/api/auth/logout');
    } catch (e) {
      debugPrint('Logout API call failed: $e');
    } finally {
      // Always clear local tokens
      await _client.clearTokens();
    }
  }

  /// Fetches the client profile associated with the userId
  Future<UserProfile?> fetchUserProfile(String userId) async {
    try {
      final response = await _client.get('/api/database/records/profiles?id=eq.$userId');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          return UserProfile.fromJson(list.first as Map<String, dynamic>);
        }
      } else {
        debugPrint('Fetch profile error: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('Exception fetching user profile: $e');
      return null;
    }
  }

  /// Fetches the technician profile associated with the userId
  Future<TechnicianProfile?> fetchTechnicianProfile(String userId) async {
    try {
      final response = await _client.get('/api/database/records/technician_profiles?id=eq.$userId');
      if (response.statusCode == 200) {
        final List<dynamic> list = jsonDecode(response.body);
        if (list.isNotEmpty) {
          return TechnicianProfile.fromJson(list.first as Map<String, dynamic>);
        }
      } else {
        debugPrint('Fetch tech profile error: ${response.body}');
      }
      return null;
    } catch (e) {
      debugPrint('Exception fetching technician profile: $e');
      return null;
    }
  }

  /// Registers a user as a technician, inserts technician_profiles and intermediate categories, and updates profile role.
  Future<bool> createTechnicianProfile(
    String userId, {
    required String dni,
    required int districtId,
    required String bio,
    required List<int> categoryIds,
  }) async {
    try {
      // 1. Insert technician profile
      final techResponse = await _client.post(
        '/api/database/records/technician_profiles',
        body: [
          {
            'id': userId,
            'dni': dni,
            'district_id': districtId,
            'bio': bio,
            'verification_status': 'pending',
          }
        ],
      );

      if (techResponse.statusCode < 200 || techResponse.statusCode >= 300) {
        debugPrint('Error creating tech profile: ${techResponse.body}');
        return false;
      }

      // 2. Update role to 'technician' in profiles table
      final roleResponse = await _client.patch(
        '/api/database/records/profiles?id=eq.$userId',
        body: {'role': 'technician'},
      );

      if (roleResponse.statusCode < 200 || roleResponse.statusCode >= 300) {
        debugPrint('Error updating user role: ${roleResponse.body}');
      }

      // 3. Insert categories in technician_categories
      for (final catId in categoryIds) {
        await _client.post(
          '/api/database/records/technician_categories',
          body: [
            {
              'technician_id': userId,
              'category_id': catId,
            }
          ],
        );
      }

      return true;
    } catch (e) {
      debugPrint('Exception in createTechnicianProfile: $e');
      return false;
    }
  }

  /// Verifies current session. Returns userId if valid, otherwise tries to refresh and returns userId, or null if invalid.
  Future<String?> checkCurrentSession() async {
    try {
      final token = await _client.getAccessToken();
      if (token == null) return null;

      final response = await _client.get('/api/auth/sessions/current');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['user']['id'] as String?;
      }

      // If token is expired or unauthorized, try to refresh
      final refreshSuccess = await refreshSession();
      if (refreshSuccess) {
        final retryResponse = await _client.get('/api/auth/sessions/current');
        if (retryResponse.statusCode == 200) {
          final data = jsonDecode(retryResponse.body);
          return data['user']['id'] as String?;
        }
      }
    } catch (e) {
      debugPrint('Exception checking current session: $e');
    }
    return null;
  }

  /// Refreshes session using stored refresh token. Returns true on success.
  Future<bool> refreshSession() async {
    try {
      final refreshToken = await _client.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _client.post(
        '/api/auth/refresh?client_type=mobile',
        body: {'refreshToken': refreshToken},
        requireAuth: false,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final nextAccessToken = data['accessToken'];
        final nextRefreshToken = data['refreshToken'];
        await _client.saveTokens(nextAccessToken, nextRefreshToken);
        return true;
      }
    } catch (e) {
      debugPrint('Exception refreshing session: $e');
    }
    return false;
  }

  /// Creates the initial profile row in the public 'profiles' table after verification.
  Future<bool> createInitialProfile(String userId, String email, String fullName, {String? avatarUrl}) async {
    final nameParts = fullName.trim().split(' ');
    final firstName = nameParts.isNotEmpty ? nameParts.first : fullName;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
    
    try {
      final response = await _client.post(
        '/api/database/records/profiles',
        body: [
          {
            'id': userId,
            'email': email,
            'first_name': firstName,
            'last_name': lastName,
            'role': 'client',
            'is_active': true,
            'avatar_url': avatarUrl,
          }
        ],
        requireAuth: true,
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return true;
      } else {
        debugPrint('Create initial profile failed: StatusCode=${response.statusCode}, Body=${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Exception creating initial profile: $e');
      return false;
    }
  }
}

