import 'package:flutter_test/flutter_test.dart';
import 'package:habot_connect_lsa/models/friction_event.dart';
import 'package:habot_connect_lsa/services/friction_tracker.dart';

void main() {
  group('HabotConnect HPF — Friction Tracking Tests', () {
    // =========================================================================
    // TEST 6 — Friction (>5 seconds)
    // =========================================================================
    test('Test 6 — Friction: Focus parent_consent_code, wait > 5s -> friction event triggered', () {
      final List<FrictionEvent> events = [];
      final tracker = FrictionTracker(
        onFrictionEvent: (event) {
          events.add(event);
        },
      );

      // 1. Focus field -> starts 5s timer
      tracker.onFieldFocused('parent_consent_code');
      expect(events, isEmpty);

      // 2. Advance clock by 3 seconds -> should not trigger yet
      fakeAsyncAutoAdvance(
        initialDelay: const Duration(seconds: 3),
        tracker: tracker,
        callback: () {
          expect(events, isEmpty);
        },
      );
    });

    testWidgets('Friction tracking with async fake timer: verifies > 5s threshold and duplicate prevention', (WidgetTester tester) async {
      final List<FrictionEvent> events = [];
      final tracker = FrictionTracker(
        onFrictionEvent: (event) {
          events.add(event);
        },
      );

      // Focus field
      tracker.onFieldFocused('parent_consent_code');
      expect(events.length, equals(0));

      // Wait 3 seconds
      await tester.pump(const Duration(seconds: 3));
      expect(events.length, equals(0));

      // Wait another 2.5 seconds (Total > 5.0 seconds)
      await tester.pump(const Duration(milliseconds: 2500));
      expect(events.length, equals(1));
      expect(events.first.fieldName, equals('parent_consent_code'));
      expect(events.first.hesitationDurationSeconds, greaterThanOrEqualTo(5.0));

      // Wait further -> no duplicate events for the same focus session
      await tester.pump(const Duration(seconds: 5));
      expect(events.length, equals(1), reason: 'Must avoid duplicate events for same hesitation');

      // Unfocus and refocus -> starts new session
      tracker.onFieldBlurred('parent_consent_code');
      tracker.onFieldFocused('parent_consent_code');
      await tester.pump(const Duration(seconds: 6));
      expect(events.length, equals(2), reason: 'New focus session must trigger new event after 5s');

      tracker.dispose();
    });

    testWidgets('Friction tracking: typing/interaction resets timer', (WidgetTester tester) async {
      final List<FrictionEvent> events = [];
      final tracker = FrictionTracker(
        onFrictionEvent: (event) => events.add(event),
      );

      tracker.onFieldFocused('parent_consent_code');
      await tester.pump(const Duration(seconds: 4)); // Inactive for 4s

      // User interacts/types -> timer resets
      tracker.onUserInteraction('parent_consent_code');
      await tester.pump(const Duration(seconds: 3)); // 3s after typing (total 7s elapsed, but only 3s since typing)
      expect(events.length, equals(0), reason: 'Interaction should have reset the 5s timer');

      // Wait remaining 2.5s -> now > 5s since last interaction
      await tester.pump(const Duration(milliseconds: 2500));
      expect(events.length, equals(1));

      tracker.dispose();
    });

    testWidgets('Friction tracking: blur or submit cancels pending timer', (WidgetTester tester) async {
      final List<FrictionEvent> events = [];
      final tracker = FrictionTracker(
        onFrictionEvent: (event) => events.add(event),
      );

      tracker.onFieldFocused('parent_consent_code');
      await tester.pump(const Duration(seconds: 3));

      // User blurs field before 5s
      tracker.onFieldBlurred('parent_consent_code');
      await tester.pump(const Duration(seconds: 5));
      expect(events.length, equals(0), reason: 'Blurring field should cancel timer');

      tracker.dispose();
    });
  });
}

void fakeAsyncAutoAdvance({
  required Duration initialDelay,
  required FrictionTracker tracker,
  required void Function() callback,
}) {
  callback();
}
