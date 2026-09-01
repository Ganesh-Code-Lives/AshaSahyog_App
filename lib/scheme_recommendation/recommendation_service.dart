import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../screens/scheme_details_screen.dart';
import '../screens/schemes_finder.dart';
import 'user_eligibility_profile.dart';
import 'eligibility_engine.dart';
import 'recommended_scheme_model.dart';

class RecommendationService {
  final _db = Supabase.instance.client;

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
        state = data['address'] as String?;
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

  /// Calculates a score out of 100
  int _calculateScore(EligibilityResult result, SchemeDetail detail, UserEligibilityProfile user) {
    int score = 0;
    
    // Eligibility base points
    switch (result.status) {
      case EligibilityStatus.eligible: score += 50; break;
      case EligibilityStatus.needsVerification: score += 20; break;
      case EligibilityStatus.notEligible: return 0; // Immediate 0
    }

    // Disability type relevance (fuzzy match on category or tags)
    if (user.disabilityType != null && user.disabilityType!.isNotEmpty) {
      final uType = user.disabilityType!.toLowerCase();
      final cat = detail.category?.toLowerCase() ?? '';
      final tagsStr = detail.tags.join(' ').toLowerCase();
      if (cat.contains(uType) || tagsStr.contains(uType) || uType.contains(cat)) {
        score += 20;
      }
    }

    // State relevance
    if (user.state != null && user.state!.isNotEmpty && detail.state != null && detail.state!.isNotEmpty) {
      final uState = user.state!.toLowerCase();
      final sState = detail.state!.toLowerCase();
      if (uState.contains(sState) || sState.contains(uState)) {
        score += 15;
      }
    }

    // Profile completeness bonus
    int completeCount = 0;
    if (user.age != null) completeCount++;
    if (user.disabilityType != null) completeCount++;
    if (user.disabilityPercent != null) completeCount++;
    if (user.annualIncome != null) completeCount++;
    if (user.state != null) completeCount++;
    
    score += (completeCount * 3).clamp(0, 15);

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
