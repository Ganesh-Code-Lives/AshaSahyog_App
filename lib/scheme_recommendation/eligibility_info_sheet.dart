import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EligibilityInfoSheet extends StatefulWidget {
  final VoidCallback onSaved;
  
  const EligibilityInfoSheet({super.key, required this.onSaved});

  static void show(BuildContext context, {required VoidCallback onSaved}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => EligibilityInfoSheet(onSaved: onSaved),
    );
  }

  @override
  State<EligibilityInfoSheet> createState() => _EligibilityInfoSheetState();
}

class _EligibilityInfoSheetState extends State<EligibilityInfoSheet> {
  final _incomeCtrl = TextEditingController();
  bool? _hasAadhaar;
  bool? _hasBankAccount;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final prefs = await SharedPreferences.getInstance();
    final inc = prefs.getInt('annualIncome');
    if (inc != null) {
      _incomeCtrl.text = inc.toString();
    }
    if (mounted) {
      setState(() {
        _hasAadhaar = prefs.getBool('hasAadhaar');
        _hasBankAccount = prefs.getBool('hasBankAccount');
      });
    }
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    
    if (_incomeCtrl.text.isNotEmpty) {
      final inc = int.tryParse(_incomeCtrl.text.trim());
      if (inc != null) {
        await prefs.setInt('annualIncome', inc);
      }
    } else {
      await prefs.remove('annualIncome');
    }

    if (_hasAadhaar != null) {
      await prefs.setBool('hasAadhaar', _hasAadhaar!);
    }
    if (_hasBankAccount != null) {
      await prefs.setBool('hasBankAccount', _hasBankAccount!);
    }

    widget.onSaved();
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _incomeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        left: 24,
        right: 24,
        top: 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Eligibility Details',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF1E1B2E),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Providing these details helps us find schemes you are eligible for. This information is saved securely on your device.',
            style: TextStyle(color: Color(0xFF6B7280), fontSize: 14),
          ),
          const SizedBox(height: 24),
          
          // Income
          const Text('Annual Family Income (₹)', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          TextField(
            controller: _incomeCtrl,
            keyboardType: TextInputType.number,
            decoration: InputDecoration(
              hintText: 'e.g. 150000',
              filled: true,
              fillColor: const Color(0xFFFAF7FF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEDE9FE)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEDE9FE)),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Aadhaar
          const Text('Do you have an Aadhaar Card?', style: TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Yes'),
                  value: true,
                  groupValue: _hasAadhaar,
                  onChanged: (v) => setState(() => _hasAadhaar = v),
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF7C3AED),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('No'),
                  value: false,
                  groupValue: _hasAadhaar,
                  onChanged: (v) => setState(() => _hasAadhaar = v),
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          
          // Bank Account
          const Text('Do you have a Bank Account?', style: TextStyle(fontWeight: FontWeight.w600)),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('Yes'),
                  value: true,
                  groupValue: _hasBankAccount,
                  onChanged: (v) => setState(() => _hasBankAccount = v),
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF7C3AED),
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('No'),
                  value: false,
                  groupValue: _hasBankAccount,
                  onChanged: (v) => setState(() => _hasBankAccount = v),
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF7C3AED),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C3AED),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Save Details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}
