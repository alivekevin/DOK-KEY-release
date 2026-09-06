import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/providers/dokkey_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:intl/intl.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Kkaebi Affection / Intimacy System Tests (3순위)', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initial state is Lv.1 with 0 EXP and default title', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      expect(provider.kkaebiAffectionExp, equals(0));
      expect(provider.dailyAffectionEarned, equals(0));
      expect(provider.kkaebiLevel, equals(1));
      expect(provider.kkaebiLevelProgress, equals(0.0));
      expect(provider.kkaebiTitle, equals('낯선 손님'));
      expect(provider.canTouchForExp, isTrue);
    });

    test('Adding EXP properly updates levels and triggers level up flag', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      // Add 30 EXP (e.g., from draw)
      final added1 = await provider.addKkaebiAffection(30, reason: 'draw');
      expect(added1, isTrue);
      expect(provider.kkaebiAffectionExp, equals(30));
      expect(provider.dailyAffectionEarned, equals(30));
      expect(provider.kkaebiLevel, equals(1));
      expect(provider.pendingAffectionLevelUp, isNull);

      // Add 70 EXP -> total 100 EXP -> Level 2 (아는 동무)
      final added2 = await provider.addKkaebiAffection(70, reason: 'bonus');
      expect(added2, isTrue);
      expect(provider.kkaebiAffectionExp, equals(100));
      expect(provider.dailyAffectionEarned, equals(100));
      expect(provider.kkaebiLevel, equals(2));
      expect(provider.pendingAffectionLevelUp, equals(2));
      expect(provider.kkaebiTitle, equals('아는 동무'));

      provider.clearPendingAffectionLevelUp();
      expect(provider.pendingAffectionLevelUp, isNull);
    });

    test('Daily cap (100 EXP) is strictly enforced', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      // Add 80 EXP
      await provider.addKkaebiAffection(80, reason: 'test');
      expect(provider.dailyAffectionEarned, equals(80));

      // Attempt to add 30 EXP -> should only add 20 to reach 100 cap
      await provider.addKkaebiAffection(30, reason: 'test');
      expect(provider.dailyAffectionEarned, equals(100));
      expect(provider.remainingDailyAffection, equals(0));

      // Subsequent attempt returns false
      final overCap = await provider.addKkaebiAffection(10, reason: 'test');
      expect(overCap, isFalse);
      expect(provider.dailyAffectionEarned, equals(100));
    });

    test('Touch mascot provides 5 EXP for first 2 touches, then reaction only', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      // 1st touch
      final res1 = await provider.touchKkaebiMascot();
      expect(res1['gainedExp'], equals(5));
      expect(provider.dailyTouchCount, equals(1));
      expect(provider.canTouchForExp, isTrue);

      // 2nd touch
      final res2 = await provider.touchKkaebiMascot();
      expect(res2['gainedExp'], equals(5));
      expect(provider.dailyTouchCount, equals(2));
      expect(provider.canTouchForExp, isFalse);

      // 3rd touch -> 0 EXP, but still returns reaction message
      final res3 = await provider.touchKkaebiMascot();
      expect(res3['gainedExp'], equals(0));
      expect(provider.dailyTouchCount, equals(3));
      expect(res3['reaction'], isNotEmpty);
    });

    test('High level thresholds and progress calculation', () async {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pref_kkaebi_affection_exp', 750);
      await prefs.setString('pref_last_affection_date', todayStr);

      final provider = DokkeyProvider();
      await provider.initialize();

      // 750 EXP -> Lv.4 (도깨비 짝꿍)
      expect(provider.kkaebiLevel, equals(4));
      expect(provider.kkaebiTitle, equals('도깨비 짝꿍'));
      expect(provider.kkaebiLevelMinExp, equals(700));
      expect(provider.kkaebiLevelMaxExp, equals(1500));
      expect(provider.kkaebiCurrentLevelExp, equals(50));
      expect(provider.kkaebiNextLevelRequiredExp, equals(800));
      expect(provider.kkaebiLevelProgress, closeTo(50 / 800, 0.001));
    });
  });
}
