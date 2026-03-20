import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/app_theme.dart';
import '../components/bottom_nav.dart';
import 'schemes_finder.dart';
import 'hospital_locator.dart';
import 'document_vault.dart';
import 'reminders.dart';
import 'profile.dart';
import 'support.dart';
import 'emergency_sos.dart';
import '../models/user_models.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'intro_screen.dart';
import 'personal_details.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentScreen = 'home';

  String fullName = 'User';
  String phoneNumber = '';
  String email = '';
  String dateOfBirth = '';
  String gender = '';
  String address = '';
  String disabilityType = '';
  String disabilityPercentage = '';
  String certificateNumber = '';
  List<String> assistiveDevices = [];
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const IntroScreen()),
        (route) => false,
      );
      return;
    }

    try {
      final profileData = await Supabase.instance.client
          .from('profiles')
          .select()
          .eq('id', user.id)
          .maybeSingle();

      if (profileData == null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => PersonalDetails(email: user.email ?? '')),
          (route) => false,
        );
        return;
      }

      setState(() {
        fullName = profileData['full_name'] ?? 'User';
        phoneNumber = profileData['phone'] ?? '';
        email = profileData['email'] ?? '';
        dateOfBirth = profileData['dob'] ?? '';
        gender = profileData['gender'] ?? '';
        address = profileData['address'] ?? '';
        disabilityType = profileData['disability_type'] ?? '';
        disabilityPercentage = profileData['disability_percentage'] ?? '';
        certificateNumber = profileData['certificate_number'] ?? '';

        var rawDevices = profileData['assistive_devices'];
        if (rawDevices is List) {
          assistiveDevices = rawDevices.map((e) => e.toString()).toList();
        } else {
          assistiveDevices = [];
        }
      });
    } catch (e) {
      debugPrint("Failed to fetch profile: $e");
    }

    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileImageBase64 = prefs.getString('profileImageBase64');
    });
  }

  void _navigate(String screen) {
    if (screen == 'home') {
      _loadProfile();
    }
    setState(() {
      currentScreen = screen;
    });
  }

  void _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const IntroScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          margin: const EdgeInsets.symmetric(horizontal: 0),
          decoration: const BoxDecoration(
            color: AppTheme.background,
          ),
          child: Column(
            children: [
              Expanded(
                child: _buildBody(),
              ),
              BottomNav(active: currentScreen, onNavigate: _navigate),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (currentScreen == 'schemes') return SchemesFinder(onBack: () => _navigate('home'));
    if (currentScreen == 'hospitals') return HospitalLocator(onBack: () => _navigate('home'));
    if (currentScreen == 'documents') return DocumentVault(onBack: () => _navigate('home'));
    if (currentScreen == 'reminders') return Reminders(onBack: () => _navigate('home'));
    if (currentScreen == 'profile') {
      return Profile(
        onBack: () => _navigate('home'),
        onLogout: _handleLogout,
        onProfileUpdated: _loadProfile,
        personalData: PersonalDetailsData(
          fullName: fullName,
          email: email,
          dateOfBirth: dateOfBirth.length > 0 ? DateTime.tryParse(dateOfBirth) : null,
          gender: gender,
          address: address,
        ),
        disabilityData: DisabilityDetailsData(
          hasDisability: disabilityType.length > 0,
          disabilityType: disabilityType,
          percentage: disabilityPercentage.length > 0 ? disabilityPercentage : null,
          certificateNumber: certificateNumber.length > 0 ? certificateNumber : null,
          assistiveDevices: assistiveDevices,
        ),
        mobile: phoneNumber.length > 0 ? phoneNumber : '9876543210',
      );
    }
    if (currentScreen == 'support') return Support(onBack: () => _navigate('home'));
    if (currentScreen == 'sos') return EmergencySOS(onBack: () => _navigate('home'));

    // Default: Home Dashboard
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ─── WELCOME PANEL ───────────────────────────────────────────────
          Container(
            width: double.infinity,
            color: const Color(0xFF7C3AED),
            child: Stack(
              children: [
                // Decorative circle — top right
                Positioned(
                  top: -50,
                  right: -40,
                  child: Container(
                    width: 180,
                    height: 180,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x12FFFFFF),
                    ),
                  ),
                ),
                // Decorative circle — bottom left
                Positioned(
                  bottom: -25,
                  left: -20,
                  child: Container(
                    width: 100,
                    height: 100,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0x0DFFFFFF),
                    ),
                  ),
                ),
                // Content
                SafeArea(
                  bottom: false,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(22, 18, 22, 28),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Welcome Back,',
                                style: TextStyle(
                                  color: Color(0xFFC4B5FD),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                fullName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 5),
                              const Text(
                                'How can we help you today?',
                                style: TextStyle(
                                  color: Color(0xA6FFFFFF),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: () => _navigate('profile'),
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0x2EFFFFFF),
                              border: Border.all(
                                color: const Color(0x4DFFFFFF),
                                width: 1.5,
                              ),
                            ),
                            child: ClipOval(
                              child: _profileImageBase64 != null
                                  ? Image.memory(
                                      base64Decode(_profileImageBase64!),
                                      fit: BoxFit.cover,
                                      width: 48,
                                      height: 48,
                                    )
                                  : const Icon(
                                      Icons.person_rounded,
                                      color: Colors.white,
                                      size: 24,
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // ─── BODY PANEL (overlaps header) ────────────────────────────────
          Transform.translate(
            offset: const Offset(1, -10),
            child: Container(
              decoration: const BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                child: Column(
                  children: [
                    // Quick Actions Grid
                    GridView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        mainAxisExtent: 140,
                      ),
                      children: [
                        _buildQuickActionCard(
                          'Find\nSchemes',
                          Icons.description,
                          const Color(0xFFEDE9FE),
                          AppTheme.primary,
                          () => _navigate('schemes'),
                        ),
                        _buildQuickActionCard(
                          'Nearby\nHospitals',
                          Icons.location_on,
                          const Color(0xFFDCFCE7),
                          const Color(0XFF15803D),
                          () => _navigate('hospitals'),
                        ),
                        _buildQuickActionCard(
                          'My\nDocuments',
                          Icons.folder,
                          const Color(0xFFDBEAFE),
                          const Color(0xFF1D4ED8),
                          () => _navigate('documents'),
                        ),
                        _buildQuickActionCard(
                          'My\nReminders',
                          Icons.notifications,
                          const Color(0xFFFDF2FA),
                          const Color(0xFFBE185D),
                          () => _navigate('reminders'),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Today at a Glance
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Today at a Glance',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    _buildGlanceCard(
                      'Doctor\'s Appointment',
                      'Today at 2:00 PM',
                      Icons.calendar_today,
                      const Color(0xFFC4B5FD),
                      AppTheme.primary,
                    ),
                    const SizedBox(height: 12),
                    _buildGlanceCard(
                      'Disability Certificate Renewal',
                      'Due in 5 days',
                      Icons.warning,
                      const Color(0xFFFBCFE8),
                      const Color(0xFFBE185D),
                    ),

                    const SizedBox(height: 24),

                    // Recommended Schemes
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Recommended Schemes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textMain,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildSchemeCard(
                            'Financial Aid Program',
                            'Provides monthly financial assistance to persons with benchmark disabilities to support their basic needs...',
                            AppTheme.primary,
                          ),
                          const SizedBox(width: 12),
                          _buildSchemeCard(
                            'Assistive Devices',
                            'Offers financial assistance for purchasing durable, advanced, and scientifically designed assistive devices...',
                            AppTheme.success,
                          ),
                          const SizedBox(width: 12),
                          _buildSchemeCard(
                            'Concessional Travel Pass',
                            'Provides concessions on train fares for persons with disabilities across multiple travel classes...',
                            AppTheme.concession,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // All widget builders below are completely unchanged from your original
  Widget _buildQuickActionCard(String title, IconData icon, Color bgColor, Color iconColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.border, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: bgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: bgColor.withOpacity(0.3),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.volume_up, size: 16, color: iconColor.withOpacity(0.7)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 38,
              child: Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textMain,
                  fontSize: 15,
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGlanceCard(String title, String subtitle, IconData icon, Color bgColor, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.textMain),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSchemeCard(String title, String description, Color color) {
    return Container(
      width: 260,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: AppTheme.border, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Text(
            description,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 14),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              minimumSize: const Size(double.infinity, 40),
              padding: const EdgeInsets.symmetric(vertical: 8),
            ),
            child: const Text('Learn More', style: TextStyle(fontSize: 14)),
          ),
        ],
      ),
    );
  }
}
