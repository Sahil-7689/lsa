import 'package:flutter/material.dart';

/// Small atomic UI component for Predecessor ID field.
/// Strictly system-controlled and read-only to guarantee Data Lineage integrity.
class PredecessorFieldByt extends StatelessWidget {
  final String? value;

  const PredecessorFieldByt({
    super.key,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final bool hasValue = value != null && value!.trim().isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Flexible(
              child: Text(
                'Predecessor ID',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF1E293B),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: hasValue
                    ? const Color(0xFFFEF3C7)
                    : const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: hasValue
                      ? const Color(0xFFFDE68A)
                      : const Color(0xFFFECACA),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    hasValue ? Icons.lock_outline_rounded : Icons.warning_amber_rounded,
                    size: 12,
                    color: hasValue
                        ? const Color(0xFFD97706)
                        : const Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    hasValue ? 'Read-Only' : 'Missing Lineage',
                    style: TextStyle(
                      fontSize: 11,
                      color: hasValue
                          ? const Color(0xFFB45309)
                          : const Color(0xFFDC2626),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          key: const Key('predecessor_id_display'),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: hasValue ? const Color(0xFFE2E8F0) : const Color(0xFFF87171),
              width: hasValue ? 1.0 : 1.5,
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.hub_outlined,
                color: hasValue ? const Color(0xFF64748B) : const Color(0xFFDC2626),
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  hasValue ? value! : '<NULL / MISSING LINEAGE>',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: hasValue
                        ? const Color(0xFF334155)
                        : const Color(0xFFDC2626),
                    fontFamily: 'monospace',
                  ),
                ),
              ),
              const Icon(
                Icons.lock_rounded,
                color: Color(0xFF94A3B8),
                size: 16,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
