import 'package:flutter/material.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_spacing.dart';

enum BadgeType { success, warning, danger, info, neutral }

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final BadgeType type;
  final Color? customBg;
  final Color? customFg;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.type = BadgeType.neutral,
    this.customBg,
    this.customFg,
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (type) {
      case BadgeType.success:
        bg = const Color(0xFFE6F4EA);
        fg = const Color(0xFF137333);
        break;
      case BadgeType.warning:
        bg = const Color(0xFFFEF7E0);
        fg = const Color(0xFFB06000);
        break;
      case BadgeType.danger:
        bg = const Color(0xFFFCE8E6);
        fg = const Color(0xFFC5221F);
        break;
      case BadgeType.info:
        bg = const Color(0xFFF3E8FF);
        fg = const Color(0xFF7E22CE);
        break;
      case BadgeType.neutral:
        bg = const Color(0xFFF4F4F5);
        fg = const Color(0xFF3F3F46);
        break;
    }

    if (customBg != null) bg = customBg!;
    if (customFg != null) fg = customFg!;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: AppRadius.borderSm,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}
