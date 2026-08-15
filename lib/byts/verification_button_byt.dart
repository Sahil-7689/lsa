import 'package:flutter/material.dart';
import '../models/verification_status.dart';

/// Small atomic UI component for the "Verify & Submit" CTA button.
class VerificationButtonByt extends StatelessWidget {
  final VerificationStatus status;
  final bool isLocked;
  final VoidCallback onSubmit;

  const VerificationButtonByt({
    super.key,
    required this.status,
    required this.isLocked,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    final bool isProcessing = status == VerificationStatus.processing;
    final bool isDisabled = isProcessing || isLocked;

    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        key: const Key('verify_submit_button'),
        onPressed: isDisabled ? null : onSubmit,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF0F766E), // Teal primary
          foregroundColor: Colors.white,
          disabledBackgroundColor: const Color(0xFF94A3B8),
          disabledForegroundColor: Colors.white70,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        child: isProcessing
            ? const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 12),
                  Text('Processing...'),
                ],
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isLocked ? Icons.lock_outline_rounded : Icons.check_circle_outline_rounded,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      isLocked ? 'Submission Locked' : 'Verify & Submit',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
