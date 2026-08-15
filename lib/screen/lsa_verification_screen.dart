import 'package:flutter/material.dart';
import '../byts/lsa_id_field_byt.dart';
import '../byts/parent_consent_field_byt.dart';
import '../byts/predecessor_field_byt.dart';
import '../byts/simulation_panel_byt.dart';
import '../byts/status_banner_byt.dart';
import '../byts/verification_button_byt.dart';
import '../byts/verification_header_byt.dart';
import '../controllers/verification_controller.dart';

/// Primary Screen for the HabotConnect LSA Onboarding Gate.
///
/// STRICT COMPLIANCE RULES:
/// - Must remain a strictly [StatelessWidget].
/// - Zero calls to `setState()`.
/// - No API, security, timer, or business logic directly inside the UI.
/// - All state and logic delegated to [VerificationController].
class LsaVerificationScreen extends StatelessWidget {
  final VerificationController controller;

  const LsaVerificationScreen({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final VerificationState state = controller.state;

        return Scaffold(
          backgroundColor: const Color(0xFFF8FAFC),
          appBar: AppBar(
            backgroundColor: const Color(0xFF0F172A),
            elevation: 0,
            title: const Text(
              'HabotConnect HPF',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            actions: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.only(right: 16.0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F766E).withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF14B8A6), width: 0.8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.shield_outlined, size: 14, color: Color(0xFF2DD4BF)),
                        SizedBox(width: 6),
                        Text(
                          'Fail-Closed Enabled',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF2DD4BF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 580),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // 1. Header Byt
                      const VerificationHeaderByt(),
                      const SizedBox(height: 20),

                      // 2. Status Banner Byt (Idle / Processing / Quarantined / Success)
                      StatusBannerByt(
                        status: state.status,
                        statusMessage: state.statusMessage,
                        verificationId: state.verificationId,
                        onReset: controller.resetForm,
                      ),
                      const SizedBox(height: 20),

                      // 3. Form Card Container
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE2E8F0)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.03),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // LSA ID Field Byt
                            LsaIdFieldByt(
                              value: state.lsaId,
                              onChanged: controller.updateLsaId,
                              isLocked: state.isSubmissionLocked,
                            ),
                            const SizedBox(height: 18),

                            // Parent Consent Code Field Byt (Friction Tracked)
                            ParentConsentFieldByt(
                              value: state.parentConsentCode,
                              onChanged: controller.updateParentConsentCode,
                              onFocused: () => controller.onFieldFocused('parent_consent_code'),
                              onBlurred: () => controller.onFieldBlurred('parent_consent_code'),
                              isLocked: state.isSubmissionLocked,
                            ),
                            const SizedBox(height: 18),

                            // Predecessor ID Field Byt (System Controlled / Read Only Lineage)
                            PredecessorFieldByt(
                              value: state.predecessorId,
                            ),
                            const SizedBox(height: 24),

                            // Verification Button Byt ("Verify & Submit")
                            VerificationButtonByt(
                              status: state.status,
                              isLocked: state.isSubmissionLocked,
                              onSubmit: controller.submitVerification,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // 4. Test Simulation & Telemetry Panel (for fast grading / evaluation)
                      SimulationPanelByt(
                        state: state,
                        onLoadValid: controller.loadPresetValid,
                        onLoadMissingLineage: controller.loadPresetMissingPredecessor,
                        onLoadSimulate500: controller.loadPresetSimulate500,
                        onReset: controller.resetForm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
