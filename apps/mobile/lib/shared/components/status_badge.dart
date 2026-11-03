import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';

class StatusBadge extends StatelessWidget {
  final String text;
  final Color backgroundColor;
  final Color textColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.text,
    required this.backgroundColor,
    required this.textColor,
    this.icon,
  });

  factory StatusBadge.live() {
    return const StatusBadge(
      text: 'লাইভ',
      backgroundColor: AppColors.liveContainer,
      textColor: AppColors.live,
    );
  }

  factory StatusBadge.practice() {
    return const StatusBadge(
      text: 'অনুশীলন',
      backgroundColor: AppColors.teal100,
      textColor: AppColors.teal600,
    );
  }

  factory StatusBadge.completed() {
    return const StatusBadge(
      text: 'সম্পন্ন',
      backgroundColor: AppColors.successContainer,
      textColor: AppColors.success,
    );
  }

  factory StatusBadge.tag(String label) {
    return StatusBadge(
      text: label,
      backgroundColor: AppColors.primary50,
      textColor: AppColors.primary600,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: TextStyle(
              color: textColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

