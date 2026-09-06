import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/providers/dokkey_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kkaebi Fortune Calendar & Streak Diary Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Calendar helper maps date correctly when draw occurs', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      expect(provider.archiveByDateMap, isEmpty);

      final result = await provider.executeDraw();
      expect(provider.hasDrawForDate(result.dateStr), isTrue);

      final fetched = provider.getDrawResultForDate(result.dateStr);
      expect(fetched, isNotNull);
      expect(fetched!.card.id, equals(result.card.id));
      expect(fetched.number, equals(result.number));
      expect(provider.archiveByDateMap.containsKey(result.dateStr), isTrue);
    });

    test('Streak milestone rewards can be claimed when reached', () async {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final provider = DokkeyProvider();
      await provider.initialize();

      // Initially streak is 1, milestone 3 cannot be claimed
      final canClaimBefore = await provider.claimStreakReward(3);
      expect(canClaimBefore, isFalse);
      expect(provider.isStreakMilestoneClaimed(3), isFalse);

      // Perform draw to ensure keys are tracked
      final initialKeys = provider.keys;

      // Pretend streak reaches 3 on a new provider instance
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pref_streak', 3);
      await prefs.setString('pref_last_draw_date', todayStr);

      final newProvider = DokkeyProvider();
      await newProvider.initialize();

      expect(newProvider.streak, equals(3));
      final canClaimAfter = await newProvider.claimStreakReward(3);
      expect(canClaimAfter, isTrue);
      expect(newProvider.isStreakMilestoneClaimed(3), isTrue);
      expect(newProvider.keys, equals(initialKeys + 1));

      // Cannot claim again (idempotent)
      final canClaimAgain = await newProvider.claimStreakReward(3);
      expect(canClaimAgain, isFalse);
    });
  });
}
