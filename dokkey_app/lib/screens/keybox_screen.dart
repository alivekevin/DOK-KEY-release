import '../widgets/quote_poster_dialog.dart';
import '../core/key_combiner_engine.dart';
import '../core/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/vault_models.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/keybox_item_widget.dart';
import '../widgets/alchemy_overlay.dart';
import '../widgets/combined_result_dialog.dart';
import '../widgets/pro_pass_dialog.dart';
import 'combined_keys_screen.dart';
import 'card_codex_screen.dart';
import '../widgets/rotating_key_home_button.dart';
import 'result_screen.dart';

/// 🗝️ 보관함 & 마법 열쇠 연성실 (v4.1.0 Commercial)
/// - 숫자 필터/정렬: 획득순 / 번호순 / 빈도순 + 기운 컬러 필터
/// - 연성: N 프리셋(2/3/4/6) + '중복 숫자 허용' 토글 + 빈도 가중치 + 연성 시네마틱 VFX
class KeyBoxScreen extends StatefulWidget {
  const KeyBoxScreen({super.key});

  @override
  State<KeyBoxScreen> createState() => _KeyBoxScreenState();
}

enum _KeySort { acquired, number, frequency }

class _KeyBoxScreenState extends State<KeyBoxScreen> {
  int _activeTab = 0; // 0: 🗝️ 숫자&연성실, 1: 📜 저장한 명언
  final Set<String> _selectedNumbers = {};
  int _targetCount = KeyCombinerEngine.defaultTargetCount;
  bool _allowDuplicates = false;
  _KeySort _sort = _KeySort.acquired;
  String? _toneFilter; // null = 전체

  List<SourceNumberItem> _applySortFilter(List<SourceNumberItem> list) {
    var items = list.where((s) => _toneFilter == null || s.lastToneColor == _toneFilter).toList();
    switch (_sort) {
      case _KeySort.acquired:
        items.sort((a, b) => b.lastAcquiredAt.compareTo(a.lastAcquiredAt));
        break;
      case _KeySort.number:
        items.sort((a, b) => int.parse(a.numberStr).compareTo(int.parse(b.numberStr)));
        break;
      case _KeySort.frequency:
        items.sort((a, b) => b.count.compareTo(a.count));
        break;
    }
    // 핀(즐겨찾기) 상단 고정
    items.sort((a, b) {
      if (a.isPinned != b.isPinned) return a.isPinned ? -1 : 1;
      return 0;
    });
    return items;
  }

  void _onCombinePressed(BuildContext context) async {
    final provider = context.read<DokkeyProvider>();
    final lang = provider.lang;
    final available = provider.sourceNumbers;

    if (!provider.canAddCombinedKey) {
      ProPassDialog.show(context);
      return;
    }

    if (available.isEmpty) {
      final msg = switch (lang) {
        'ja' => '集めた数字がまだありません！',
        'zh' => '还没有收集任何数字！',
        'de' => 'Noch keine Zahlen gesammelt!',
        'hi' => 'अभी तक कोई संख्या एकत्र नहीं की गई!',
        'en' => 'No numbers collected yet!',
        _ => '모은 숫자가 하나도 없습니다!',
      };
      _toast(context, msg);
      return;
    }

    if (!_allowDuplicates && available.length < _targetCount) {
      final text = switch (lang) {
        'ja' => '固有の数字が不足しています！（必要: $_targetCount個、所持: ${available.length}個）\n💡 重複許可モードで今すぐ錬成できます！',
        'zh' => '持有的唯一数字不足！（需要: $_targetCount个，拥有: ${available.length}个）\n💡 切换为允许重复模式即可立即炼制！',
        'de' => 'Nicht genug eindeutige Zahlen! (Benötigt: $_targetCount, Vorhanden: ${available.length})\n💡 Duplikate-Modus aktivieren!',
        'hi' => 'पर्याप्त अद्वितीय संख्याएँ नहीं हैं! (आवश्यक: $_targetCount, उपलब्ध: ${available.length})\n💡 दोहराव मोड आज़माएँ!',
        'en' => 'Not enough unique numbers! (Need: $_targetCount, Have: ${available.length})\n💡 Try Allow Duplicates mode!',
        _ => '보유한 고유 숫자가 부족합니다! (필요: $_targetCount개, 보유: ${available.length}개)\n💡 중복 허용 모드로 전환하면 지금 바로 연성할 수 있어요!',
      };
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(text),
          backgroundColor: DokkeyTheme.cardDark,
        ),
      );
      return;
    }

    // 연성 시네마틱: 엽전 짤랑 → 마법 링/충격파 VFX → 조합 → 징 환호
    SoundService().playCoinJangle();
    if (!mounted) return;
    await AlchemyOverlay.run(context, onComplete: () {
      SoundService().playGong();
    });
    if (!mounted) return;

    try {
      final combinedKey = await provider.combineAndSaveKeys(
        targetCount: _targetCount,
        selectedPool: _selectedNumbers,
        allowDuplicates: _allowDuplicates,
      );

      if (!mounted) return;
      setState(() => _selectedNumbers.clear());
      showDialog(
        context: context,
        builder: (_) => CombinedResultDialog(
          combinedKey: combinedKey,
          allowDuplicates: _allowDuplicates,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      if (e.toString().contains('MAX_SLOTS_REACHED')) {
        // 무료 9/9 한도 도달 → 삭제 유도 또는 Pro 업그레이드
        final isPro = provider.isProUser;
        final title = switch (lang) {
          'ja' => '保管箱が満杯です',
          'zh' => '钥匙保管箱已满',
          'de' => 'Tresor ist voll',
          'hi' => 'वॉल्ट भर गया है',
          'en' => 'Vault is full',
          _ => '조합 보관함이 가득 찼습니다',
        };
        final desc = switch (lang) {
          'ja' => isPro
              ? '99/99スロットがすべて満杯です。保管箱で古いキーを整理してから再錬成してください。'
              : '無料スロット9/9が満杯です。\n\n🗑️ 保管箱で古いキーを整理するか\n👑 プロパス(PRO PASS)で99スロットに拡張できます。',
          'zh' => isPro
              ? '99/99个槽位已满。请在保管箱清理旧钥匙后再炼制。'
              : '免费9/9槽位已满。\n\n🗑️ 在保管箱清理旧钥匙，或\n👑 通过 PRO PASS 扩充至99个槽位。',
          'de' => isPro
              ? 'Alle 99 Plätze belegt. Räume alte Schlüssel im Tresor auf.'
              : 'Gratis-Plätze voll (9/9).\n\n🗑️ Alte Schlüssel löschen oder\n👑 mit PRO PASS auf 99 erweitern.',
          'hi' => isPro
              ? 'सभी 99 स्लॉट भरे हैं। पुराने कुंजी साफ़ करें और पुनः प्रयास करें।'
              : 'निःशुल्क 9/9 स्लॉट भरे हैं।\n\n🗑️ वॉल्ट साफ़ करें या\n👑 PRO PASS से 99 स्लॉट पाएँ।',
          'en' => isPro
              ? 'All 99 slots are full. Clean old keys in the vault and try again.'
              : 'Free slots full (9/9).\n\n🗑️ Clean old keys in the vault, or\n👑 expand to 99 slots with the PRO PASS.',
          _ => isPro
              ? '조합 키 99/99 슬롯이 모두 찼습니다. 보관함에서 오래된 키를 정리한 뒤 다시 연성해주세요.'
              : '무료 슬롯 9/9가 모두 찼습니다.\n\n🗑️ 보관함에서 오래된 키를 정리하거나\n👑 프로 패스(PRO PASS)로 99개 슬롯으로 확장할 수 있습니다.',
        };
        final cleanLabel = switch (lang) {
          'ja' => '保管箱へ',
          'zh' => '前往保管箱',
          'de' => 'Tresor öffnen',
          'hi' => 'वॉल्ट खोलें',
          'en' => 'Open Vault',
          _ => '보관함 정리하러 가기',
        };
        final upgradeLabel = switch (lang) {
          'ja' => '99スロット拡張',
          'zh' => '获取99槽位',
          'de' => '99 Plätze holen',
          'hi' => '99 स्लॉट पाएँ',
          'en' => 'Get 99 Slots',
          _ => '99슬롯 확장',
        };

        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: DokkeyTheme.cardDark,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: DokkeyTheme.gold, width: 1.5),
            ),
            title: Row(
              children: [
                Icon(Icons.inventory_rounded, color: DokkeyTheme.gold),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    title,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              desc,
              style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13, height: 1.5),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CombinedKeysScreen()),
                  );
                },
                child: Text(
                  cleanLabel,
                  style: TextStyle(color: DokkeyTheme.textMuted),
                ),
              ),
              if (!isPro)
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    ProPassDialog.show(context);
                  },
                  icon: const Icon(Icons.workspace_premium_rounded, size: 16, color: Colors.amber),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.gold,
                    foregroundColor: Colors.black,
                  ),
                  label: Text(
                    upgradeLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: DokkeyTheme.dokFire,
          ),
        );
      }
    }
  }

  void _toast(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: DokkeyTheme.cardDark),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final isKo = lang == 'ko';
    final isJa = lang == 'ja';
    final sourceList = provider.sourceNumbers;
    final maxAvailable = sourceList.length;
    // 유니크 모드에서 N이 보유 수를 넘으면 자동 보정
    if (!_allowDuplicates && maxAvailable >= 2 && _targetCount > maxAvailable) {
      _targetCount = maxAvailable;
    } else if (_targetCount < 2) {
      _targetCount = 2;
    }

    final combinedCount = provider.combinedKeys.length;

    final String appbarTitle = switch (lang) {
      'ja' => '保管箱',
      'zh' => '保管箱',
      'de' => 'Schlüsselbox',
      'hi' => 'कुंजी बॉक्स',
      'en' => 'Key Box',
      _ => '보관함',
    };

    final String keysButtonLabel = switch (lang) {
      'ja' => '組合せ ($combinedCount)',
      'zh' => '组合钥匙 ($combinedCount)',
      'de' => 'Schlüssel ($combinedCount)',
      'hi' => 'कुंजियाँ ($combinedCount)',
      'en' => 'Keys ($combinedCount)',
      _ => '조합 키 ($combinedCount)',
    };

    final String codexTooltip = switch (lang) {
      'ja' => '99 グランド図鑑',
      'zh' => '99 宏伟图鉴',
      'de' => '99 Grand Codex',
      'hi' => '99 ग्रैंड कोडेक्स',
      'en' => '99 Grand Codex',
      _ => '99 그랜드 도감',
    };

    final String tab0Label = switch (lang) {
      'ja' => '🗝️ 数字・錬成',
      'zh' => '🗝️ 幸运数字与炼制',
      'de' => '🗝️ Zahlen & Schmiede',
      'hi' => '🗝️ अंक और संयोजन',
      'en' => '🗝️ Keys & Alchemy',
      _ => '🗝️ 행운 숫자 & 연성',
    };

    final String tab1Label = switch (lang) {
      'ja' => '📜 保存した名言',
      'zh' => '📜 已收藏名言',
      'de' => '📜 Gespeicherte Zitate',
      'hi' => '📜 सहेजे गए विचार',
      'en' => '📜 Saved Quotes',
      _ => '📜 저장한 명언',
    };

    return Scaffold(
      appBar: AppBar(
        title: Text(appbarTitle),
        actions: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
            child: TextButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CombinedKeysScreen()),
                );
              },
              icon: Icon(Icons.vpn_key_rounded, color: DokkeyTheme.gold, size: 15),
              label: Text(
                keysButtonLabel,
                style: TextStyle(
                  color: DokkeyTheme.goldLight,
                  fontWeight: FontWeight.bold,
                  fontSize: 11.5,
                ),
              ),
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                backgroundColor: DokkeyTheme.surfaceDark,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(
                    color: DokkeyTheme.gold.withValues(alpha: 0.5),
                    width: 1.0,
                  ),
                ),
              ),
            ),
          ),
          IconButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CardCodexScreen()),
              );
            },
            icon: Icon(Icons.menu_book_rounded, color: DokkeyTheme.goldLight),
            tooltip: codexTooltip,
          ),
          const RotatingKeyHomeButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          // 상단 탭 선택기: [🗝️ 행운 숫자 & 연성] / [📜 마음에 저장한 명언]
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: DokkeyTheme.surfaceDark,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 0 ? DokkeyTheme.gold : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Text(
                          tab0Label,
                          style: TextStyle(
                            color: _activeTab == 0 ? Colors.black : DokkeyTheme.textMuted,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => _activeTab = 1),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeTab == 1 ? DokkeyTheme.gold : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              tab1Label,
                              style: TextStyle(
                                color: _activeTab == 1 ? Colors.black : DokkeyTheme.textMuted,
                                fontWeight: FontWeight.bold,
                                fontSize: 12.5,
                              ),
                            ),
                            if (provider.bookmarkedQuoteIds.isNotEmpty) ...[
                              const SizedBox(width: 5),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(
                                  color: _activeTab == 1 ? Colors.black : DokkeyTheme.dokFire,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${provider.bookmarkedQuoteIds.length}',
                                  style: TextStyle(
                                    color: _activeTab == 1 ? DokkeyTheme.goldLight : Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // 탭별 컨텐츠 뷰
          Expanded(
            child: _activeTab == 1
                ? _buildBookmarkedQuotesView(provider, isKo)
                : (sourceList.isEmpty
                    ? _buildEmptyState(provider, combinedCount)
                    : _buildNumbersView(provider, isKo, isJa, sourceList)),
          ),
        ],
      ),
    );
  }

  Widget _buildNumbersView(
    DokkeyProvider provider,
    bool isKo,
    bool isJa,
    List<SourceNumberItem> sourceList,
  ) {
    final lang = provider.lang;
    final sortedList = _applySortFilter(sourceList);
    final maxAvailable = sourceList.length;
    final toneColors = [null, '#F5BD42', '#388E3C', '#1976D2', '#C94A2E', '#8E24AA', '#D32F2F', '#00796B', '#455A64'];

    return Column(
      children: [
        // Top Summary Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  color: DokkeyTheme.surfaceDark,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isKo
                            ? '보유 고유 숫자: $maxAvailable개 · 총 ${sourceList.fold<int>(0, (s, e) => s + e.count)}회 획득'
                            : 'Unique: $maxAvailable · Total: ${sourceList.fold<int>(0, (s, e) => s + e.count)}',
                        style: TextStyle(
                          color: DokkeyTheme.textMain,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        _selectedNumbers.isEmpty
                            ? (isKo ? '전체 풀 조합' : 'Random from all')
                            : (isKo ? '${_selectedNumbers.length}개 고정 픽' : '${_selectedNumbers.length} fixed'),
                        style: TextStyle(
                          color: _selectedNumbers.isNotEmpty ? DokkeyTheme.gold : DokkeyTheme.textMuted,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                // Filter & Sort Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  color: DokkeyTheme.surfaceDark,
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _SortChip(
                          label: isKo ? '획득순' : (isJa ? '獲得順' : 'Recent'),
                          selected: _sort == _KeySort.acquired,
                          onTap: () => setState(() => _sort = _KeySort.acquired),
                        ),
                        const SizedBox(width: 6),
                        _SortChip(
                          label: isKo ? '번호순' : (isJa ? '番号順' : 'Number'),
                          selected: _sort == _KeySort.number,
                          onTap: () => setState(() => _sort = _KeySort.number),
                        ),
                        const SizedBox(width: 6),
                        _SortChip(
                          label: isKo ? '빈도순' : (isJa ? '頻度順' : 'Frequency'),
                          selected: _sort == _KeySort.frequency,
                          onTap: () => setState(() => _sort = _KeySort.frequency),
                        ),
                        const SizedBox(width: 10),
                        // 기운 컬러 필터 칩
                        for (final tc in toneColors) ...[
                          GestureDetector(
                            onTap: () => setState(() => _toneFilter = tc),
                            child: Container(
                              width: tc == null ? 30 : 24,
                              height: 24,
                              margin: const EdgeInsets.only(right: 6),
                              decoration: BoxDecoration(
                                shape: tc == null ? BoxShape.rectangle : BoxShape.circle,
                                borderRadius: tc == null ? BorderRadius.circular(12) : null,
                                color: tc == null
                                    ? (_toneFilter == null ? DokkeyTheme.gold : DokkeyTheme.cardDark)
                                    : DokkeyTheme.parseHex(tc).withOpacity(_toneFilter == tc ? 1.0 : 0.35),
                                border: Border.all(
                                  color: tc == null
                                      ? DokkeyTheme.gold
                                      : DokkeyTheme.parseHex(tc),
                                ),
                              ),
                              child: tc == null
                                  ? Center(
                                      child: Text(
                                        isKo ? '전체' : 'All',
                                        style: TextStyle(
                                          fontSize: 9,
                                          color: _toneFilter == null ? Colors.black : DokkeyTheme.textMuted,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    )
                                  : null,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                // 1-Line Detailed List View
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedList.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (ctx, idx) {
                      final item = sortedList[idx];
                      final isSelected = _selectedNumbers.contains(item.numberStr);

                      return KeyBoxItemWidget(
                        item: item,
                        isSelected: isSelected,
                        onTogglePin: () => provider.toggleSourceNumberPin(item.numberStr),
                        onToggleSelect: () {
                          setState(() {
                            if (isSelected) {
                              _selectedNumbers.remove(item.numberStr);
                            } else {
                              _selectedNumbers.add(item.numberStr);
                            }
                          });
                        },
                        onTapCard: () {
                          final archiveMatch = provider.archive.firstWhere(
                            (a) => a.number.toString().padLeft(2, '0') == item.numberStr,
                            orElse: () => provider.archive.first,
                          );
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ResultScreen(result: archiveMatch),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),

                // Bottom Sticky Combiner Bar
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark,
                    border: Border(top: BorderSide(color: DokkeyTheme.borderDark)),
                  ),
                  child: SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // N 프리셋 칩 + 중복 허용 토글
                        Row(
                          children: [
                            Text(
                              switch (lang) {
                                'ja' => 'プリセット',
                                'zh' => '预设',
                                'de' => 'Vorgabe',
                                'hi' => 'प्रीसेट',
                                'en' => 'Preset',
                                _ => '프리셋',
                              },
                              style: TextStyle(
                                color: DokkeyTheme.textMuted,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 6),
                            for (final p in KeyCombinerEngine.presets) ...[
                              _PresetChip(
                                label: '$p',
                                selected: _targetCount == p,
                                onTap: () {
                                  setState(() => _targetCount = p);
                                  HapticFeedback.selectionClick();
                                },
                              ),
                              const SizedBox(width: 5),
                            ],
                            const Spacer(),
                            // ✨ 중복 숫자 허용 토글
                            GestureDetector(
                              onTap: () {
                                setState(() => _allowDuplicates = !_allowDuplicates);
                                HapticFeedback.selectionClick();
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _allowDuplicates
                                      ? DokkeyTheme.dokFire.withOpacity(0.2)
                                      : DokkeyTheme.surfaceDark,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: _allowDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.borderDark,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.bolt_rounded,
                                      size: 13,
                                      color: _allowDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.textMuted,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      switch (lang) {
                                        'ja' => '重複許可',
                                        'zh' => '允许重复',
                                        'de' => 'Duplikate',
                                        'hi' => 'दोहराव',
                                        'en' => 'Dupes',
                                        _ => '중복 허용',
                                      },
                                      style: TextStyle(
                                        fontSize: 10.5,
                                        fontWeight: FontWeight.bold,
                                        color: _allowDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.textMuted,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    SizedBox(
                                      height: 16,
                                      width: 28,
                                      child: Switch(
                                        value: _allowDuplicates,
                                        onChanged: (v) => setState(() => _allowDuplicates = v),
                                        activeColor: DokkeyTheme.dokFire,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        // SpinBox + Action Row
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _allowDuplicates
                                        ? switch (lang) {
                                            'ja' => '重複錬成モード（頻度重み反映）',
                                            'zh' => '叠加炼制模式（权重累加）',
                                            'de' => 'Resonanz-Modus (Gewichtet)',
                                            'hi' => 'प्रतिध्वनि मोड (भारित)',
                                            'en' => 'Restoration + Weighted',
                                            _ => '중첩 연성 모드 (빈도 가중치 반영)',
                                          }
                                        : switch (lang) {
                                            'ja' => '固有番号錬成モード',
                                            'zh' => '唯一编号炼制模式',
                                            'de' => 'Einzigartiger Modus',
                                            'hi' => 'अद्वितीय मोड',
                                            'en' => 'Unique Mode',
                                            _ => '고유 번호 연성 모드',
                                          },
                                    style: TextStyle(
                                      color: _allowDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    switch (lang) {
                                      'ja' => '固定: ${_selectedNumbers.length} / 所持: $maxAvailable',
                                      'zh' => '固定: ${_selectedNumbers.length} / 拥有: $maxAvailable',
                                      'de' => 'Fixiert: ${_selectedNumbers.length} / Vorrat: $maxAvailable',
                                      'hi' => 'निश्चित: ${_selectedNumbers.length} / कुल: $maxAvailable',
                                      'en' => 'Fixed: ${_selectedNumbers.length} / Pool: $maxAvailable',
                                      _ => '고정: ${_selectedNumbers.length} / 보유: $maxAvailable',
                                    },
                                    style: TextStyle(
                                      color: DokkeyTheme.textMuted,
                                      fontSize: 11,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                              decoration: BoxDecoration(
                                color: DokkeyTheme.surfaceDark,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: DokkeyTheme.borderDark),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    onPressed: (_targetCount > 2)
                                        ? () {
                                            setState(() => _targetCount--);
                                            HapticFeedback.selectionClick();
                                          }
                                        : null,
                                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                                    color: DokkeyTheme.gold,
                                    disabledColor: DokkeyTheme.textMuted.withOpacity(0.3),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                    child: Text(
                                      '$_targetCount Keys',
                                      style: TextStyle(
                                        color: DokkeyTheme.textMain,
                                        fontWeight: FontWeight.w900,
                                        fontSize: 14,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    onPressed: (_targetCount < (_allowDuplicates ? 6 : maxAvailable) && _targetCount < 6)
                                        ? () {
                                            setState(() => _targetCount++);
                                            HapticFeedback.selectionClick();
                                          }
                                        : null,
                                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                                    color: DokkeyTheme.gold,
                                    disabledColor: DokkeyTheme.textMuted.withOpacity(0.3),
                                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                                    padding: EdgeInsets.zero,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 12),
                            ElevatedButton(
                              onPressed: () => _onCombinePressed(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: DokkeyTheme.gold,
                                foregroundColor: Colors.black,
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(
                                switch (lang) {
                                  'ja' => '錬成する',
                                  'zh' => '炼制',
                                  'de' => 'Kombinieren',
                                  'hi' => 'संयोजित करें',
                                  'en' => 'Combine',
                                  _ => '연성하기',
                                },
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
  }


  Widget _buildBookmarkedQuotesView(DokkeyProvider provider, bool isKo) {
    final savedQuotes = provider.bookmarkedQuotes;

    if (savedQuotes.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('📜', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 16),
              Text(
                isKo ? '마음에 저장한 명언이 없습니다' : 'No Saved Quotes Yet',
                style: TextStyle(
                  color: DokkeyTheme.goldLight,
                  fontSize: 16.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isKo
                    ? '홈 화면에서 명언 옆의 하트(❤️) 버튼을 누르면\n소중한 명언과 깨비의 조언이 여기에 보관됩니다!'
                    : 'Tap the heart (❤️) icon next to the daily quote on the Home screen to save your favorite wisdom here!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DokkeyTheme.textMuted,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.arrow_back_rounded, size: 18),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DokkeyTheme.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                label: Text(
                  isKo ? '홈으로 돌아가기' : 'Back to Home',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: savedQuotes.length,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (ctx, idx) {
        final q = savedQuotes[idx];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: DokkeyTheme.cardDark,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.45), width: 1.2),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: DokkeyTheme.gold.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      '${q.theme.toUpperCase()} · ${q.authorLabel}',
                      style: TextStyle(
                        color: DokkeyTheme.goldLight,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.favorite_rounded, color: Colors.redAccent, size: 20),
                    tooltip: isKo ? '저장 해제' : 'Remove',
                    onPressed: () async {
                      await provider.bookmarkQuote(q.id);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(isKo ? '명언 저장이 해제되었습니다.' : 'Removed from saved quotes.'),
                            backgroundColor: DokkeyTheme.surfaceDark,
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                '“${q.text}”',
                style: TextStyle(
                  color: DokkeyTheme.textMain,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                  height: 1.45,
                ),
              ),
              if (q.hasKkaebiComment) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.gold.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.35)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('👺', style: TextStyle(fontSize: 15)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          q.kkaebiComment,
                          style: const TextStyle(
                            color: Color(0xFFFFEAA7),
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton.icon(
                    onPressed: () {
                      SoundService().playSuccessChime();
                      QuotePosterDialog.show(context, q);
                    },
                    icon: Icon(Icons.ios_share_rounded, size: 15, color: DokkeyTheme.gold),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: DokkeyTheme.gold.withValues(alpha: 0.6)),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    ),
                    label: Text(
                      isKo ? '🎴 부적 카드로 열기' : '🎴 View Amulet',
                      style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(DokkeyProvider provider, int combinedCount) {
    final lang = provider.lang;
    final emptyMsg = switch (lang) {
      'ja' => '集めた数字がまだありません。',
      'zh' => '还没有收集任何数字。',
      'de' => 'Noch keine Zahlen gesammelt.',
      'hi' => 'अभी तक कोई संख्या एकत्र नहीं की गई।',
      'en' => 'No numbers collected yet.',
      _ => '아직 모은 숫자가 없습니다.',
    };
    final tipMsg = switch (lang) {
      'ja' => '運勢カード・なぞなぞ・夢占いから幸運の数字を集めよう！',
      'zh' => '从运势卡片、谜语和解梦中收集幸运数字吧！',
      'de' => 'Sammle Glückszahlen aus Ziehungen, Rätseln & Träumen!',
      'hi' => 'ड्रा, पहेलियों और सपनों से भाग्यशाली अंक एकत्र करें!',
      'en' => 'Collect lucky numbers from draws, riddles & dreams!',
      _ => '운세 카드 · 수수께끼 · 꿈풀이에서 행운의 숫자를 모아보세요!',
    };
    final buttonLabel = switch (lang) {
      'ja' => '組合せキー保管箱 ($combinedCount)',
      'zh' => '查看组合钥匙保管箱 ($combinedCount)',
      'de' => 'Kombinierte Schlüssel ansehen ($combinedCount)',
      'hi' => 'संयोजित कुंजियाँ देखें ($combinedCount)',
      'en' => 'View Combined Keys ($combinedCount)',
      _ => '완성된 조합 키 보관함 열기 ($combinedCount)',
    };

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: DokkeyTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              emptyMsg,
              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              tipMsg,
              textAlign: TextAlign.center,
              style: TextStyle(color: DokkeyTheme.gold, fontSize: 13),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CombinedKeysScreen()),
                );
              },
              icon: Icon(Icons.vpn_key_rounded, color: DokkeyTheme.gold, size: 18),
              style: OutlinedButton.styleFrom(
                foregroundColor: DokkeyTheme.goldLight,
                side: BorderSide(color: DokkeyTheme.gold.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              label: Text(
                buttonLabel,
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SortChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? DokkeyTheme.gold.withOpacity(0.25) : DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? DokkeyTheme.gold : DokkeyTheme.borderDark),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? DokkeyTheme.goldLight : DokkeyTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _PresetChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PresetChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 32,
        height: 26,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? DokkeyTheme.gold : DokkeyTheme.surfaceDark,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: selected ? DokkeyTheme.goldLight : DokkeyTheme.borderDark),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w900,
            color: selected ? Colors.black : DokkeyTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
