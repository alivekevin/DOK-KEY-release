import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../models/dokkey_models.dart';
import '../providers/dokkey_provider.dart';
import 'kkaebi_face_widget.dart';

/// 도깨비 꿈풀이 다이얼로그 (v4.1.0 PHASE 1/4)
/// - 자연어 검색 & 유사어 매칭 ("호랑이한테 쫓기는 꿈" → 호랑이/쫓김 분리 매칭)
/// - 길흉 판정 감정 연동: 길몽 jackpot / 흉몽 angry / 평몽 wink
/// - 도깨비 실천형 처방전 + 꿈 상징수 보관함 자동 입고
class DreamDialog extends StatefulWidget {
  const DreamDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (_) => const DreamDialog(),
    );
  }

  @override
  State<DreamDialog> createState() => _DreamDialogState();
}

class _DreamDialogState extends State<DreamDialog> {
  DreamSymbol? _selected;
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  KkaebiFaceMode _faceModeFor(DreamSymbol s) {
    if (s.isAuspicious) return KkaebiFaceMode.jackpot;
    if (s.isOminous) return KkaebiFaceMode.angry;
    return KkaebiFaceMode.wink;
  }

  String _fortuneLine(bool isKo, bool isJa, DreamSymbol s) {
    if (s.isAuspicious) {
      return isKo
          ? '대박 꿈이다깨비! 오늘 기운을 놓치지 마라!'
          : (isJa ? '大当たりの夢だケビ！今日の気運を逃すな！' : 'A jackpot dream! Ride today\'s energy!');
    }
    if (s.isOminous) {
      return isKo
          ? '내가 나쁜 기운은 방망이로 쳐서 없애줄게! 걱정 마라!'
          : (isJa ? '悪い気はこん棒で叩いて消してやる！心配するな！' : 'I\'ll smash the bad vibes with my club! Don\'t worry!');
    }
    return isKo
        ? '오늘 하루 차분하게 보내면 돼! 무난하다깨비!'
        : (isJa ? '今日は穏やかに過ごせば大丈夫！' : 'Just take it easy today — all is calm!');
  }

  String _fortuneBadge(bool isKo, bool isJa, DreamSymbol s) {
    if (s.isAuspicious) return isKo ? '길몽 ✨' : (isJa ? '吉夢 ✨' : 'Auspicious ✨');
    if (s.isOminous) return isKo ? '흉몽 ⚡' : (isJa ? '凶夢 ⚡' : 'Ominous ⚡');
    return isKo ? '평몽 🌿' : (isJa ? '平夢 🌿' : 'Normal 🌿');
  }

  Color _fortuneColor(DreamSymbol s) {
    if (s.isAuspicious) return DokkeyTheme.gold;
    if (s.isOminous) return DokkeyTheme.dokFire;
    return DokkeyTheme.mintCalm;
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final symbols = provider.dreamSymbols;
    final daily = provider.todayDreamSymbol;

    final query = _searchCtrl.text.trim();
    final filtered = query.isEmpty
        ? symbols
        : symbols.where((s) => s.matchesQuery(query)).toList();

    final selected = _selected;

    String title = isKo ? '깨비의 꿈풀이' : (isJa ? 'クケビの夢占い' : "Kkaebi's Dream Reading");
    String prompt = isKo
        ? '꿈의 내용을 검색하거나 상징을 골라보거라'
        : (isJa ? '夢の内容を検索するか、象徴を選んでみて' : 'Search your dream or pick a symbol');
    String dailyLabel = isKo ? '오늘의 추천 상징' : (isJa ? '今日のおすすめ象徴' : "Today's Suggested Symbol");
    String searchHint = isKo
        ? '예: 호랑이한테 쫓기는 꿈'
        : (isJa ? '例: 虎に追いかけられる夢' : 'e.g. being chased by a tiger');

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        constraints: const BoxConstraints(maxWidth: 440),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.mintCalm.withOpacity(0.6), width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const SizedBox(width: 24),
                  const Spacer(),
                  Icon(Icons.nightlight_round, color: DokkeyTheme.mintCalm, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: DokkeyTheme.textMuted, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: isKo ? '닫기' : (isJa ? '閉じる' : 'Close'),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 자연어 검색 필드 (유사어 매칭)
              TextField(
                controller: _searchCtrl,
                onChanged: (_) => setState(() {}),
                style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13),
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: DokkeyTheme.mintCalm),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: DokkeyTheme.textMuted),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: DokkeyTheme.borderDark),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(color: DokkeyTheme.mintCalm),
                  ),
                  filled: true,
                  fillColor: DokkeyTheme.surfaceDark,
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),

              // Symbol chips (검색 결과)
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Center(
                    child: Text(
                      isKo
                          ? '검색 결과가 없다깨비... 다른 단어로 찾아봐라!'
                          : (isJa ? '検索結果がないケビ...別の言葉で探して！' : 'No matches... try another word!'),
                      style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: filtered.take(12).map((s) {
                    final active = selected?.id == s.id;
                    final isDaily = s.id == daily.id;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isDaily) ...[
                            Icon(Icons.auto_awesome, size: 12, color: DokkeyTheme.gold),
                            const SizedBox(width: 3),
                          ],
                          Text(s.label, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                      selected: active,
                      selectedColor: DokkeyTheme.mintCalm.withOpacity(0.35),
                      backgroundColor: DokkeyTheme.surfaceDark,
                      labelStyle: TextStyle(
                        color: active ? DokkeyTheme.mintCalm : DokkeyTheme.textMuted,
                      ),
                      side: BorderSide(
                        color: active ? DokkeyTheme.mintCalm : DokkeyTheme.borderDark,
                      ),
                      onSelected: (_) {
                        setState(() {
                          _selected = s;
                        });
                        provider.onDreamAnalyzed(s);
                        if (s.isAuspicious) {
                          SoundService().playGayageum();
                        }
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  '✨ $dailyLabel: ${daily.label}',
                  style: TextStyle(color: DokkeyTheme.gold, fontSize: 11),
                ),
              ),
              const SizedBox(height: 14),

              // Interpretation result
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: selected == null
                    ? SizedBox(
                        key: const ValueKey('empty'),
                        height: 72,
                        child: Center(
                          child: KkaebiFaceWidget(
                            size: 64,
                            mode: KkaebiFaceMode.idle,
                          ),
                        ),
                      )
                    : Container(
                        key: ValueKey(selected.id),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: DokkeyTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _fortuneColor(selected).withOpacity(0.5),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // 길흉 판정 감정 연동: 길몽 jackpot / 흉몽 angry / 평몽 wink
                                KkaebiFaceWidget(
                                  size: 44,
                                  mode: _faceModeFor(selected),
                                  glowColor: _fortuneColor(selected),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Flexible(
                                            child: Text(
                                              selected.label,
                                              style: TextStyle(
                                                color: DokkeyTheme.goldLight,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                                horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _fortuneColor(selected).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _fortuneBadge(isKo, isJa, selected),
                                              style: TextStyle(
                                                color: _fortuneColor(selected),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _fortuneLine(isKo, isJa, selected),
                                        style: TextStyle(
                                          color: DokkeyTheme.textMain,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              selected.meaning,
                              style: TextStyle(color: DokkeyTheme.textMain, fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            // 도깨비 실천형 처방전
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: DokkeyTheme.cardDark,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('💊', style: TextStyle(fontSize: 13)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      selected.advice,
                                      style: TextStyle(
                                        color: DokkeyTheme.textMuted,
                                        fontSize: 12,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            // 꿈 상징수 자동 입고 배너
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFFFE29A), Color(0xFFB8860B)],
                                ),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.paid_rounded, size: 15, color: Colors.black),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      isKo
                                          ? '꿈 상징수 #${selected.luckyNumberStr} 보관함 입고 완료!'
                                          : (isJa
                                              ? '夢の象徴数 #${selected.luckyNumberStr} 入庫完了！'
                                              : 'Dream No.#${selected.luckyNumberStr} added to KeyBox!'),
                                      style: const TextStyle(
                                        color: Colors.black,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 11.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
              ),
              const SizedBox(height: 16),

              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isKo ? '닫기' : (isJa ? '閉じる' : 'Close'),
                  style: TextStyle(color: DokkeyTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
