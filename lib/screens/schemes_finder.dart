import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';
import '../l10n/app_strings.dart';
import '../theme/app_theme.dart';
import 'scheme_details_screen.dart';

// ─────────────────────────────────────────────
//  COLOURS  (mirrors scheme_details_screen.dart)
// ─────────────────────────────────────────────
const _purple      = Color(0xFF7C3AED);
const _purpleLight = Color(0xFFEDE9FE);
const _purpleMid   = Color(0xFFA855F7);
const _green       = Color(0xFF15803D);
const _greenLight  = Color(0xFFDCFCE7);
const _bg          = Color(0xFFFAF7FF);
const _cardBorder  = Color(0xFFEDE9FE);
const _textMain    = Color(0xFF1E1B2E);
const _textSub     = Color(0xFF6B7280);

// ─────────────────────────────────────────────
//  DATA MODEL  (move to lib/models/ later)
// ─────────────────────────────────────────────
class SchemeSummary {
  final String id;
  final String title;
  final String? category;
  final String? state;
  final String? summary;
  final dynamic amount;
  final bool active;

  const SchemeSummary({
    required this.id,
    required this.title,
    this.category,
    this.state,
    this.summary,
    this.amount,
    this.active = true,
  });

  factory SchemeSummary.fromJson(Map<String, dynamic> j, {String langCode = 'en'}) {
    String t = j['title'] as String? ?? '';
    String? s = j['summary'] as String?;
    
    if (langCode == 'hi') {
      t = j['title_hi'] as String? ?? t;
      if (t.isEmpty) t = j['title'] as String? ?? '';
      s = j['summary_hi'] as String? ?? s;
    } else if (langCode == 'mr') {
      t = j['title_mr'] as String? ?? t;
      if (t.isEmpty) t = j['title'] as String? ?? '';
      s = j['summary_mr'] as String? ?? s;
    }

    return SchemeSummary(
      id: j['id'] as String? ?? '',
      title: t,
      category: j['category'] as String?,
      state: j['state'] as String?,
      summary: s,
      amount: j['amount'],
      active: j['active'] as bool? ?? true,
    );
  }
}

// ─────────────────────────────────────────────
//  REPOSITORY
// ─────────────────────────────────────────────
class _SchemeRepository {
  final _db = Supabase.instance.client;

  /// Fetch the scheme list (lightweight — only columns needed for cards).
  Future<List<SchemeSummary>> getSchemes({
    String? category,
    String? state,
    String? search,
    String langCode = 'en',
  }) async {
    var query = _db
        .from('schemes')
        .select('*')
        .eq('active', true);

    if (category != null && category != 'All') {
      query = query.eq('category', category);
    }
    if (state != null && state != 'All') {
      query = query.eq('state', state);
    }
    if (search != null && search.trim().isNotEmpty) {
      // Search by title only since translated columns don't exist in DB
      query = query.or('title.ilike.%${search.trim()}%');
    }

    final data = await query.order('title');
    return (data as List)
        .map((j) => SchemeSummary.fromJson(j as Map<String, dynamic>, langCode: langCode))
        .toList();
  }

  /// Fetch one scheme with ALL related data for the details screen.
  Future<SchemeDetail> getSchemeById(String id, {String langCode = 'en'}) async {
    final json = await _db.from('schemes').select('''
      *,
      scheme_eligibility(*),
      scheme_benefits(*),
      scheme_documents(*),
      scheme_apply_steps(*),
      scheme_tags(*),
      scheme_similar(*)
    ''').eq('id', id).single();

    return SchemeDetail.fromJson(json as Map<String, dynamic>, langCode: langCode);
  }
}

// ─────────────────────────────────────────────
//  SCHEME FINDER SCREEN
// ─────────────────────────────────────────────
class SchemesFinder extends StatefulWidget {
  final VoidCallback onBack;
  const SchemesFinder({super.key, required this.onBack});

  @override
  State<SchemesFinder> createState() => _SchemesFinderState();
}

class _SchemesFinderState extends State<SchemesFinder> {
  final _repo             = _SchemeRepository();
  final _searchCtrl       = TextEditingController();
  final _scrollCtrl       = ScrollController();

  List<SchemeSummary> _schemes = [];
  bool _loading = true;
  String? _error;

  String _selectedCategory = 'All';
  String _selectedState    = 'All';

  final Set<String> _savedIds = {};

  final _categories = [
    'All', 'Financial Assistance', 'Education',
    'Employment', 'Healthcare', 'Housing',
  ];

  final _states = [
    'All', 'Maharashtra', 'Delhi', 'Karnataka', 'Tamil Nadu', 'Gujarat',
  ];

  String _translateCategory(String cat) {
    if (cat == 'All') return AppStrings.t(context, 'schemes_finder_all', 'All');
    if (cat == 'Financial Assistance') return AppStrings.t(context, 'schemes_finder_financial', 'Financial');
    if (cat == 'Education') return AppStrings.t(context, 'schemes_finder_education', 'Education');
    if (cat == 'Employment') return AppStrings.t(context, 'schemes_finder_employment', 'Employment');
    if (cat == 'Healthcare') return AppStrings.t(context, 'schemes_finder_health', 'Health');
    if (cat == 'Housing') return AppStrings.t(context, 'schemes_finder_housing', 'Housing');
    return cat;
  }

  String _translateState(String state) {
    if (state == 'All') return AppStrings.t(context, 'schemes_finder_all', 'All');
    return AppStrings.t(context, 'state_${state.toLowerCase().replaceAll(' ', '_')}', state);
  }

  // ── lifecycle ─────────────────────────────────
  @override
  void initState() {
    super.initState();
    _loadSchemes();
    _searchCtrl.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  // ── data ──────────────────────────────────────
  Future<void> _loadSchemes() async {
    if (!mounted) return;
    setState(() { _loading = true; _error = null; });
    try {
      final langCode = Provider.of<LanguageProvider>(context, listen: false).langCode;
      final data = await _repo.getSchemes(
        category: _selectedCategory == 'All' ? null : _selectedCategory,
        state   : _selectedState    == 'All' ? null : _selectedState,
        search  : _searchCtrl.text,
        langCode: langCode,
      );
      if (mounted) setState(() { _schemes = data; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  // 400ms debounce — only fires after user stops typing
  DateTime _lastType = DateTime.now();
  void _onSearchChanged() {
    _lastType = DateTime.now();
    final captured = _lastType;
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted && captured == _lastType) _loadSchemes();
    });
  }

  // ── navigation ────────────────────────────────
  Future<void> _openDetails(String schemeId) async {
    // Show a small loading indicator without blocking the whole screen
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
      final scheme = await _repo.getSchemeById(schemeId, langCode: langCode);
      overlay.remove();
      if (!mounted) return;
      Navigator.push(
        context,
        PageRouteBuilder(
          pageBuilder: (_, anim, __) =>
              SchemeDetailsScreen(scheme: scheme),
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
      overlay.remove();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not load scheme: $e'),
          backgroundColor: const Color(0xFFDC2626),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────
  //  BUILD
  // ─────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      color: Colors.white,
      child: Column(
        children: [
          // Top nav row
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 12, 16, 0),
            child: Row(
              children: [
                IconButton(
                  onPressed: widget.onBack,
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: _textMain, size: 18),
                ),
                Expanded(
                  child: Text(
                    AppStrings.t(context, 'schemes_finder_title', 'Scheme Finder'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {}, // TODO: hook up voice search
                  child: Container(
                    width: 36, height: 36,
                    decoration: const BoxDecoration(
                      color: _purple,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.mic_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: _cardBorder, width: 1.5),
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  const Icon(Icons.search_rounded,
                      color: Color(0xFFA78BFA), size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _searchCtrl,
                      style: const TextStyle(
                          fontSize: 14, color: _textMain),
                      decoration: InputDecoration(
                        hintText: AppStrings.t(context, 'schemes_finder_search', 'Search disability schemes…'),
                        hintStyle: const TextStyle(color: _textSub, fontSize: 14),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  if (_searchCtrl.text.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _searchCtrl.clear();
                        _loadSchemes();
                      },
                      child: const Padding(
                        padding: EdgeInsets.all(12),
                        child: Icon(Icons.close_rounded,
                            color: _textSub, size: 18),
                      ),
                    )
                  else
                    const SizedBox(width: 14),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Category filter chips
          SizedBox(
            height: 36,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              itemBuilder: (_, i) {
                final cat      = _categories[i];
                final selected = cat == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedCategory = cat);
                      _loadSchemes();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 7),
                      decoration: BoxDecoration(
                        color: selected ? _purple : Colors.white,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected
                              ? Colors.transparent
                              : _cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _translateCategory(cat),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: selected ? Colors.white : _textSub,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // State filter chips
          SizedBox(
            height: 34,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
              itemCount: _states.length,
              itemBuilder: (_, i) {
                final state    = _states[i];
                final selected = state == _selectedState;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      setState(() => _selectedState = state);
                      _loadSchemes();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 3),
                      decoration: BoxDecoration(
                        color: selected
                            ? _purpleLight
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(100),
                        border: Border.all(
                          color: selected ? _purple : _cardBorder,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        _translateState(state),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: selected ? _purple : _textSub,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),

          // Bottom border
          const Divider(height: 1, color: _cardBorder),
        ],
      ),
    );
  }

  // ── Body dispatcher ───────────────────────────
  Widget _buildBody() {
    if (_loading) return _buildShimmer();
    if (_error != null) return _buildError();
    if (_schemes.isEmpty) return _buildEmpty();
    return _buildList();
  }

  // ── List ──────────────────────────────────────
  Widget _buildList() {
    return RefreshIndicator(
      color: _purple,
      onRefresh: _loadSchemes,
      child: ListView.builder(
        controller: _scrollCtrl,
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 100),
        itemCount: _schemes.length + 1,
        itemBuilder: (_, i) {
          if (i == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_schemes.length} ${AppStrings.t(context, 'schemes_found', 'schemes found')}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textSub,
                    letterSpacing: 0.3),
              ),
            );
          }
          final scheme = _schemes[i - 1];
          final id = scheme.id;
          return _SchemeCard(
            scheme: scheme,
            isSaved: _savedIds.contains(id),
            onTap: () => _openDetails(id),
            onSave: () => setState(() => _savedIds.contains(id)
                ? _savedIds.remove(id)
                : _savedIds.add(id)),
          );
        },
      ),
    );
  }

  // ── Shimmer ───────────────────────────────────
  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
      itemCount: 5,
      itemBuilder: (_, __) => const _ShimmerCard(),
    );
  }

  // ── Error state ───────────────────────────────
  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.wifi_off_rounded, color: _textSub, size: 48),
            const SizedBox(height: 16),
            Text(AppStrings.t(context, 'error_loading_schemes', 'Could not load schemes'),
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600, color: _textMain)),
            const SizedBox(height: 8),
            Text(_error ?? 'Unknown error',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 13, color: _textSub)),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: _loadSchemes,
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 12),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_purple, _purpleMid]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(AppStrings.t(context, 'try_again', 'Try again'),
                    style: const TextStyle(color: Colors.white,
                        fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Empty state ───────────────────────────────
  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: const BoxDecoration(
                  color: _purpleLight, shape: BoxShape.circle),
              child: const Icon(Icons.search_off_rounded,
                  color: _purple, size: 36),
            ),
            const SizedBox(height: 16),
            Text(AppStrings.t(context, 'schemes_finder_no_results', 'No schemes found'),
                style: const TextStyle(fontSize: 16,
                    fontWeight: FontWeight.w600, color: _textMain)),
            const SizedBox(height: 8),
            Text(AppStrings.t(context, 'try_changing_search', 'Try changing your search or filters'),
                style: const TextStyle(fontSize: 13, color: _textSub)),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                _searchCtrl.clear();
                setState(() {
                  _selectedCategory = 'All';
                  _selectedState    = 'All';
                });
                _loadSchemes();
              },
              child: Text(AppStrings.t(context, 'clear_all_filters', 'Clear all filters'),
                  style: const TextStyle(color: _purple,
                      fontWeight: FontWeight.w600, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  SCHEME CARD
// ─────────────────────────────────────────────
class _SchemeCard extends StatelessWidget {
  final SchemeSummary scheme;
  final bool isSaved;
  final VoidCallback onTap;
  final VoidCallback onSave;

  const _SchemeCard({
    required this.scheme,
    required this.isSaved,
    required this.onTap,
    required this.onSave,
  });

  Color _categoryColor(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('financial')) return _purple;
    if (c.contains('education')) return const Color(0xFF1D4ED8);
    if (c.contains('employ')) return _green;
    if (c.contains('health')) return const Color(0xFFBE185D);
    if (c.contains('housing')) return const Color(0xFFB45309);
    return _purple;
  }

  Color _categoryBg(String? cat) {
    final c = (cat ?? '').toLowerCase();
    if (c.contains('financial')) return _purpleLight;
    if (c.contains('education')) return const Color(0xFFDBEAFE);
    if (c.contains('employ')) return _greenLight;
    if (c.contains('health')) return const Color(0xFFFCE7F3);
    if (c.contains('housing')) return const Color(0xFFFEF9C3);
    return _purpleLight;
  }

  @override
  Widget build(BuildContext context) {
    final title = scheme.title;
    final category = scheme.category ?? '';
    final state = scheme.state ?? '';
    final summary = scheme.summary ?? '';
    final amount = scheme.amount;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _cardBorder, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Card body
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge row + bookmark
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            if (category.isNotEmpty)
                              _Badge(
                                label: category,
                                color: _categoryColor(category),
                                bg   : _categoryBg(category),
                              ),
                            if (state.isNotEmpty)
                              _Badge(
                                label: state,
                                color: _green,
                                bg   : _greenLight,
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: onSave,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 32, height: 32,
                          decoration: BoxDecoration(
                            color: isSaved ? _purpleLight : const Color(0xFFFAF7FF),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: _cardBorder, width: 1.5),
                          ),
                          child: Icon(
                            isSaved ? Icons.bookmark_rounded
                                    : Icons.bookmark_border_rounded,
                            color: _purple, size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Title
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: _textMain,
                      height: 1.3,
                    ),
                  ),

                  // Summary
                  if (summary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      summary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13, color: _textSub, height: 1.5),
                    ),
                  ],

                  // Amount pill
                  if (amount != null) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _purpleLight,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '₹$amount/month',
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: _purple,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Divider
            const Divider(height: 1, color: Color(0xFFF3F0FF)),

            // Footer
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
              child: Row(
                children: [
                  // Read aloud button
                  GestureDetector(
                    onTap: () {}, // TODO: TTS
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 7.5),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDF2FA),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: const Color(0xFFF9A8D4), width: 1.5),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.volume_up_rounded,
                              color: Color(0xFFBE185D), size: 13),
                          const SizedBox(width: 5),
                          Text(AppStrings.t(context, 'read_aloud', 'Read Aloud'),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: Color(0xFFBE185D))),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),

                  // View details button
                  GestureDetector(
                    onTap: onTap,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: _purple,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(AppStrings.t(context, 'view_details', 'View Details'),
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                          const SizedBox(width: 4),
                          const Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 13),
                        ],
                      ),
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
}

// ─────────────────────────────────────────────
//  BADGE
// ─────────────────────────────────────────────
class _Badge extends StatelessWidget {
  final String label;
  final Color  color, bg;
  const _Badge({required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(100)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      const SizedBox(width: 4),
      Text(label, style: TextStyle(fontSize: 11,
          fontWeight: FontWeight.w500, color: color)),
    ]),
  );
}

// ─────────────────────────────────────────────
//  SHIMMER CARD
// ─────────────────────────────────────────────
class _ShimmerCard extends StatefulWidget {
  const _ShimmerCard();
  @override
  State<_ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<_ShimmerCard>
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
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final g = LinearGradient(
          begin: Alignment(_anim.value - 1, 0),
          end  : Alignment(_anim.value,     0),
          colors: const [
            Color(0xFFF3F0FF), Color(0xFFE9E4FF), Color(0xFFF3F0FF),
          ],
        );
        return Container(
          margin: const EdgeInsets.only(bottom: 14),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _cardBorder, width: 1.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _box(g, width: 100, height: 20),
            const SizedBox(height: 12),
            _box(g, width: double.infinity, height: 16),
            const SizedBox(height: 6),
            _box(g, width: 220, height: 14),
            const SizedBox(height: 6),
            _box(g, width: 160, height: 14),
            const SizedBox(height: 14),
            _box(g, width: 80, height: 24, radius: 100),
          ]),
        );
      },
    );
  }

  Widget _box(LinearGradient g,
      {required double width, required double height, double radius = 8}) =>
      Container(
        width: width, height: height,
        decoration: BoxDecoration(
            gradient: g, borderRadius: BorderRadius.circular(radius)),
      );
}