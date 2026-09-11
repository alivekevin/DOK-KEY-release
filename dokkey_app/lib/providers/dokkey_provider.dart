import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/brand_config.dart';
import '../core/context_key_engine.dart';
import '../core/daily_quote_engine.dart';
import '../core/dokkey_engine.dart';
import '../core/widget_service.dart';
import '../core/codex_service.dart';
import '../core/notification_service.dart';
import '../core/sound_service.dart';
import '../models/talisman_model.dart';
import '../core/source_number_manager.dart';
import '../core/key_combiner_engine.dart';
import '../core/ttl_manager.dart';
import '../core/personal_cloud_vault_service.dart';
import '../core/theme.dart';
import '../models/dokkey_models.dart';
import '../models/vault_models.dart';
import '../widgets/seasonal_ambient_background.dart';

class DokkeyProvider extends ChangeNotifier {
  final DokkeyEngine _engine = DokkeyEngine();
  final ContextKeyEngine _context = ContextKeyEngine();
  final NotificationService _notifications = NotificationService();

  bool _initialized = false;
  bool get isInitialized => _initialized;

  String _lang = 'ko';
  String get lang => _lang;

  int _keys = 1;
  int _coins = 0;
  int get coins => _coins;

  String _arcadePlaysDate = '';
  int _arcadePlaysToday = 0;
  int get arcadePlaysToday => _arcadePlaysToday;
  bool get arcadeQuotaRemaining => _isProUser || _arcadePlaysToday < 3;
  int get arcadeQuotaDisplay => _isProUser ? -1 : _arcadePlaysToday.clamp(0, 3);

  /// 아케이드 플레이 1회 소비 (무료 일 3회 / PRO 무제한). false면 쿼터 소진.
  Future<bool> consumeArcadePlay() async {
    if (!arcadeQuotaRemaining) return false;
    if (!_isProUser) {
      _arcadePlaysToday += 1;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('pref_arcade_plays', _arcadePlaysToday);
      await prefs.setString('pref_arcade_plays_date',
          DateFormat('yyyy-MM-dd').format(DateTime.now()));
    }
    notifyListeners();
    return true;
  }

  /// 아케이드 플레이 횟수 리셋 및 무료 충전 (광고 시청 또는 테스트용)
  Future<void> rechargeArcadePlays() async {
    _arcadePlaysToday = 0;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_arcade_plays', 0);
    await prefs.setString('pref_arcade_plays_date',
        DateFormat('yyyy-MM-dd').format(DateTime.now()));
    notifyListeners();
  }

  Future<void> addCoins(int amount) async {
    _coins = (_coins + amount).clamp(0, 999999);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_coins', _coins);
    notifyListeners();
  }
  int get keys => _keys;

  int _streak = 1;
  int get streak => _streak;

  int _drawCountToday = 0;
  int get drawCountToday => _drawCountToday;

  String _userId = 'dokkey_user_001';
  DrawResult? _todayResult;
  DrawResult? get todayResult => _todayResult;

  QuoteModel? _todayQuote;
  QuoteModel? get todayQuote => _todayQuote;

  DokkeyEngine get engine => _engine;

  // Zero-Delay Context Keys (v3.0.0)
  ContextKeyEngine get context => _context;

  // Daily draws archive (history)
  List<DrawResult> _archive = [];
  List<DrawResult> get archive => _archive;

  // Vault Tab 1: Source Numbers Pool (01 ~ 99)
  List<SourceNumberItem> _sourceNumbers = [];
  List<SourceNumberItem> get sourceNumbers => _sourceNumbers;

  // --- Monetization & Pro Pass (99-Slot Expansion & Ad-Free) ---
  bool _isProUser = false;
  bool get isProUser => _isProUser;
  static const int maxFreeCombinedSlots = 9;
  static const int maxProCombinedSlots = 99;
  int get maxCombinedSlots => _isProUser ? maxProCombinedSlots : maxFreeCombinedSlots;
  bool get canAddCombinedKey => _combinedKeys.length < maxCombinedSlots;

  Future<void> upgradeToProPass() async {
    _isProUser = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dokkey_is_pro_user', true);
    // 프로 패스 활성화 시 만료 제한 해제 (장기 보관)
    final newExpiry = DateTime.now().add(proKeyTtl);
    for (final key in _combinedKeys) {
      if (key.expiresAt != null && key.expiresAt!.isBefore(newExpiry)) {
        key.expiresAt = newExpiry;
      }
    }
    await _saveCombinedKeys(prefs);
    notifyListeners();
  }

  // Vault Tab 2: Combined Keys (7-Day TTL / 10-Year Safe Lock)
  List<CombinedKeyItem> _combinedKeys = [];
  List<CombinedKeyItem> get combinedKeys => _combinedKeys;

  // Card Codex: Unlocked Card IDs (33 신수 + 33 신격 = 66 정례 카드 도감)
  Set<String> _unlockedCardIds = {};
  Set<String> get unlockedCardIds => _unlockedCardIds;

  // --- v4.7.0: 명언 북마크 (마음에 저장) ---
  Set<String> _bookmarkedQuoteIds = {};
  Set<String> get bookmarkedQuoteIds => _bookmarkedQuoteIds;
  bool isQuoteBookmarked(String id) => _bookmarkedQuoteIds.contains(id);

  List<QuoteModel> get bookmarkedQuotes {
    final all = _engine.getAllQuotes(_lang);
    return all.where((q) => _bookmarkedQuoteIds.contains(q.id)).toList();
  }

  Future<void> bookmarkQuote(String id) async {
    if (!_bookmarkedQuoteIds.add(id)) {
      _bookmarkedQuoteIds.remove(id); // 토글
    }
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pref_bookmark_quotes', _bookmarkedQuoteIds.toList());
    notifyListeners();
  }

  // --- v4.7.1: 18종 부적 수집 (100% 온디바이스 저장) ---
  Set<String> _issuedTalismanIds = {};
  Set<String> get issuedTalismanIds => _issuedTalismanIds;

  bool isTalismanCollected(String talismanId) =>
      _issuedTalismanIds.contains(talismanId);

  int get talismanCollectionCount => _issuedTalismanIds.length;

  /// 명언 획득 시 키워드·감정·시간대에 맞춰 부적 1:1 자동 발급 (신규 발급 시 true)
  Future<bool> issueTalismanForText(String text, {String? emotion}) async {
    final item = TalismanRegistry.matchTalisman(text, emotion: emotion);
    if (_issuedTalismanIds.contains(item.id)) return false;
    _issuedTalismanIds.add(item.id);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList('pref_issued_talismans', _issuedTalismanIds.toList());
    notifyListeners();
    return true;
  }

  /// BM v5: PRO는 전면/보상형 광고 100% 제거
  bool get adFreeExperience => _isProUser;

  /// BM v5: PRO는 데일리 추가 뽑기 +3 (하루 총 4회)
  int get dailyDrawQuota => _isProUser ? 4 : 1;

  // --- PHASE 5/6: 이벤트 숫자 수집 & 도감 완성 업적 ---
  Set<String> _collectedNumbers = {}; // "1" ~ "66" (도감 정례 카드와 1:1 매핑)
  Set<String> get collectedNumbers => _collectedNumbers;
  bool _codexMasterAchieved = false;
  bool get codexMasterAchieved => _codexMasterAchieved;
  int get codexMasterProgress {
    final collected = _collectedNumbers.map((s) => int.parse(s)).toSet();
    var count = 0;
    for (var i = 1; i <= 66; i++) {
      if (collected.contains(i)) count++;
    }
    return count;
  }

  bool _pendingCodexMasterCelebration = false;
  bool get pendingCodexMasterCelebration => _pendingCodexMasterCelebration;

  // 신규 사용자 웰컴 보너스 열쇠 (1~3개 무작위 선물)
  List<int>? _pendingWelcomeNumbers;
  List<int>? get pendingWelcomeNumbers => _pendingWelcomeNumbers;
  void clearPendingWelcome() {
    _pendingWelcomeNumbers = null;
    notifyListeners();
  }

  // --- PHASE 4: 수수께끼 출석 스탬프 ---
  Set<String> _riddleStampDates = {};
  Set<String> get riddleStampDates => _riddleStampDates;
  int get riddleStampCount => _riddleStampDates.length;
  bool get riddleStampToday {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _riddleStampDates.contains(todayStr);
  }

  // --- Kkaebi Fortune Calendar & Streak Milestones (1순위) ---
  Set<int> _claimedStreakMilestones = {};
  Set<int> get claimedStreakMilestones => _claimedStreakMilestones;
  bool isStreakMilestoneClaimed(int milestone) => _claimedStreakMilestones.contains(milestone);

  // --- Kkaebi Affection / Intimacy System (3순위) ---
  int _kkaebiAffectionExp = 0;
  int get kkaebiAffectionExp => _kkaebiAffectionExp;
  int _dailyAffectionEarned = 0;
  int get dailyAffectionEarned => _dailyAffectionEarned;
  static const int dailyAffectionCap = 100;
  int get remainingDailyAffection => (dailyAffectionCap - _dailyAffectionEarned).clamp(0, dailyAffectionCap);

  int _dailyTouchCount = 0;
  int get dailyTouchCount => _dailyTouchCount;
  bool get canTouchForExp => _dailyTouchCount < 2;

  int? _pendingAffectionLevelUp;
  int? get pendingAffectionLevelUp => _pendingAffectionLevelUp;
  void clearPendingAffectionLevelUp() {
    _pendingAffectionLevelUp = null;
    notifyListeners();
  }

  /// 5단계 레벨 계산 (Lv.1: 0~99, Lv.2: 100~299, Lv.3: 300~699, Lv.4: 700~1499, Lv.5: 1500+)
  int get kkaebiLevel {
    if (_kkaebiAffectionExp >= 1500) return 5;
    if (_kkaebiAffectionExp >= 700) return 4;
    if (_kkaebiAffectionExp >= 300) return 3;
    if (_kkaebiAffectionExp >= 100) return 2;
    return 1;
  }

  int get kkaebiLevelMinExp {
    switch (kkaebiLevel) {
      case 5: return 1500;
      case 4: return 700;
      case 3: return 300;
      case 2: return 100;
      default: return 0;
    }
  }

  int get kkaebiLevelMaxExp {
    switch (kkaebiLevel) {
      case 5: return 1500;
      case 4: return 1500;
      case 3: return 700;
      case 2: return 300;
      default: return 100;
    }
  }

  int get kkaebiCurrentLevelExp {
    if (kkaebiLevel >= 5) return 1500;
    return _kkaebiAffectionExp - kkaebiLevelMinExp;
  }

  int get kkaebiNextLevelRequiredExp {
    if (kkaebiLevel >= 5) return 1500;
    return kkaebiLevelMaxExp - kkaebiLevelMinExp;
  }

  double get kkaebiLevelProgress {
    if (kkaebiLevel >= 5) return 1.0;
    final req = kkaebiNextLevelRequiredExp;
    if (req <= 0) return 1.0;
    return (kkaebiCurrentLevelExp / req).clamp(0.0, 1.0);
  }

  String get kkaebiTitle => _engine.getAffectionTitle(_lang, kkaebiLevel);
  String get kkaebiSubtitle => _engine.getAffectionSubtitle(_lang, kkaebiLevel);
  String get kkaebiQuote => _engine.getAffectionQuote(_lang, kkaebiLevel);
  List<String> get kkaebiPerks => _engine.getAffectionPerks(_lang, kkaebiLevel);

  Future<bool> addKkaebiAffection(int exp, {required String reason}) async {
    if (exp <= 0) return false;
    final remaining = dailyAffectionCap - _dailyAffectionEarned;
    if (remaining <= 0) return false;

    final actualGain = exp > remaining ? remaining : exp;
    if (actualGain <= 0) return false;

    final oldLevel = kkaebiLevel;
    _kkaebiAffectionExp += actualGain;
    _dailyAffectionEarned += actualGain;

    final newLevel = kkaebiLevel;
    if (newLevel > oldLevel) {
      _pendingAffectionLevelUp = newLevel;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_kkaebi_affection_exp', _kkaebiAffectionExp);
    await prefs.setInt('pref_daily_affection_earned', _dailyAffectionEarned);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('pref_last_affection_date', todayStr);

    notifyListeners();
    return true;
  }

  Future<Map<String, dynamic>> touchKkaebiMascot() async {
    final prefs = await SharedPreferences.getInstance();
    _dailyTouchCount++;
    await prefs.setInt('pref_daily_touch_count', _dailyTouchCount);
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    await prefs.setString('pref_last_affection_date', todayStr);

    int gainedExp = 0;
    if (_dailyTouchCount <= 2) {
      gainedExp = 5;
      await addKkaebiAffection(5, reason: 'touch');
    }

    final reaction = _engine.getRandomTouchReaction(_lang);
    notifyListeners();
    return {
      'reaction': reaction,
      'gainedExp': gainedExp,
      'level': kkaebiLevel,
      'title': kkaebiTitle,
    };
  }

  // 오늘의 골드 럭키 넘버 (수수께끼 정답 보상, 날짜 결정론)
  int get todayGoldLuckyNumber {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final hash = todayStr.hashCode.abs();
    return (hash % 99) + 1;
  }

  // Notifications
  bool _notifyEnabled = true;
  bool get notifyEnabled => _notifyEnabled;
  int _notifyHour = 8;
  int get notifyHour => _notifyHour;
  int _notifyMinute = 0;
  int get notifyMinute => _notifyMinute;

  // Daily Bonus Treasure Box
  String? _lastBonusBoxClaimDate;
  bool get canClaimBonusBox {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _lastBonusBoxClaimDate != todayStr;
  }

  // --- Seasonal & Ambient Particle System ---
  bool _particlesEnabled = true;
  bool get particlesEnabled => _particlesEnabled;
  String _seasonOverride = 'auto'; // 'auto', 'spring', 'summer', 'autumn', 'winter'
  String get seasonOverride => _seasonOverride;

  AppSeason get effectiveSeason {
    if (_seasonOverride == 'spring') return AppSeason.spring;
    if (_seasonOverride == 'summer') return AppSeason.summer;
    if (_seasonOverride == 'autumn') return AppSeason.autumn;
    if (_seasonOverride == 'winter') return AppSeason.winter;

    final month = DateTime.now().month;
    if (month >= 3 && month <= 5) return AppSeason.spring;
    if (month >= 6 && month <= 8) return AppSeason.summer;
    if (month >= 9 && month <= 11) return AppSeason.autumn;
    return AppSeason.winter;
  }

  AppTimeOfDay get effectiveTimeOfDay {
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 11) return AppTimeOfDay.dawn;
    if (hour >= 11 && hour < 17) return AppTimeOfDay.day;
    if (hour >= 17 && hour < 20) return AppTimeOfDay.dusk;
    return AppTimeOfDay.night;
  }

  bool get hasProfile =>
      _context.ageGroup != 'anon' || _context.gender != 'anon' || _context.hasNickname;
  bool get isLightTheme => _context.isLightTheme;
  String get themeOverride => _context.themeOverride;

  Future<void> initialize() async {
    if (_initialized) return;

    await SoundService().initialize();
    await _context.initialize(await SharedPreferences.getInstance());
    await _engine.initialize();
    await BrandConfig.ensureLoaded();
    await CodexService().init();

    DokkeyTheme.applyBrightness(_context.isLightTheme);

    final prefs = await SharedPreferences.getInstance();

    _lang = prefs.getString('pref_lang') ?? 'ko';
    _userId = prefs.getString('pref_user_id') ?? 'user_${DateTime.now().millisecondsSinceEpoch % 100000}';
    _keys = prefs.getInt('pref_keys') ?? 1;
    _streak = prefs.getInt('pref_streak') ?? 1;

    // v4.8.0: 아케이드 코인 & 일일 플레이 쿼터 로드
    _coins = prefs.getInt('pref_coins') ?? 0;
    final playsDate = prefs.getString('pref_arcade_plays_date') ?? '';
    final todayDate = DateFormat('yyyy-MM-dd').format(DateTime.now());
    if (playsDate == todayDate) {
      _arcadePlaysToday = prefs.getInt('pref_arcade_plays') ?? 0;
    } else {
      _arcadePlaysToday = 0;
    }

    // Load daily draws archive
    final archiveRaw = prefs.getStringList('pref_archive') ?? [];
    _archive = archiveRaw.map((s) => DrawResult.fromJson(json.decode(s))).toList();

    // Load Source Numbers
    final sourceRaw = prefs.getStringList('pref_source_numbers') ?? [];
    _sourceNumbers = sourceRaw.map((s) => SourceNumberItem.fromJson(json.decode(s))).toList();

    // Load Combined Keys & Purge expired
    final combinedRaw = prefs.getStringList('pref_combined_keys') ?? [];
    final loadedCombined = combinedRaw.map((s) => CombinedKeyItem.fromJson(json.decode(s))).toList();
    _combinedKeys = TTLManager.purgeExpiredKeys(loadedCombined);
    await _saveCombinedKeys(prefs);

    // Load Unlocked Cards for Codex
    final unlockedRaw = prefs.getStringList('pref_unlocked_cards') ?? [];
    _unlockedCardIds = unlockedRaw.toSet();

    // v4.7.0: 명언 북마크 로드
    _bookmarkedQuoteIds = (prefs.getStringList('pref_bookmark_quotes') ?? []).toSet();

    // Load Notification settings
    _notifyEnabled = prefs.getBool('pref_notify_enabled') ?? true;
    _notifyHour = prefs.getInt('pref_notify_hour') ?? 8;
    _notifyMinute = prefs.getInt('pref_notify_minute') ?? 0;

    // Load Seasonal Particles & Ambient Settings
    _particlesEnabled = prefs.getBool('pref_particles_enabled') ?? true;
    _seasonOverride = prefs.getString('pref_season_override') ?? 'auto';

    // Load Bonus Box claim date
    _lastBonusBoxClaimDate = prefs.getString('pref_last_bonus_box_date');
    _onboardingDismissed = prefs.getBool('pref_onboarding_dismissed') ?? false;
    _isProUser = prefs.getBool('dokkey_is_pro_user') ?? false;

    // PHASE 5/6: collected numbers & codex master achievement
    final collectedRaw = prefs.getStringList('pref_collected_numbers') ?? [];
    _collectedNumbers = collectedRaw.toSet();
    _codexMasterAchieved = prefs.getBool('pref_codex_master') ?? false;
    _codexMasterAchieved = _codexMasterAchieved || codexMasterProgress >= 66;

    // 등급 변경(패스 만료·환불 등)에 대비해 슬롯 한도 초과분을 오래된 순으로 정리
    _trimToSlotLimit();

    // PHASE 4: riddle attendance stamps
    final stampRaw = prefs.getStringList('pref_riddle_stamps') ?? [];
    _riddleStampDates = stampRaw.toSet();

    // Kkaebi Fortune Calendar: claimed streak milestones
    final claimedMilestonesRaw = prefs.getStringList('pref_claimed_streak_milestones') ?? [];
    _claimedStreakMilestones = claimedMilestonesRaw.map((s) => int.tryParse(s) ?? 0).where((m) => m > 0).toSet();

    // v4.7.0: Saved / Bookmarked Quotes
    final bookmarkedQuotesRaw = prefs.getStringList('pref_bookmark_quotes') ?? [];
    _bookmarkedQuoteIds = bookmarkedQuotesRaw.toSet();

    // Check today draw & reset daily count if new date
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

    // Kkaebi Affection / Intimacy System
    _kkaebiAffectionExp = prefs.getInt('pref_kkaebi_affection_exp') ?? 0;
    final lastAffectionDate = prefs.getString('pref_last_affection_date');
    if (lastAffectionDate == todayStr) {
      _dailyAffectionEarned = prefs.getInt('pref_daily_affection_earned') ?? 0;
      _dailyTouchCount = prefs.getInt('pref_daily_touch_count') ?? 0;
    } else {
      _dailyAffectionEarned = 0;
      _dailyTouchCount = 0;
      await prefs.setInt('pref_daily_affection_earned', 0);
      await prefs.setInt('pref_daily_touch_count', 0);
    }

    final lastDrawDate = prefs.getString('pref_last_draw_date');
    if (lastDrawDate == todayStr) {
      _drawCountToday = prefs.getInt('pref_draw_count_today') ?? 0;
      final savedResultJson = prefs.getString('pref_today_result');
      if (savedResultJson != null) {
        _todayResult = DrawResult.fromJson(json.decode(savedResultJson));
      }
    } else {
      _drawCountToday = 0;
      // v4.7.1 BM: 무료 하루 1회 / PRO 하루 총 4회 (데일리 추가 뽑기 +3)
      _keys = _isProUser ? 4 : 1;
      await prefs.setInt('pref_keys', _keys);
      await prefs.setInt('pref_draw_count_today', 0);

      // 어제도 안 들어왔고 오늘 처음 온 경우 스트릭 리셋 검사
      if (lastDrawDate != null) {
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
        if (lastDrawDate != yesterdayStr) {
          _streak = 1;
          await prefs.setInt('pref_streak', 1);
        }
      }
    }

    // v4.7.0 Wisdom-First: 데일리 명언 엔진으로 결정론적 선정
    _todayQuote = DailyQuoteEngine.pickDailyQuote(
      pool: _engine.getAllQuotes(_lang),
      userUuid: _userId,
      now: DateTime.now(),
      recentIds: prefs.getStringList('pref_recent_quote_ids') ?? [],
      currentSlot: _context.slotId,
    );
    final pickedQuoteId = _todayQuote?.id;
    if (pickedQuoteId != null) {
      final history = prefs.getStringList('pref_recent_quote_ids') ?? [];
      history.insert(0, pickedQuoteId);
      if (history.length > 14) history.removeLast();
      await prefs.setStringList('pref_recent_quote_ids', history);
    }

    // v4.7.0 5순위: 홈 화면 위젯 데이터 갱신 (명언 중심)
    if (_todayQuote != null) {
      await WidgetService.updateToday(
        quoteText: _todayQuote!.text,
        quoteAuthor: _todayQuote!.authorLabel,
        kkaebiComment: _todayQuote!.kkaebiComment,
        luckyNumber: todayGoldLuckyNumber.toString().padLeft(2, '0'),
      );
    }

    // v4.7.1: 부적 수집 로드 (18종)
    _issuedTalismanIds =
        (prefs.getStringList('pref_issued_talismans') ?? []).toSet();

    // Real morning notification scheduling (native only)
    await _notifications.initialize();
    await _notifications.scheduleDaily(
      enabled: _notifyEnabled,
      hour: _notifyHour,
      minute: _notifyMinute,
    );

    _initialized = true;

    // 신규 사용자 웰컴 보너스 3개 열쇠 자동 지급 (보관함 + 도감 100% 동기화)
    final welcomeGiven = prefs.getBool('pref_welcome_bonus_v1') ?? false;
    if (!welcomeGiven && _sourceNumbers.isEmpty) {
      await _grantWelcomeBonus(prefs);
    }

    // PHASE 5: 시진별(2시간) 재방문 보너스 숫자 (초기화 완료 후 1회 체크)
    await _checkShichenRevisitBonus();

    notifyListeners();
  }

  /// 신규 사용자 웰컴 선물: 무작위 1~3개(3개)의 행운 열쇠 번호 보관함 & 도감 지급
  Future<void> _grantWelcomeBonus(SharedPreferences prefs) async {
    final rand = Random();
    // 3개 고유 번호 (1~33 신수 1개, 34~66 신격 1개, 1~99 자유 1개)
    final num1 = rand.nextInt(33) + 1;
    final num2 = rand.nextInt(33) + 34;
    final bonusSet = <int>{num1, num2};
    while (bonusSet.length < 3) {
      bonusSet.add(rand.nextInt(99) + 1);
    }
    final bonusList = bonusSet.toList()..sort();
    _pendingWelcomeNumbers = bonusList;

    for (final num in bonusList) {
      await addEventNumber(
        rawNumber: num,
        cardName: '깨비의 웰컴 선물',
        toneName: '웰컴',
        toneColor: '#FFD700',
        headline: '첫 방문 웰컴 스타터 열쇠 번호',
      );
    }
    await prefs.setBool('pref_welcome_bonus_v1', true);
  }

  /// 시진(2시간)이 바뀐 재방문일 때만 1회 보너스 숫자 지급
  Future<void> _checkShichenRevisitBonus() async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final currentShichen = _engine.getShichenForNow();
    final key = '$todayStr:${currentShichen['id']}';
    final lastKey = prefs.getString('pref_last_shichen_bonus_key');
    if (lastKey == key) return;

    await prefs.setString('pref_last_shichen_bonus_key', key);
    if (_context.visitState.name == 'firstVisit') return; // 첫 방문은 첫 드로우로 충분

    final bonusSeed = '$_userId:$key:shichen_bonus:DOK_KEY_V1';
    final bonusNumber = (bonusSeed.hashCode.abs() % 99) + 1;
    await addEventNumber(
      rawNumber: bonusNumber,
      cardName: currentShichen['hanja'] ?? '',
      toneName: '럭키',
      toneColor: '#F5BD42',
      headline: '시진(${currentShichen['hanja']}) 재방문 보너스 숫자!',
    );
  }

  /// PHASE 4/5: 다채널 숫자 드롭 통합 게이트
  /// (카드 드로우 / 시진 보너스 / 수수께끼 정답 / 꿈풀이 완료 → 보관함 + 도감 연동)
  Future<(bool newNumber, bool newAchievement)> addEventNumber({
    required int rawNumber,
    String cardId = '',
    String cardName = '',
    String timeslotId = '',
    String toneName = '럭키',
    String toneColor = '#F5BD42',
    String headline = '',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    _sourceNumbers = SourceNumberManager.addOrUpdateNumber(
      currentPool: _sourceNumbers,
      rawNumber: rawNumber,
      cardId: cardId,
      cardName: cardName,
      timeslotId: timeslotId,
      toneName: toneName,
      toneColor: toneColor,
      headline: headline,
    );
    await _saveSourceNumbers(prefs);

    var newNumber = false;
    final n = rawNumber.clamp(1, 99);
    if (n <= 66) {
      newNumber = _collectedNumbers.add('$n');
      await prefs.setStringList('pref_collected_numbers', _collectedNumbers.toList());
      await CodexService().unlockNumber(n);
    }

    var newAchievement = false;
    if (!_codexMasterAchieved && codexMasterProgress >= 66) {
      _codexMasterAchieved = true;
      _pendingCodexMasterCelebration = true;
      await prefs.setBool('pref_codex_master', true);
      newAchievement = true;
    }

    notifyListeners();
    return (newNumber, newAchievement);
  }

  /// 인스펙터 치트: 숫자 풀 강제 주입 ("07", "77", "88" ...)
  Future<void> injectNumber(String numberStr) async {
    final raw = int.tryParse(numberStr);
    if (raw == null || raw < 1 || raw > 99) return;
    await addEventNumber(
      rawNumber: raw,
      cardName: 'INSPECTOR',
      toneName: '디버그',
      toneColor: '#8338EC',
      headline: '인스펙터 주입 번호 $numberStr',
    );
  }

  /// 인스펙터 치트: 오늘의 카드를 지정 카드로 강제 교체
  Future<DrawResult?> forceTodayCard(String cardId) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    final result = _engine.draw(
      userId: _userId,
      dateStr: todayStr,
      lang: _lang,
      contextSlot: _context.slotId,
      drawIndex: _drawCountToday,
      overrideCardId: cardId,
    );
    _todayResult = result;
    _unlockedCardIds.add(result.card.id);
    await prefs.setStringList('pref_unlocked_cards', _unlockedCardIds.toList());
    await prefs.setString('pref_today_result', json.encode(result.toJson()));

    // v4.7.1: 드로우 결과의 기운에 맞춰 18종 부적 1:1 자동 발급 & 도감 수집
    await issueTalismanForText(
      '${result.headline} ${result.body} ${result.card.name}',
      emotion: result.tone.id,
    );

    notifyListeners();
    return result;
  }

  /// PHASE 4: 수수께끼 정답 처리 (럭키 넘버 드롭 + 출석 스탬프 적립)
  Future<int?> onRiddleCorrect() async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();
    _riddleStampDates.add(todayStr);
    await prefs.setStringList('pref_riddle_stamps', _riddleStampDates.toList());

    await addBonusKeys(1);
    await addKkaebiAffection(15, reason: 'riddle');

    // 일일 1회만 골드 럭키 넘버 드롭 (재도전 시 열쇠만 지급)
    if (!riddleStampToday || _riddleStampDates.where((d) => d == todayStr).length == 1) {
      final lucky = todayGoldLuckyNumber;
      await addEventNumber(
        rawNumber: lucky,
        cardName: 'GOLD',
        toneName: '골드',
        toneColor: '#F5BD42',
        headline: '수수께끼 정답 골드 럭키 넘버!',
      );
      return lucky;
    }
    return null;
  }

  /// PHASE 4: 꿈풀이 분석 완료 → 꿈 상징수 보관함 입고 (심볼당 일 1회)
  Future<bool> onDreamAnalyzed(DreamSymbol symbol) async {
    final prefs = await SharedPreferences.getInstance();
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final dropKey = '$todayStr:${symbol.id}';
    final drops = prefs.getStringList('pref_dream_number_drops') ?? [];
    if (drops.contains(dropKey)) return false;

    drops.add(dropKey);
    if (drops.length > 90) drops.removeAt(0);
    await prefs.setStringList('pref_dream_number_drops', drops);

    await addEventNumber(
      rawNumber: symbol.luckyNumber,
      cardId: symbol.cardId,
      cardName: symbol.label,
      toneName: '꿈',
      toneColor: '#4E9F8E',
      headline: '꿈풀이 상징수: ${symbol.label}',
    );
    return true;
  }

  void consumeCodexMasterCelebration() {
    _pendingCodexMasterCelebration = false;
  }

  /// 테스트 전용: 직접 만든 조합키 주입 (만료/정리 시나리오 검증용)
  void combinedKeysManualInsertForTest(CombinedKeyItem fresh, CombinedKeyItem stale) {
    _combinedKeys.insert(0, fresh);
    _combinedKeys.insert(0, stale);
  }

  bool _onboardingDismissed = false;

  /// 첫 방문이며 프로필이 비어 있고 아직 건너뛰지 않았을 때만 1회 유도
  bool shouldShowOnboarding() =>
      _initialized &&
      _context.isFirstVisit &&
      !hasProfile &&
      !_onboardingDismissed;

  Future<void> markOnboardingShown() async {
    _onboardingDismissed = true;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_onboarding_dismissed', true);
    notifyListeners();
  }

  // --- Profile Keys (옵션 입력 키) ---

  Future<void> updateProfile({
    required String ageGroup,
    required String gender,
    required String nickname,
  }) async {
    await _context.updateProfile(
      ageGroup: ageGroup,
      gender: gender,
      nickname: nickname,
    );
    notifyListeners();
  }

  // --- Theme (조도 키) ---

  Future<void> setThemeOverride(String mode) async {
    await _context.setThemeOverride(mode);
    DokkeyTheme.applyBrightness(_context.isLightTheme);
    notifyListeners();
  }

  String get greeting {
    if (!_initialized) return '';
    return _engine.getContextGreeting(
      lang: _lang,
      visitState: _context.visitState,
      slotId: _context.slotId,
      nickname: _context.displayNickname,
    );
  }

  void toggleLanguage() async {
    final next = _lang == 'ko'
        ? 'en'
        : (_lang == 'en'
            ? 'ja'
            : (_lang == 'ja'
                ? 'zh'
                : (_lang == 'zh' ? 'hi' : 'ko')));
    await setLanguage(next);
  }

  /// 언어 즉시 전환 (인스펙터 스위처용, 재시작 불필요)
  Future<void> setLanguage(String lang) async {
    if (!['ko', 'en', 'ja', 'zh', 'hi', 'de'].contains(lang)) return;
    _lang = lang;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_lang', _lang);

    if (_todayResult != null) {
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      _todayResult = _engine.draw(
        userId: _userId,
        dateStr: todayStr,
        lang: _lang,
        timeslotOverride: ContextKeyEngine.slotIdFromString(_todayResult!.timeslot.id),
        drawIndex: 0,
      );
      await prefs.setString('pref_today_result', json.encode(_todayResult!.toJson()));
    }

    // 언어 전환 시에도 결정론적 데일리 명언 유지 (동일 날짜 = 동일 명언, 언어만 교체)
    _todayQuote = DailyQuoteEngine.pickDailyQuote(
      pool: _engine.getAllQuotes(_lang),
      userUuid: _userId,
      now: DateTime.now(),
      recentIds: prefs.getStringList('pref_recent_quote_ids') ?? [],
      currentSlot: _context.slotId,
    );
    notifyListeners();
  }

  /// 사계절 및 시간대 앰비언트 파티클 활성화 토글
  Future<void> setParticlesEnabled(bool val) async {
    _particlesEnabled = val;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_particles_enabled', val);
    notifyListeners();
  }

  /// 계절 수동 오버라이드 ('auto', 'spring', 'summer', 'autumn', 'winter')
  Future<void> setSeasonOverride(String season) async {
    _seasonOverride = season;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_season_override', season);
    notifyListeners();
  }

  Future<DrawResult> executeDraw({bool isExtra = false}) async {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final prefs = await SharedPreferences.getInstance();

    final seed = _context.toSeed();
    final result = _engine.draw(
      userId: _userId,
      dateStr: todayStr,
      lang: _lang,
      contextSlot: _context.slotId,
      contextSeed: seed,
      drawIndex: _drawCountToday,
      overrideSeed: isExtra ? DateTime.now().millisecondsSinceEpoch : null,
    );

    _drawCountToday += 1;
    _todayResult = result;
    if (_keys > 0) {
      _keys--;
    }

    final lastDrawDate = prefs.getString('pref_last_draw_date');
    if (lastDrawDate != todayStr) {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayStr = DateFormat('yyyy-MM-dd').format(yesterday);
      if (lastDrawDate == yesterdayStr) {
        _streak += 1;
      } else {
        _streak = 1;
      }
      await prefs.setInt('pref_streak', _streak);
    }

    // 1. Unlock Card in Codex
    _unlockedCardIds.add(result.card.id);
    await prefs.setStringList('pref_unlocked_cards', _unlockedCardIds.toList());
    await CodexService().unlockNumber(result.number);

    // 1.5 v4.7.1: 18종 부적 1:1 자동 발급 & 도감 수집 (100% 온디바이스)
    await issueTalismanForText(
      '${result.headline} ${result.body} ${result.card.name}',
      emotion: result.tone.id,
    );

    // 2. Save to daily history archive (max 365 days, deduplicated by dateStr)
    _archive.removeWhere((a) => a.dateStr == result.dateStr);
    _archive.insert(0, result);
    if (_archive.length > 365) {
      _archive = _archive.sublist(0, 365);
    }

    // 3. Automatically collect in Source Numbers Pool with fortune metadata
    _sourceNumbers = SourceNumberManager.addOrUpdateNumber(
      currentPool: _sourceNumbers,
      rawNumber: result.number,
      cardId: result.card.id,
      cardName: result.card.name,
      timeslotId: result.timeslot.id,
      toneName: result.tone.name,
      toneColor: result.tone.color,
      headline: result.headline,
    );

    await prefs.setString('pref_last_draw_date', todayStr);
    await prefs.setInt('pref_draw_count_today', _drawCountToday);
    await prefs.setString('pref_today_result', json.encode(result.toJson()));
    await prefs.setInt('pref_keys', _keys);
    await prefs.setStringList('pref_archive', _archive.map((a) => json.encode(a.toJson())).toList());
    await _saveSourceNumbers(prefs);

    await addKkaebiAffection(30, reason: 'draw');

    notifyListeners();
    return result;
  }

  /// Kkaebi Fortune Calendar & Streak Milestone Reward Claim
  Future<bool> claimStreakReward(int milestone) async {
    if (_streak < milestone || _claimedStreakMilestones.contains(milestone)) return false;
    _claimedStreakMilestones.add(milestone);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      'pref_claimed_streak_milestones',
      _claimedStreakMilestones.map((m) => m.toString()).toList(),
    );

    int bonusKeys = 1;
    if (milestone == 3) {
      bonusKeys = 1;
    } else if (milestone == 7) {
      bonusKeys = 2;
    } else if (milestone == 14) {
      bonusKeys = 3;
    } else if (milestone == 30) {
      bonusKeys = 5;
    }

    _keys += bonusKeys;
    await prefs.setInt('pref_keys', _keys);

    SoundService().playAlchemyFanfare();
    notifyListeners();
    return true;
  }

  /// 날짜별 운세 검색 헬퍼 (yyyy-MM-dd)
  DrawResult? getDrawResultForDate(String dateStr) {
    if (_todayResult != null && _todayResult!.dateStr == dateStr) {
      return _todayResult;
    }
    for (final r in _archive) {
      if (r.dateStr == dateStr) return r;
    }
    return null;
  }

  bool hasDrawForDate(String dateStr) => getDrawResultForDate(dateStr) != null;

  Map<String, DrawResult> get archiveByDateMap {
    final map = <String, DrawResult>{};
    for (final r in _archive) {
      map[r.dateStr] = r;
    }
    if (_todayResult != null) {
      map[_todayResult!.dateStr] = _todayResult!;
    }
    return map;
  }

  bool isNewUnlock(DrawResult result) => result.card.id == _todayResult?.card.id;

  Future<bool> claimDailyBonusBox() async {
    if (!canClaimBonusBox) return false;

    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    _lastBonusBoxClaimDate = todayStr;
    _keys += 1;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('pref_last_bonus_box_date', todayStr);
    await prefs.setInt('pref_keys', _keys);

    notifyListeners();
    return true;
  }

  Future<void> updateNotificationSettings(bool enabled, int hour, int minute) async {
    _notifyEnabled = enabled;
    _notifyHour = hour;
    _notifyMinute = minute;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('pref_notify_enabled', enabled);
    await prefs.setInt('pref_notify_hour', hour);
    await prefs.setInt('pref_notify_minute', minute);

    await _notifications.scheduleDaily(enabled: enabled, hour: hour, minute: minute);

    notifyListeners();
  }

  Future<void> addBonusKeys(int amount) async {
    _keys += amount;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('pref_keys', _keys);
    notifyListeners();
  }

  List<CardModel> getAllCodexCards() {
    return _engine.getAllCards(_lang);
  }

  List<Map<String, dynamic>> getKkaebiTopics() {
    return _engine.getKkaebiTopics(_lang);
  }

  String getKkaebiAnswer(String topicId, [int stepCount = 1]) {
    return _engine.getKkaebiProgressiveAnswer(
      _lang,
      topicId,
      stepCount,
      _todayResult,
      nickname: _context.displayNickname,
    );
  }

  RiddleModel getTodayRiddle([int? index]) {
    return _engine.getRiddle(_lang, index);
  }

  // --- Dream Interpretation (꿈풀이) ---

  List<DreamSymbol> get dreamSymbols => _engine.getDreamSymbols(_lang);

  DreamSymbol get todayDreamSymbol {
    final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _engine.getDailyDreamSymbol(_lang, todayStr);
  }

  /// 시辰 브릿지: 오늘 결과의 카드가 현재 지신과 공명하는지
  Map<String, dynamic> get shichen => _engine.getShichenForNow();

  bool get isShichenResonant {
    if (_todayResult == null) return false;
    return _engine.isZodiacCard(_todayResult!.card.id) &&
        _todayResult!.card.id == shichen['zodiac'];
  }

  // --- N-Key Combiner Operations ---

  /// 무료: 7일 TTL 자동 만료 순환 / Pro: 장기 고정 보관
  static const Duration freeKeyTtl = Duration(days: 7);
  static const Duration proKeyTtl = Duration(days: 3650);

  Duration get combinedKeyTtl => _isProUser ? proKeyTtl : freeKeyTtl;

  /// 만료(또는 곧 만료)된 조합키 개수 — 일괄 정리 버튼 노출 조건
  int get expiredCombinedKeyCount {
    final now = DateTime.now();
    return _combinedKeys.where((k) => k.expiresAt != null && !now.isBefore(k.expiresAt!)).length;
  }

  /// 조합키가 슬롯 한도를 초과했을 때 초과분을 가장 오래된 순으로 잘라내는 정리기
  List<CombinedKeyItem> _trimToSlotLimit() {
    if (_combinedKeys.length <= maxCombinedSlots) return const [];
    final removed = _combinedKeys.sublist(maxCombinedSlots);
    _combinedKeys = _combinedKeys.sublist(0, maxCombinedSlots);
    return removed;
  }

  Future<CombinedKeyItem> combineAndSaveKeys({
    bool checkSlotLimit = true,
    required int targetCount,
    required Set<String> selectedPool,
    String? userTag,
    bool allowDuplicates = false,
  }) async {
    if (checkSlotLimit && !canAddCombinedKey) {
      throw Exception('MAX_SLOTS_REACHED');
    }
    final weights = {for (final s in _sourceNumbers) s.numberStr: s.count};
    final combinedNumbers = KeyCombinerEngine.combine(
      availablePool: _sourceNumbers.map((s) => s.numberStr).toList(),
      selectedPool: selectedPool.toList(),
      targetCount: targetCount,
      allowDuplicates: allowDuplicates,
      weightByNumber: weights,
    );

    final newKey = KeyCombinerEngine.createCombinedKeyItem(
      numbers: combinedNumbers,
      userTag: userTag,
      ttl: combinedKeyTtl, // 무료 7일 순환 / Pro 장기 고정
    );

    _combinedKeys.insert(0, newKey);
    final prefs = await SharedPreferences.getInstance();
    await _saveCombinedKeys(prefs);

    await addKkaebiAffection(10, reason: 'combine');

    notifyListeners();
    return newKey;
  }

  Future<void> togglePermanentLock(String keyId) async {
    final index = _combinedKeys.indexWhere((k) => k.id == keyId);
    if (index != -1) {
      final key = _combinedKeys[index];
      if (key.isPermanent) {
        // 잠금 해제 시 등급별 보관 기간 복원 (무료 7일 / Pro 장기)
        key.expiresAt = DateTime.now().add(combinedKeyTtl);
      } else {
        key.expiresAt = null;
        key.isCloudSynced = true;
      }
      final prefs = await SharedPreferences.getInstance();
      await _saveCombinedKeys(prefs);
      notifyListeners();
    }
  }

  /// 만료된 조합키 일괄 정리 (Clean Expired) — 정리된 개수 반환
  Future<int> clearExpiredCombinedKeys() async {
    final before = _combinedKeys.length;
    _combinedKeys = TTLManager.purgeExpiredKeys(_combinedKeys);
    final removed = before - _combinedKeys.length;
    if (removed > 0) {
      final prefs = await SharedPreferences.getInstance();
      await _saveCombinedKeys(prefs);
      notifyListeners();
    }
    return removed;
  }

  /// 만료된 키 + 무료 등급에서 7일이 지난 오래된 키를 포함해 일괄 정리
  /// (Pro의 장기 보관 키는 만료 전이므로 보존됨)
  Future<int> clearStaleCombinedKeys() async {
    final now = DateTime.now();
    final before = _combinedKeys.length;
    _combinedKeys = _combinedKeys.where((k) {
      if (k.expiresAt == null) return true;
      if (now.isBefore(k.expiresAt!)) return true;
      return false;
    }).toList();
    final removed = before - _combinedKeys.length;
    if (removed > 0) {
      final prefs = await SharedPreferences.getInstance();
      await _saveCombinedKeys(prefs);
      notifyListeners();
    }
    return removed;
  }

  /// 전체 조합키 일괄 삭제 (Clean All) — 삭제 확인 다이얼로그 통과 후 호출
  Future<int> clearAllCombinedKeys() async {
    final removed = _combinedKeys.length;
    _combinedKeys.clear();
    final prefs = await SharedPreferences.getInstance();
    await _saveCombinedKeys(prefs);
    notifyListeners();
    return removed;
  }

  Future<void> deleteCombinedKey(String keyId) async {
    _combinedKeys.removeWhere((k) => k.id == keyId);
    final prefs = await SharedPreferences.getInstance();
    await _saveCombinedKeys(prefs);
    notifyListeners();
  }

  /// 완성된 열쇠의 커스텀 태그 편집 ("이번 주 로또", "도깨비 중첩비기" 등)
  Future<void> updateCombinedKeyTag(String keyId, String tag) async {
    final index = _combinedKeys.indexWhere((k) => k.id == keyId);
    if (index != -1) {
      _combinedKeys[index].userTag = tag.trim().isEmpty ? null : tag.trim();
      final prefs = await SharedPreferences.getInstance();
      await _saveCombinedKeys(prefs);
      notifyListeners();
    }
  }

  Future<void> toggleSourceNumberPin(String numberStr) async {
    final index = _sourceNumbers.indexWhere((s) => s.numberStr == numberStr);
    if (index != -1) {
      _sourceNumbers[index].isPinned = !_sourceNumbers[index].isPinned;
      _sourceNumbers.sort((a, b) {
        if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
        return a.numberStr.compareTo(b.numberStr);
      });
      final prefs = await SharedPreferences.getInstance();
      await _saveSourceNumbers(prefs);
      notifyListeners();
    }
  }

  String exportVaultBackup() {
    return PersonalCloudVaultService.exportVaultJson(
      sourceNumbers: _sourceNumbers,
      combinedKeys: _combinedKeys,
    );
  }

  Future<bool> importVaultBackup(String jsonString) async {
    try {
      final data = PersonalCloudVaultService.importVaultJson(jsonString);
      _sourceNumbers = data.sourceNumbers;
      _combinedKeys = TTLManager.purgeExpiredKeys(data.combinedKeys);

      final prefs = await SharedPreferences.getInstance();
      await _saveSourceNumbers(prefs);
      await _saveCombinedKeys(prefs);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _saveSourceNumbers(SharedPreferences prefs) async {
    await prefs.setStringList(
      'pref_source_numbers',
      _sourceNumbers.map((s) => json.encode(s.toJson())).toList(),
    );
  }

  Future<void> _saveCombinedKeys(SharedPreferences prefs) async {
    await prefs.setStringList(
      'pref_combined_keys',
      _combinedKeys.map((k) => json.encode(k.toJson())).toList(),
    );
  }
}
