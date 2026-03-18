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
      print("Supabase AuthException: ${e.message}");
      rethrow;
    } catch (e) {
      print("General Sign Up Exception: $e");
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
      print("Supabase AuthException: ${e.message}");
      rethrow;
    } catch (e) {
      print("General Login Exception: $e");
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await supabase.auth.signOut();
    } catch (e) {
      print("General Logout Exception: $e");
      rethrow;
    }
  }

  User? getCurrentUser() {
    return supabase.auth.currentUser;
  }
}
