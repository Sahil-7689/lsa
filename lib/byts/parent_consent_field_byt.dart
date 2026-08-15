import 'package:flutter/material.dart';

/// Small atomic UI component for Parent Consent Code input field.
/// Enforces user-editable input and hooks into friction tracking lifecycle.
class ParentConsentFieldByt extends StatefulWidget {
  final String value;
  final ValueChanged<String> onChanged;
  final VoidCallback onFocused;
  final VoidCallback onBlurred;
  final bool isLocked;

  const ParentConsentFieldByt({
    super.key,
    required this.value,
    required this.onChanged,
    required this.onFocused,
    required this.onBlurred,
    this.isLocked = false,
  });

  @override
  State<ParentConsentFieldByt> createState() => _ParentConsentFieldBytState();
}

class _ParentConsentFieldBytState extends State<ParentConsentFieldByt> {
  late final TextEditingController _textController;
  late final FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.value);
    _focusNode = FocusNode();
    _focusNode.addListener(_handleFocusChange);
  }

  void _handleFocusChange() {
    if (_focusNode.hasFocus) {
      widget.onFocused();
    } else {
      widget.onBlurred();
    }
  }

  @override
  void didUpdateWidget(covariant ParentConsentFieldByt oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _textController.text) {
      _textController.text = widget.value;
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Parent Consent Code',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF1E293B),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.timer_outlined,
                    size: 12,
                    color: Color(0xFF2563EB),
                  ),
                  SizedBox(width: 4),
                  Text(
                    'Tracked Field',
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF2563EB),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          key: const Key('parent_consent_field'),
          controller: _textController,
          focusNode: _focusNode,
          enabled: !widget.isLocked,
          onChanged: widget.onChanged,
          decoration: InputDecoration(
            hintText: 'Enter consent code (e.g. PCC-2026-9901)',
            filled: true,
            fillColor: widget.isLocked ? const Color(0xFFF8FAFC) : Colors.white,
            prefixIcon: const Icon(
              Icons.lock_open_rounded,
              color: Color(0xFF0F766E),
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFF0F766E), width: 1.8),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
          ),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
