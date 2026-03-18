import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
  
  // To update UI on change to enable/disable button
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
    );
    if (picked != null) {
      setState(() {
        _dateOfBirthController.text = "${picked.toLocal()}".split(' ')[0];
      });
    }
  }

  bool get _isValid =>
      _fullNameController.text.isNotEmpty &&
      _emailController.text.isNotEmpty &&
      _dateOfBirthController.text.isNotEmpty &&
      _gender.isNotEmpty;

  void _handleContinue() async {
    if (_isValid) {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        try {
          // Update core profile info - explicitly preventing arbitrary inserts
          await Supabase.instance.client.from('profiles').update({
            'full_name': _fullNameController.text,
            'dob': _dateOfBirthController.text,
            'gender': _gender,
            'address': _addressController.text,
            'updated_at': DateTime.now().toUtc().toIso8601String(),
          }).eq('id', user.id);
        } catch (e) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error saving profile: $e")),
          );
          return;
        }
      }

      if (!mounted) return;
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
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Form(
              key: _formKey,
              onChanged: _updateState,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Progress
                  Row(
                    children: [
                      Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)))),
                      const SizedBox(width: 8),
                      Expanded(child: Container(height: 4, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(2)))),
                    ],
                  ),
                  const SizedBox(height: 32),
                  
                  const Text('Personal Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppTheme.textMain)),
                  const SizedBox(height: 8),
                  const Text('Please provide your personal information', style: TextStyle(color: AppTheme.textSecondary, fontSize: 16)),
                  const SizedBox(height: 32),
                  
                  // Full Name
                  const Text('Full Name *', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _fullNameController,
                    decoration: const InputDecoration(hintText: 'Enter your full name'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Email
                  const Text('Email *', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(hintText: 'Enter your email'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 16),
                  
                  // Date of Birth
                  const Text('Date of Birth *', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _dateOfBirthController,
                    readOnly: true,
                    onTap: () => _selectDate(context),
                    decoration: const InputDecoration(
                      hintText: 'YYYY-MM-DD', // Typically localized
                      suffixIcon: Icon(Icons.calendar_today, size: 20),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Gender using Dropdown
                  const Text('Gender *', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    initialValue: _gender.isEmpty ? null : _gender,
                    items: const [
                      DropdownMenuItem(value: 'male', child: Text('Male')),
                      DropdownMenuItem(value: 'female', child: Text('Female')),
                      DropdownMenuItem(value: 'other', child: Text('Other')),
                      DropdownMenuItem(value: 'prefer-not-to-say', child: Text('Prefer not to say')),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _gender = value!;
                      });
                    },
                    decoration: const InputDecoration(
                      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    hint: const Text('Select gender'),
                  ),
                  const SizedBox(height: 16),
                  
                  // Address
                  const Text('Address (Optional)', style: TextStyle(color: AppTheme.textSecondary, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 3,
                    decoration: const InputDecoration(hintText: 'Enter your address'),
                  ),
                  const SizedBox(height: 100), // Spacing for bottom button
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: Padding(
        padding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: _isValid ? AppTheme.primaryGradient : null,
            color: _isValid ? null : AppTheme.primary.withOpacity(0.1),
          ),
          child: ElevatedButton(
            onPressed: _isValid ? _handleContinue : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: _isValid ? Colors.white : AppTheme.primary.withOpacity(0.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text('Continue', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ),
      ),
    );
  }
}
