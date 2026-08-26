// Model: UserEligibilityProfile
// Assembled from the Supabase `profiles` table (read-only)
// and optional fields stored in SharedPreferences on device.
class UserEligibilityProfile {
  /// Age in years, derived from the `dob` field in profiles.
  final int? age;

  /// Disability type string from `disability_type` in profiles.
  final String? disabilityType;

  /// Disability percentage (int), parsed from `disability_percentage` in profiles.
  final int? disabilityPercent;

  /// Annual family income — stored in SharedPreferences (user-provided).
  final int? annualIncome;

  /// State extracted from the free-text `address` field in profiles.
  final String? state;

  /// Whether the user has an Aadhaar card — stored in SharedPreferences.
  final bool? hasAadhaar;

  /// Whether the user has a bank account — stored in SharedPreferences.
  final bool? hasBankAccount;

  const UserEligibilityProfile({
    this.age,
    this.disabilityType,
    this.disabilityPercent,
    this.annualIncome,
    this.state,
    this.hasAadhaar,
    this.hasBankAccount,
  });

  /// True if at least some profile data is available to make recommendations.
  bool get hasAnyData =>
      age != null || disabilityType != null || disabilityPercent != null;

  /// Returns the list of optional eligibility fields not yet provided.
  /// These are the fields stored in SharedPreferences.
  List<String> get missingEligibilityFields {
    final missing = <String>[];
    if (annualIncome == null) missing.add('Annual Family Income');
    if (hasAadhaar == null) missing.add('Aadhaar Card availability');
    if (hasBankAccount == null) missing.add('Bank Account availability');
    return missing;
  }
}
