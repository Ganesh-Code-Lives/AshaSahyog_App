import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart'; // add url_launcher: ^6.2.4 to pubspec.yaml
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────
//  DATA MODELS — field names match Supabase exactly
// ─────────────────────────────────────────────

class SchemeEligibility {
  final int?    minAge;
  final int?    maxAge;
  final int?    minDisabilityPercent; // Supabase col: min_disability_percent
  final int?    maxIncome;            // Supabase col: max_income
  final bool?   requiresResidency;   // Supabase col: requires_residency
  final String? residencyState;      // Supabase col: residency_state
  final bool?   requiresAadhaar;     // Supabase col: requires_aadhaar
  final bool?   requiresBankAccount; // Supabase col: requires_bank_account
  final String? additionalNotes;     // Supabase col: additional_notes

  const SchemeEligibility({
    this.minAge, this.maxAge, this.minDisabilityPercent, this.maxIncome,
    this.requiresResidency, this.residencyState,
    this.requiresAadhaar, this.requiresBankAccount, this.additionalNotes,
  });

  factory SchemeEligibility.fromJson(Map<String, dynamic> j) =>
      SchemeEligibility(
        minAge               : j['min_age']                as int?,
        maxAge               : j['max_age']                as int?,
        minDisabilityPercent : j['min_disability_percent'] as int?,
        maxIncome            : j['max_income']             as int?,
        requiresResidency    : j['requires_residency']     as bool?,
        residencyState       : j['residency_state']        as String?,
        requiresAadhaar      : j['requires_aadhaar']       as bool?,
        requiresBankAccount  : j['requires_bank_account']  as bool?,
        additionalNotes      : j['additional_notes']       as String?,
      );
}

class SchemeBenefit {
  final String  text;       // Supabase col: benefit_text  ← FIX was 'title'
  final String? valueLabel; // Supabase col: value_label
  final String? unit;       // Supabase col: unit
  final String? iconKey;    // Supabase col: icon_key
  final int     sortOrder;  // Supabase col: sort_order

  const SchemeBenefit({
    required this.text, this.valueLabel, this.unit,
    this.iconKey, this.sortOrder = 0,
  });

  factory SchemeBenefit.fromJson(Map<String, dynamic> j) => SchemeBenefit(
    text      : j['benefit_text'] as String? ?? '', // ← FIX
    valueLabel: j['value_label']  as String?,
    unit      : j['unit']         as String?,
    iconKey   : j['icon_key']     as String?,
    sortOrder : j['sort_order']   as int? ?? 0,
  );
}

class SchemeDocument {
  final String  name;       // Supabase col: doc_name  ← FIX was 'name'
  final bool    isOptional; // Supabase col: is_optional
  final String? hint;       // Supabase col: hint
  final int     sortOrder;  // Supabase col: sort_order

  const SchemeDocument({
    required this.name, this.isOptional = false, this.hint, this.sortOrder = 0,
  });

  factory SchemeDocument.fromJson(Map<String, dynamic> j) => SchemeDocument(
    name      : j['doc_name']    as String? ?? '', // ← FIX
    isOptional: j['is_optional'] as bool?   ?? false,
    hint      : j['hint']        as String?,
    sortOrder : j['sort_order']  as int?    ?? 0,
  );
}

class SchemeApplyStep {
  final int    stepNumber;
  final String title;
  final String description;

  const SchemeApplyStep({
    required this.stepNumber, required this.title, required this.description,
  });

  factory SchemeApplyStep.fromJson(Map<String, dynamic> j) => SchemeApplyStep(
    stepNumber : j['step_number'] as int?    ?? 0,
    title      : j['title']       as String? ?? '',
    description: j['description'] as String? ?? '',
  );
}

class SchemeSimilar {
  final String  title;
  final String? category;
  final int?    matchPercent;

  const SchemeSimilar({required this.title, this.category, this.matchPercent});

  factory SchemeSimilar.fromJson(Map<String, dynamic> j) => SchemeSimilar(
    title       : j['similar_scheme_title'] as String? ?? '',
    category    : j['category']             as String?,
    matchPercent: j['match_percent']        as int?,
  );
}

class SchemeDetail {
  final String  id;
  final String  title;
  final String? category;
  final String? state;
  final String? summary;
  final int?    amount;
  final String? officialLink;
  final int?    processingDays;
  final String? helplineNumber;
  final SchemeEligibility?   eligibility;
  final List<SchemeBenefit>  benefits;
  final List<SchemeDocument> documents;
  final List<SchemeApplyStep> applySteps;
  final List<String>         tags;
  final List<SchemeSimilar>  similarSchemes;

  const SchemeDetail({
    required this.id, required this.title,
    this.category, this.state, this.summary, this.amount,
    this.officialLink, this.processingDays, this.helplineNumber,
    this.eligibility,
    this.benefits      = const [],
    this.documents     = const [],
    this.applySteps    = const [],
    this.tags          = const [],
    this.similarSchemes = const [],
  });

  factory SchemeDetail.fromJson(Map<String, dynamic> j) {
    SchemeEligibility? eligibility;
    final rawElig = j['scheme_eligibility'];
    if (rawElig is List && rawElig.isNotEmpty) {
      eligibility = SchemeEligibility.fromJson(rawElig.first as Map<String, dynamic>);
    } else if (rawElig is Map<String, dynamic>) {
      eligibility = SchemeEligibility.fromJson(rawElig);
    }

    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) fn) =>
        (raw as List<dynamic>? ?? []).map((e) => fn(e as Map<String, dynamic>)).toList();

    final tags = (j['scheme_tags'] as List<dynamic>? ?? [])
        .map((t) => (t as Map<String, dynamic>)['tag'] as String? ?? '')
        .where((t) => t.isNotEmpty)
        .toList();

    final benefits = parseList(j['scheme_benefits'], SchemeBenefit.fromJson)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final documents = parseList(j['scheme_documents'], SchemeDocument.fromJson)
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    final applySteps = parseList(j['scheme_apply_steps'], SchemeApplyStep.fromJson)
      ..sort((a, b) => a.stepNumber.compareTo(b.stepNumber));

    return SchemeDetail(
      id            : j['id']              as String? ?? '',
      title         : j['title']           as String? ?? '',
      category      : j['category']        as String?,
      state         : j['state']           as String?,
      summary       : j['summary']         as String?,
      amount        : j['amount']          as int?,
      officialLink  : j['official_link']   as String?,
      processingDays: j['processing_days'] as int?,
      helplineNumber: j['helpline_number'] as String?,
      eligibility   : eligibility,
      benefits      : benefits,
      documents     : documents,
      applySteps    : applySteps,
      tags          : tags,
      similarSchemes: parseList(j['scheme_similar'], SchemeSimilar.fromJson),
    );
  }
}

// ─────────────────────────────────────────────
//  COLOURS
// ─────────────────────────────────────────────
const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFEDE9FE);
const _purpleMid   = Color(0xFFA855F7);
const _green       = Color(0xFF15803D);
const _greenLight  = Color(0xFFDCFCE7);
const _amber       = Color(0xFFB45309);
const _amberLight  = Color(0xFFFEF9C3);
const _red         = Color(0xFFDC2626);
const _redLight    = Color(0xFFFEE2E2);
const _blue        = Color(0xFF1D4ED8);
const _blueLight   = Color(0xFFDBEAFE);
const _bg          = Color(0xFFFAF7FF);
const _cardBorder  = Color(0xFFEDE9FE);
const _textMain    = Color(0xFF1E1B2E);
const _textSub     = Color(0xFF6B7280);

// ─────────────────────────────────────────────
//  SCREEN
// ─────────────────────────────────────────────
class SchemeDetailsScreen extends StatefulWidget {
  final SchemeDetail scheme;
  const SchemeDetailsScreen({super.key, required this.scheme});

  @override
  State<SchemeDetailsScreen> createState() => _SchemeDetailsScreenState();
}

class _SchemeDetailsScreenState extends State<SchemeDetailsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isSaved = false;

  final _tabs = ['Overview', 'Benefits', 'Eligibility', 'Documents', 'How to Apply'];

  SchemeDetail get _s => widget.scheme;
  String get _amountLabel     => _s.amount != null ? '₹${_s.amount}' : '—';
  String get _disabilityLabel => _s.eligibility?.minDisabilityPercent != null
      ? '${_s.eligibility!.minDisabilityPercent}%+' : '—';
  String get _processingLabel => _s.processingDays != null ? '${_s.processingDays}d' : '—';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
  }

  @override
  void dispose() { _tabController.dispose(); super.dispose(); }

  // FIX: Apply Now opens real URL
  Future<void> _launchOfficialLink() async {
    final raw = _s.officialLink ?? '';
    if (raw.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No official link available.')));
      return;
    }
    final uri = Uri.tryParse(raw);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open: $raw')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: NestedScrollView(
        headerSliverBuilder: (ctx, scrolled) => [_buildHeroSliverAppBar(scrolled)],
        body: Column(children: [
          _buildTabBar(),
          Expanded(child: TabBarView(
            controller: _tabController,
            children: [
              _OverviewTab(scheme: _s),
              _BenefitsTab(benefits: _s.benefits, amount: _s.amount),
              _EligibilityTab(eligibility: _s.eligibility, similarSchemes: _s.similarSchemes),
              _DocumentsTab(documents: _s.documents),
              _HowToApplyTab(applySteps: _s.applySteps, helpline: _s.helplineNumber),
            ],
          )),
        ]),
      ),
      bottomNavigationBar: _buildBottomBar(),
    );
  }

  SliverAppBar _buildHeroSliverAppBar(bool scrolled) {
    return SliverAppBar(
      expandedHeight: 235, pinned: true, backgroundColor: _purple,
      leading: Center(
        child: _HeroIconBtn(icon: Icons.arrow_back_ios_new_rounded,
            onTap: () => Navigator.of(context).pop()),
      ),
      actions: [
        _HeroIconBtn(
          icon: _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
          onTap: () => setState(() => _isSaved = !_isSaved),
        ),
        const SizedBox(width: 4),
        _HeroIconBtn(icon: Icons.share_rounded, onTap: () {}),
        const SizedBox(width: 12),
      ],
      title: AnimatedOpacity(
        opacity: scrolled ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(_s.title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.pin,
        background: ClipRect(child: _HeroContent(
          title: _s.title, category: _s.category ?? '',
          state: _s.state ?? '', amountLabel: _amountLabel,
          disabilityLabel: _disabilityLabel, processingLabel: _processingLabel,
        )),
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      color: Colors.white,
      child: TabBar(
        controller: _tabController, isScrollable: true,
        tabAlignment: TabAlignment.start,
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(color: _purple, width: 2.5),
          insets: EdgeInsets.symmetric(horizontal: 4),
        ),
        labelColor: _purple, unselectedLabelColor: _textSub,
        labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        tabs: _tabs.map((t) => Tab(text: t)).toList(),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, MediaQuery.of(context).padding.bottom + 12),
      child: Row(children: [
        GestureDetector(
          onTap: () => setState(() => _isSaved = !_isSaved),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: _isSaved ? _purpleLight : _bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cardBorder, width: 1.5),
            ),
            child: Icon(_isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                color: _purple, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(child: GestureDetector(
          onTap: _launchOfficialLink, // ← FIX: real URL
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: _purple,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [BoxShadow(color: _purple.withOpacity(0.35),
                  blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text('Apply Now', style: TextStyle(color: Colors.white,
                  fontWeight: FontWeight.w700, fontSize: 15)),
              SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
            ]),
          ),
        )),
      ]),
    );
  }
}

// ─────────────────────────────────────────────
//  HERO
// ─────────────────────────────────────────────
class _HeroContent extends StatelessWidget {
  final String title, category, state, amountLabel, disabilityLabel, processingLabel;
  const _HeroContent({required this.title, required this.category, required this.state,
      required this.amountLabel, required this.disabilityLabel,
      required this.processingLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(gradient: LinearGradient(
          colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
          begin: Alignment.topLeft, end: Alignment.bottomRight)),
      child: Stack(children: [
        Positioned(top: -60, right: -40, child: Container(width: 200, height: 200,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06)))),
        Positioned(bottom: -30, left: -20, child: Container(width: 120, height: 120,
            decoration: BoxDecoration(shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06)))),
        Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 55, 20, 20),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(color: Colors.white.withOpacity(0.25), width: 1)),
              child: Text('$category · $state', maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Color(0xFFE9D5FF),
                      fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.4)),
            ),
            const SizedBox(height: 10),
            Text(title, maxLines: 3, overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white,
                    fontSize: 19, fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 12),
            Row(children: [
              _HeroStat(value: amountLabel,     label: 'Per month'),
              const SizedBox(width: 8),
              _HeroStat(value: disabilityLabel, label: 'Min. disability'),
              const SizedBox(width: 8),
              _HeroStat(value: processingLabel, label: 'Processing'),
            ]),
          ]),
        ),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String value, label;
  const _HeroStat({required this.value, required this.label});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 10),
    decoration: BoxDecoration(color: Colors.white.withOpacity(0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withOpacity(0.18), width: 1)),
    child: Column(children: [
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w700)),
      const SizedBox(height: 2),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          style: const TextStyle(color: Color(0xFFC4B5FD), fontSize: 10, fontWeight: FontWeight.w500)),
    ]),
  ));
}

class _HeroTag extends StatelessWidget {
  final String label;
  final bool isGreen;
  const _HeroTag(this.label, {this.isGreen = false});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isGreen ? const Color(0xFF4ADE80).withOpacity(0.2) : Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(100),
      border: Border.all(
        color: isGreen ? const Color(0xFF4ADE80).withOpacity(0.35) : Colors.white.withOpacity(0.22),
        width: 1),
    ),
    child: Text(label, style: TextStyle(
      color: isGreen ? const Color(0xFFBBF7D0) : const Color(0xFFE9D5FF),
      fontSize: 11, fontWeight: FontWeight.w500)),
  );
}

class _HeroIconBtn extends StatelessWidget {
  final IconData icon; final VoidCallback onTap;
  const _HeroIconBtn({required this.icon, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(onTap: onTap,
    child: Container(width: 34, height: 34,
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.2), width: 1)),
      child: Icon(icon, color: Colors.white, size: 16)));
}

// ─────────────────────────────────────────────
//  SHARED
// ─────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final Widget child; final EdgeInsets? padding;
  const _SectionCard({required this.child, this.padding});
  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity, padding: padding ?? const EdgeInsets.all(16),
    decoration: BoxDecoration(color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _cardBorder, width: 1.5)),
    child: child);
}

class _CardHeader extends StatelessWidget {
  final IconData icon; final Color iconBg, iconColor;
  final String title; final String? subtitle;
  const _CardHeader({required this.icon, required this.iconBg,
      required this.iconColor, required this.title, this.subtitle});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 32, height: 32,
        decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: iconColor, size: 16)),
    const SizedBox(width: 10),
    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: _textMain)),
      if (subtitle != null)
        Text(subtitle!, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, color: _textSub)),
    ])),
  ]);
}

class _MiniStat extends StatelessWidget {
  final String value, label; final Color bg, textColor;
  const _MiniStat({required this.value, required this.label,
      required this.bg, required this.textColor});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(vertical: 12),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Column(children: [
      Text(value, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: textColor)),
      const SizedBox(height: 3),
      Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10, color: _textSub)),
    ]),
  ));
}

// ─────────────────────────────────────────────
//  TAB 1 — OVERVIEW
// ─────────────────────────────────────────────
class _OverviewTab extends StatelessWidget {
  final SchemeDetail scheme;
  const _OverviewTab({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
      _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardHeader(icon: Icons.info_outline_rounded,
            iconBg: _purpleLight, iconColor: _purple, title: 'About this scheme'),
        const SizedBox(height: 12),
        Text(scheme.summary?.isNotEmpty == true ? scheme.summary! : 'No description available.',
            style: const TextStyle(fontSize: 13, color: _textSub, height: 1.7)),
      ])),
      const SizedBox(height: 12),
      _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardHeader(icon: Icons.analytics_outlined,
            iconBg: Color(0xFFEAF3DE), iconColor: _green, title: 'Your match score'),
        const SizedBox(height: 14),
        Row(children: [
          const Text('87%', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: _purple)),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Profile compatibility', style: TextStyle(fontSize: 12, color: _textSub)),
            const SizedBox(height: 6),
            ClipRRect(borderRadius: BorderRadius.circular(100),
              child: const LinearProgressIndicator(value: 0.87, backgroundColor: _purpleLight,
                  valueColor: AlwaysStoppedAnimation<Color>(_purple), minHeight: 6)),
          ])),
        ]),
        const SizedBox(height: 8),
        const Text('You meet eligibility criteria based on your profile.',
            style: TextStyle(fontSize: 12, color: _textSub)),
      ])),
      const SizedBox(height: 12),
      _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardHeader(icon: Icons.volume_up_rounded,
            iconBg: Color(0xFFFDF2FA), iconColor: Color(0xFFBE185D),
            title: 'Listen to this scheme'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: const Color(0xFFFDF2FA),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: const Color(0xFFFBCFE8), width: 1.5)),
          child: Row(children: [
            Container(width: 34, height: 34,
                decoration: const BoxDecoration(color: Color(0xFFEC4899), shape: BoxShape.circle),
                child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 18)),
            const SizedBox(width: 10),
            Expanded(child: Row(children: List.generate(18, (i) => Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: [7,14,20,10,17,8,22,13,18,9,14,20,7,15,11,19,8,16][i].toDouble(),
                decoration: BoxDecoration(color: const Color(0xFFFBCFE8),
                    borderRadius: BorderRadius.circular(2)),
              ),
            )))),
            const SizedBox(width: 10),
            Column(crossAxisAlignment: CrossAxisAlignment.end, children: const [
              Text('Read Aloud', style: TextStyle(fontSize: 12,
                  fontWeight: FontWeight.w600, color: Color(0xFFBE185D))),
              Text('Hindi · English · Marathi',
                  style: TextStyle(fontSize: 10, color: _textSub)),
            ]),
          ]),
        ),
      ])),
    ]);
  }
}

// ─────────────────────────────────────────────
//  TAB 2 — BENEFITS  ← FIX: reads benefit_text
// ─────────────────────────────────────────────
class _BenefitsTab extends StatelessWidget {
  final List<SchemeBenefit> benefits;
  final int? amount;
  const _BenefitsTab({required this.benefits, this.amount});

  static IconData _icon(String? k) { switch(k) {
    case 'pension':   return Icons.payments_outlined;
    case 'health':    return Icons.favorite_border_rounded;
    case 'udid':      return Icons.credit_card_rounded;
    case 'education': return Icons.school_outlined;
    case 'housing':   return Icons.home_outlined;
    default:          return Icons.check_circle_outline;
  }}
  static Color _ic(String? k) { switch(k) {
    case 'pension':   return _purple;
    case 'health':    return _blue;
    case 'udid':      return _green;
    case 'education': return _amber;
    default:          return _purple;
  }}
  static Color _bg2(String? k) { switch(k) {
    case 'pension':   return _purpleLight;
    case 'health':    return _blueLight;
    case 'udid':      return _greenLight;
    case 'education': return _amberLight;
    default:          return _purpleLight;
  }}

  String get _annual => amount != null ? '₹${amount! * 12}' : '—';

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
    Row(children: [
      _MiniStat(value: _annual, label: 'Annual value', bg: _purpleLight, textColor: _purple),
      const SizedBox(width: 10),
      _MiniStat(value: '${benefits.length}', label: 'Total benefits', bg: _greenLight, textColor: _green),
      const SizedBox(width: 10),
      _MiniStat(value: 'Direct', label: 'Transfer mode', bg: _blueLight, textColor: _blue),
    ]),
    const SizedBox(height: 12),
    _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _CardHeader(icon: Icons.checklist_rounded, iconBg: _purpleLight, iconColor: _purple,
          title: 'All benefits', subtitle: 'What you receive under this scheme'),
      const SizedBox(height: 12),
      if (benefits.isEmpty)
        const Padding(padding: EdgeInsets.symmetric(vertical: 12),
          child: Text('No benefits listed.', style: TextStyle(fontSize: 13, color: _textSub)))
      else
        ...List.generate(benefits.length, (i) {
          final b = benefits[i];
          return _BenefitRow(
            icon     : _icon(b.iconKey),
            iconBg   : _bg2(b.iconKey),
            iconColor: _ic(b.iconKey),
            title    : b.text,           // ← reads benefit_text from Supabase
            value    : b.valueLabel ?? '',
            unit     : b.unit       ?? '',
            isLast   : i == benefits.length - 1,
          );
        }),
    ])),
    const SizedBox(height: 12),
    Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFDE68A), width: 1.5)),
      child: Row(children: const [
        Icon(Icons.warning_amber_rounded, color: _amber, size: 16), SizedBox(width: 10),
        Expanded(child: Text('Benefit amounts may be revised by the government.',
            style: TextStyle(fontSize: 11, color: _amber, height: 1.5))),
      ]),
    ),
  ]);
}

class _BenefitRow extends StatelessWidget {
  final IconData icon; final Color iconBg, iconColor;
  final String title, value, unit; final bool isLast;
  const _BenefitRow({required this.icon, required this.iconBg, required this.iconColor,
      required this.title, required this.value, required this.unit, required this.isLast});
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
      Container(width: 34, height: 34,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _textMain))),
      if (value.isNotEmpty)
        Column(crossAxisAlignment: CrossAxisAlignment.end, mainAxisSize: MainAxisSize.min, children: [
          Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: iconColor)),
          Text(unit,  style: const TextStyle(fontSize: 10, color: _textSub)),
        ]),
    ])),
    if (!isLast) const Divider(height: 1, color: Color(0xFFF3F0FF)),
  ]);
}

// ─────────────────────────────────────────────
//  TAB 3 — ELIGIBILITY  ← FIX: correct field names
// ─────────────────────────────────────────────
class _EligibilityTab extends StatelessWidget {
  final SchemeEligibility?  eligibility;
  final List<SchemeSimilar> similarSchemes;
  const _EligibilityTab({required this.eligibility, required this.similarSchemes});

  static String _fmt(int v) {
    if (v >= 100000) return '₹${(v/100000).toStringAsFixed(1)}L';
    if (v >= 1000)   return '₹${(v/1000).toStringAsFixed(0)}K';
    return '₹$v';
  }

  List<Map<String, String>> _buildCriteria() {
    final e = eligibility;
    if (e == null) return [];
    return [
      if (e.requiresResidency == true)
        {'label': '${e.residencyState ?? 'State'} resident', 'status': 'pass', 'detail': 'Verified'},
      if (e.minAge != null)
        {'label': 'Age ${e.minAge}+', 'status': 'pass', 'detail': 'Verified'},
      if (e.minDisabilityPercent != null)
        {'label': 'Disability certificate (${e.minDisabilityPercent}%+)', 'status': 'pass', 'detail': 'On file'},
      if (e.maxIncome != null)
        {'label': 'Annual income < ${_fmt(e.maxIncome!)}', 'status': 'pass', 'detail': 'Verified'},
      if (e.requiresAadhaar == true)
        {'label': 'Valid Aadhaar card', 'status': 'pass', 'detail': 'Linked'},
      if (e.requiresBankAccount == true)
        {'label': 'Active bank account (DBT)', 'status': 'pass', 'detail': 'Linked'},
      if (e.additionalNotes?.isNotEmpty == true)
        {'label': e.additionalNotes!, 'status': 'warn', 'detail': 'Confirm'},
    ];
  }

  @override
  Widget build(BuildContext context) {
    final criteria = _buildCriteria();
    final passed = criteria.where((c) => c['status'] == 'pass').length;
    final total  = criteria.length;
    final pct    = total > 0 ? ((passed / total) * 100).round() : 0;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBBF7D0), width: 1.5)),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: const BoxDecoration(color: _greenLight, shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: _green, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('You likely qualify', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w700, color: _green)),
            Text(total > 0 ? '$passed of $total criteria met' : 'Check criteria below',
                style: const TextStyle(fontSize: 11, color: _textSub)),
            if (total > 0) ...[
              const SizedBox(height: 6),
              ClipRRect(borderRadius: BorderRadius.circular(100),
                child: LinearProgressIndicator(value: passed / total,
                    backgroundColor: _greenLight,
                    valueColor: const AlwaysStoppedAnimation<Color>(_green), minHeight: 5)),
            ],
          ])),
          const SizedBox(width: 12),
          if (total > 0) Text('$pct%', style: const TextStyle(
              fontSize: 22, fontWeight: FontWeight.w800, color: _green)),
        ]),
      ),
      const SizedBox(height: 12),
      _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardHeader(icon: Icons.person_outline_rounded, iconBg: _purpleLight,
            iconColor: _purple, title: 'Criteria check', subtitle: 'Based on your profile data'),
        const SizedBox(height: 12),
        if (criteria.isEmpty)
          const Text('No eligibility criteria available.',
              style: TextStyle(fontSize: 13, color: _textSub))
        else
          ...criteria.asMap().entries.map((e) => _EligibilityRow(
            label: e.value['label']!, status: e.value['status']!,
            detail: e.value['detail']!, isLast: e.key == criteria.length - 1)),
      ])),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: _amberLight, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFFDE68A), width: 1.5)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Icon(Icons.info_rounded, color: _amber, size: 15), SizedBox(width: 9),
          Expanded(child: Text(
            'You can still apply if unsure — the officer will verify during the home visit.',
            style: TextStyle(fontSize: 11, color: _amber, height: 1.5))),
        ]),
      ),
      if (similarSchemes.isNotEmpty) ...[
        const SizedBox(height: 12),
        _SectionCard(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Similar schemes you also qualify for',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMain)),
            const SizedBox(height: 10),
            ...similarSchemes.map((ss) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _SimilarSchemeRow(icon: Icons.description_outlined,
                iconBg: _blueLight, iconColor: _blue, title: ss.title,
                subtitle: ss.matchPercent != null ? '${ss.matchPercent}% match' : ss.category ?? ''),
            )),
          ])),
      ],
    ]);
  }
}

class _EligibilityRow extends StatelessWidget {
  final String label, status, detail; final bool isLast;
  const _EligibilityRow({required this.label, required this.status,
      required this.detail, required this.isLast});
  Color get _checkBg    => status=='pass' ? _greenLight : status=='fail' ? _redLight  : _amberLight;
  Color get _checkColor => status=='pass' ? _green      : status=='fail' ? _red       : _amber;
  Color get _detColor   => status=='pass' ? _green      : status=='fail' ? _red       : _amber;
  IconData get _checkIcon => status=='pass' ? Icons.check_rounded
      : status=='fail' ? Icons.close_rounded : Icons.warning_amber_rounded;
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
      Container(width: 22, height: 22,
          decoration: BoxDecoration(color: _checkBg, shape: BoxShape.circle),
          child: Icon(_checkIcon, color: _checkColor, size: 12)),
      const SizedBox(width: 10),
      Expanded(child: Text(label, style: const TextStyle(
          fontSize: 12, fontWeight: FontWeight.w500, color: _textMain))),
      Text(detail, maxLines: 1, overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _detColor)),
    ])),
    if (!isLast) const Divider(height: 1, color: Color(0xFFF3F0FF)),
  ]);
}

class _SimilarSchemeRow extends StatelessWidget {
  final IconData icon; final Color iconBg, iconColor;
  final String title, subtitle;
  const _SimilarSchemeRow({required this.icon, required this.iconBg,
      required this.iconColor, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cardBorder, width: 1.5)),
    child: Row(children: [
      Container(width: 28, height: 28,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: iconColor, size: 14)),
      const SizedBox(width: 10),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: _textMain)),
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: _textSub)),
      ])),
      const Icon(Icons.chevron_right_rounded, color: Color(0xFFC4B5FD), size: 16),
    ]),
  );
}

// ─────────────────────────────────────────────
//  TAB 4 — DOCUMENTS  ← FIX: shows doc name + hint
// ─────────────────────────────────────────────
class _DocumentsTab extends StatelessWidget {
  final List<SchemeDocument> documents;
  const _DocumentsTab({required this.documents});

  String _status(SchemeDocument d, int i) {
    if (d.isOptional) return 'optional';
    if (i < 2) return 'uploaded'; // mock — replace with real vault check
    return 'missing';
  }

  IconData _icon(String name) {
    final d = name.toLowerCase();
    if (d.contains('aadhaar') || d.contains('identity')) return Icons.badge_outlined;
    if (d.contains('disability'))  return Icons.medical_services_outlined;
    if (d.contains('bank') || d.contains('passbook')) return Icons.account_balance_outlined;
    if (d.contains('income'))      return Icons.receipt_long_outlined;
    if (d.contains('residence') || d.contains('domicile')) return Icons.location_on_outlined;
    if (d.contains('enrollment') || d.contains('admission')) return Icons.school_outlined;
    if (d.contains('business'))    return Icons.business_outlined;
    return Icons.description_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final required = documents.where((d) => !d.isOptional).toList();
    final optional = documents.where((d) =>  d.isOptional).toList();
    int uploaded = 0;
    for (int i = 0; i < required.length; i++) {
      if (_status(required[i], i) == 'uploaded') uploaded++;
    }
    final missing   = required.length - uploaded;
    final readiness = required.isEmpty ? 0.0 : uploaded / required.length;

    return ListView(padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
      Row(children: [
        _MiniStat(value: '$uploaded', label: 'Uploaded', bg: _greenLight, textColor: _green),
        const SizedBox(width: 10),
        _MiniStat(value: '$missing',  label: 'Missing',  bg: _redLight,   textColor: _red),
        const SizedBox(width: 10),
        _MiniStat(value: '${optional.length}', label: 'Optional', bg: _purpleLight, textColor: _purple),
      ]),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cardBorder, width: 1.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            const Text('Document readiness', style: TextStyle(fontSize: 12,
                fontWeight: FontWeight.w600, color: _textMain)),
            Text('${(readiness * 100).round()}%', style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: _purple)),
          ]),
          const SizedBox(height: 8),
          ClipRRect(borderRadius: BorderRadius.circular(100),
            child: LinearProgressIndicator(value: readiness, backgroundColor: _purpleLight,
                valueColor: const AlwaysStoppedAnimation<Color>(_purple), minHeight: 5)),
          const SizedBox(height: 6),
          Text(missing > 0
              ? 'Upload $missing more document${missing > 1 ? 's' : ''} to apply'
              : 'All required documents ready!',
              style: const TextStyle(fontSize: 11, color: _textSub)),
        ]),
      ),
      const SizedBox(height: 12),
      _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const _CardHeader(icon: Icons.folder_outlined, iconBg: _purpleLight, iconColor: _purple,
            title: 'Required documents', subtitle: 'Must submit to complete application'),
        const SizedBox(height: 12),
        if (documents.isEmpty)
          const Text('No documents listed.', style: TextStyle(fontSize: 13, color: _textSub))
        else
          ...documents.asMap().entries.map((e) => _DocumentRow(
            icon  : _icon(e.value.name),
            name  : e.value.name,         // ← reads doc_name from Supabase
            hint  : e.value.hint,         // ← reads hint from Supabase
            status: _status(e.value, e.key),
            isLast: e.key == documents.length - 1,
          )),
      ])),
      const SizedBox(height: 12),
      GestureDetector(onTap: () {},
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 13),
          decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFC4B5FD), width: 1.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
            Icon(Icons.upload_file_rounded, color: _purple, size: 16), SizedBox(width: 8),
            Text('Upload missing documents',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _purple)),
          ]),
        )),
      if (optional.isNotEmpty) ...[
        const SizedBox(height: 12),
        _SectionCard(padding: const EdgeInsets.all(14),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _CardHeader(icon: Icons.info_outline_rounded, iconBg: _purpleLight,
                iconColor: _purple, title: 'Optional documents',
                subtitle: 'Speeds up processing if submitted'),
            const SizedBox(height: 12),
            ...optional.asMap().entries.map((e) => _DocumentRow(
              icon: _icon(e.value.name), name: e.value.name,
              hint: e.value.hint, status: 'optional',
              isLast: e.key == optional.length - 1)),
          ])),
      ],
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(13),
        decoration: BoxDecoration(color: const Color(0xFFF0F9FF),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFBAE6FD), width: 1.5)),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
          Icon(Icons.info_rounded, color: _blue, size: 15), SizedBox(width: 9),
          Expanded(child: Text('Files must be PDF or JPG, under 2MB each.',
              style: TextStyle(fontSize: 11, color: _blue, height: 1.5))),
        ]),
      ),
    ]);
  }
}

class _DocumentRow extends StatelessWidget {
  final IconData icon; final String name, status; final String? hint; final bool isLast;
  const _DocumentRow({required this.icon, required this.name,
      required this.status, required this.isLast, this.hint});
  Color get _iconBg    => status=='uploaded' ? _greenLight : status=='missing' ? _redLight  : _purpleLight;
  Color get _iconColor => status=='uploaded' ? _green      : status=='missing' ? _red       : _purple;
  String get _tagLabel => status=='uploaded' ? 'Uploaded'  : status=='missing' ? 'Missing'  : 'Optional';
  Color get _tagBg     => status=='uploaded' ? _greenLight : status=='missing' ? _redLight  : _purpleLight;
  Color get _tagColor  => status=='uploaded' ? _green      : status=='missing' ? _red       : _purple;
  @override
  Widget build(BuildContext context) => Column(children: [
    Padding(padding: const EdgeInsets.symmetric(vertical: 10), child: Row(children: [
      Container(width: 34, height: 34,
          decoration: BoxDecoration(color: _iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: _iconColor, size: 16)),
      const SizedBox(width: 12),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(name, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _textMain)),
        Text(hint ?? 'Original · Self-attested', maxLines: 1, overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10, color: _textSub)),
      ])),
      const SizedBox(width: 8),
      Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
          decoration: BoxDecoration(color: _tagBg, borderRadius: BorderRadius.circular(100)),
          child: Text(_tagLabel, style: TextStyle(fontSize: 10,
              fontWeight: FontWeight.w600, color: _tagColor))),
    ])),
    if (!isLast) const Divider(height: 1, color: Color(0xFFF3F0FF)),
  ]);
}

// ─────────────────────────────────────────────
//  TAB 5 — HOW TO APPLY
// ─────────────────────────────────────────────
class _HowToApplyTab extends StatelessWidget {
  final List<SchemeApplyStep> applySteps;
  final String? helpline;
  const _HowToApplyTab({required this.applySteps, this.helpline});

  String _stepStatus(int i) => i == 0 ? 'done' : i == 1 ? 'active' : 'pending';

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24), children: [
    _SectionCard(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _CardHeader(icon: Icons.timeline_rounded, iconBg: _purpleLight,
          iconColor: _purple, title: 'Application process'),
      const SizedBox(height: 16),
      if (applySteps.isEmpty)
        const Text('No steps available. Visit the official link to apply.',
            style: TextStyle(fontSize: 13, color: _textSub))
      else
        ...applySteps.asMap().entries.map((e) => _TimelineStep(
          title: e.value.title, sub: e.value.description,
          status: _stepStatus(e.key), isLast: e.key == applySteps.length - 1)),
    ])),
    if (helpline != null && helpline!.isNotEmpty) ...[
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: _purpleLight, borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFC4B5FD), width: 1.5)),
        child: Row(children: [
          Container(width: 36, height: 36,
              decoration: const BoxDecoration(color: _purple, shape: BoxShape.circle),
              child: const Icon(Icons.phone_rounded, color: Colors.white, size: 18)),
          const SizedBox(width: 12),
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('Need help applying?', style: TextStyle(fontSize: 13,
                fontWeight: FontWeight.w600, color: _textMain)),
            Text('Call: $helpline', style: const TextStyle(
                fontSize: 12, color: _purple, fontWeight: FontWeight.w500)),
          ]),
        ]),
      ),
    ],
  ]);
}

class _TimelineStep extends StatelessWidget {
  final String title, sub, status; final bool isLast;
  const _TimelineStep({required this.title, required this.sub,
      required this.status, required this.isLast});
  Color get _dotBg     => status=='done' ? _purple : Colors.white;
  Color get _dotBorder => status=='pending' ? const Color(0xFFE5E7EB) : _purple;
  Color get _badgeBg   => status=='done' ? _purpleLight : status=='active' ? _amberLight : const Color(0xFFF3F4F6);
  Color get _badgeColor=> status=='done' ? _purple : status=='active' ? _amber : _textSub;
  String get _label    => status=='done' ? 'Completed' : status=='active' ? 'In progress' : 'Pending';
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Column(children: [
        Container(width: 14, height: 14,
            decoration: BoxDecoration(color: _dotBg, shape: BoxShape.circle,
                border: Border.all(color: _dotBorder, width: 2)),
            child: status=='done' ? const Icon(Icons.check, color: Colors.white, size: 8) : null),
        if (!isLast) Expanded(child: Container(width: 2,
            margin: const EdgeInsets.symmetric(vertical: 4), color: _purpleLight)),
      ]),
      const SizedBox(width: 14),
      Expanded(child: Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 13,
              fontWeight: FontWeight.w600, color: _textMain)),
          const SizedBox(height: 2),
          Text(sub, style: const TextStyle(fontSize: 11, color: _textSub)),
          const SizedBox(height: 5),
          Container(padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: _badgeBg, borderRadius: BorderRadius.circular(100)),
              child: Text(_label, style: TextStyle(fontSize: 10,
                  fontWeight: FontWeight.w600, color: _badgeColor))),
        ]),
      )),
    ]),
  );
}