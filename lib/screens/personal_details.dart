import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'disability_details.dart';

class PersonalDetails extends StatefulWidget {
  final String? email;

  const PersonalDetails({super.key, this.email});

  @override
  State<PersonalDetails> createState() => _PersonalDetailsState();
}

class _PersonalDetailsState extends State<PersonalDetails> {
  final _formKey = GlobalKey<FormState>();
  
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _dateOfBirthController = TextEditingController();
  String _gender = '';
  final _addressController = TextEditingController();
  bool _isLoading = false;
  
  void _updateState() {
     setState(() {});
  }

  @override
  void initState() {
    super.initState();
    if (widget.email != null) {
      _emailController.text = widget.email!;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppTheme.primary,
              onPrimary: Colors.white,
              onSurface: AppTheme.textMain,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  bool get _isValid =>
      _fullNameController.text.trim().isNotEmpty &&
      _emailController.text.trim().isNotEmpty &&
      _dateOfBirthController.text.isNotEmpty &&
      _gender.isNotEmpty;

  void _handleContinue() async {
    if (_isValid) {
      setState(() => _isLoading = true);
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          await Supabase.instance.client.from('profiles').upsert({
            'id': user.id,
            'full_name': _fullNameController.text.trim(),
            'dob': _dateOfBirthController.text,
            'gender': _gender,
            'address': _addressController.text.trim(),
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          });
        } catch (e) {
          if (!mounted) return;
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Error saving profile: $e"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() => _isLoading = false);
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DisabilityDetails()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Form(
                  key: _formKey,
                  onChanged: _updateState,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Progress Indicator (Step 3/4 theoretically)
                      Row(
                        children: [
                          Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3)))),
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3)))),
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3)))),
                          const SizedBox(width: 8),
                          Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.purpleLight, borderRadius: BorderRadius.circular(3)))),
                        ],
                      ),
                      const SizedBox(height: 40),
                      
                      const Text(
                        'Personal Details', 
                        style: TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.w800, 
                          color: AppTheme.textMain
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Please provide your personal information', 
                        style: TextStyle(
                          fontSize: 16, 
                          color: AppTheme.textSecondary
                        ),
                      ),
                      const SizedBox(height: 40),
                      
                      // Full Name
                      _buildTextField(
                        controller: _fullNameController,
                        label: 'Full Name *',
                        hint: 'Enter your full name',
                        icon: Icons.person_outline_rounded,
                      ),
                      const SizedBox(height: 20),
                      
                      // Email
                      _buildTextField(
                        controller: _emailController,
                        label: 'Email *',
                        hint: 'Enter your email address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 20),
                      
                      // Date of Birth
                      GestureDetector(
                        onTap: () => _selectDate(context),
                        child: AbsorbPointer(
                          child: _buildTextField(
                            controller: _dateOfBirthController,
                            label: 'Date of Birth *',
                            hint: 'YYYY-MM-DD',
                            icon: Icons.calendar_today_rounded,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Gender
                      _buildDropdownField(),
                      const SizedBox(height: 20),
                      
                      // Address
                      _buildTextField(
                        controller: _addressController,
                        label: 'Address (Optional)',
                        hint: 'Enter your full address',
                        icon: Icons.location_on_outlined,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
            
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Color(0xFFE5E7EB), width: 1)),
              ),
              child: ElevatedButton(
                onPressed: _isValid && !_isLoading ? _handleContinue : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 24, 
                        height: 24, 
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5)
                      )
                    : const Text(
                        'Continue', 
                        style: TextStyle(
                          fontSize: 16, 
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
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
          keyboardType: keyboardType,
          maxLines: maxLines,
          style: const TextStyle(fontSize: 15, color: AppTheme.textMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            prefixIcon: maxLines > 1 
                ? Padding(
                    padding: const EdgeInsets.only(bottom: 50.0), // align top for multi-line
                    child: Icon(icon, color: AppTheme.textSecondary, size: 22),
                  )
                : Icon(icon, color: AppTheme.textSecondary, size: 22),
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
          ),
        ),
      ],
    );
  }

  Widget _buildDropdownField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender *',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _gender.isEmpty ? null : _gender,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
          dropdownColor: Colors.white,
          isExpanded: true,
          style: const TextStyle(fontSize: 15, color: AppTheme.textMain),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
            DropdownMenuItem(value: 'prefer-not-to-say', child: Text('Prefer not to say')),
          ],
          onChanged: (value) {
            setState(() {
              _gender = value ?? '';
            });
          },
          decoration: InputDecoration(
            hintText: 'Select gender',
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.people_alt_outlined, color: AppTheme.textSecondary, size: 22),
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
          ),
        ),
      ],
    );
  }
}
