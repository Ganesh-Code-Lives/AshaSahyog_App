import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../l10n/app_strings.dart';
import '../providers/language_provider.dart';
import '../screens/scheme_details_screen.dart';
import 'eligibility_engine.dart';
import 'eligibility_info_sheet.dart';
import 'recommendation_service.dart';
import 'recommended_scheme_model.dart';
import 'user_eligibility_profile.dart';
import '../services/tts_service.dart';
import '../components/tts_button.dart';

// ─────────────────────────────────────────────
// COLOURS
// ─────────────────────────────────────────────
const _purple = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFEDE9FE);
const _green = Color(0xFF15803D);
const _greenLight = Color(0xFFDCFCE7);
const _amber = Color(0xFFB45309);
const _amberLight = Color(0xFFFEF9C3);
const _red = Color(0xFFDC2626);
const _redLight = Color(0xFFFEE2E2);
const _bg = Color(0xFFFAF7FF);
const _cardBorder = Color(0xFFEDE9FE);
const _textMain = Color(0xFF1E1B2E);
const _textSub = Color(0xFF6B7280);

class RecommendationScreen extends StatefulWidget {
  final VoidCallback onBack;
  const RecommendationScreen({super.key, required this.onBack});

  @override
  State<RecommendationScreen> createState() => _RecommendationScreenState();
}

class _RecommendationScreenState extends State<RecommendationScreen> {
  final _service = RecommendationService();
  
  bool _loading = true;
  String? _error;
  UserEligibilityProfile? _profile;
  List<RecommendedScheme> _allRecommendations = [];
  List<RecommendedScheme> _filteredRecommendations = [];
  
  // Filter state
  EligibilityStatus? _filterStatus; // null means 'All'

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    
    try {
      final langCode = Provider.of<LanguageProvider>(context, listen: false).langCode;
      _profile = await _service.getUserProfile();
      _allRecommendations = await _service.getRecommendations(langCode: langCode);
      _applyFilter();
      
      if (mounted) setState(() { _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  void _applyFilter() {
    if (_filterStatus == null) {
      _filteredRecommendations = _allRecommendations;
    } else {
      _filteredRecommendations = _allRecommendations
          .where((r) => r.status == _filterStatus)
          .toList();
    }
  }

  void _setFilter(EligibilityStatus? status) {
    setState(() {
      _filterStatus = status;
      _applyFilter();
    });
  }

  Future<void> _openDetails(String schemeId) async {
    // Show a small loading indicator
    final overlay = OverlayEntry(
      builder: (_) => const Positioned.fill(
        child: ColoredBox(
          color: Colors.black12,
          child: Center(
            child: CircularProgressIndicator(color: _purple),
          ),
        ),
      ),
    );
    Overlay.of(context).insert(overlay);

    try {
      final langCode = Provider.of<LanguageProvider>(context, listen: false).langCode;
      // We need to fetch the full scheme detail by id.
      // Reusing the same query structure from schemes_finder repository:
      final db = Supabase.instance.client;
      final json = await db.from('schemes').select('''
        *,
        scheme_eligibility(*),
        scheme_benefits(*),
        scheme_documents(*),
        scheme_apply_steps(*),
        scheme_tags(*),
        scheme_similar(*)
      ''').eq('id', schemeId).single();
      
      final detail = SchemeDetail.fromJson(json, langCode: langCode);
      
      if (overlay.mounted) overlay.remove();
      if (!mounted) return;
      
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) => SchemeDetailsScreen(scheme: detail),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(
            opacity: anim,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.04),
                end: Offset.zero,
              ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOut)),
              child: child,
            ),
          ),
        ),
      );
    } catch (e) {
      if (overlay.mounted) overlay.remove();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not load scheme: $e')),
      );
    }
  }

  // ─────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_loading && _profile != null) _buildMissingInfoBanner(),
            if (!_loading && _allRecommendations.isNotEmpty) _buildFilters(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(4, 12, 16, 12),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              final langCode = context.read<LanguageProvider>().langCode;
              TTSService().speakFeedback(
                'Going back',
                hiMessage: 'वापस जा रहे हैं',
                mrMessage: 'मागे जात आहे',
                langCode: langCode,
              );
              widget.onBack();
            },
            icon: const Icon(Icons.arrow_back_ios_new_rounded, color: _textMain, size: 18),
          ),
          Expanded(
            child: Text(
              AppStrings.t(context, 'schemes_for_you', 'Schemes For You'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: _textMain),
            ),
          ),
          IconButton(
            tooltip: 'Edit Eligibility Info',
            onPressed: () => EligibilityInfoSheet.show(context, onSaved: _loadData),
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: _purpleLight,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.tune_rounded, color: _purple, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMissingInfoBanner() {
    if (_profile == null) return const SizedBox.shrink();
    
    final missing = _profile!.missingEligibilityFields;
    if (missing.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _amberLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded, color: _amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Complete your profile for better matches',
                  style: TextStyle(fontWeight: FontWeight.w600, color: _amber, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Missing: ${missing.join(', ')}',
                  style: TextStyle(color: _amber.withOpacity(0.8), fontSize: 12),
                ),
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => EligibilityInfoSheet.show(context, onSaved: _loadData),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Update Profile',
                      style: TextStyle(color: _amber, fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters() {
    return Container(
      height: 44,
      margin: const EdgeInsets.only(top: 12, bottom: 4),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _filterChip('All', null, _purple, _purpleLight),
          const SizedBox(width: 8),
          _filterChip('Eligible', EligibilityStatus.eligible, _green, _greenLight),
          const SizedBox(width: 8),
          _filterChip('Needs Verification', EligibilityStatus.needsVerification, _amber, _amberLight),
          const SizedBox(width: 8),
          _filterChip('Not Eligible', EligibilityStatus.notEligible, _red, _redLight),
        ],
      ),
    );
  }

  Widget _filterChip(String label, EligibilityStatus? status, Color color, Color bg) {
    final selected = _filterStatus == status;
    return GestureDetector(
      onTap: () => _setFilter(status),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? Colors.transparent : _cardBorder),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: selected ? Colors.white : _textSub,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator(color: _purple));
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, color: _red, size: 48),
              const SizedBox(height: 16),
              const Text('Could not load recommendations', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
              const SizedBox(height: 8),
              Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: _textSub)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(backgroundColor: _purple),
                child: const Text('Try Again', style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ),
      );
    }

    if (_filteredRecommendations.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72, height: 72,
                decoration: const BoxDecoration(color: _purpleLight, shape: BoxShape.circle),
                child: const Icon(Icons.search_off_rounded, color: _purple, size: 36),
              ),
              const SizedBox(height: 16),
              const Text('No schemes found', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textMain)),
              const SizedBox(height: 8),
              const Text('Try changing your filters or updating your profile.', style: TextStyle(fontSize: 13, color: _textSub), textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
      itemCount: _filteredRecommendations.length,
      itemBuilder: (_, i) => _RecommendationCard(
        rec: _filteredRecommendations[i],
        onTap: () => _openDetails(_filteredRecommendations[i].summary.id),
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final RecommendedScheme rec;
  final VoidCallback onTap;

  const _RecommendationCard({required this.rec, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color statusColor;
    Color statusBg;
    String statusLabel;
    IconData statusIcon;

    switch (rec.status) {
      case EligibilityStatus.eligible:
        statusColor = _green;
        statusBg = _greenLight;
        statusLabel = 'Eligible';
        statusIcon = Icons.check_circle_rounded;
        break;
      case EligibilityStatus.needsVerification:
        statusColor = _amber;
        statusBg = _amberLight;
        statusLabel = 'Needs Verification';
        statusIcon = Icons.help_outline_rounded;
        break;
      case EligibilityStatus.notEligible:
        statusColor = _red;
        statusBg = _redLight;
        statusLabel = 'Not Eligible';
        statusIcon = Icons.cancel_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cardBorder, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: statusColor.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Status + Match Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: statusBg.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              border: Border(bottom: BorderSide(color: statusBg)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(statusIcon, color: statusColor, size: 18),
                    const SizedBox(width: 6),
                    Text(
                      statusLabel,
                      style: TextStyle(color: statusColor, fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                  ],
                ),
                if (rec.status != EligibilityStatus.notEligible)
                  Text(
                    '${rec.score}% Match',
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 12),
                  ),
              ],
            ),
          ),
          
          // Body
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.summary.title,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: _textMain, height: 1.3),
                ),
                if (rec.summary.summary != null && rec.summary.summary!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    rec.summary.summary!,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 13, color: _textSub, height: 1.5),
                  ),
                ],
                
                const SizedBox(height: 16),
                const Text('Eligibility Checklist:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain)),
                const SizedBox(height: 8),
                
                // Show up to 3 checks to keep it compact
                ...rec.checks.take(3).map((check) {
                  IconData icon;
                  Color iconColor;
                  if (check.passed == true) {
                    icon = Icons.check_circle_rounded;
                    iconColor = _green;
                  } else if (check.passed == false) {
                    icon = Icons.cancel_rounded;
                    iconColor = _red;
                  } else {
                    icon = Icons.help_rounded;
                    iconColor = _amber;
                  }
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(icon, size: 16, color: iconColor),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            check.reason,
                            style: const TextStyle(fontSize: 12, color: _textSub),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                
                if (rec.checks.length > 3)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '+ ${rec.checks.length - 3} more checks',
                      style: const TextStyle(fontSize: 12, color: _purple, fontStyle: FontStyle.italic),
                    ),
                  ),
              ],
            ),
          ),
          
          const Divider(height: 1, color: Color(0xFFF3F0FF)),
          
          // Footer
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: onTap,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                    decoration: BoxDecoration(
                      color: _purple,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('View Details', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                        SizedBox(width: 4),
                        Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 13),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
