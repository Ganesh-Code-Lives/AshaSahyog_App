import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageSelection extends StatefulWidget {
  final Function(String) onComplete;

  const LanguageSelection({super.key, required this.onComplete});

  @override
  State<LanguageSelection> createState() => _LanguageSelectionState();
}

class _LanguageSelectionState extends State<LanguageSelection> {
  String selectedLanguage = '';

  final List<Map<String, String>> languages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिंदी'},
    {'code': 'mr', 'name': 'Marathi', 'nativeName': 'मराठी'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Progress Indicator
                    Row(
                      children: [
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.primary, borderRadius: BorderRadius.circular(3)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.purpleLight, borderRadius: BorderRadius.circular(3)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.purpleLight, borderRadius: BorderRadius.circular(3)))),
                        const SizedBox(width: 8),
                        Expanded(child: Container(height: 6, decoration: BoxDecoration(color: AppTheme.purpleLight, borderRadius: BorderRadius.circular(3)))),
                      ],
                    ),
                    const SizedBox(height: 40),
                    
                    const Text(
                      'Select Language',
                      style: TextStyle(
                        fontSize: 28, 
                        fontWeight: FontWeight.w800, 
                        color: AppTheme.textMain
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Choose your preferred language for the app',
                      style: TextStyle(
                        fontSize: 16, 
                        color: AppTheme.textSecondary
                      ),
                    ),
                    const SizedBox(height: 48),
                    
                    // Language List
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: languages.length,
                      separatorBuilder: (context, index) => const SizedBox(height: 16),
                      itemBuilder: (context, index) {
                        final lang = languages[index];
                        final code = lang['code']!;
                        final isActive = selectedLanguage == code;
                        
                        return InkWell(
                          onTap: () => setState(() => selectedLanguage = code),
                          borderRadius: BorderRadius.circular(20),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            curve: Curves.easeInOut,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: isActive ? AppTheme.purpleLight.withOpacity(0.5) : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isActive ? AppTheme.primary : const Color(0xFFE5E7EB),
                                width: isActive ? 2 : 1.5,
                              ),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: AppTheme.primary.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: const Offset(0, 4),
                                      )
                                    ]
                                  : null,
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        lang['name']!, 
                                        style: TextStyle(
                                          fontSize: 18, 
                                          fontWeight: FontWeight.w700, 
                                          color: isActive ? AppTheme.primary : AppTheme.textMain
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        lang['nativeName']!, 
                                        style: TextStyle(
                                          fontSize: 14, 
                                          color: isActive ? AppTheme.primary.withOpacity(0.8) : AppTheme.textSecondary
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                AnimatedOpacity(
                                  duration: const Duration(milliseconds: 200),
                                  opacity: isActive ? 1.0 : 0.0,
                                  child: Container(
                                    width: 28,
                                    height: 28,
                                    decoration: const BoxDecoration(
                                      color: AppTheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.check, 
                                      size: 18, 
                                      color: Colors.white
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Bottom Action Area
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: const Color(0xFFE5E7EB), width: 1)),
              ),
              child: ElevatedButton(
                onPressed: selectedLanguage.isNotEmpty ? () => widget.onComplete(selectedLanguage) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  disabledBackgroundColor: AppTheme.primary.withOpacity(0.4),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  elevation: 0,
                  minimumSize: const Size(double.infinity, 56),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Continue', 
                  style: TextStyle(
                    fontSize: 16, 
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  )
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
