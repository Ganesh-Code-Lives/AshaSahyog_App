import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class AshaQuickActions extends StatelessWidget {
  final Function(String text) onActionTap;

  const AshaQuickActions({super.key, required this.onActionTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.local_hospital_rounded,
                title: "Find nearby hospital",
                color: AppTheme.success,
                bgColor: const Color(0xFFDCFCE7),
                onTap: () => onActionTap("Find nearby hospital"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.description_rounded,
                title: "Find eligible schemes",
                color: AppTheme.primary,
                bgColor: AppTheme.purpleLight,
                onTap: () => onActionTap("Find eligible schemes"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _ActionCard(
                icon: Icons.notifications_rounded,
                title: "Set a reminder",
                color: const Color(0xFFBE185D), // Pink
                bgColor: const Color(0xFFFDF2FA),
                onTap: () => onActionTap("Set a reminder"),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _ActionCard(
                icon: Icons.folder_shared_rounded,
                title: "Document Vault",
                color: const Color(0xFF2563EB),
                bgColor: const Color(0xFFEFF6FF),
                onTap: () => onActionTap("Tell me about the Document Vault and UDID"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _SuggestionChip(
                label: "♿ ADIP Scheme",
                onTap: () => onActionTap("What is the ADIP scheme and who is eligible?"),
              ),
              const SizedBox(width: 8),
              _SuggestionChip(
                label: "🆔 UDID Card",
                onTap: () => onActionTap("How do I get a UDID card?"),
              ),
              const SizedBox(width: 8),
              _SuggestionChip(
                label: "🚨 Emergency SOS",
                onTap: () => onActionTap("Emergency SOS help"),
              ),
              const SizedBox(width: 8),
              _SuggestionChip(
                label: "💰 Disability Pension",
                onTap: () => onActionTap("What disability pensions are available?"),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _SuggestionChip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: AppTheme.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 1),
            )
          ],
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: AppTheme.textMain,
          ),
        ),
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 96,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            Text(
              title,
              style: TextStyle(
                color: AppTheme.textMain.withValues(alpha: 0.9),
                fontWeight: FontWeight.w600,
                fontSize: 13,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
