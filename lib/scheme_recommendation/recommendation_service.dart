import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/scheme_details_screen.dart';
import '../models/scheme_models.dart'; // canonical SchemeSummary
import 'user_eligibility_profile.dart';
import 'eligibility_engine.dart';
import 'recommended_scheme_model.dart';

class RecommendationService {
  final _db = Supabase.instance.client;

  static final List<String> _indianStates = [
    'Andhra Pradesh', 'Arunachal Pradesh', 'Assam', 'Bihar', 'Chhattisgarh',
    'Goa', 'Gujarat', 'Haryana', 'Himachal Pradesh', 'Jharkhand', 'Karnataka',
    'Kerala', 'Madhya Pradesh', 'Maharashtra', 'Manipur', 'Meghalaya', 'Mizoram',
    'Nagaland', 'Odisha', 'Punjab', 'Rajasthan', 'Sikkim', 'Tamil Nadu',
    'Telangana', 'Tripura', 'Uttar Pradesh', 'Uttarakhand', 'West Bengal',
    'Delhi', 'Jammu and Kashmir', 'Ladakh', 'Puducherry', 'Chandigarh',
  ];

  static String? _extractStateFromAddress(String? address) {
    if (address == null || address.trim().isEmpty) return null;
    final lower = address.toLowerCase();
    for (final s in _indianStates) {
      if (lower.contains(s.toLowerCase())) {
        return s;
      }
    }
    if (lower.contains('mumbai') || lower.contains('pune') || lower.contains('nagpur')) return 'Maharashtra';
    if (lower.contains('bangalore') || lower.contains('bengaluru') || lower.contains('mysore')) return 'Karnataka';
    if (lower.contains('chennai') || lower.contains('coimbatore')) return 'Tamil Nadu';
    if (lower.contains('hyderabad')) return 'Telangana';
    if (lower.contains('kolkata') || lower.contains('calcutta')) return 'West Bengal';
    if (lower.contains('new delhi') || lower.contains('ncr')) return 'Delhi';
    if (lower.contains('ahmedabad') || lower.contains('surat')) return 'Gujarat';
    if (lower.contains('jaipur')) return 'Rajasthan';
    if (lower.contains('lucknow') || lower.contains('kanpur') || lower.contains('noida')) return 'Uttar Pradesh';

    return address.trim();
  }

  /// Fetch user profile from Supabase and SharedPreferences
  Future<UserEligibilityProfile> getUserProfile() async {
    final user = _db.auth.currentUser;
    int? age;
    String? disType;
    int? disPercent;
    String? state;

    final userMeta = user?.userMetadata ?? {};

    if (user != null) {
      final data = await _db.from('profiles').select().eq('id', user.id).maybeSingle();
      if (data != null) {
        // Calculate age from dob
        final dobStr = data['dob'] as String?;
        if (dobStr != null && dobStr.isNotEmpty) {
          try {
            final dob = DateTime.parse(dobStr);
            final now = DateTime.now();
            age = now.year - dob.year;
            if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) {
              age--;
            }
          } catch (_) {}
        }
        disType = data['disability_type'] as String?;
        final dpStr = data['disability_percentage'] as String?;
        if (dpStr != null && dpStr.isNotEmpty) {
          disPercent = int.tryParse(dpStr.replaceAll('%', '').trim());
        }
        final rawAddress = data['address'] as String?;
        state = _extractStateFromAddress(rawAddress);
      }
    }

    // Load local optional prefs
    final prefs = await SharedPreferences.getInstance();
    int? income = prefs.getInt('annualIncome');
    bool? hasAadhaar = prefs.getBool('hasAadhaar');
    bool? hasBankAccount = prefs.getBool('hasBankAccount');

    // Cloud fallback / cross-platform sync if local is null
    if (income == null && userMeta['annual_income'] != null) {
      income = (userMeta['annual_income'] as num?)?.toInt();
      if (income != null) await prefs.setInt('annualIncome', income);
    }
    if (hasAadhaar == null && userMeta['has_aadhaar'] != null) {
      hasAadhaar = userMeta['has_aadhaar'] as bool?;
      if (hasAadhaar != null) await prefs.setBool('hasAadhaar', hasAadhaar);
    }
    if (hasBankAccount == null && userMeta['has_bank_account'] != null) {
      hasBankAccount = userMeta['has_bank_account'] as bool?;
      if (hasBankAccount != null) await prefs.setBool('hasBankAccount', hasBankAccount);
    }

    // Cross-reference with Document Vault (both local & cloud metadata)
    final vaultRaw = prefs.getStringList('vault_documents') ?? [];
    bool hasAadhaarInVault = false;
    for (final s in vaultRaw) {
      try {
        final doc = json.decode(s) as Map<String, dynamic>;
        final title = (doc['title'] as String? ?? '').toLowerCase();
        final fileName = (doc['fileName'] as String? ?? '').toLowerCase();
        if (title.contains('aadhaar') || fileName.contains('aadhaar') ||
            title.contains('aadhar') || fileName.contains('aadhar')) {
          hasAadhaarInVault = true;
          break;
        }
      } catch (_) {}
    }

    if (hasAadhaarInVault) {
      hasAadhaar = true;
    }

    return UserEligibilityProfile(
      age: age,
      disabilityType: disType,
      disabilityPercent: disPercent,
      annualIncome: income,
      state: state,
      hasAadhaar: hasAadhaar,
      hasBankAccount: hasBankAccount,
    );
  }

  /// Calculates a score out of 100 based on criteria evaluation
  int _calculateScore(EligibilityResult result, SchemeDetail detail, UserEligibilityProfile user) {
    if (result.status == EligibilityStatus.notEligible) {
      final hasFailures = result.checks.any((c) => c.passed == false);
      if (hasFailures) return 0;
    }

    final totalChecks = result.checks.length;
    if (totalChecks == 0) {
      if (result.status == EligibilityStatus.eligible) return 100;
      if (result.status == EligibilityStatus.needsVerification) return 50;
      return 0;
    }

    final passedChecks = result.checks.where((c) => c.passed == true).length;
    final score = ((passedChecks / totalChecks) * 100).round();
    return score.clamp(0, 100);
  }

  /// Calculates the match score for a single scheme against a user profile
  int calculateSchemeScore({
    required SchemeDetail detail,
    required UserEligibilityProfile user,
  }) {
    final result = EligibilityEngine.evaluate(
      user: user,
      eligibility: detail.eligibility,
    );
    return _calculateScore(result, detail, user);
  }

  /// Evaluates both eligibility result and numeric score for a scheme
  ({EligibilityResult result, int score}) evaluateScheme({
    required SchemeDetail detail,
    required UserEligibilityProfile user,
  }) {
    final result = EligibilityEngine.evaluate(
      user: user,
      eligibility: detail.eligibility,
    );
    final score = _calculateScore(result, detail, user);
    return (result: result, score: score);
  }

  /// Get personalized recommendations
  Future<List<RecommendedScheme>> getRecommendations({String langCode = 'en'}) async {
    final user = await getUserProfile();
    
    // Fetch all active schemes with eligibility criteria
    final response = await _db.from('schemes').select('''
      *,
      scheme_eligibility(*),
      scheme_tags(*)
    ''').eq('active', true);

    final recommendations = <RecommendedScheme>[];

    for (final row in response as List) {
      final j = row as Map<String, dynamic>;
      // We parse just enough of SchemeDetail to evaluate eligibility and get summary
      final detail = SchemeDetail.fromJson(j, langCode: langCode);
      final summary = SchemeSummary.fromJson(j, langCode: langCode);

      final result = EligibilityEngine.evaluate(
        user: user,
        eligibility: detail.eligibility,
      );

      final score = _calculateScore(result, detail, user);

      recommendations.add(RecommendedScheme(
        summary: summary,
        status: result.status,
        checks: result.checks,
        score: score,
      ));
    }

    // Sort: Eligible first, then Needs Verification, then Not Eligible
    // Secondary sort: Score descending
    recommendations.sort((a, b) {
      if (a.status != b.status) {
        if (a.status == EligibilityStatus.eligible) return -1;
        if (b.status == EligibilityStatus.eligible) return 1;
        if (a.status == EligibilityStatus.needsVerification) return -1;
        if (b.status == EligibilityStatus.needsVerification) return 1;
      }
      return b.score.compareTo(a.score);
    });

    return recommendations;
  }
}
