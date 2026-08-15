import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/friction_event.dart';

/// Service managing hesitation and friction tracking on security-critical form inputs.
///
/// Specific rules:
/// 1. Only tracks `parent_consent_code`.
/// 2. Starts a 5-second timer upon focus.
/// 3. Resets timer whenever user types / interacts.
/// 4. If inactivity exceeds 5.0 seconds without interaction/submit, emits [FrictionEvent].
/// 5. Prevents duplicate event triggers during the same focus session.
/// 6. Stops timer on blur/unfocus and submit.
/// 7. A subsequent focus session starts a fresh timer.
class FrictionTracker {
  static const Duration hesitationThreshold = Duration(seconds: 5);
  static const String trackedFieldName = 'parent_consent_code';

  final void Function(FrictionEvent event)? onFrictionEvent;

  Timer? _hesitationTimer;
  DateTime? _focusStartTime;
  DateTime? _lastInteractionTime;
  bool _hasTriggeredForCurrentFocus = false;
  final List<FrictionEvent> _loggedEvents = [];

  FrictionTracker({this.onFrictionEvent});

  List<FrictionEvent> get loggedEvents => List.unmodifiable(_loggedEvents);

  /// Called when the user focuses the tracked input field.
  void onFieldFocused(String fieldName) {
    if (fieldName != trackedFieldName) return;

    _stopTimer();
    _focusStartTime = DateTime.now();
    _lastInteractionTime = _focusStartTime;
    _hasTriggeredForCurrentFocus = false;

    _startTimer();
  }

  /// Called when the user interacts / types into the field.
  void onUserInteraction(String fieldName) {
    if (fieldName != trackedFieldName) return;

    _lastInteractionTime = DateTime.now();
    _stopTimer();

    // If we haven't fired for this focus session yet, restart the timer
    if (!_hasTriggeredForCurrentFocus) {
      _startTimer();
    }
  }

  /// Called when the user unfocuses / blurs the field.
  void onFieldBlurred(String fieldName) {
    if (fieldName != trackedFieldName) return;
    _stopTimer();
    _focusStartTime = null;
    _lastInteractionTime = null;
    _hasTriggeredForCurrentFocus = false;
  }

  /// Called when a form submission occurs. Stops all timers immediately.
  void onFormSubmitted() {
    _stopTimer();
    _focusStartTime = null;
    _lastInteractionTime = null;
    _hasTriggeredForCurrentFocus = false;
  }

  void _startTimer() {
    _hesitationTimer = Timer(hesitationThreshold, () {
      if (_hasTriggeredForCurrentFocus) return;

      final DateTime now = DateTime.now();
      final DateTime referenceTime = _lastInteractionTime ?? _focusStartTime ?? now;
      final double durationSeconds =
          now.difference(referenceTime).inMilliseconds / 1000.0;

      final FrictionEvent event = FrictionEvent(
        timestamp: now,
        fieldName: trackedFieldName,
        hesitationDurationSeconds:
            durationSeconds >= 5.0 ? durationSeconds : 5.0,
      );

      _hasTriggeredForCurrentFocus = true;
      _loggedEvents.add(event);

      // Print specified format to console
      debugPrint(event.toLogString());

      onFrictionEvent?.call(event);
    });
  }

  void _stopTimer() {
    _hesitationTimer?.cancel();
    _hesitationTimer = null;
  }

  void dispose() {
    _stopTimer();
    _loggedEvents.clear();
  }
}
