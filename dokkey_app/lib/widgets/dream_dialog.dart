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

  String _fortuneLine(String lang, DreamSymbol s) {
    if (s.isAuspicious) {
      switch (lang) {
        case 'ko':
          return '대박 꿈이다깨비! 오늘 기운을 놓치지 마라!';
        case 'ja':
          return '大当たりの夢だケビ！今日の気運を逃すな！';
        case 'zh':
          return '大吉之梦！千万别错过今日的好运！';
        case 'hi':
          return 'यह एक बहुत ही शुभ सपना है! आज के अवसर को न चूकें!';
        case 'de':
          return 'Ein absoluter Glückstraum! Nutze die heutige Energie!';
        default:
          return 'A jackpot dream! Ride today\'s energy!';
      }
    }
    if (s.isOminous) {
      switch (lang) {
        case 'ko':
          return '내가 나쁜 기운은 방망이로 쳐서 없애줄게! 걱정 마라!';
        case 'ja':
          return '悪い気はこん棒で叩いて消してやる！心配するな！';
        case 'zh':
          return '我会用神棒驱散厄运！别担心！';
        case 'hi':
          return 'मैं अपनी गदा से सारी नकारात्मक ऊर्जा दूर कर दूँगा! चिंता न करें!';
        case 'de':
          return 'Ich vertreibe das Unheil mit meiner Keule! Keine Sorge!';
        default:
          return 'I\'ll smash the bad vibes with my club! Don\'t worry!';
      }
    }
    switch (lang) {
      case 'ko':
        return '오늘 하루 차분하게 보내면 돼! 무난하다깨비!';
      case 'ja':
        return '今日は穏やかに過ごせば大丈夫！';
      case 'zh':
        return '今天平平安安度过即可，一切顺遂！';
      case 'hi':
        return 'आज का दिन शांति से बिताएं, सब ठीक रहेगा!';
      case 'de':
        return 'Verbringe den Tag in Ruhe, alles verläuft harmonisch!';
      default:
        return 'Just take it easy today — all is calm!';
    }
  }

  String _fortuneBadge(String lang, DreamSymbol s) {
    if (s.isAuspicious) {
      switch (lang) {
        case 'ko':
          return '길몽 ✨';
        case 'ja':
          return '吉夢 ✨';
        case 'zh':
          return '吉梦 ✨';
        case 'hi':
          return 'शुभ सपना ✨';
        case 'de':
          return 'Glückstraum ✨';
        default:
          return 'Auspicious ✨';
      }
    }
    if (s.isOminous) {
      switch (lang) {
        case 'ko':
          return '흉몽 ⚡';
        case 'ja':
          return '凶夢 ⚡';
        case 'zh':
          return '凶梦 ⚡';
        case 'hi':
          return 'अशुभ सपना ⚡';
        case 'de':
          return 'Unheilstraum ⚡';
        default:
          return 'Ominous ⚡';
      }
    }
    switch (lang) {
      case 'ko':
        return '평몽 🌿';
      case 'ja':
        return '平夢 🌿';
      case 'zh':
        return '平梦 🌿';
      case 'hi':
        return 'सामान्य सपना 🌿';
      case 'de':
        return 'Neutraler Traum 🌿';
      default:
        return 'Normal 🌿';
    }
  }

  Color _fortuneColor(DreamSymbol s) {
    if (s.isAuspicious) return DokkeyTheme.gold;
    if (s.isOminous) return DokkeyTheme.dokFire;
    return DokkeyTheme.mintCalm;
  }

  String _depositBannerText(String lang, DreamSymbol s) {
    switch (lang) {
      case 'ko':
        return '꿈 상징수 #${s.luckyNumberStr} 보관함 입고 완료!';
      case 'ja':
        return '夢の象徴数 #${s.luckyNumberStr} 入庫完了！';
      case 'zh':
        return '梦境幸运数 #${s.luckyNumberStr} 已存入宝箱！';
      case 'hi':
        return 'स्वप्न लकी नंबर #${s.luckyNumberStr} तिजोरी में जोड़ा गया!';
      case 'de':
        return 'Traumnummer #${s.luckyNumberStr} im Tresor gespeichert!';
      default:
        return 'Dream No.#${s.luckyNumberStr} added to KeyBox!';
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final symbols = provider.dreamSymbols;
    final daily = provider.todayDreamSymbol;

    final query = _searchCtrl.text.trim();
    final filtered = query.isEmpty
        ? symbols
        : symbols.where((s) => s.matchesQuery(query)).toList();

    // 실시간 검색 시 첫 번째 매칭 상징 자동 활성화 (검색 즉시 해몽 카드 표출)
    DreamSymbol? effectiveSelected;
    if (query.isNotEmpty) {
      if (filtered.isNotEmpty) {
        if (_selected != null && filtered.any((s) => s.id == _selected!.id)) {
          effectiveSelected = _selected;
        } else {
          effectiveSelected = filtered.first;
        }
      } else {
        effectiveSelected = null;
      }
    } else {
      effectiveSelected = _selected ?? daily;
    }

    String title;
    switch (lang) {
      case 'ko':
        title = '깨비의 꿈풀이';
        break;
      case 'ja':
        title = 'クケビの夢占い';
        break;
      case 'zh':
        title = '小妖解梦';
        break;
      case 'hi':
        title = 'कैकबी का स्वप्न फल';
        break;
      case 'de':
        title = 'Kkaebis Traumdeutung';
        break;
      default:
        title = "Kkaebi's Dream Reading";
    }

    String dailyLabel;
    switch (lang) {
      case 'ko':
        dailyLabel = '오늘의 추천 상징';
        break;
      case 'ja':
        dailyLabel = '今日のおすすめ象徴';
        break;
      case 'zh':
        dailyLabel = '今日推荐梦境';
        break;
      case 'hi':
        dailyLabel = 'आज का अनुशंसित प्रतीक';
        break;
      case 'de':
        dailyLabel = 'Heutiges Traumsymbol';
        break;
      default:
        dailyLabel = "Today's Suggested Symbol";
    }

    String searchHint;
    switch (lang) {
      case 'ko':
        searchHint = '예: 조상님, 용, 돼지, 하늘을 나는 꿈';
        break;
      case 'ja':
        searchHint = '例: ご先祖様、龍、豚、空を飛ぶ夢';
        break;
      case 'zh':
        searchHint = '例: 祖先、龙、金猪、飞天之梦';
        break;
      case 'hi':
        searchHint = 'उदा.: पूर्वज, ड्रैगन, सुअर, उड़ना';
        break;
      case 'de':
        searchHint = 'z.B. Ahnen, Drache, Schwein, Fliegen';
        break;
      default:
        searchHint = 'e.g. ancestors, dragon, pig, flying';
    }

    String searchSectionHeader;
    if (query.isNotEmpty) {
      switch (lang) {
        case 'ko':
          searchSectionHeader = '🔍 검색된 꿈 상징 (${filtered.length})';
          break;
        case 'ja':
          searchSectionHeader = '🔍 検索された夢象徴 (${filtered.length})';
          break;
        case 'zh':
          searchSectionHeader = '🔍 匹配的梦境 (${filtered.length})';
          break;
        case 'hi':
          searchSectionHeader = '🔍 खोजे गए प्रतीक (${filtered.length})';
          break;
        case 'de':
          searchSectionHeader = '🔍 Gefundene Symbole (${filtered.length})';
          break;
        default:
          searchSectionHeader = '🔍 Matched Symbols (${filtered.length})';
      }
    } else {
      switch (lang) {
        case 'ko':
          searchSectionHeader = '🔮 인기 꿈 상징';
          break;
        case 'ja':
          searchSectionHeader = '🔮 人気の夢象徴';
          break;
        case 'zh':
          searchSectionHeader = '🔮 热门梦境';
          break;
        case 'hi':
          searchSectionHeader = '🔮 लोकप्रिय स्वप्न प्रतीक';
          break;
        case 'de':
          searchSectionHeader = '🔮 Beliebte Traumsymbole';
          break;
        default:
          searchSectionHeader = '🔮 Popular Dream Symbols';
      }
    }

    String closeLabel;
    switch (lang) {
      case 'ko':
        closeLabel = '닫기';
        break;
      case 'ja':
        closeLabel = '閉じる';
        break;
      case 'zh':
        closeLabel = '关闭';
        break;
      case 'hi':
        closeLabel = 'बंद करें';
        break;
      case 'de':
        closeLabel = 'Schließen';
        break;
      default:
        closeLabel = 'Close';
    }

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
                    tooltip: closeLabel,
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // 자연어 검색 필드 (유사어 매칭)
              TextField(
                controller: _searchCtrl,
                textInputAction: TextInputAction.search,
                onSubmitted: (_) {
                  FocusScope.of(context).unfocus();
                  if (effectiveSelected != null) {
                    provider.onDreamAnalyzed(effectiveSelected);
                    if (effectiveSelected.isAuspicious) {
                      SoundService().playGayageum();
                    }
                  }
                },
                onChanged: (_) {
                  setState(() {
                    _selected = null; // 검색어 변경 시 자동 매칭 갱신
                  });
                },
                style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13),
                decoration: InputDecoration(
                  hintText: searchHint,
                  hintStyle: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
                  prefixIcon: Icon(Icons.search_rounded, color: DokkeyTheme.mintCalm),
                  suffixIcon: query.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(Icons.close_rounded, size: 16, color: DokkeyTheme.textMuted),
                          tooltip: 'Clear',
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {
                              _selected = null;
                            });
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
              const SizedBox(height: 10),

              // 상징 목록 헤더
              Row(
                children: [
                  Text(
                    searchSectionHeader,
                    style: TextStyle(
                      color: query.isNotEmpty ? DokkeyTheme.mintCalm : DokkeyTheme.textMuted,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(),
                  if (query.isEmpty)
                    Text(
                      '✨ $dailyLabel: ${daily.label}',
                      style: TextStyle(color: DokkeyTheme.gold, fontSize: 11),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              // Symbol chips (검색 결과)
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        KkaebiFaceWidget(
                          size: 48,
                          mode: KkaebiFaceMode.surprise,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          lang == 'ko'
                              ? '검색 결과가 없다깨비... (예: 용, 조상, 돼지, 불, 돈)'
                              : (lang == 'ja'
                                  ? '検索結果がないケビ...（例：龍、先祖、豚、火、お金）'
                                  : (lang == 'zh'
                                      ? '未找到匹配结果...（例如：龙、祖先、金猪、火焰、财富）'
                                      : (lang == 'hi'
                                          ? 'कोई परिणाम नहीं मिला... (उदा.: ड्रैगन, पूर्वज, सुअर, आग)'
                                          : (lang == 'de'
                                              ? 'Keine Treffer gefunden... (z.B. Drache, Ahnen, Schwein)'
                                              : 'No matches found... (e.g. dragon, ancestor, pig)')))),
                          textAlign: TextAlign.center,
                          style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: filtered.take(12).map((s) {
                    final active = effectiveSelected?.id == s.id;
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
                        fontWeight: active ? FontWeight.bold : FontWeight.normal,
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
              const SizedBox(height: 14),

              // Interpretation result (즉시 표출되는 해몽 카드)
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                child: effectiveSelected == null
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
                        key: ValueKey(effectiveSelected.id),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: DokkeyTheme.surfaceDark,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: _fortuneColor(effectiveSelected).withOpacity(0.5),
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
                                  mode: _faceModeFor(effectiveSelected),
                                  glowColor: _fortuneColor(effectiveSelected),
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
                                              effectiveSelected.label,
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
                                              color: _fortuneColor(effectiveSelected).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(6),
                                            ),
                                            child: Text(
                                              _fortuneBadge(lang, effectiveSelected),
                                              style: TextStyle(
                                                color: _fortuneColor(effectiveSelected),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        _fortuneLine(lang, effectiveSelected),
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
                              effectiveSelected.meaning,
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
                                      effectiveSelected.advice,
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
                                    colors: [Color(0xFFFFE29A), Color(0xFFB8860B)]),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.paid_rounded, size: 15, color: Colors.black),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      _depositBannerText(lang, effectiveSelected),
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
                  closeLabel,
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
