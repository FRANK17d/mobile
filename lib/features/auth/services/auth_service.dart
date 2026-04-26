import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/network/insforge_client.dart';

class AuthService {
  final InsForgeClient _client = InsForgeClient();

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
        print('Login Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during login: $e');
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
        print('Register Error: ${response.body}');
        return false;
      }
    } catch (e) {
      print('Exception during register: $e');
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
        print('Verify Error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception during email verification: $e');
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
      print('Exception during resend OTP: $e');
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

    // Note: Store codeVerifier in secure storage so we can use it in the callback
    // (Omitted here for simplicity, but necessary for a full flow)

    final redirectUri = 'myapp://callback'; // You will need to configure Deep Links in your app
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
          print('Could not launch $url');
        }
      } else {
        print('Error getting Google auth URL: ${response.body}');
      }
    } catch (e) {
      print('Exception during Google Auth: $e');
    }
  }

  /// Logs out the user
  Future<void> logout() async {
    try {
      await _client.post('/api/auth/logout');
    } catch (e) {
      print('Logout API call failed: $e');
    } finally {
      // Always clear local tokens
      await _client.clearTokens();
    }
  }
}
