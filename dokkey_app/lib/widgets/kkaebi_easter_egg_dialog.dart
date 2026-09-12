import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';

/// 🎲 깨비 12연타 이스터에그 서비스 (1시간 고정 번호 관리)
class KkaebiEasterEggService {
  static const String _prefHourKey = 'pref_easter_egg_hour_slot';
  static const String _prefNumberKey = 'pref_easter_egg_number';

  /// 현재 1시간 슬롯 키 (예: "2026_9_10_1")
  static String getCurrentHourSlotKey([DateTime? now]) {
    final dt = now ?? DateTime.now();
    return '${dt.year}_${dt.month}_${dt.day}_${dt.hour}';
  }

  /// 이번 1시간 동안 고정된 0~9 행운/사다리 숫자 반환
  static Future<int> getHourlyNumber([DateTime? now]) async {
    final prefs = await SharedPreferences.getInstance();
    final currentSlot = getCurrentHourSlotKey(now);
    final savedSlot = prefs.getString(_prefHourKey);

    if (savedSlot == currentSlot && prefs.containsKey(_prefNumberKey)) {
      return prefs.getInt(_prefNumberKey)!;
    }

    // 새로운 1시간 슬롯: 0 ~ 9 사이의 랜덤 숫자 1개 발급 및 저장
    final randomNum = math.Random().nextInt(10);
    await prefs.setString(_prefHourKey, currentSlot);
    await prefs.setInt(_prefNumberKey, randomNum);
    return randomNum;
  }

  /// 다음 정시까지 남은 시간(분) 계산
  static int getRemainingMinutes([DateTime? now]) {
    final dt = now ?? DateTime.now();
    return math.max(1, 60 - dt.minute);
  }
}

/// 💥 12연타 히든 사다리 숫자 게임 전체화면 모달 (6개 언어 완벽 지원 & 고가시성 UI)
class KkaebiEasterEggDialog extends StatefulWidget {
  const KkaebiEasterEggDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false, // 우측 상단 X 버튼으로만 닫힘
      builder: (_) => const KkaebiEasterEggDialog(),
    );
  }

  @override
  State<KkaebiEasterEggDialog> createState() => _KkaebiEasterEggDialogState();
}

class _KkaebiEasterEggDialogState extends State<KkaebiEasterEggDialog>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _glowAnim;
  final math.Random _rollRandom = math.Random();
  Timer? _tickTimer;

  int? _displayNumber;
  String? _loadedSlot;
  int _remainingMinutes = 60;
  bool _isLoading = true;
  bool _isRevealing = false;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _scaleAnim = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutBack),
    );

    _glowAnim = Tween<double>(begin: 0.45, end: 0.90).animate(
      CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOutSine),
    );

    _loadNumber();
    // 🕒 15초 주기: 카운트다운 갱신 + 정시 전환 감지 시 새 번호 자동 재추첨
    _tickTimer = Timer.periodic(const Duration(seconds: 15), (_) => _onTick());
  }

  Future<void> _loadNumber() async {
    if (_isRevealing) return;
    _isRevealing = true;
    final slot = KkaebiEasterEggService.getCurrentHourSlotKey();
    final num = await KkaebiEasterEggService.getHourlyNumber();
    final remaining = KkaebiEasterEggService.getRemainingMinutes();
    if (!mounted) {
      _isRevealing = false;
      return;
    }
    _loadedSlot = slot;
    // 🎰 슬롯머신 롤링 연출 후 운명 숫자 확정
    setState(() => _isLoading = false);
    for (var i = 0; i < 12; i++) {
      if (!mounted) {
        _isRevealing = false;
        return;
      }
      setState(() => _displayNumber = _rollRandom.nextInt(10));
      await Future.delayed(const Duration(milliseconds: 55));
    }
    if (!mounted) {
      _isRevealing = false;
      return;
    }
    HapticFeedback.mediumImpact();
    SoundService().playGong();
    setState(() {
      _displayNumber = num;
      _remainingMinutes = remaining;
    });
    _isRevealing = false;
  }

  /// 🕒 주기 동기화: 잔여 시간 갱신 + 정시 전환 감지 시 새 번호 재추첨
  Future<void> _onTick() async {
    if (_isRevealing) return;
    final slot = KkaebiEasterEggService.getCurrentHourSlotKey();
    if (slot != _loadedSlot) {
      await _loadNumber();
      return;
    }
    final remaining = KkaebiEasterEggService.getRemainingMinutes();
    if (mounted && remaining != _remainingMinutes) {
      setState(() => _remainingMinutes = remaining);
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _pulseCtrl.dispose();
    super.dispose();
  }

  // 6개 언어 번역 사전 (ko, en, ja, zh, hi, de)
  Map<String, String> _getTexts(String lang) {
    switch (lang) {
      case 'ja':
        return {
          'badge': '⚡ 隠しイースターエッグ',
          'title': 'クケビあみだくじ番号',
          'subtitle': 'クケビを12回タップして召喚された運命の番号！',
          'lockHeader': '1時間この番号に固定されます',
          'rule1': '• 1時間以内は何回タップしても番号は変わりません（引き直し不正防止！）',
          'rule2': '• 「一番低い数字の人がご飯やコーヒーを奢る！」といった勝負ゲームにご活用ください。',
          'refreshLabel': '🕒 次の番号更新まで',
          'refreshValue': '残り約 $_remainingMinutes分（毎正時更新）',
          'closeTooltip': '閉じる',
        };
      case 'zh':
        return {
          'badge': '⚡ 隐藏彩蛋',
          'title': '小妖梯子游戏号码',
          'subtitle': '连续点击小妖12次召唤的命运号码！',
          'lockHeader': '此号码将在1小时内锁定',
          'rule1': '• 在接下来的1小时内，无论点击多少次号码都不会改变（防止重抽耍赖！）',
          'rule2': '• 可用于“抽到最小数字的人请喝咖啡或吃饭！”等趣味游戏。',
          'refreshLabel': '🕒 距离下次号码刷新',
          'refreshValue': '约剩 $_remainingMinutes 分钟（整点自动刷新）',
          'closeTooltip': '关闭',
        };
      case 'hi':
        return {
          'badge': '⚡ गुप्त ईस्टर एग',
          'title': 'क्काएबी लैडर संख्या',
          'subtitle': 'क्काएबी को 12 बार छूकर बुलाई गई आपकी भाग्यशाली संख्या!',
          'lockHeader': 'यह संख्या 1 घंटे के लिए स्थिर रहेगी',
          'rule1': '• 1 घंटे के दौरान दोबारा छूने पर भी यह नंबर नहीं बदलेगा। (धोखाधड़ी से बचाव!)',
          'rule2': '• "सबसे कम नंबर वाला चाय या लंच खिलाएगा!" जैसे मजेदार दांव के लिए इस्तेमाल करें।',
          'refreshLabel': '🕒 अगला नंबर रीसेट होने में',
          'refreshValue': 'लगभग $_remainingMinutes मिनट शेष (हर घंटे रीसेट)',
          'closeTooltip': 'बंद करें',
        };
      case 'de':
        return {
          'badge': '⚡ Verstecktes Easter Egg',
          'title': 'Kkaebi-Leiter-Zahl',
          'subtitle': 'Durch 12-maliges Antippen beschworen! Deine Schicksalszahl!',
          'lockHeader': 'Diese Zahl bleibt 1 Stunde lang fest',
          'rule1': '• Die Zahl ändert sich 1 Stunde lang nicht, egal wie oft du tippst. (Kein Neuziehen!)',
          'rule2': '• Perfekt für Spiele: „Wer die niedrigste Zahl hat, zahlt den Kaffee oder das Essen!“',
          'refreshLabel': '🕒 Nächste Aktualisierung in',
          'refreshValue': 'Ca. $_remainingMinutes Min. verbleibend (stündlich neu)',
          'closeTooltip': 'Schließen',
        };
      case 'en':
        return {
          'badge': '⚡ Hidden Easter Egg',
          'title': 'Kkaebi Ladder Number',
          'subtitle': 'Summoned by tapping Kkaebi 12 times! Your destiny number!',
          'lockHeader': 'This number is locked for 1 hour',
          'rule1': '• The number stays fixed for 1 hour no matter how many times you tap. (No re-rolling!)',
          'rule2': '• Use it for betting games like "Lowest number buys coffee or lunch!" with friends.',
          'refreshLabel': '🕒 Next number reset in',
          'refreshValue': 'Approx. $_remainingMinutes m left (Resets hourly)',
          'closeTooltip': 'Close',
        };
      case 'ko':
      default:
        return {
          'badge': '⚡ 히든 이스터에그',
          'title': '도깨비 사다리 번호',
          'subtitle': '깨비를 12번 터치해 소환된 오늘의 운명 번호!',
          'lockHeader': '1시간 동안 이 번호가 고정됩니다',
          'rule1': '• 아무리 다시 터치해도 이번 1시간 동안은 번호가 바뀌지 않습니다. (재추첨 꼼수 방지!)',
          'rule2': '• "가장 낮은/높은 숫자가 밥이나 커피 사기!" 같은 사다리 게임에 활용해 보세요.',
          'refreshLabel': '🕒 다음 번호 갱신까지',
          'refreshValue': '약 $_remainingMinutes분 남음 (매 정시 갱신)',
          'closeTooltip': '닫기',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final t = _getTexts(provider.lang);

    return PopScope(
      canPop: false, // 안드로이드 백버튼으로 닫히지 않고 우측 상단 X 버튼으로만 닫힘
      child: Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 420),
          decoration: BoxDecoration(
            color: const Color(0xFF14120E),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: DokkeyTheme.gold,
              width: 2.2,
            ),
            boxShadow: [
              BoxShadow(
                color: DokkeyTheme.gold.withValues(alpha: 0.40),
                blurRadius: 40,
                spreadRadius: 4,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.95),
                blurRadius: 24,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 1. 헤더: 선명한 타이틀 바 & 고가시성 우측 상단 [X] 닫기 버튼
              Container(
                padding: const EdgeInsets.fromLTRB(18, 16, 14, 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [
                      Color(0xFF2E2416),
                      Color(0xFF1E1911),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border(
                    bottom: BorderSide(
                      color: DokkeyTheme.gold.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // 히든 이스터에그 뱃지
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.gold.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DokkeyTheme.gold,
                          width: 1.2,
                        ),
                      ),
                      child: Text(
                        t['badge']!,
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontSize: 11.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // 메인 타이틀
                    Expanded(
                      child: Text(
                        t['title']!,
                        style: const TextStyle(
                          color: Color(0xFFFFF6D6),
                          fontWeight: FontWeight.w900,
                          fontSize: 16.5,
                          letterSpacing: 0.6,
                          shadows: [
                            Shadow(
                              color: Color(0xFFD4AF37),
                              blurRadius: 10,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),

                    // 닫기 [X] 버튼: 고대비 원형 골드 테두리 + 확실한 시각 피드백
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          Navigator.of(context).pop();
                        },
                        borderRadius: BorderRadius.circular(20),
                        child: Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF2C2417),
                            border: Border.all(
                              color: DokkeyTheme.gold,
                              width: 1.8,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.6),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                              BoxShadow(
                                color: DokkeyTheme.gold.withValues(alpha: 0.3),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            size: 22,
                            color: Color(0xFFFFF6D6),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. 중앙: 초대형 황금 숫자 (0 ~ 9)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 22),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t['subtitle']!,
                      style: TextStyle(
                        color: DokkeyTheme.goldLight.withValues(alpha: 0.95),
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        height: 1.35,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),

                    // 거대 숫자 박스
                    _isLoading
                        ? SizedBox(
                            height: 165,
                            child: Center(
                              child: CircularProgressIndicator(
                                color: DokkeyTheme.gold,
                              ),
                            ),
                          )
                        : AnimatedBuilder(
                            animation: _pulseCtrl,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _scaleAnim.value,
                                child: Container(
                                  width: 175,
                                  height: 175,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: RadialGradient(
                                      colors: [
                                        DokkeyTheme.gold.withValues(alpha: 0.35),
                                        DokkeyTheme.cardDark,
                                        const Color(0xFF0F0E0B),
                                      ],
                                      stops: const [0.0, 0.65, 1.0],
                                    ),
                                    border: Border.all(
                                      color: DokkeyTheme.gold,
                                      width: 3.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: DokkeyTheme.gold.withValues(
                                          alpha: _glowAnim.value,
                                        ),
                                        blurRadius: 40,
                                        spreadRadius: 6,
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    '${_displayNumber ?? 0}',
                                    style: TextStyle(
                                      fontSize: 115,
                                      fontWeight: FontWeight.w900,
                                      fontFamily: 'serif',
                                      color: const Color(0xFFFFF9E0),
                                      shadows: [
                                        Shadow(
                                          color: DokkeyTheme.gold,
                                          blurRadius: 32,
                                          offset: const Offset(0, 4),
                                        ),
                                        const Shadow(
                                          color: Colors.black,
                                          blurRadius: 12,
                                          offset: Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                    const SizedBox(height: 22),

                    // 하단 룰 안내 배너
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: DokkeyTheme.gold.withValues(alpha: 0.45),
                          width: 1.2,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Text('⏳', style: TextStyle(fontSize: 15)),
                              const SizedBox(width: 6),
                              Text(
                                t['lockHeader']!,
                                style: const TextStyle(
                                  color: Color(0xFFFFF6D6),
                                  fontWeight: FontWeight.w900,
                                  fontSize: 13.5,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${t['rule1']!}\n${t['rule2']!}',
                            style: TextStyle(
                              color: DokkeyTheme.textMain.withValues(alpha: 0.9),
                              fontSize: 12,
                              height: 1.45,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: DokkeyTheme.bgDark,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: DokkeyTheme.dokFire.withValues(alpha: 0.6),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  t['refreshLabel']!,
                                  style: TextStyle(
                                    color: DokkeyTheme.textMuted,
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                Text(
                                  t['refreshValue']!,
                                  style: const TextStyle(
                                    color: Color(0xFFFF9E80),
                                    fontWeight: FontWeight.w900,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
