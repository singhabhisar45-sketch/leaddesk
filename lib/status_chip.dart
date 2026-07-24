// ──────────────────────────────────────────────────────────────────────────────
// status_chip.dart — Coloured status badge widget
// ──────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';

class StatusChip extends StatelessWidget {
  final String status;
  final VoidCallback? onTap;
  final bool isLoading;

  const StatusChip({
    super.key,
    required this.status,
    this.onTap,
    this.isLoading = false,
  });

  Color get _bgColor {
    switch (status) {
      case 'New':       return const Color(0xFF1A3A5C);
      case 'Contacted': return const Color(0xFF1A3A2A);
      case 'Closed':    return const Color(0xFF3A1A1A);
      default:          return const Color(0xFF2A2A45);
    }
  }

  Color get _fgColor {
    switch (status) {
      case 'New':       return const Color(0xFF64B5F6);
      case 'Contacted': return const Color(0xFF81C784);
      case 'Closed':    return const Color(0xFFEF9A9A);
      default:          return Colors.white70;
    }
  }

  IconData get _icon {
    switch (status) {
      case 'New':       return Icons.fiber_new_rounded;
      case 'Contacted': return Icons.mark_email_read_rounded;
      case 'Closed':    return Icons.check_circle_rounded;
      default:          return Icons.circle_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: _bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _fgColor.withValues(alpha: 0.4)),
        ),
        child: isLoading
            ? SizedBox(
                width: 60, height: 16,
                child: Center(
                  child: SizedBox(
                    width: 14, height: 14,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: _fgColor),
                  ),
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(_icon, size: 14, color: _fgColor),
                  const SizedBox(width: 5),
                  Text(status, style: TextStyle(
                      color: _fgColor, fontSize: 12,
                      fontWeight: FontWeight.w600)),
                  if (onTap != null) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.swap_horiz_rounded,
                        size: 12, color: _fgColor.withValues(alpha: 0.6)),
                  ],
                ],
              ),
      ),
    );
  }
}
