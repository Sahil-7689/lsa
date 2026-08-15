import 'package:flutter/material.dart';
import '../controllers/verification_controller.dart';

/// Test & Telemetry helper component allowing fast testing of all three assignment cases.
class SimulationPanelByt extends StatelessWidget {
  final VerificationState state;
  final VoidCallback onLoadValid;
  final VoidCallback onLoadMissingLineage;
  final VoidCallback onLoadSimulate500;
  final VoidCallback onReset;

  const SimulationPanelByt({
    super.key,
    required this.state,
    required this.onLoadValid,
    required this.onLoadMissingLineage,
    required this.onLoadSimulate500,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: ExpansionTile(
        key: const Key('test_simulation_panel'),
        initiallyExpanded: false,
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: const Icon(Icons.science_outlined, color: Color(0xFF0F766E), size: 20),
        title: const Text(
          'Assignment Test Scenarios & Telemetry',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
        subtitle: const Text(
          'Quickly load valid, missing lineage, or HTTP 500 presets',
          style: TextStyle(fontSize: 11, color: Color(0xFF64748B)),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Preset Test Loaders:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: onLoadValid,
                      icon: const Icon(Icons.check_circle_outline, size: 14, color: Color(0xFF16A34A)),
                      label: const Text('Case 1: Valid', style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed: onLoadMissingLineage,
                      icon: const Icon(Icons.link_off_rounded, size: 14, color: Color(0xFFDC2626)),
                      label: const Text('Case 2: Missing Lineage', style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed: onLoadSimulate500,
                      icon: const Icon(Icons.error_outline_rounded, size: 14, color: Color(0xFFEA580C)),
                      label: const Text('Case 3: HTTP 500 / Null Status', style: TextStyle(fontSize: 11)),
                    ),
                    OutlinedButton.icon(
                      onPressed: onReset,
                      icon: const Icon(Icons.refresh_rounded, size: 14),
                      label: const Text('Reset', style: TextStyle(fontSize: 11)),
                    ),
                  ],
                ),
                const Divider(height: 24),
                const Text(
                  'Cryptographic & Trace Telemetry:',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF334155)),
                ),
                const SizedBox(height: 6),
                _telemetryRow('x-trace-id', state.lastTraceId ?? 'Generated on submit'),
                const SizedBox(height: 4),
                _telemetryRow('x-logic-hash', state.lastLogicHash ?? 'Generated on submit'),
                const SizedBox(height: 4),
                _telemetryRow('Quarantine Records', '${state.quarantinedRecords.length} recorded'),
                const SizedBox(height: 4),
                _telemetryRow('Friction Events (>5s)', '${state.frictionEvents.length} triggered'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _telemetryRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 130,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF64748B)),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 11,
              fontFamily: 'monospace',
              color: Color(0xFF0F172A),
            ),
          ),
        ),
      ],
    );
  }
}
