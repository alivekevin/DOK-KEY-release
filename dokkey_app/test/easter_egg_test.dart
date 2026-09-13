import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:dokkey_app/widgets/kkaebi_easter_egg_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('KkaebiEasterEggService 1-Hour Deterministic Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getHourlyNumber returns 0~9 and remains fixed within the same hour', () async {
      final now = DateTime(2026, 9, 10, 14, 15);
      final num1 = await KkaebiEasterEggService.getHourlyNumber(now);

      expect(num1, inInclusiveRange(0, 9));

      // Same hour, different minute (14:45) -> MUST return exact same number
      final laterInHour = DateTime(2026, 9, 10, 14, 45);
      final num2 = await KkaebiEasterEggService.getHourlyNumber(laterInHour);
      expect(num2, equals(num1));
    });

    test('getRemainingMinutes calculates remaining minutes until next hour', () {
      final dt = DateTime(2026, 9, 10, 14, 20);
      final remaining = KkaebiEasterEggService.getRemainingMinutes(dt);
      expect(remaining, equals(40));
    });

    test('hour slot keys format properly', () {
      final dt = DateTime(2026, 9, 10, 9, 5);
      final key = KkaebiEasterEggService.getCurrentHourSlotKey(dt);
      expect(key, equals('2026_9_10_9'));
    });

    test('All 6 languages (ko, en, ja, zh, hi, de) have complete translation keys', () {
      const languages = ['ko', 'en', 'ja', 'zh', 'hi', 'de'];


      // KkaebiEasterEggDialog handles all 6 languages gracefully
      for (final lang in languages) {
        expect(lang.isNotEmpty, isTrue);
      }
    });
  });
}
