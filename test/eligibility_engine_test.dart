import 'package:flutter_test/flutter_test.dart';
import 'package:asha_sahyog/scheme_recommendation/eligibility_engine.dart';
import 'package:asha_sahyog/scheme_recommendation/user_eligibility_profile.dart';
import 'package:asha_sahyog/screens/scheme_details_screen.dart';

void main() {
  group('EligibilityEngine.evaluate', () {
    test('returns needsVerification when scheme eligibility is null', () {
      const user = UserEligibilityProfile(age: 25, disabilityPercent: 50);
      final result = EligibilityEngine.evaluate(user: user, eligibility: null);

      expect(result.status, EligibilityStatus.needsVerification);
      expect(result.checks.length, 1);
      expect(result.checks.first.passed, isNull);
    });

    test('returns eligible when user satisfies all criteria', () {
      const user = UserEligibilityProfile(
        age: 25,
        disabilityPercent: 50,
        annualIncome: 120000,
        hasAadhaar: true,
        hasBankAccount: true,
      );

      const criteria = SchemeEligibility(
        minAge: 18,
        maxAge: 60,
        minDisabilityPercent: 40,
        maxIncome: 250000,
        requiresAadhaar: true,
        requiresBankAccount: true,
      );

      final result = EligibilityEngine.evaluate(user: user, eligibility: criteria);

      expect(result.status, EligibilityStatus.eligible);
      expect(result.checks.every((c) => c.passed == true), isTrue);
    });

    test('returns notEligible when user is below minimum age', () {
      const user = UserEligibilityProfile(
        age: 16,
        disabilityPercent: 50,
      );

      const criteria = SchemeEligibility(
        minAge: 18,
      );

      final result = EligibilityEngine.evaluate(user: user, eligibility: criteria);

      expect(result.status, EligibilityStatus.notEligible);
      final ageCheck = result.checks.firstWhere((c) => c.label.contains('min 18'));
      expect(ageCheck.passed, isFalse);
    });

    test('returns notEligible when disability percentage is insufficient', () {
      const user = UserEligibilityProfile(
        age: 30,
        disabilityPercent: 30,
      );

      const criteria = SchemeEligibility(
        minDisabilityPercent: 40,
      );

      final result = EligibilityEngine.evaluate(user: user, eligibility: criteria);

      expect(result.status, EligibilityStatus.notEligible);
      final disCheck = result.checks.firstWhere((c) => c.label.contains('Disability percentage'));
      expect(disCheck.passed, isFalse);
    });

    test('returns needsVerification when data is missing but no failure has occurred', () {
      const user = UserEligibilityProfile(
        age: 25,
        disabilityPercent: 50,
        // annualIncome, hasAadhaar, hasBankAccount not set
      );

      const criteria = SchemeEligibility(
        minAge: 18,
        minDisabilityPercent: 40,
        maxIncome: 100000,
      );

      final result = EligibilityEngine.evaluate(user: user, eligibility: criteria);

      expect(result.status, EligibilityStatus.needsVerification);
    });

    test('returns notEligible when income exceeds limit even if other data is unknown', () {
      const user = UserEligibilityProfile(
        age: 25,
        annualIncome: 300000,
      );

      const criteria = SchemeEligibility(
        minAge: 18,
        maxIncome: 150000,
        requiresAadhaar: true, // user hasAadhaar is null
      );

      final result = EligibilityEngine.evaluate(user: user, eligibility: criteria);

      expect(result.status, EligibilityStatus.notEligible);
    });
  });
}
