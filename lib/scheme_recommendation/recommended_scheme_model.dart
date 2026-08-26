import '../screens/schemes_finder.dart';
import 'eligibility_engine.dart';

/// A scheme paired with its eligibility evaluation result and recommendation score.
class RecommendedScheme {
  /// Lightweight scheme summary used for card display.
  final SchemeSummary summary;

  /// Overall eligibility status for this user.
  final EligibilityStatus status;

  /// Per-rule eligibility check results, shown in the "Why recommended" section.
  final List<EligibilityCheckResult> checks;

  /// Recommendation score 0–100. Higher = stronger match.
  /// Scheme cards are sorted by this score descending (not-eligible always last).
  final int score;

  const RecommendedScheme({
    required this.summary,
    required this.status,
    required this.checks,
    required this.score,
  });
}
