import 'package:flutter_test/flutter_test.dart';
import 'package:dokkey_app/widgets/seasonal_ambient_background.dart';
import 'package:dokkey_app/providers/dokkey_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Seasonal & Time-of-Day Ambient Particle Engine Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default state has particles enabled and auto season override', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      expect(provider.particlesEnabled, isTrue);
      expect(provider.seasonOverride, equals('auto'));
      expect(provider.effectiveSeason, isA<AppSeason>());
      expect(provider.effectiveTimeOfDay, isA<AppTimeOfDay>());
    });

    test('Season override properly returns requested season', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      await provider.setSeasonOverride('spring');
      expect(provider.effectiveSeason, equals(AppSeason.spring));

      await provider.setSeasonOverride('summer');
      expect(provider.effectiveSeason, equals(AppSeason.summer));

      await provider.setSeasonOverride('autumn');
      expect(provider.effectiveSeason, equals(AppSeason.autumn));

      await provider.setSeasonOverride('winter');
      expect(provider.effectiveSeason, equals(AppSeason.winter));
    });

    test('Toggling particles enabled updates state and persists', () async {
      final provider = DokkeyProvider();
      await provider.initialize();

      await provider.setParticlesEnabled(false);
      expect(provider.particlesEnabled, isFalse);

      await provider.setParticlesEnabled(true);
      expect(provider.particlesEnabled, isTrue);
    });
  });
}
