import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../theme/app_theme.dart';
import 'splash_screen.dart';

class DisabilityDetails extends StatefulWidget {
  const DisabilityDetails({super.key});

  @override
  State<DisabilityDetails> createState() => _DisabilityDetailsState();
}

class _DisabilityDetailsState extends State<DisabilityDetails> {
  bool _hasDisability = false;
  String _disabilityType = '';
  final _percentageController = TextEditingController();
  final _certificateController = TextEditingController();
  final List<String> _selectedDevices = [];
  bool _isLoading = false;

  final List<String> _availableDevices = [
    "Wheelchair",
    "Hearing Aid",
    "Cane",
    "Prosthetics",
    "Screen Reader",
    "Other",
  ];

  void _toggleDevice(String device) {
    setState(() {
      if (_selectedDevices.contains(device)) {
        _selectedDevices.remove(device);
      } else {
        _selectedDevices.add(device);
      }
    });
  }

  void _handleContinue() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        await Supabase.instance.client.from('profiles').upsert({
          'id': user.id,
          'has_disability': _hasDisability,
          'disability_type': _hasDisability ? _disabilityType : null,
          'disability_percentage': _hasDisability ? _percentageController.text.trim() : null,
          'certificate_number': _hasDisability ? _certificateController.text.trim() : null,
          'assistive_devices': _hasDisability ? _selectedDevices : [],
          'has_completed_profile': true,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        });
      } catch (e) {
        if (!mounted) return;
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error saving details: $e"),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }
    
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const SplashScreen()),
      (route) => false,
    );
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Indicator (Step 4/4)
                    Row(
                      children: [
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3)))),
                      ],
                    ),
                    const SizedBox(height: 40),

                    const Text(
                      'Disability Information', 
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w800, 
                        color: AppTheme.textMain
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Optional details to help us personalize services', 
                      style: TextStyle(
                        fontSize: 16, 
                        color: AppTheme.textSecondary
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Toggle Switch Card
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: const Color(0xFFE5E7EB), width: 1.5),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppTheme.purpleLight.withOpacity(0.5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.accessible_rounded, color: AppTheme.primary, size: 20),
                              ),
                              const SizedBox(width: 14),
                              const Text(
                                'I have a disability', 
                                style: TextStyle(
                                  fontSize: 16, 
                                  fontWeight: FontWeight.w600, 
                                  color: AppTheme.textMain
                                ),
                              ),
                            ],
                          ),
                          Switch(
                            value: _hasDisability,
                            onChanged: (val) => setState(() => _hasDisability = val),
                            activeTrackColor: AppTheme.primary.withOpacity(0.8),
                            activeColor: Colors.white,
                            inactiveTrackColor: const Color(0xFFE5E7EB),
                            inactiveThumbColor: Colors.white,
                          ),
                        ],
                      ),
                    ),

                    if (_hasDisability) ...[
                      const SizedBox(height: 32),
                      
                      // Disability Type Dropdown
                      _buildDropdownField(),
                      const SizedBox(height: 20),

                      // Percentage
                      _buildTextField(
                        controller: _percentageController,
                        label: 'Disability Percentage',
                        hint: 'e.g. 40',
                        icon: Icons.percent_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 20),
                      
                      // Certificate
                      _buildTextField(
                        controller: _certificateController,
                        label: 'Certificate Number',
                        hint: 'Enter your UDID or certificate number',
                        icon: Icons.assignment_outlined,
                      ),
                      const SizedBox(height: 28),

                      // Assistive Devices
                      const Text(
                        'Assistive Devices Used',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textMain,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: _availableDevices.map((device) {
                          final isSelected = _selectedDevices.contains(device);
                          return InkWell(
                            onTap: () => _toggleDevice(device),
                            borderRadius: BorderRadius.circular(20),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? AppTheme.primary : Colors.white,
                                border: Border.all(
                                  color: isSelected ? AppTheme.primary : const Color(0xFFE5E7EB),
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: isSelected
                                    ? [
                                        BoxShadow(
                                          color: AppTheme.primary.withOpacity(0.2),
                                          blurRadius: 8,
                                          offset: const Offset(0, 3),
                                        )
                                      ]
                                    : null,
                              ),
                              child: Text(
                                device,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : AppTheme.textSecondary,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                    
                    const SizedBox(height: 48),

                    // Privacy Notice
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.purpleLight.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.purpleLight, width: 1.5),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.shield_outlined, size: 22, color: AppTheme.primary),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Your Privacy Matters',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 14, 
                                    color: AppTheme.primary
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'This information is kept confidential and is used strictly to suggest relevant schemes and tailor app features to your needs.',
                                  style: TextStyle(
                                    fontSize: 13, 
                                    color: AppTheme.primary.withOpacity(0.8), 
                                    height: 1.4
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
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
                onPressed: _isLoading ? null : _handleContinue,
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
                        'Complete Setup', 
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
          style: const TextStyle(fontSize: 15, color: AppTheme.textMain),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            prefixIcon: Icon(icon, color: AppTheme.textSecondary, size: 22),
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
          'Type of Disability',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textMain,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _disabilityType.isEmpty ? null : _disabilityType,
          icon: const Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.textSecondary),
          dropdownColor: Colors.white,
          isExpanded: true,
          style: const TextStyle(fontSize: 15, color: AppTheme.textMain),
          items: const [
            DropdownMenuItem(value: 'visual', child: Text('Visual Impairment')),
            DropdownMenuItem(value: 'hearing', child: Text('Hearing Impairment')),
            DropdownMenuItem(value: 'mobility', child: Text('Mobility Impairment')),
            DropdownMenuItem(value: 'cognitive', child: Text('Cognitive Impairment')),
            DropdownMenuItem(value: 'speech', child: Text('Speech Impairment')),
            DropdownMenuItem(value: 'multiple', child: Text('Multiple Disabilities')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
          ],
          onChanged: (value) {
            setState(() {
              _disabilityType = value ?? '';
            });
          },
          decoration: InputDecoration(
            hintText: 'Select disability type',
            hintStyle: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
            prefixIcon: const Icon(Icons.category_outlined, color: AppTheme.textSecondary, size: 22),
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
