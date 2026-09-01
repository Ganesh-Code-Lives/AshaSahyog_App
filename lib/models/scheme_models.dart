// lib/models/scheme_models.dart
//
// Single source of truth for scheme-related data-transfer objects.
// Previously SchemeSummary was duplicated in:
//   - lib/screens/home_screen.dart (simplified, int? amount, no langCode)
//   - lib/screens/schemes_finder.dart (full, dynamic amount, multilingual)
// Both are now replaced by this canonical version.

/// Lightweight scheme object used in list views, home dashboard cards,
/// and the recommendation engine. Only carries columns needed for display.
class SchemeSummary {
  final String id;
  final String title;
  final String? category;
  final String? state;
  final String? summary;

  /// Kept as [dynamic] because Supabase may return an int or null depending
  /// on the column type. Cast to int where needed: `(amount as int?) ?? 0`.
  final dynamic amount;

  /// Whether the scheme is active/published on the backend.
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

  /// Deserialises a Supabase row into a [SchemeSummary].
  ///
  /// Pass [langCode] ('en', 'hi', or 'mr') to pick the correct localised
  /// title / summary columns when they exist in the database.
  factory SchemeSummary.fromJson(
    Map<String, dynamic> j, {
    String langCode = 'en',
  }) {
    // Start with the English values as fallback
    String title = j['title'] as String? ?? '';
    String? summary = j['summary'] as String?;

    if (langCode == 'hi') {
      final hiTitle = j['title_hi'] as String?;
      if (hiTitle != null && hiTitle.isNotEmpty) title = hiTitle;
      summary = j['summary_hi'] as String? ?? summary;
    } else if (langCode == 'mr') {
      final mrTitle = j['title_mr'] as String?;
      if (mrTitle != null && mrTitle.isNotEmpty) title = mrTitle;
      summary = j['summary_mr'] as String? ?? summary;
    }

    return SchemeSummary(
      id: j['id'] as String? ?? '',
      title: title,
      category: j['category'] as String?,
      state: j['state'] as String?,
      summary: summary,
      amount: j['amount'],
      active: j['active'] as bool? ?? true,
    );
  }
}
