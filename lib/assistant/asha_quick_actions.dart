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
                icon: Icons.sos_rounded,
                title: "Emergency SOS",
                color: AppTheme.error,
                bgColor: const Color(0xFFFEE2E2),
                onTap: () => onActionTap("Emergency SOS"),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
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
          border: Border.all(color: color.withOpacity(0.2), width: 1.5),
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
                color: AppTheme.textMain.withOpacity(0.9),
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
