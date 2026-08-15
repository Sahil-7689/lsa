import 'package:flutter/material.dart';
import '../models/verification_status.dart';

/// Small atomic UI component for displaying current compliance verification status.
/// Visually highlights Idle, Processing, Quarantined (Fail-Closed), and Success.
class StatusBannerByt extends StatelessWidget {
  final VerificationStatus status;
  final String? statusMessage;
  final String? verificationId;
  final VoidCallback? onReset;

  const StatusBannerByt({
    super.key,
    required this.status,
    this.statusMessage,
    this.verificationId,
    this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    Color backgroundColor;
    Color borderColor;
    Color iconColor;
    Color textColor;
    IconData iconData;

    switch (status) {
      case VerificationStatus.idle:
        backgroundColor = const Color(0xFFF1F5F9);
        borderColor = const Color(0xFFCBD5E1);
        iconColor = const Color(0xFF64748B);
        textColor = const Color(0xFF334155);
        iconData = Icons.radio_button_checked_rounded;
        break;

      case VerificationStatus.processing:
        backgroundColor = const Color(0xFFEFF6FF);
        borderColor = const Color(0xFF93C5FD);
        iconColor = const Color(0xFF2563EB);
        textColor = const Color(0xFF1E40AF);
        iconData = Icons.sync_rounded;
        break;

      case VerificationStatus.quarantined:
        backgroundColor = const Color(0xFFFEF2F2);
        borderColor = const Color(0xFFFCA5A5);
        iconColor = const Color(0xFFDC2626);
        textColor = const Color(0xFF991B1B);
        iconData = Icons.gpp_bad_rounded;
        break;

      case VerificationStatus.success:
        backgroundColor = const Color(0xFFF0FDF4);
        borderColor = const Color(0xFF86EFAC);
        iconColor = const Color(0xFF16A34A);
        textColor = const Color(0xFF166534);
        iconData = Icons.verified_rounded;
        break;
    }

    return Container(
      key: const Key('status_banner'),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(iconData, color: iconColor, size: 24),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  status.displayLabel,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
              ),
              if (status == VerificationStatus.quarantined && onReset != null)
                TextButton.icon(
                  onPressed: onReset,
                  icon: const Icon(Icons.refresh_rounded, size: 16, color: Color(0xFFDC2626)),
                  label: const Text(
                    'Reset Form',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFDC2626),
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
            ],
          ),
          if (statusMessage != null && statusMessage!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              statusMessage!,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: textColor.withValues(alpha: 0.9),
              ),
            ),
          ],
          if (status == VerificationStatus.success && verificationId != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFDCFCE7),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Verification ID: $verificationId',
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF15803D),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
