import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../models/dokkey_models.dart';
import '../providers/dokkey_provider.dart';
import '../screens/card_codex_screen.dart';
import 'share_card_dialog.dart';

/// 📅 깨비 운세 캘린더 & 스트릭 다이어리 다이얼로그 (1순위)
class KkaebiCalendarDialog extends StatefulWidget {
  const KkaebiCalendarDialog({super.key});

  static void show(BuildContext context) {
    SoundService().playCardFlip();
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.75),
      builder: (_) => const KkaebiCalendarDialog(),
    );
  }

  @override
  State<KkaebiCalendarDialog> createState() => _KkaebiCalendarDialogState();
}

class _KkaebiCalendarDialogState extends State<KkaebiCalendarDialog> {
  late DateTime _selectedMonth;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month, 1);
  }

  void _prevMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  void _nextMonth() {
    HapticFeedback.selectionClick();
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _goToToday() {
    HapticFeedback.selectionClick();
    final now = DateTime.now();
    setState(() {
      _selectedMonth = DateTime(now.year, now.month, 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final isKo = lang == 'ko';
    final isJa = lang == 'ja';

    final now = DateTime.now();
    final todayStr = DateFormat('yyyy-MM-dd').format(now);
    final monthFormat = DateFormat(isKo ? 'yyyy년 M월' : (isJa ? 'yyyy年 M月' : 'MMMM yyyy'));
    final currentMonthTitle = monthFormat.format(_selectedMonth);

    final archiveMap = provider.archiveByDateMap;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.gold, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: DokkeyTheme.gold.withValues(alpha: 0.25),
              blurRadius: 24,
              spreadRadius: 2,
            ),
          ],
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 헤더: 타이틀 & 닫기 'X' 버튼
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.calendar_month_rounded, color: DokkeyTheme.gold, size: 22),
                      const SizedBox(width: 8),
                      Text(
                        isKo
                            ? '깨비 운세 캘린더'
                            : (isJa ? 'クケビ運勢カレンダー' : 'Kkaebi Fortune Calendar'),
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.surfaceDark,
                        shape: BoxShape.circle,
                        border: Border.all(color: DokkeyTheme.borderDark),
                      ),
                      child: Icon(Icons.close_rounded, size: 16, color: DokkeyTheme.textMuted),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 2. 상단 연속 출석(스트릭) 및 마일스톤 대시보드
              _buildStreakBanner(provider, isKo, isJa),
              const SizedBox(height: 16),

              // 3. 월 탐색 헤더 (< 2026년 9월 > [오늘])
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: _prevMonth,
                        icon: Icon(Icons.chevron_left_rounded, color: DokkeyTheme.goldLight),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                      Text(
                        currentMonthTitle,
                        style: TextStyle(
                          color: DokkeyTheme.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      IconButton(
                        onPressed: _nextMonth,
                        icon: Icon(Icons.chevron_right_rounded, color: DokkeyTheme.goldLight),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    onPressed: _goToToday,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      backgroundColor: DokkeyTheme.surfaceDark,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: Icon(Icons.today_rounded, size: 14, color: DokkeyTheme.gold),
                    label: Text(
                      isKo ? '오늘' : (isJa ? '今日' : 'Today'),
                      style: TextStyle(color: DokkeyTheme.gold, fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // 4. 요일 헤더 (일 ~ 토)
              _buildWeekdayHeader(lang),
              const SizedBox(height: 6),

              // 5. 월간 캘린더 날짜 그리드
              _buildMonthGrid(context, provider, archiveMap, todayStr),
              const SizedBox(height: 16),

              // 6. 안내 풋터
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: DokkeyTheme.surfaceDark.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: DokkeyTheme.borderDark.withValues(alpha: 0.5)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded, color: DokkeyTheme.goldLight, size: 14),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isKo
                            ? '출석한 날(🔥)을 터치하면 그날의 운세 카드를 다시 확인할 수 있습니다.'
                            : (isJa
                                ? '出席日(🔥)をタップすると、その日の運勢カードを再確認できます。'
                                : 'Tap any attended date (🔥) to recall your fortune card.'),
                        style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10.5),
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

  /// 상단 스트릭 대시보드 및 마일스톤 보상 영역
  Widget _buildStreakBanner(DokkeyProvider provider, bool isKo, bool isJa) {
    final streak = provider.streak;
    final milestones = [
      (3, 1, isKo ? '3일 연속' : '3-Day', '🗝️+1'),
      (7, 2, isKo ? '7일 연속' : '7-Day', '🗝️+2'),
      (14, 3, isKo ? '14일 연속' : '14-Day', '🗝️+3'),
      (30, 5, isKo ? '30일 완주' : '30-Day', '🎁+5'),
    ];

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            DokkeyTheme.surfaceDark,
            DokkeyTheme.surfaceDark.withValues(alpha: 0.8),
            const Color(0xFF1E1610),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: DokkeyTheme.dokFire.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('🔥', style: TextStyle(fontSize: 16)),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isKo
                            ? '$streak일 연속 출석 중!'
                            : (isJa ? '$streak日 連続出席中！' : '$streak-Day Streak!'),
                        style: TextStyle(
                          color: DokkeyTheme.gold,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        isKo
                            ? '매일 운세를 열어 깨비의 축복을 이어가세요'
                            : (isJa ? '毎日運勢を開いて福を受け取ろう' : 'Unlock daily fortunes to keep the flame alive'),
                        style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10.5),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: DokkeyTheme.cardDark,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.3)),
                ),
                child: Text(
                  '🔥 $streak',
                  style: TextStyle(
                    color: DokkeyTheme.goldLight,
                    fontWeight: FontWeight.w900,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // 마일스톤 칩 목록
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: milestones.map((m) {
                final days = m.$1;
                final label = m.$3;
                final reward = m.$4;
                final reached = streak >= days;
                final claimed = provider.isStreakMilestoneClaimed(days);

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: reached
                        ? (claimed
                            ? DokkeyTheme.surfaceDark
                            : DokkeyTheme.gold.withValues(alpha: 0.18))
                        : DokkeyTheme.bgDark.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: reached
                          ? (claimed ? DokkeyTheme.borderDark : DokkeyTheme.gold)
                          : DokkeyTheme.borderDark.withValues(alpha: 0.5),
                      width: reached && !claimed ? 1.5 : 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$label ($reward)',
                        style: TextStyle(
                          color: reached
                              ? (claimed ? DokkeyTheme.textMuted : DokkeyTheme.goldLight)
                              : DokkeyTheme.textMuted,
                          fontSize: 10.5,
                          fontWeight: reached ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      if (reached && !claimed) ...[
                        const SizedBox(width: 6),
                        GestureDetector(
                          onTap: () async {
                            final ok = await provider.claimStreakReward(days);
                            if (ok && context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isKo
                                        ? '🎉 $days일 연속 출석 보너스 ($reward) 수령 완료!'
                                        : '🎉 Claimed $days-day streak bonus ($reward)!',
                                  ),
                                  backgroundColor: DokkeyTheme.cardDark,
                                ),
                              );
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: DokkeyTheme.gold,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isKo ? '받기' : 'Claim',
                              style: TextStyle(
                                color: DokkeyTheme.bgDark,
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ] else if (claimed) ...[
                        const SizedBox(width: 4),
                        Icon(Icons.check_rounded, size: 12, color: DokkeyTheme.gold),
                      ],
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  /// 요일 헤더 (일 ~ 토)
  Widget _buildWeekdayHeader(String lang) {
    final isKo = lang == 'ko';
    final isJa = lang == 'ja';
    final weekdays = isKo
        ? ['일', '월', '화', '수', '목', '금', '토']
        : (isJa ? ['日', '月', '火', '水', '木', '金', '土'] : ['S', 'M', 'T', 'W', 'T', 'F', 'S']);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: List.generate(7, (i) {
        final color = i == 0
            ? const Color(0xFFFF8A80) // 일요일
            : (i == 6 ? const Color(0xFF80D8FF) : DokkeyTheme.textMuted); // 토요일

        return Expanded(
          child: Center(
            child: Text(
              weekdays[i],
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        );
      }),
    );
  }

  /// 월간 캘린더 그리드
  Widget _buildMonthGrid(
    BuildContext context,
    DokkeyProvider provider,
    Map<String, DrawResult> archiveMap,
    String todayStr,
  ) {
    final year = _selectedMonth.year;
    final month = _selectedMonth.month;
    final firstDayOfMonth = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startWeekday = firstDayOfMonth.weekday % 7; // 0=Sunday

    final totalCells = ((startWeekday + daysInMonth + 6) ~/ 7) * 7;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        childAspectRatio: 0.95,
        mainAxisSpacing: 4,
        crossAxisSpacing: 4,
      ),
      itemCount: totalCells,
      itemBuilder: (ctx, index) {
        final dayOffset = index - startWeekday;
        if (dayOffset < 0 || dayOffset >= daysInMonth) {
          return const SizedBox.shrink();
        }

        final dayNumber = dayOffset + 1;
        final cellDateStr =
            '$year-${month.toString().padLeft(2, '0')}-${dayNumber.toString().padLeft(2, '0')}';
        final isToday = cellDateStr == todayStr;
        final drawResult = archiveMap[cellDateStr];
        final hasDraw = drawResult != null;
        final hasRiddleStamp = provider.riddleStampDates.contains(cellDateStr);

        return InkWell(
          onTap: hasDraw
              ? () => _DailyFortuneRecallSheet.show(context, drawResult)
              : null,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            decoration: BoxDecoration(
              color: hasDraw
                  ? DokkeyTheme.gold.withValues(alpha: 0.12)
                  : (isToday
                      ? DokkeyTheme.surfaceDark
                      : DokkeyTheme.surfaceDark.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isToday
                    ? DokkeyTheme.gold
                    : (hasDraw
                        ? DokkeyTheme.gold.withValues(alpha: 0.4)
                        : DokkeyTheme.borderDark.withValues(alpha: 0.3)),
                width: isToday ? 1.8 : 1.0,
              ),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$dayNumber',
                      style: TextStyle(
                        color: hasDraw
                            ? DokkeyTheme.goldLight
                            : (isToday ? DokkeyTheme.gold : DokkeyTheme.textMuted),
                        fontSize: 12,
                        fontWeight: (hasDraw || isToday) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    if (hasDraw) ...[
                      const SizedBox(height: 2),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: DokkeyTheme.gold.withValues(alpha: 0.25),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${drawResult.number}',
                          style: TextStyle(
                            color: DokkeyTheme.gold,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (hasDraw)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: const Text('🔥', style: TextStyle(fontSize: 8)),
                  ),
                if (hasRiddleStamp && !hasDraw)
                  Positioned(
                    top: 2,
                    right: 2,
                    child: const Text('💡', style: TextStyle(fontSize: 8)),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 🎴 날짜별 운세 회고 다이얼로그
class _DailyFortuneRecallSheet extends StatelessWidget {
  final DrawResult result;

  const _DailyFortuneRecallSheet({required this.result});

  static void show(BuildContext context, DrawResult result) {
    SoundService().playCardFlip();
    showModalBottomSheet(
      context: context,
      backgroundColor: DokkeyTheme.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _DailyFortuneRecallSheet(result: result),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';

    final dateFormatted = result.dateStr;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. 헤더: 날짜 & 닫기
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.history_edu_rounded, color: DokkeyTheme.gold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        isKo
                            ? '$dateFormatted 의 운세 다이어리'
                            : (isJa ? '$dateFormatted の運勢' : 'Fortune for $dateFormatted'),
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: DokkeyTheme.textMuted, size: 18),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 2. 카드 정보 박스
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DokkeyTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 72,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: DokkeyTheme.gold, width: 1.2),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: Image.asset(
                          result.card.artAsset,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/images/kkaebi_mascot.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: DokkeyTheme.dokFire.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  result.card.deck,
                                  style: TextStyle(color: DokkeyTheme.dokFire, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: DokkeyTheme.gold.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  'No. ${result.number}',
                                  style: TextStyle(color: DokkeyTheme.gold, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            result.card.name,
                            style: TextStyle(
                              color: DokkeyTheme.textMain,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            result.card.symbol,
                            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // 3. 운세 헤드라인 & 조언
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: DokkeyTheme.cardDark,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: DokkeyTheme.borderDark),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '“${result.headline}”',
                      style: TextStyle(
                        color: DokkeyTheme.goldLight,
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      result.body,
                      style: TextStyle(color: DokkeyTheme.textMain, fontSize: 12, height: 1.4),
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.surfaceDark,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.lightbulb_outline_rounded, color: DokkeyTheme.gold, size: 14),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              result.tip,
                              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 4. 액션 버튼 (도감 가기 & 카드 공유)
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DokkeyTheme.goldLight,
                        side: BorderSide(color: DokkeyTheme.gold.withValues(alpha: 0.5)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const CardCodexScreen()),
                        );
                      },
                      icon: const Icon(Icons.menu_book_rounded, size: 16),
                      label: Text(
                        isKo ? '99 도감 열기' : (isJa ? '図鑑を開く' : 'Open Codex'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DokkeyTheme.gold,
                        foregroundColor: DokkeyTheme.bgDark,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: () {
                        Navigator.of(context).pop();
                        showDialog(
                          context: context,
                          builder: (_) => ShareCardDialog(result: result),
                        );
                      },
                      icon: const Icon(Icons.share_rounded, size: 16),
                      label: Text(
                        isKo ? '카드 공유' : (isJa ? 'シェア' : 'Share Card'),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
