import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/language_provider.dart';

class AppStrings {
  static String t(BuildContext context, String key, [String? defaultText]) {
    final langCode = context.watch<LanguageProvider>().langCode;
    final map = _translations[key];
    if (map == null) {
      return defaultText ?? key;
    }
    return map[langCode] ?? map['en'] ?? defaultText ?? key;
  }

  static const Map<String, Map<String, String>> _translations = {
    // General
    'save': {
      'en': 'Save',
      'hi': 'सहेजें',
      'mr': 'जतन करा',
    },
    'cancel': {
      'en': 'Cancel',
      'hi': 'रद्द करें',
      'mr': 'रद्द करा',
    },
    'error': {
      'en': 'Error',
      'hi': 'त्रुटि',
      'mr': 'त्रुटी',
    },
    'retry': {
      'en': 'Retry',
      'hi': 'पुनः प्रयास करें',
      'mr': 'पुन्हा प्रयत्न करा',
    },

    // Bottom Navigation
    'nav_home': {
      'en': 'Home',
      'hi': 'होम',
      'mr': 'मुख्यपृष्ठ',
    },
    'nav_schemes': {
      'en': 'Schemes',
      'hi': 'योजनाएं',
      'mr': 'योजना',
    },
    'nav_sos': {
      'en': 'SOS',
      'hi': 'आपातकाल',
      'mr': 'तातडीची मदत',
    },
    'nav_reminders': {
      'en': 'Reminders',
      'hi': 'रिमाइंडर',
      'mr': 'स्मरणपत्रे',
    },
    'nav_profile': {
      'en': 'Profile',
      'hi': 'प्रोफ़ाइल',
      'mr': 'प्रोफाइल',
    },

    // Home Screen
    'home_greeting': {
      'en': 'Hi',
      'hi': 'नमस्ते',
      'mr': 'नमस्कार',
    },
    'home_discover_schemes': {
      'en': 'Discover Schemes',
      'hi': 'योजनाएं खोजें',
      'mr': 'योजना शोधा',
    },
    'home_search_hint': {
      'en': 'Search for schemes, benefits...',
      'hi': 'योजनाएं, लाभ खोजें...',
      'mr': 'योजना, फायदे शोधा...',
    },
    'home_quick_actions': {
      'en': 'Quick Actions',
      'hi': 'त्वरित कार्रवाइयां',
      'mr': 'जलद क्रिया',
    },
    'action_scheme_finder': {
      'en': 'Scheme\nFinder',
      'hi': 'योजना\nखोजकर्ता',
      'mr': 'योजना\nशोधक',
    },
    'action_document_vault': {
      'en': 'Document\nVault',
      'hi': 'दस्तावेज़\nवॉल्ट',
      'mr': 'कागदपत्र\nवॉल्ट',
    },
    'action_hospital_locator': {
      'en': 'Hospital\nLocator',
      'hi': 'अस्पताल\nखोजें',
      'mr': 'रुग्णालय\nशोधक',
    },
    'action_support': {
      'en': 'Support',
      'hi': 'सहायता',
      'mr': 'मदत',
    },
    'home_upcoming_reminders': {
      'en': 'Upcoming Reminders',
      'hi': 'आगामी रिमाइंडर',
      'mr': 'आगामी स्मरणपत्रे',
    },
    'home_view_all': {
      'en': 'View All',
      'hi': 'सभी देखें',
      'mr': 'सर्व पहा',
    },
    'home_no_reminders': {
      'en': 'No upcoming reminders',
      'hi': 'कोई आगामी रिमाइंडर नहीं',
      'mr': 'कोणतेही आगामी स्मरणपत्र नाही',
    },
    'home_add_reminder': {
      'en': 'Add Reminder',
      'hi': 'रिमाइंडर जोड़ें',
      'mr': 'स्मरणपत्र जोडा',
    },
    'home_saved_schemes': {
      'en': 'Saved Schemes',
      'hi': 'सहेजी गई योजनाएं',
      'mr': 'जतन केलेल्या योजना',
    },
    'home_no_saved_schemes': {
      'en': 'You haven\'t saved any schemes yet. Explore the Scheme Finder to discover schemes for you.',
      'hi': 'आपने अभी तक कोई योजना नहीं सहेजी है। अपने लिए योजनाएं खोजने के लिए योजना खोजकर्ता का अन्वेषण करें।',
      'mr': 'तुम्ही अद्याप कोणत्याही योजना जतन केलेल्या नाहीत. तुमच्यासाठी योजना शोधण्यासाठी योजना शोधक एक्सप्लोर करा.',
    },
    'home_explore_schemes': {
      'en': 'Explore Schemes',
      'hi': 'योजनाएं खोजें',
      'mr': 'योजना एक्सप्लोर करा',
    },
    
    // Support Screen
    'support_title': {
      'en': 'Help & Support',
      'hi': 'सहायता और समर्थन',
      'mr': 'मदत आणि समर्थन',
    },
    'support_faq_title': {
      'en': 'Frequently Asked Questions',
      'hi': 'अक्सर पूछे जाने वाले प्रश्न',
      'mr': 'सतत विचारले जाणारे प्रश्न',
    },
    'support_faq_q1': {
      'en': 'How do I apply for a UDID card?',
      'hi': 'मैं यूडीआईडी कार्ड के लिए कैसे आवेदन करूं?',
      'mr': 'मी यूडीआयडी कार्डसाठी अर्ज कसा करू?',
    },
    'support_faq_a1': {
      'en': 'You can apply for a UDID card through the official Swavlamban website. You will need your Aadhaar card, disability certificate, and a passport-size photo.',
      'hi': 'आप आधिकारिक स्वावलंबन वेबसाइट के माध्यम से यूडीआईडी कार्ड के लिए आवेदन कर सकते हैं। आपको अपना आधार कार्ड, विकलांगता प्रमाण पत्र और पासपोर्ट आकार के फोटो की आवश्यकता होगी।',
      'mr': 'तुम्ही अधिकृत स्वावलंबन वेबसाइटद्वारे यूडीआयडी कार्डसाठी अर्ज करू शकता. तुम्हाला तुमचे आधार कार्ड, अपंगत्व प्रमाणपत्र आणि पासपोर्ट आकाराचा फोटो लागेल.',
    },
    'support_faq_q2': {
      'en': 'What documents are usually required for schemes?',
      'hi': 'योजनाओं के लिए आमतौर पर किन दस्तावेजों की आवश्यकता होती है?',
      'mr': 'योजनांसाठी सहसा कोणती कागदपत्रे आवश्यक असतात?',
    },
    'support_faq_a2': {
      'en': 'Commonly required documents include Aadhaar Card, UDID/Disability Certificate, Income Certificate, Domicile Certificate, and Bank Passbook.',
      'hi': 'आमतौर पर आवश्यक दस्तावेजों में आधार कार्ड, यूडीआईडी/विकलांगता प्रमाण पत्र, आय प्रमाण पत्र, निवास प्रमाण पत्र और बैंक पासबुक शामिल हैं।',
      'mr': 'सामान्यतः आवश्यक कागदपत्रांमध्ये आधार कार्ड, यूडीआयडी/अपंगत्व प्रमाणपत्र, उत्पन्नाचा दाखला, अधिवास प्रमाणपत्र आणि बँक पासबुक यांचा समावेश होतो.',
    },
    'support_faq_q3': {
      'en': 'How do I update my profile details?',
      'hi': 'मैं अपनी प्रोफ़ाइल विवरण कैसे अपडेट करूं?',
      'mr': 'मी माझे प्रोफाइल तपशील कसे अपडेट करू?',
    },
    'support_faq_a3': {
      'en': 'Go to the Profile tab from the bottom navigation, tap on "Personal Details" or "Disability Details", make your changes, and tap Save.',
      'hi': 'नीचे नेविगेशन से प्रोफ़ाइल टैब पर जाएं, "व्यक्तिगत विवरण" या "विकलांगता विवरण" पर टैप करें, अपने परिवर्तन करें, और सहेजें पर टैप करें।',
      'mr': 'तळाशी असलेल्या नेव्हिगेशनमधून प्रोफाइल टॅबवर जा, "वैयक्तिक तपशील" किंवा "अपंगत्व तपशील" वर टॅप करा, तुमचे बदल करा आणि सेव्ह करा वर टॅप करा.',
    },
    'support_contact_title': {
      'en': 'Need more help?',
      'hi': 'क्या और मदद चाहिए?',
      'mr': 'आणखी मदत हवी आहे?',
    },
    'support_contact_desc': {
      'en': 'Get in touch with our support team.',
      'hi': 'हमारी सहायता टीम से संपर्क करें।',
      'mr': 'आमच्या सपोर्ट टीमशी संपर्क साधा.',
    },
    'support_email': {
      'en': 'Email Support',
      'hi': 'ईमेल सहायता',
      'mr': 'ईमेल सपोर्ट',
    },
    'support_call': {
      'en': 'Call Helpline',
      'hi': 'हेल्पलाइन पर कॉल करें',
      'mr': 'हेल्पलाईनला कॉल करा',
    },

    // Reminders Screen
    'reminders_title': {
      'en': 'Reminders',
      'hi': 'रिमाइंडर',
      'mr': 'स्मरणपत्रे',
    },
    'reminders_upcoming': {
      'en': 'Upcoming',
      'hi': 'आगामी',
      'mr': 'आगामी',
    },
    'reminders_past': {
      'en': 'Past',
      'hi': 'पिछला',
      'mr': 'मागील',
    },
    'reminders_no_upcoming': {
      'en': 'No upcoming reminders.',
      'hi': 'कोई आगामी रिमाइंडर नहीं है।',
      'mr': 'कोणतेही आगामी स्मरणपत्र नाही.',
    },
    'reminders_no_past': {
      'en': 'No past reminders.',
      'hi': 'कोई पिछला रिमाइंडर नहीं है।',
      'mr': 'कोणतेही मागील स्मरणपत्र नाही.',
    },

    // Profile Screen
    'profile_title': {
      'en': 'Profile',
      'hi': 'प्रोफ़ाइल',
      'mr': 'प्रोफाइल',
    },
    'profile_personal_details': {
      'en': 'Personal Details',
      'hi': 'व्यक्तिगत विवरण',
      'mr': 'वैयक्तिक तपशील',
    },
    'profile_disability_details': {
      'en': 'Disability Details',
      'hi': 'विकलांगता विवरण',
      'mr': 'अपंगत्व तपशील',
    },
    'profile_language': {
      'en': 'App Language',
      'hi': 'ऐप की भाषा',
      'mr': 'अॅपची भाषा',
    },
    'profile_settings': {
      'en': 'Settings & Preferences',
      'hi': 'सेटिंग्स और प्राथमिकताएं',
      'mr': 'सेटिंग्ज आणि प्राधान्ये',
    },
    'profile_about': {
      'en': 'About AshaSahyog',
      'hi': 'आशा सहयोग के बारे में',
      'mr': 'आशासहयोग बद्दल',
    },
    'profile_logout': {
      'en': 'Logout',
      'hi': 'लॉग आउट',
      'mr': 'लॉग आउट',
    },

    // Schemes Finder Screen
    'schemes_found': {
      'en': 'schemes found',
      'hi': 'योजनाएं मिलीं',
      'mr': 'योजना आढळल्या',
    },
    'error_loading_schemes': {
      'en': 'Could not load schemes',
      'hi': 'योजनाएं लोड नहीं हो सकीं',
      'mr': 'योजना लोड करू शकलो नाही',
    },
    'try_again': {
      'en': 'Try again',
      'hi': 'पुनः प्रयास करें',
      'mr': 'पुन्हा प्रयत्न करा',
    },
    'try_changing_search': {
      'en': 'Try changing your search or filters',
      'hi': 'अपनी खोज या फ़िल्टर बदलने का प्रयास करें',
      'mr': 'तुमचा शोध किंवा फिल्टर बदलून पहा',
    },
    'clear_all_filters': {
      'en': 'Clear all filters',
      'hi': 'सभी फ़िल्टर साफ़ करें',
      'mr': 'सर्व फिल्टर साफ करा',
    },
    'read_aloud': {
      'en': 'Read Aloud',
      'hi': 'जोर से पढ़ें',
      'mr': 'मोठ्याने वाचा',
    },
    'schemes_finder_title': {
      'en': 'Scheme Finder',
      'hi': 'योजना खोजकर्ता',
      'mr': 'योजना शोधक',
    },
    'schemes_finder_search': {
      'en': 'Search schemes...',
      'hi': 'योजनाएं खोजें...',
      'mr': 'योजना शोधा...',
    },
    'schemes_finder_filters': {
      'en': 'Filters',
      'hi': 'फिल्टर',
      'mr': 'फिल्टर्स',
    },
    'schemes_finder_all': {
      'en': 'All',
      'hi': 'सभी',
      'mr': 'सर्व',
    },
    'schemes_finder_central': {
      'en': 'Central',
      'hi': 'केंद्रीय',
      'mr': 'केंद्र',
    },
    'schemes_finder_state': {
      'en': 'State',
      'hi': 'राज्य',
      'mr': 'राज्य',
    },
    'schemes_finder_no_results': {
      'en': 'No schemes found.',
      'hi': 'कोई योजना नहीं मिली।',
      'mr': 'कोणत्याही योजना आढळल्या नाहीत.',
    },
    'schemes_finder_financial': {
      'en': 'Financial',
      'hi': 'वित्तीय',
      'mr': 'आर्थिक',
    },
    'schemes_finder_education': {
      'en': 'Education',
      'hi': 'शिक्षा',
      'mr': 'शिक्षण',
    },
    'schemes_finder_health': {
      'en': 'Health',
      'hi': 'स्वास्थ्य',
      'mr': 'आरोग्य',
    },
    'schemes_finder_employment': {
      'en': 'Employment',
      'hi': 'रोज़गार',
      'mr': 'रोजगार',
    },
    'schemes_finder_equipment': {
      'en': 'Equipment',
      'hi': 'उपकरण',
      'mr': 'उपकरणे',
    },

    // Scheme Details Screen
    'scheme_details_overview': {
      'en': 'Overview',
      'hi': 'अवलोकन',
      'mr': 'आढावा',
    },
    'scheme_details_benefits': {
      'en': 'Benefits',
      'hi': 'लाभ',
      'mr': 'फायदे',
    },
    'scheme_details_eligibility': {
      'en': 'Eligibility',
      'hi': 'पात्रता',
      'mr': 'पात्रता',
    },
    'scheme_details_documents': {
      'en': 'Documents',
      'hi': 'दस्तावेज़',
      'mr': 'कागदपत्रे',
    },
    'scheme_details_how_to_apply': {
      'en': 'How to Apply',
      'hi': 'आवेदन कैसे करें',
      'mr': 'अर्ज कसा करावा',
    },
    'scheme_details_save': {
      'en': 'Save Scheme',
      'hi': 'योजना सहेजें',
      'mr': 'योजना जतन करा',
    },
    'scheme_details_saved': {
      'en': 'Saved',
      'hi': 'सहेजा गया',
      'mr': 'जतन केले',
    },
    'scheme_details_required_docs': {
      'en': 'Required Documents',
      'hi': 'आवश्यक दस्तावेज़',
      'mr': 'आवश्यक कागदपत्रे',
    },
    'scheme_details_upload_missing': {
      'en': 'Upload Missing Documents',
      'hi': 'गायब दस्तावेज़ अपलोड करें',
      'mr': 'हरवलेली कागदपत्रे अपलोड करा',
    },
    'scheme_details_track_status': {
      'en': 'Document Tracking',
      'hi': 'दस्तावेज़ ट्रैकिंग',
      'mr': 'दस्तऐवज ट्रॅकिंग',
    },
    'scheme_details_available': {
      'en': 'Available',
      'hi': 'उपलब्ध',
      'mr': 'उपलब्ध',
    },
    'scheme_details_missing': {
      'en': 'Missing',
      'hi': 'गायब',
      'mr': 'गहाळ',
    },
    'scheme_details_status_ready': {
      'en': 'Ready to Apply',
      'hi': 'आवेदन करने के लिए तैयार',
      'mr': 'अर्ज करण्यासाठी तयार',
    },
    'scheme_details_status_missing': {
      'en': 'Missing Documents',
      'hi': 'दस्तावेज़ गायब हैं',
      'mr': 'कागदपत्रे गहाळ',
    },
    'action_find_schemes': {
      'en': 'Find Schemes',
      'hi': 'योजनाएं खोजें',
      'mr': 'योजना शोधा',
    },
    'action_find_schemes_desc': {
      'en': 'Browse govt. schemes',
      'hi': 'सरकारी योजनाएं देखें',
      'mr': 'सरकारी योजना पहा',
    },
    'action_hospitals': {
      'en': 'Nearby Hospitals',
      'hi': 'निकटतम अस्पताल',
      'mr': 'जवळचे रुग्णालय',
    },
    'action_hospitals_desc': {
      'en': 'Locate care near you',
      'hi': 'अपने पास देखभाल खोजें',
      'mr': 'आपल्या जवळची काळजी शोधा',
    },
    'action_documents': {
      'en': 'My Documents',
      'hi': 'मेरे दस्तावेज़',
      'mr': 'माझी कागदपत्रे',
    },
    'action_documents_desc': {
      'en': 'Manage your files',
      'hi': 'अपनी फ़ाइलें प्रबंधित करें',
      'mr': 'तुमच्या फाईल्स व्यवस्थापित करा',
    },
    'action_reminders': {
      'en': 'My Reminders',
      'hi': 'मेरे रिमाइंडर',
      'mr': 'माझी स्मरणपत्रे',
    },
    'action_reminders_desc': {
      'en': 'Stay on schedule',
      'hi': 'समय पर रहें',
      'mr': 'वेळेवर रहा',
    },


    'home_add_reminder_hint': {
      'en': 'Tap below to add your first reminder',
      'hi': 'अपना पहला रिमाइंडर जोड़ने के लिए नीचे टैप करें',
      'mr': 'तुमचे पहिले स्मरणपत्र जोडण्यासाठी खाली टॅप करा',
    },

    'home_recommended_schemes': {
      'en': 'Recommended Schemes',
      'hi': 'अनुशंसित योजनाएं',
      'mr': 'शिफारस केलेल्या योजना',
    },
    'home_no_schemes': {
      'en': 'No schemes available',
      'hi': 'कोई योजना उपलब्ध नहीं है',
      'mr': 'कोणत्याही योजना उपलब्ध नाहीत',
    },
    'home_no_schemes_hint': {
      'en': 'Check back later or browse all schemes',
      'hi': 'बाद में वापस आएं या सभी योजनाएं ब्राउज़ करें',
      'mr': 'नंतर परत या किंवा सर्व योजना ब्राउझ करा',
    },
    'greeting_morning': {
      'en': 'Good Morning,',
      'hi': 'शुभ प्रभात,',
      'mr': 'शुभ सकाळ,',
    },
    'greeting_afternoon': {
      'en': 'Good Afternoon,',
      'hi': 'शुभ दोपहर,',
      'mr': 'शुभ दुपार,',
    },
    'greeting_evening': {
      'en': 'Good Evening,',
      'hi': 'शुभ संध्या,',
      'mr': 'शुभ संध्याकाळ,',
    },
    'home_help': {
      'en': 'How can we help you today?',
      'hi': 'आज हम आपकी कैसे मदद कर सकते हैं?',
      'mr': 'आज आम्ही तुमची कशी मदत करू शकतो?',
    },
    'today': {
      'en': 'Today',
      'hi': 'आज',
      'mr': 'आज',
    },
    'at': {
      'en': 'at',
      'hi': 'पर',
      'mr': 'वर',
    },
    'soon': {
      'en': 'Soon',
      'hi': 'जल्द ही',
      'mr': 'लवकरच',
    },
    'see_all': {
      'en': 'See all',
      'hi': 'सभी देखें',
      'mr': 'सर्व पहा',
    },

    'schemes_finder_housing': {
      'en': 'Housing',
      'hi': 'आवास',
      'mr': 'गृहनिर्माण',
    },
    'state_maharashtra': {
      'en': 'Maharashtra',
      'hi': 'महाराष्ट्र',
      'mr': 'महाराष्ट्र',
    },
    'state_delhi': {
      'en': 'Delhi',
      'hi': 'दिल्ली',
      'mr': 'दिल्ली',
    },
    'state_karnataka': {
      'en': 'Karnataka',
      'hi': 'कर्नाटक',
      'mr': 'कर्नाटक',
    },
    'state_tamil_nadu': {
      'en': 'Tamil Nadu',
      'hi': 'तमिलनाडु',
      'mr': 'तमिळनाडू',
    },
    'state_gujarat': {
      'en': 'Gujarat',
      'hi': 'गुजरात',
      'mr': 'गुजरात',
    },
    'quick_emergency': {
      'en': 'Quick Emergency',
      'hi': 'त्वरित आपातकाल',
      'mr': 'त्वरित आणीबाणी',
    },
    'gov_helplines': {
      'en': 'Government Helplines',
      'hi': 'सरकारी हेल्पलाइन',
      'mr': 'सरकारी हेल्पलाइन',
    },
    'disability_helpline': {
      'en': 'Disability Helpline',
      'hi': 'विकलांगता हेल्पलाइन',
      'mr': 'अपंगत्व हेल्पलाइन',
    },
    'health_ministry': {
      'en': 'Health Ministry',
      'hi': 'स्वास्थ्य मंत्रालय',
      'mr': 'आरोग्य मंत्रालय',
    },
    'senior_citizen_helpline': {
      'en': 'Senior Citizen',
      'hi': 'वरिष्ठ नागरिक',
      'mr': 'ज्येष्ठ नागरिक',
    },
    'child_helpline': {
      'en': 'Child Helpline',
      'hi': 'चाइल्ड हेल्पलाइन',
      'mr': 'चाईल्ड हेल्पलाईन',
    },
    'mental_health_support': {
      'en': 'Mental Health',
      'hi': 'मानसिक स्वास्थ्य',
      'mr': 'मानसिक आरोग्य',
    },
    'support_subtitle': {
      'en': 'Get help when you need it',
      'hi': 'जरूरत पड़ने पर मदद पाएं',
      'mr': 'गरज असेल तेव्हा मदत मिळवा',
    },
    'immediate_danger': {
      'en': 'Are you in immediate danger?',
      'hi': 'क्या आप तत्काल खतरे में हैं?',
      'mr': 'तुम्ही तात्काळ धोक्यात आहात का?',
    },
    'call_national_emergency': {
      'en': 'Call National Emergency',
      'hi': 'राष्ट्रीय आपातकाल को कॉल करें',
      'mr': 'राष्ट्रीय आणीबाणीला कॉल करा',
    },
    'ambulance': {
      'en': 'Ambulance',
      'hi': 'एंबुलेंस',
      'mr': 'रुग्णवाहिका',
    },
    'police': {
      'en': 'Police',
      'hi': 'पुलिस',
      'mr': 'पोलीस',
    },
    'fire': {
      'en': 'Fire',
      'hi': 'आग',
      'mr': 'आग',
    },
    'women_help': {
      'en': 'Women Helpline',
      'hi': 'महिला हेल्पलाइन',
      'mr': 'महिला हेल्पलाइन',
    },
    'call_now': {
      'en': 'Call Now',
      'hi': 'अभी कॉल करें',
      'mr': 'आता कॉल करा',
    },
    'free': {
      'en': 'Toll Free',
      'hi': 'टोल फ्री',
      'mr': 'टोल फ्री',
    },
    'mental_health_desc': {
      'en': 'Free mental health support',
      'hi': 'मुफ्त मानसिक स्वास्थ्य सहायता',
      'mr': 'मोफत मानसिक आरोग्य समर्थन',
    },
  };
}
