import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
import '../models/reminder.dart';
import '../services/reminder_service.dart';
import 'intro_screen.dart';
import 'personal_details.dart';

// ─────────────────────────────────────────────
//  SCHEME SUMMARY MODEL
// ─────────────────────────────────────────────
class SchemeSummary {
  final String  id;
  final String  title;
  final String? category;
  final String? state;
  final String? summary;
  final int?    amount;

  const SchemeSummary({
    required this.id, required this.title,
    this.category, this.state, this.summary, this.amount,
  });

  factory SchemeSummary.fromJson(Map<String, dynamic> j) => SchemeSummary(
    id      : j['id']       as String? ?? '',
    title   : j['title']    as String? ?? '',
    category: j['category'] as String?,
    state   : j['state']    as String?,
    summary : j['summary']  as String?,
    amount  : j['amount']   as int?,
  );
}

// ─────────────────────────────────────────────
//  COLOURS
// ─────────────────────────────────────────────
const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFEDE9FE);
const _purpleMid   = Color(0xFFA855F7);
const _green       = Color(0xFF15803D);
const _greenLight  = Color(0xFFDCFCE7);
const _blue        = Color(0xFF1D4ED8);
const _blueLight   = Color(0xFFDBEAFE);
const _pink        = Color(0xFFBE185D);
const _pinkLight   = Color(0xFFFDF2FA);
const _amber       = Color(0xFFB45309);
const _amberLight  = Color(0xFFFEF9C3);
const _red         = Color(0xFFDC2626);
const _bg          = Color(0xFFFAF7FF);
const _cardBorder  = Color(0xFFEDE9FE);
const _textMain    = Color(0xFF1E1B2E);
const _textSub     = Color(0xFF6B7280);

// ─────────────────────────────────────────────
//  HOME SCREEN
// ─────────────────────────────────────────────
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String currentScreen = 'home';

  // Profile
  String       fullName             = 'User';
  String       phoneNumber          = '';
  String       email                = '';
  String       dateOfBirth          = '';
  String       gender               = '';
  String       address              = '';
  String       disabilityType       = '';
  String       disabilityPercentage = '';
  String       certificateNumber    = '';
  List<String> assistiveDevices     = [];
  String?      _profileImageBase64;

  // Home data
  List<Reminder>      _upcomingReminders  = [];
  bool                _loadingReminders   = true;
  List<SchemeSummary> _recommendedSchemes = [];
  bool                _loadingSchemes     = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    _loadReminders();
    _loadSchemes();
  }

  Future<void> _loadReminders() async {
    if (!mounted) return;
    setState(() => _loadingReminders = true);
    try {
      final all = await ReminderService.loadReminders();
      final upcoming = all.where((r) => !r.isCompleted).toList()
        ..sort((a, b) {
          final at = DateTime(a.date.year, a.date.month, a.date.day,
              a.time.hour, a.time.minute);
          final bt = DateTime(b.date.year, b.date.month, b.date.day,
              b.time.hour, b.time.minute);
          return at.compareTo(bt);
        });
      if (mounted) setState(() {
        _upcomingReminders = upcoming.take(3).toList();
        _loadingReminders  = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingReminders = false);
    }
  }

  Future<void> _loadSchemes() async {
    if (!mounted) return;
    setState(() => _loadingSchemes = true);
    try {
      final data = await Supabase.instance.client
          .from('schemes')
          .select('id, title, category, state, summary, amount, active')
          .eq('active', true)
          .limit(5);
      if (mounted) setState(() {
        _recommendedSchemes = (data as List)
            .map((j) => SchemeSummary.fromJson(j as Map<String, dynamic>))
            .toList();
        _loadingSchemes = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingSchemes = false);
    }
  }

  Future<void> _loadProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) {
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(context,
          MaterialPageRoute(builder: (_) => const IntroScreen()), (_) => false);
      return;
    }
    try {
      final data = await Supabase.instance.client
          .from('profiles').select().eq('id', user.id).maybeSingle();
      if (data == null) {
        if (!mounted) return;
        Navigator.pushAndRemoveUntil(context,
            MaterialPageRoute(builder: (_) => PersonalDetails(email: user.email ?? '')),
            (_) => false);
        return;
      }
      if (!mounted) return;
      setState(() {
        fullName             = data['full_name']             ?? 'User';
        phoneNumber          = data['phone']                 ?? '';
        email                = data['email']                 ?? '';
        dateOfBirth          = data['dob']                   ?? '';
        gender               = data['gender']                ?? '';
        address              = data['address']               ?? '';
        disabilityType       = data['disability_type']       ?? '';
        disabilityPercentage = data['disability_percentage'] ?? '';
        certificateNumber    = data['certificate_number']    ?? '';
        final raw = data['assistive_devices'];
        assistiveDevices = raw is List
            ? raw.map((e) => e.toString()).toList() : [];
      });
    } catch (e) {
      debugPrint('Profile load error: $e');
    }
    final prefs = await SharedPreferences.getInstance();
    if (mounted) setState(() {
      _profileImageBase64 = prefs.getString('profileImageBase64');
    });
  }

  void _navigate(String screen) {
    if (screen == 'home') { _loadProfile(); _loadDashboardData(); }
    setState(() => currentScreen = screen);
  }

  void _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const IntroScreen()), (_) => false);
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
          decoration: const BoxDecoration(color: _bg),
          child: Column(children: [
            Expanded(child: _buildBody()),
            BottomNav(active: currentScreen, onNavigate: _navigate),
          ]),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (currentScreen == 'schemes')
      return SchemesFinder(onBack: () => _navigate('home'));
    if (currentScreen == 'hospitals')
      return HospitalLocator(onBack: () => _navigate('home'));
    if (currentScreen == 'documents')
      return DocumentVault(onBack: () => _navigate('home'));
    if (currentScreen == 'reminders')
      return Reminders(onBack: () => _navigate('home'));
    if (currentScreen == 'support')
      return Support(onBack: () => _navigate('home'));
    if (currentScreen == 'sos')
      return EmergencySOS(onBack: () => _navigate('home'));
    if (currentScreen == 'profile') {
      return Profile(
        onBack          : () => _navigate('home'),
        onLogout        : _handleLogout,
        onProfileUpdated: _loadProfile,
        personalData: PersonalDetailsData(
          fullName   : fullName,
          email      : email,
          dateOfBirth: dateOfBirth.isNotEmpty
              ? DateTime.tryParse(dateOfBirth) : null,
          gender: gender, address: address,
        ),
        disabilityData: DisabilityDetailsData(
          hasDisability    : disabilityType.isNotEmpty,
          disabilityType   : disabilityType,
          percentage       : disabilityPercentage.isNotEmpty
              ? disabilityPercentage : null,
          certificateNumber: certificateNumber.isNotEmpty
              ? certificateNumber : null,
          assistiveDevices : assistiveDevices,
        ),
        mobile: phoneNumber.isNotEmpty ? phoneNumber : '9876543210',
      );
    }

    // ── Home Dashboard ──────────────────────────
    return RefreshIndicator(
      color: _purple,
      onRefresh: () async {
        await _loadProfile();
        await _loadDashboardData();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroHeader(),
            _buildDashboard(),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  HERO HEADER  — clean, no stats strip
  // ─────────────────────────────────────────────
  Widget _buildHeroHeader() {
    final hour     = DateTime.now().hour;
    final greeting = hour < 12 ? 'Good Morning,'
        : hour < 17 ? 'Good Afternoon,' : 'Good Evening,';
    final firstName = fullName.split(' ').first;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Stack(children: [
        // Decorative circles
        Positioned(top: -50, right: -40,
          child: Container(width: 180, height: 180,
            decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0x12FFFFFF)))),
        Positioned(bottom: -30, left: -20,
          child: Container(width: 120, height: 120,
            decoration: const BoxDecoration(
              shape: BoxShape.circle, color: Color(0x0DFFFFFF)))),

        SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(22, 22, 22, 30),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(greeting,
                        style: const TextStyle(
                          color: Color(0xFFD8B4FE),
                          fontSize: 15,
                          fontWeight: FontWeight.w400,
                        )),
                      const SizedBox(height: 4),
                      Text(firstName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 30,
                          fontWeight: FontWeight.w800,
                          height: 1.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      const Text(
                        'How can we help you today?',
                        style: TextStyle(
                          color: Color(0xCCFFFFFF),
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        )),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                // Avatar
                GestureDetector(
                  onTap: () => _navigate('profile'),
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.2),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.5),
                        width: 2),
                    ),
                    child: ClipOval(
                      child: _profileImageBase64 != null
                        ? Image.memory(
                            base64Decode(_profileImageBase64!),
                            fit: BoxFit.cover,
                            width: 52, height: 52)
                        : Center(
                            child: Text(
                              fullName.isNotEmpty
                                  ? fullName[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700))),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  DASHBOARD BODY
  // ─────────────────────────────────────────────
  Widget _buildDashboard() {
    return Container(
      decoration: const BoxDecoration(
        color: _bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      // Pull up slightly to overlap header
      transform: Matrix4.translationValues(0, -16, 0),
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildQuickActionsGrid(),
          const SizedBox(height: 26),
          _buildTodayAtAGlance(),
          const SizedBox(height: 26),
          _buildRecommendedSchemes(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  QUICK ACTIONS  — FIX: use intrinsic height,
  //  no overflow
  // ─────────────────────────────────────────────
  Widget _buildQuickActionsGrid() {
    final actions = [
      _ActionData(
        'Find Schemes',
        'Browse govt. schemes',
        Icons.description_rounded,
        _purpleLight, _purple, 'schemes',
      ),
      _ActionData(
        'Nearby Hospitals',
        'Locate care near you',
        Icons.local_hospital_rounded,
        _greenLight, _green, 'hospitals',
      ),
      _ActionData(
        'My Documents',
        'Manage your files',
        Icons.folder_rounded,
        _blueLight, _blue, 'documents',
      ),
      _ActionData(
        'My Reminders',
        'Stay on schedule',
        Icons.notifications_rounded,
        _pinkLight, _pink, 'reminders',
      ),
    ];

    return Column(
      children: [
        Row(children: [
          Expanded(child: _actionCard(actions[0])),
          const SizedBox(width: 14),
          Expanded(child: _actionCard(actions[1])),
        ]),
        const SizedBox(height: 14),
        Row(children: [
          Expanded(child: _actionCard(actions[2])),
          const SizedBox(width: 14),
          Expanded(child: _actionCard(actions[3])),
        ]),
      ],
    );
  }

  // ── Single action card — fixed height, no overflow ──
  Widget _actionCard(_ActionData a) {
    return GestureDetector(
      onTap: () => _navigate(a.screen),
      child: Container(
        height: 126,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: a.iconColor.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4)),
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
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: a.bgColor,
                    borderRadius: BorderRadius.circular(12)),
                  child: Icon(a.icon, color: a.iconColor, size: 22)),
                Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: a.bgColor.withOpacity(0.5),
                    shape: BoxShape.circle),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: 10, color: a.iconColor)),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: _textMain,
                    fontSize: 14,
                    height: 1.2),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(a.subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSub,
                    height: 1.3),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  TODAY AT A GLANCE
  // ─────────────────────────────────────────────
  Widget _buildTodayAtAGlance() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Today at a Glance', onTap: () => _navigate('reminders')),
        const SizedBox(height: 14),

        if (_loadingReminders)
          Column(children: List.generate(2, (i) => Padding(
            padding: EdgeInsets.only(bottom: i == 0 ? 10 : 0),
            child: const _Shimmer(height: 70))))

        else if (_upcomingReminders.isEmpty)
          _emptyReminders()

        else
          Column(
            children: _upcomingReminders.map((r) {
              final dt = DateTime(r.date.year, r.date.month, r.date.day,
                  r.time.hour, r.time.minute);
              final isToday = _isToday(dt);
              final isSoon  = dt.difference(DateTime.now()).inHours < 3
                  && dt.isAfter(DateTime.now());

              Color icBg, icColor;
              IconData icon;
              if (r.type == ReminderType.appointment) {
                icon = Icons.calendar_today_rounded;
                icBg = _purpleLight; icColor = _purple;
              } else if (r.type == ReminderType.medication) {
                icon = Icons.medication_rounded;
                icBg = _pinkLight; icColor = _pink;
              } else {
                icon = Icons.notifications_rounded;
                icBg = _blueLight; icColor = _blue;
              }
              if (isSoon) { icBg = const Color(0xFFFEE2E2); icColor = _red; }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _glanceCard(
                  r.title,
                  '${isToday ? 'Today' : _shortDate(r.date)} at ${r.time.format(context)}',
                  icon, icBg, icColor,
                  badge: isSoon ? 'Soon' : isToday ? 'Today' : null,
                  badgeColor: isSoon ? _red : _purple,
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  Widget _emptyReminders() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Column(children: [
        Container(width: 48, height: 48,
          decoration: const BoxDecoration(color: _purpleLight, shape: BoxShape.circle),
          child: const Icon(Icons.notifications_none_rounded, color: _purple, size: 24)),
        const SizedBox(height: 10),
        const Text('No upcoming reminders',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMain)),
        const SizedBox(height: 4),
        const Text('Tap below to add your first reminder',
          style: TextStyle(fontSize: 12, color: _textSub)),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: () => _navigate('reminders'),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            decoration: BoxDecoration(
              color: AppTheme.primary,
              borderRadius: BorderRadius.circular(100),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primary.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 4)
                )
              ]
            ),
            child: const Text('Add Reminder',
              style: TextStyle(color: Colors.white,
                  fontSize: 14, fontWeight: FontWeight.bold))),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────
  //  RECOMMENDED SCHEMES
  // ─────────────────────────────────────────────
  Widget _buildRecommendedSchemes() {
    final colors = [_purple, _green, _blue, _pink, _amber];
    final bgs    = [_purpleLight, _greenLight, _blueLight, _pinkLight, _amberLight];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader('Recommended Schemes', onTap: () => _navigate('schemes')),
        const SizedBox(height: 14),

        if (_loadingSchemes)
          SizedBox(
            height: 200,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: 3,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, __) =>
                  const _Shimmer(width: 240, height: 190, radius: 16),
            ),
          )

        else if (_recommendedSchemes.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(22),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _cardBorder, width: 1.5)),
            child: const Column(children: [
              Icon(Icons.description_outlined, color: _purple, size: 38),
              SizedBox(height: 8),
              Text('No schemes available',
                style: TextStyle(fontSize: 14,
                    fontWeight: FontWeight.w600, color: _textMain)),
              SizedBox(height: 4),
              Text('Check back later or browse all schemes',
                style: TextStyle(fontSize: 12, color: _textSub)),
            ]))

        else
          SizedBox(
            height: 215,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _recommendedSchemes.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (_, i) => _schemeCard(
                _recommendedSchemes[i],
                colors[i % colors.length],
                bgs[i % bgs.length],
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  //  WIDGET BUILDERS
  // ─────────────────────────────────────────────

  Widget _sectionHeader(String title, {required VoidCallback onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(
            fontSize: 17, fontWeight: FontWeight.w700, color: _textMain)),
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _purpleLight,
              borderRadius: BorderRadius.circular(100)),
            child: const Text('See all',
              style: TextStyle(fontSize: 12, color: _purple,
                  fontWeight: FontWeight.w600)))),
      ],
    );
  }

  Widget _glanceCard(
    String title, String subtitle,
    IconData icon, Color bgColor, Color iconColor, {
    String? badge, Color? badgeColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: bgColor, borderRadius: BorderRadius.circular(12)),
          child: Icon(icon, color: iconColor, size: 22)),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: const TextStyle(fontWeight: FontWeight.w600,
                  color: _textMain, fontSize: 14),
              overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text(subtitle,
              style: const TextStyle(color: _textSub, fontSize: 12),
              overflow: TextOverflow.ellipsis),
          ],
        )),
        if (badge != null) ...[
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: (badgeColor ?? _purple).withOpacity(0.12),
              borderRadius: BorderRadius.circular(100)),
            child: Text(badge, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w700,
              color: badgeColor ?? _purple))),
        ],
      ]),
    );
  }

  Widget _schemeCard(SchemeSummary s, Color color, Color bg) {
    return Container(
      width: 242,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category + amount
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (s.category?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: bg, borderRadius: BorderRadius.circular(100)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 5, height: 5,
                      decoration: BoxDecoration(
                        color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 4),
                    Text(s.category!,
                      style: TextStyle(fontSize: 10,
                          fontWeight: FontWeight.w600, color: color)),
                  ]))
              else const SizedBox(),
              if (s.amount != null)
                Text('₹${s.amount}/mo',
                  style: TextStyle(fontSize: 11,
                      fontWeight: FontWeight.w700, color: color)),
            ],
          ),
          const SizedBox(height: 10),
          Text(s.title,
            style: const TextStyle(color: _textMain,
                fontWeight: FontWeight.w700, fontSize: 14, height: 1.3),
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Expanded(
            child: Text(
              s.summary ?? 'No description available.',
              maxLines: 3, overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: _textSub, fontSize: 12, height: 1.5)),
          ),
          const SizedBox(height: 12),
          GestureDetector(
            onTap: () => _navigate('schemes'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, color.withOpacity(0.82)],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight),
                borderRadius: BorderRadius.circular(10)),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Learn More',
                    style: TextStyle(color: Colors.white,
                        fontSize: 12, fontWeight: FontWeight.w600)),
                  SizedBox(width: 4),
                  Icon(Icons.arrow_forward_rounded,
                      color: Colors.white, size: 13),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Helpers ───────────────────────────────────
  bool _isToday(DateTime dt) {
    final n = DateTime.now();
    return dt.year == n.year && dt.month == n.month && dt.day == n.day;
  }

  String _shortDate(DateTime dt) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun',
                'Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${dt.day} ${m[dt.month - 1]}';
  }
}

// ─────────────────────────────────────────────
//  DATA CLASS
// ─────────────────────────────────────────────
class _ActionData {
  final String   title;
  final String   subtitle;
  final IconData icon;
  final Color    bgColor;
  final Color    iconColor;
  final String   screen;
  const _ActionData(this.title, this.subtitle, this.icon,
      this.bgColor, this.iconColor, this.screen);
}

// ─────────────────────────────────────────────
//  SHIMMER WIDGET
// ─────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double? width;
  final double  height;
  final double  radius;
  const _Shimmer({this.width, required this.height, this.radius = 14});

  @override
  State<_Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double>   _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
    _anim = Tween<double>(begin: -2, end: 2)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _anim,
    builder: (_, __) => Container(
      width: widget.width,
      height: widget.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(widget.radius),
        gradient: LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end  : Alignment(_anim.value, 0),
          colors: const [
            Color(0xFFF3F0FF),
            Color(0xFFE9E4FF),
            Color(0xFFF3F0FF),
          ],
        ),
      ),
    ),
  );
}
