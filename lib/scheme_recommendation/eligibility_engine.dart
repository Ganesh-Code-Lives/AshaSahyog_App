import '../screens/scheme_details_screen.dart';
import 'user_eligibility_profile.dart';

/// The three possible eligibility states for a scheme.
/// Critically, [needsVerification] is used whenever required information
/// is missing — we never falsely claim [eligible] with incomplete data.
enum EligibilityStatus { eligible, notEligible, needsVerification }

/// Result of evaluating a single eligibility rule.
class EligibilityCheckResult {
  /// Short label shown in the UI, e.g. "Age requirement (min 18 years)".
  final String label;

  /// true = rule satisfied (✓), false = rule violated (✗), null = unknown (?).
  final bool? passed;

  /// User-friendly explanation of the result.
  final String reason;

  const EligibilityCheckResult({
    required this.label,
    required this.passed,
    required this.reason,
  });
}

/// Aggregate result returned by [EligibilityEngine.evaluate].
class EligibilityResult {
  final EligibilityStatus status;
  final List<EligibilityCheckResult> checks;

  const EligibilityResult({required this.status, required this.checks});
}

/// Pure Dart service — no Flutter / UI dependencies.
/// Evaluates one scheme's eligibility criteria against a user profile,
/// returning an [EligibilityResult] with per-rule explanations.
class EligibilityEngine {
  EligibilityEngine._();

  static EligibilityResult evaluate({
    required UserEligibilityProfile user,
    required SchemeEligibility? eligibility,
  }) {
    // No criteria recorded → cannot determine eligibility
    if (eligibility == null) {
      return const EligibilityResult(
        status: EligibilityStatus.needsVerification,
        checks: [
          EligibilityCheckResult(
            label: 'Eligibility criteria',
            passed: null,
            reason: 'No eligibility criteria are defined for this scheme — '
                'please verify eligibility directly with the scheme authority.',
          ),
        ],
      );
    }

    final checks = <EligibilityCheckResult>[];
    bool hasFailure = false;
    bool hasUnknown = false;

    // ── 1. Minimum age ────────────────────────────
    final minAge = eligibility.minAge;
    if (minAge != null && minAge > 0) {
      if (user.age == null) {
        checks.add(EligibilityCheckResult(
          label: 'Age requirement (min $minAge years)',
          passed: null,
          reason: 'Date of birth is not recorded in your profile — age could not be verified.',
        ));
        hasUnknown = true;
      } else if (user.age! < minAge) {
        checks.add(EligibilityCheckResult(
          label: 'Age requirement (min $minAge years)',
          passed: false,
          reason: 'Your age (${user.age} years) is below the minimum required age of $minAge years.',
        ));
        hasFailure = true;
      } else {
        checks.add(EligibilityCheckResult(
          label: 'Age requirement (min $minAge years)',
          passed: true,
          reason: 'Age requirement satisfied (you are ${user.age} years old).',
        ));
      }
    }

    // ── 2. Maximum age ────────────────────────────
    final maxAge = eligibility.maxAge;
    if (maxAge != null && maxAge > 0) {
      if (user.age == null) {
        checks.add(EligibilityCheckResult(
          label: 'Age requirement (max $maxAge years)',
          passed: null,
          reason: 'Date of birth is not recorded in your profile — age could not be verified.',
        ));
        hasUnknown = true;
      } else if (user.age! > maxAge) {
        checks.add(EligibilityCheckResult(
          label: 'Age requirement (max $maxAge years)',
          passed: false,
          reason: 'Your age (${user.age} years) exceeds the maximum age limit of $maxAge years for this scheme.',
        ));
        hasFailure = true;
      } else {
        checks.add(EligibilityCheckResult(
          label: 'Age requirement (max $maxAge years)',
          passed: true,
          reason: 'Age requirement satisfied (you are ${user.age} years old).',
        ));
      }
    }

    // ── 3. Minimum disability percentage ──────────
    final minPercent = eligibility.minDisabilityPercent;
    if (minPercent != null && minPercent > 0) {
      if (user.disabilityPercent == null) {
        checks.add(EligibilityCheckResult(
          label: 'Disability percentage (min $minPercent%)',
          passed: null,
          reason: 'Disability percentage is not recorded in your profile — cannot verify this requirement.',
        ));
        hasUnknown = true;
      } else if (user.disabilityPercent! < minPercent) {
        checks.add(EligibilityCheckResult(
          label: 'Disability percentage (min $minPercent%)',
          passed: false,
          reason: 'Your recorded disability percentage (${user.disabilityPercent}%) '
              'is below the minimum required percentage of $minPercent%.',
        ));
        hasFailure = true;
      } else {
        checks.add(EligibilityCheckResult(
          label: 'Disability percentage (min $minPercent%)',
          passed: true,
          reason: 'Disability percentage requirement satisfied '
              '(your percentage: ${user.disabilityPercent}%).',
        ));
      }
    }

    // ── 4. Maximum annual income ──────────────────
    final maxIncome = eligibility.maxIncome;
    if (maxIncome != null && maxIncome > 0) {
      if (user.annualIncome == null) {
        checks.add(EligibilityCheckResult(
          label: 'Income requirement (max ₹$maxIncome/year)',
          passed: null,
          reason: 'Annual family income has not been provided — cannot verify this requirement.',
        ));
        hasUnknown = true;
      } else if (user.annualIncome! > maxIncome) {
        checks.add(EligibilityCheckResult(
          label: 'Income requirement (max ₹$maxIncome/year)',
          passed: false,
          reason: 'Your annual family income (₹${user.annualIncome}) '
              'exceeds the maximum income limit of ₹$maxIncome/year for this scheme.',
        ));
        hasFailure = true;
      } else {
        checks.add(EligibilityCheckResult(
          label: 'Income requirement (max ₹$maxIncome/year)',
          passed: true,
          reason: 'Income requirement satisfied.',
        ));
      }
    }

    // ── 5. State residency ────────────────────────
    final requiresResidency = eligibility.requiresResidency ?? false;
    final residencyState = eligibility.residencyState;
    if (requiresResidency && residencyState != null && residencyState.isNotEmpty) {
      if (user.state == null) {
        checks.add(EligibilityCheckResult(
          label: '$residencyState residency required',
          passed: null,
          reason: 'Your state could not be determined from your recorded address — '
              'residency could not be verified.',
        ));
        hasUnknown = true;
      } else {
        final userStateLower = user.state!.toLowerCase();
        final schemeStateLower = residencyState.toLowerCase();
        final matches = userStateLower.contains(schemeStateLower) ||
            schemeStateLower.contains(userStateLower);
        if (!matches) {
          checks.add(EligibilityCheckResult(
            label: '$residencyState residency required',
            passed: false,
            reason: 'This scheme requires residency in $residencyState. '
                'Your recorded state is ${user.state}.',
          ));
          hasFailure = true;
        } else {
          checks.add(EligibilityCheckResult(
            label: '$residencyState residency required',
            passed: true,
            reason: 'Residency requirement satisfied.',
          ));
        }
      }
    }

    // ── 6. Aadhaar ────────────────────────────────
    final requiresAadhaar = eligibility.requiresAadhaar ?? false;
    if (requiresAadhaar) {
      if (user.hasAadhaar == null) {
        checks.add(const EligibilityCheckResult(
          label: 'Aadhaar card required',
          passed: null,
          reason: 'Aadhaar availability has not been provided — cannot verify this requirement.',
        ));
        hasUnknown = true;
      } else if (!user.hasAadhaar!) {
        checks.add(const EligibilityCheckResult(
          label: 'Aadhaar card required',
          passed: false,
          reason: 'This scheme requires an Aadhaar card, which you have indicated you do not have.',
        ));
        hasFailure = true;
      } else {
        checks.add(const EligibilityCheckResult(
          label: 'Aadhaar card required',
          passed: true,
          reason: 'Aadhaar requirement satisfied.',
        ));
      }
    }

    // ── 7. Bank account ───────────────────────────
    final requiresBank = eligibility.requiresBankAccount ?? false;
    if (requiresBank) {
      if (user.hasBankAccount == null) {
        checks.add(const EligibilityCheckResult(
          label: 'Bank account required',
          passed: null,
          reason: 'Bank account availability has not been provided — cannot verify this requirement.',
        ));
        hasUnknown = true;
      } else if (!user.hasBankAccount!) {
        checks.add(const EligibilityCheckResult(
          label: 'Bank account required',
          passed: false,
          reason: 'This scheme requires a bank account, which you have indicated you do not have.',
        ));
        hasFailure = true;
      } else {
        checks.add(const EligibilityCheckResult(
          label: 'Bank account required',
          passed: true,
          reason: 'Bank account requirement satisfied.',
        ));
      }
    }

    // ── Determine overall status ──────────────────
    // If no checks were applicable, mark as needs-verification
    if (checks.isEmpty) {
      return EligibilityResult(
        status: EligibilityStatus.needsVerification,
        checks: [
          const EligibilityCheckResult(
            label: 'General eligibility',
            passed: null,
            reason: 'No specific eligibility rules to evaluate — '
                'please verify eligibility with the scheme authority.',
          ),
        ],
      );
    }

    final EligibilityStatus status;
    if (hasFailure) {
      status = EligibilityStatus.notEligible;
    } else if (hasUnknown) {
      // Never claim eligible when any required check is unknown
      status = EligibilityStatus.needsVerification;
    } else {
      status = EligibilityStatus.eligible;
    }

    return EligibilityResult(status: status, checks: checks);
  }
}
