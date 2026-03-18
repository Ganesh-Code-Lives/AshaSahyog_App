import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../models/user_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Profile extends StatefulWidget {
  final VoidCallback onBack;
  final VoidCallback onLogout;
  final PersonalDetailsData? personalData;
  final DisabilityDetailsData? disabilityData;
  final String? mobile;
  final VoidCallback? onProfileUpdated;

  const Profile({
    super.key,
    required this.onBack,
    required this.onLogout,
    this.personalData,
    this.disabilityData,
    this.mobile,
    this.onProfileUpdated,
  });

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _headerSlide;
  late Animation<double> _bodyFade;
  String? _profileImageBase64;
  bool _isAvatarPressed = false;

  bool _isEditingPersonal = false;
  bool _isSavingPersonal = false;
  final _personalFormKey = GlobalKey<FormState>();

  late TextEditingController _nameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _dobCtrl;
  late TextEditingController _addressCtrl;
  String _gender = 'Male';

  bool _isEditingDisability = false;
  bool _isSavingDisability = false;
  final _disabilityFormKey = GlobalKey<FormState>();

  late TextEditingController _disTypeCtrl;
  late TextEditingController _disPercentCtrl;
  late TextEditingController _certCtrl;
  List<String> _selectedDevices = [];

  final List<String> _commonDevices = [
    'Wheelchair', 'Crutches', 'Hearing Aid', 'Prosthetic Limb', 'White Cane', 'Walking Stick'
  ];

  @override
  void initState() {
    super.initState();
    _loadProfileImage();
    _initControllers();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 700),
      vsync: this,
    );

    _headerSlide = Tween<Offset>(
      begin: const Offset(0, -1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
    ));

    _bodyFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
  }

  void _initControllers() {
    _nameCtrl = TextEditingController(text: widget.personalData?.fullName ?? '');
    _phoneCtrl = TextEditingController(text: widget.mobile ?? '');
    _dobCtrl = TextEditingController(text: widget.personalData?.dateOfBirth?.toLocal().toString().split(' ')[0] ?? '');
    _addressCtrl = TextEditingController(text: widget.personalData?.address ?? '');
    // Normalize gender: capitalize first letter so stored 'male'/'female' matches dropdown items
    const validGenders = ['Male', 'Female', 'Other'];
    String rawGender = widget.personalData?.gender ?? '';
    String normalizedGender = rawGender.isNotEmpty
        ? rawGender[0].toUpperCase() + rawGender.substring(1).toLowerCase()
        : 'Male';
    _gender = validGenders.contains(normalizedGender) ? normalizedGender : 'Male';

    _disTypeCtrl = TextEditingController(text: widget.disabilityData?.disabilityType ?? '');
    _disPercentCtrl = TextEditingController(text: widget.disabilityData?.percentage?.replaceAll('%', '') ?? '');
    _certCtrl = TextEditingController(text: widget.disabilityData?.certificateNumber ?? '');
    _selectedDevices = List<String>.from(widget.disabilityData?.assistiveDevices ?? []);
  }

  @override
  void dispose() {
    _controller.dispose();
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _addressCtrl.dispose();
    _disTypeCtrl.dispose();
    _disPercentCtrl.dispose();
    _certCtrl.dispose();
    super.dispose();
  }

  Future<void> _savePersonalDetails() async {
    if (!_personalFormKey.currentState!.validate()) return;
    setState(() => _isSavingPersonal = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').update({
          'full_name': _nameCtrl.text.trim(),
          'phone': _phoneCtrl.text.trim(),
          'dob': _dobCtrl.text.trim(),
          'gender': _gender,
          'address': _addressCtrl.text.trim(),
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', user.id);
        
        setState(() => _isEditingPersonal = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
        widget.onProfileUpdated?.call();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update. Try again.")));
    } finally {
      if (mounted) setState(() => _isSavingPersonal = false);
    }
  }

  Future<void> _saveDisabilityDetails() async {
    if (!_disabilityFormKey.currentState!.validate()) return;
    setState(() => _isSavingDisability = true);
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        await Supabase.instance.client.from('profiles').update({
          'has_disability': true,
          'disability_type': _disTypeCtrl.text.trim(),
          'disability_percentage': _disPercentCtrl.text.trim(),
          'certificate_number': _certCtrl.text.trim(),
          'assistive_devices': _selectedDevices,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        }).eq('id', user.id);
        
        setState(() => _isEditingDisability = false);
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Profile updated successfully")));
        widget.onProfileUpdated?.call();
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Failed to update. Try again.")));
    } finally {
      if (mounted) setState(() => _isSavingDisability = false);
    }
  }

  Future<void> _loadProfileImage() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImageBase64 = prefs.getString('profileImageBase64');
    });
  }

  Future<void> _handleImageChange() async {
    if (_profileImageBase64 != null) {
      final shouldChange = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Change Photo'),
          content: const Text('Do you want to change your profile photo?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Change'),
            ),
          ],
        ),
      );
      if (shouldChange != true) return;
    }
    await _pickImage();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    try {
      final pickedFile = await picker.pickImage(source: ImageSource.gallery);

      if (pickedFile != null) {
        final bytes = await pickedFile.readAsBytes();
        final base64String = base64Encode(bytes);

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('profileImageBase64', base64String);
        if (mounted) {
          setState(() {
            _profileImageBase64 = base64String;
          });
        }
      }
    } catch (e) {
      debugPrint("Image picking failed: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- Header Section (slides down) ---
            SlideTransition(
              position: _headerSlide,
              child: Stack(
                clipBehavior: Clip.none,
                alignment: Alignment.center,
                children: [
                  // 1. Gradient Background
                  Container(
                    height: 200,
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF7C3AED), Color(0xFFA78BFA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
                    ),
                  ),
                  
                  // 2. Back Button & Title
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: widget.onBack,
                              icon: const Icon(Icons.arrow_back, color: Colors.white),
                            ),
                            const Spacer(),
                            const Text(
                              'My Profile',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            IconButton(
                              onPressed: () {},
                              icon: const Icon(Icons.settings, color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // 3. Avatar (floating halfway)
                  Positioned(
                    bottom: -50,
                    child: Column(
                      children: [
                        Material(
                          type: MaterialType.transparency,
                          child: InkWell(
                            onTap: _handleImageChange,
                            onHighlightChanged: (isHighlighted) {
                              setState(() {
                                _isAvatarPressed = isHighlighted;
                              });
                            },
                            customBorder: const CircleBorder(),
                            child: Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                border: Border.all(
                                  color: _isAvatarPressed ? AppTheme.border : Colors.white, 
                                  width: 4
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.1),
                                    blurRadius: 10,
                                    offset: const Offset(0, 5),
                                  ),
                                ],
                              ),
                              child: ClipOval(
                                child: Container(
                                  color: const Color(0xFFF3E8FF),
                                  child: _profileImageBase64 != null
                                      ? Image.memory(base64Decode(_profileImageBase64!), fit: BoxFit.cover)
                                      : const Icon(Icons.person, size: 50, color: AppTheme.primary),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // --- Body content (fades in) ---
            FadeTransition(
              opacity: _bodyFade,
              child: Column(
                children: [
                  const SizedBox(height: 60), // Space for floating avatar

                  // --- User Name & Email ---
                  Text(
                    widget.personalData?.fullName ?? 'AshaSahyog User',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF1F2937),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.personalData?.email ?? 'user@example.com',
                    style: const TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // --- Content Sections ---
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      children: [
                        // Personal Information Card
                        _SectionCard(
                          title: 'Personal Information',
                          icon: Icons.person_outline_rounded,
                          trailing: _isEditingPersonal 
                              ? null 
                              : IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.primary, size: 20),
                                  onPressed: () {
                                    _initControllers();
                                    setState(() => _isEditingPersonal = true);
                                  },
                                ),
                          children: [
                            if (!_isEditingPersonal) ...[
                              _InfoRow(label: 'Full Name', value: widget.personalData?.fullName),
                              _InfoDivider(),
                              _InfoRow(label: 'Mobile', value: widget.mobile != null ? '+91 ${widget.mobile}' : null),
                              _InfoDivider(),
                              _InfoRow(label: 'Date of Birth', value: widget.personalData?.dateOfBirth?.toLocal().toString().split(' ')[0]),
                              _InfoDivider(),
                              _InfoRow(label: 'Gender', value: widget.personalData?.gender),
                              _InfoDivider(),
                              _InfoRow(label: 'Address', value: widget.personalData?.address, isLast: true),
                            ] else 
                              Form(
                                key: _personalFormKey,
                                child: Column(
                                  children: [
                                    _buildEditableField('Full Name', _nameCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                                    const SizedBox(height: 12),
                                    _buildEditableField('Mobile', _phoneCtrl, keyboardType: TextInputType.phone, validator: (v) => v!.length < 10 ? 'Invalid' : null),
                                    const SizedBox(height: 12),
                                    _buildEditableField('Date of Birth', _dobCtrl, hint: 'YYYY-MM-DD'),
                                    const SizedBox(height: 12),
                                    DropdownButtonFormField<String>(
                                      value: _gender,
                                      decoration: InputDecoration(
                                        labelText: 'Gender',
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      items: const [
                                        DropdownMenuItem(value: 'Male', child: Text('Male')),
                                        DropdownMenuItem(value: 'Female', child: Text('Female')),
                                        DropdownMenuItem(value: 'Other', child: Text('Other')),
                                      ],
                                      onChanged: (val) => setState(() => _gender = val!),
                                    ),
                                    const SizedBox(height: 12),
                                    _buildEditableField('Address', _addressCtrl),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: _isSavingPersonal ? null : () {
                                            setState(() => _isEditingPersonal = false);
                                          },
                                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: _isSavingPersonal ? null : _savePersonalDetails,
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                          child: _isSavingPersonal ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Disability Information Card
                        _SectionCard(
                          title: 'Disability Details',
                          icon: Icons.accessible_forward_rounded,
                          trailing: _isEditingDisability 
                              ? null 
                              : IconButton(
                                  icon: const Icon(Icons.edit, color: AppTheme.primary, size: 20),
                                  onPressed: () {
                                    _initControllers();
                                    setState(() => _isEditingDisability = true);
                                  },
                                ),
                          children: [
                            if (!_isEditingDisability && widget.disabilityData?.hasDisability == true) ...[
                              _InfoRow(label: 'Type', value: widget.disabilityData?.disabilityType),
                              _InfoDivider(),
                              _InfoRow(label: 'Percentage', value: widget.disabilityData?.percentage != null ? '${widget.disabilityData!.percentage}%' : null),
                              _InfoDivider(),
                              _InfoRow(label: 'Cert. Number', value: widget.disabilityData?.certificateNumber, isLast: true),
                              if (widget.disabilityData!.assistiveDevices.isNotEmpty) ...[
                                _InfoDivider(),
                                _InfoRow(label: 'Devices', value: widget.disabilityData!.assistiveDevices.join(", "), isLast: true),
                              ],
                            ] else if (!_isEditingDisability) 
                              const Padding(
                                padding: EdgeInsets.symmetric(vertical: 8),
                                child: Text('No disability details provided.', style: TextStyle(color: Color(0xFF9CA3AF), fontStyle: FontStyle.italic)),
                              )
                            else 
                              Form(
                                key: _disabilityFormKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildEditableField('Type of Disability', _disTypeCtrl, validator: (v) => v!.isEmpty ? 'Required' : null),
                                    const SizedBox(height: 12),
                                    _buildEditableField('Percentage (%)', _disPercentCtrl, keyboardType: TextInputType.number),
                                    const SizedBox(height: 12),
                                    _buildEditableField('Certificate Number', _certCtrl),
                                    const SizedBox(height: 16),
                                    const Text('Assistive Devices', style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
                                    const SizedBox(height: 8),
                                    Wrap(
                                      spacing: 8,
                                      runSpacing: 8,
                                      children: _commonDevices.map((device) {
                                        final isSelected = _selectedDevices.contains(device);
                                        return FilterChip(
                                          label: Text(device),
                                          selected: isSelected,
                                          selectedColor: AppTheme.primary.withOpacity(0.2),
                                          checkmarkColor: AppTheme.primary,
                                          onSelected: (bool selected) {
                                            setState(() {
                                              if (selected) _selectedDevices.add(device);
                                              else _selectedDevices.remove(device);
                                            });
                                          },
                                        );
                                      }).toList(),
                                    ),
                                    const SizedBox(height: 16),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton(
                                          onPressed: _isSavingDisability ? null : () {
                                            setState(() => _isEditingDisability = false);
                                          },
                                          child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
                                        ),
                                        const SizedBox(width: 8),
                                        ElevatedButton(
                                          onPressed: _isSavingDisability ? null : _saveDisabilityDetails,
                                          style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primary, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                                          child: _isSavingDisability ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save', style: TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // Settings / Quick Links Card
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.border, width: 2),
                          ),
                          child: Column(
                            children: [
                              _SettingsTile(
                                icon: Icons.language,
                                color: const Color(0xFF0284C7), 
                                bgColor: const Color(0xFFE0F2FE), 
                                title: 'Language & Accessibility',
                              ),
                              Divider(height: 1, color: AppTheme.border, indent: 56, endIndent: 20),
                              _SettingsTile(
                                icon: Icons.lock_outline_rounded,
                                color: const Color(0xFFBE185D), 
                                bgColor: const Color(0xFFFCE7F3), 
                                title: 'Change Password',
                              ),
                              Divider(height: 1, color: AppTheme.border, indent: 56, endIndent: 20),
                              _SettingsTile(
                                icon: Icons.help_outline_rounded,
                                color: const Color(0xFF059669), 
                                bgColor: const Color(0xFFD1FAE5), 
                                title: 'Help & Support',
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Logout Button
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton.icon(
                            onPressed: widget.onLogout,
                            icon: const Icon(Icons.logout_rounded, color: Color(0xFFBE185D)),
                            label: const Text('Log Out', style: TextStyle(color: Color(0xFFBE185D), fontSize: 16, fontWeight: FontWeight.bold)),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFFECACA)),
                              backgroundColor: const Color(0xFFFEF2F2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEditableField(String label, TextEditingController controller, {TextInputType? keyboardType, String? Function(String?)? validator, String? hint}) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}

// --- Helper Widgets ---

class _SectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<Widget> children;
  final Widget? trailing;

  const _SectionCard({required this.title, required this.icon, required this.children, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(icon, size: 20, color: AppTheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF374151),
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ],
            ),
          ),
          Divider(height: 1, color: AppTheme.border),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String? value;
  final bool isLast;

  const _InfoRow({required this.label, required this.value, this.isLast = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Color(0xFF9CA3AF),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF1F2937),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 12),
      child: Divider(height: 1, color: AppTheme.border),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bgColor;
  final String title;

  const _SettingsTile({required this.icon, required this.color, required this.bgColor, required this.title});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Color(0xFF374151),
        ),
      ),
      trailing: const Icon(Icons.chevron_right_rounded, color: Color(0xFF9CA3AF), size: 20),
      onTap: () {},
    );
  }
}
