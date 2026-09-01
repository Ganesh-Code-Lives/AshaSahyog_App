import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final supabase = Supabase.instance.client;

  // Singleton pattern
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  Future<AuthResponse> signUp(String email, String password) async {
    try {
      final response = await supabase.auth.signUp(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint("Supabase AuthException: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("General Sign Up Exception: $e");
      rethrow;
    }
  }

  Future<AuthResponse> signInWithPassword(String email, String password) async {
    try {
      final response = await supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      debugPrint("Supabase AuthException: ${e.message}");
      rethrow;
    } catch (e) {
      debugPrint("General Login Exception: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      debugPrint("General Logout Exception: $e");
      rethrow;
    }
  }

  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }
}
