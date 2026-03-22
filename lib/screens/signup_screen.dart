import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_screen.dart';
import 'personal_details.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _isFormValid = false;
  String? _authError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');

  @override
  void initState() {
    super.initState();
    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
    _confirmPasswordController.addListener(_validateForm);
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) return 'Enter valid email (example@gmail.com)';
    if (!emailRegex.hasMatch(value)) return 'Enter valid email (example@gmail.com)';
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password must be strong (Aa1@...)';
    final hasUpper = value.contains(RegExp(r'[A-Z]'));
    final hasLower = value.contains(RegExp(r'[a-z]'));
    final hasDigits = value.contains(RegExp(r'[0-9]'));
    final hasSpecial = value.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (value.length < 8 || !hasUpper || !hasLower || !hasDigits || !hasSpecial) {
      return 'Password must be strong (Aa1@...)';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  void _validateForm() {
    setState(() {
      _isFormValid = _validateEmail(_emailController.text) == null &&
                     _validatePassword(_passwordController.text) == null &&
                     _validateConfirm(_confirmPasswordController.text) == null;
    });
  }

  Future<void> _handleSignup() async {
    final email = _emailController.text.trim().toLowerCase();
    final password = _passwordController.text.trim();

    setState(() => _isLoading = true);
    try {
      final authResponse = await _authService.signUp(email, password);
      
      final user = authResponse.user;
      if (user != null) {
        // PREVENT DUPLICATE CREATION: Create the singular initial profile row here!
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'email': email,
          'has_completed_profile': false,
        });
      }

      if (!mounted) return;
      // Auto login after signup is handled by Supabase, it automatically sets the session
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => PersonalDetails(email: email)),
        (route) => false,
      );
    } on AuthException catch (e) {
      setState(() {
        _authError = e.message;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        if (e.toString().contains('SocketException') || e.toString().contains('ClientException') || e.toString().contains('Failed host lookup')) {
          _authError = "Network error. Please try again.";
        } else {
          _authError = "An unexpected error occurred";
        }
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.purpleLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.person_add_alt_1_rounded,
                    size: 36,
                    color: AppTheme.primary,
                  ),
                ),
                const SizedBox(height: 32),
                
                const Text(
                  'Create Account',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.textMain,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Sign up to get started',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 48),
                
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email',
                        hint: 'Enter your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        validator: (val) {
                          if (val == null || val.isEmpty) return null; // Wait until they type
                          return _validateEmail(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _passwordController,
                        label: 'Password',
                        hint: 'Create a password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        isPassword: true,
                        onVisibilityToggle: () {
                          setState(() => _obscurePassword = !_obscurePassword);
                        },
                        validator: (val) {
                          if (val == null || val.isEmpty) return null;
                          return _validatePassword(val);
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: 'Confirm Password',
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outline_rounded,
                        obscureText: _obscureConfirmPassword,
                        isPassword: true,
                        onVisibilityToggle: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                        errorText: _authError,
                        validator: (val) {
                          if (val == null || val.isEmpty) return null;
                          return _validateConfirm(val);
                        },
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 40),
                
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: AppTheme.primary.withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: (_isFormValid && !_isLoading) ? _handleSignup : null,
                  child: _isLoading 
                    ? const SizedBox(
                        width: 24, height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      )
                    : const Text(
                    'Sign Up',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(color: AppTheme.textSecondary),
                    ),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(builder: (_) => const LoginScreen()),
                        );
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: AppTheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onVisibilityToggle,
    TextInputType keyboardType = TextInputType.text,
    String? errorText,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          validator: validator,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          style: const TextStyle(fontSize: 15, color: AppTheme.textMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            errorText: errorText,
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: AppTheme.textSecondary,
                      size: 20,
                    ),
                    onPressed: onVisibilityToggle,
                  )
                : null,
            filled: true,
            fillColor: const Color(0xFFF9FAFB),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide.none,
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: AppTheme.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: Colors.red, width: 1.5),
            ),
            errorStyle: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
