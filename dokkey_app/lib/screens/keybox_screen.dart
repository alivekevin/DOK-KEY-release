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
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final available = provider.sourceNumbers;

    if (!provider.canAddCombinedKey) {
      ProPassDialog.show(context);
      return;
    }

    if (available.isEmpty) {
      _toast(context, isKo ? '모은 숫자가 하나도 없습니다!' : 'No numbers collected yet!');
      return;
    }

    if (!_allowDuplicates && available.length < _targetCount) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isKo
                ? '보유한 고유 숫자가 부족합니다! (필요: $_targetCount개, 보유: ${available.length}개)\n💡 중복 허용 모드로 전환하면 지금 바로 연성할 수 있어요!'
                : 'Not enough unique numbers! (Need: $_targetCount, Have: ${available.length})\n💡 Try Allow Duplicates mode!',
          ),
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
                    isKo ? '조합 보관함이 가득 찼습니다' : (isJa ? '保管箱が満杯です' : 'Vault is full'),
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              isKo
                  ? (isPro
                      ? '조합 키 99/99 슬롯이 모두 찼습니다. 보관함에서 오래된 키를 정리한 뒤 다시 연성해주세요.'
                      : '무료 슬롯 9/9가 모두 찼습니다.\n\n🗑️ 보관함에서 오래된 키를 정리하거나\n👑 10년 안심 패스로 99개 슬롯으로 확장할 수 있습니다.')
                  : (isPro
                      ? 'All 99 slots are full. Clean old keys in the vault and try again.'
                      : 'Free slots full (9/9).\n\n🗑️ Clean old keys in the vault, or\n👑 expand to 99 slots with the Pro Pass.'),
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
                  isKo ? '보관함 정리하러 가기' : (isJa ? '保管箱へ' : 'Open Vault'),
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
                    isKo ? '99슬롯 확장' : (isJa ? '99スロット' : 'Get 99 Slots'),
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

  void _showCloudVaultDialog(BuildContext context) {
    final provider = context.read<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: DokkeyTheme.cardDark,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
          side: BorderSide(color: DokkeyTheme.gold, width: 1.5),
        ),
        title: Row(
          children: [
            Icon(Icons.cloud_sync_outlined, color: DokkeyTheme.gold),
            const SizedBox(width: 8),
            Text(
              isKo ? 'Zero-Login 개인 클라우드 볼트' : 'Zero-Login Personal Vault',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              isKo
                  ? '내가 완성한 소중한 조합 키와 수집 숫자를 안전하게 백업하고 복원하는 Zero-Login 개인 볼트입니다.'
                  : 'Backup and restore your generated combined keys and collected numbers safely without any central servers.',
              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 13),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () {
                final backupJson = provider.exportVaultBackup();
                Clipboard.setData(ClipboardData(text: backupJson));
                Navigator.of(ctx).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(isKo ? '볼트 백업 JSON이 복사되었습니다! 📋' : 'Vault JSON copied to clipboard! 📋'),
                    backgroundColor: DokkeyTheme.surfaceDark,
                  ),
                );
              },
              icon: const Icon(Icons.download_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: DokkeyTheme.gold,
                foregroundColor: Colors.black,
              ),
              label: Text(isKo ? '볼트 백업 데이터 내보내기 (복사)' : 'Export Vault Backup',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(isKo ? '닫기' : 'Close', style: TextStyle(color: DokkeyTheme.gold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final sourceList = provider.sourceNumbers;
    final maxAvailable = sourceList.length;
    final sortedList = _applySortFilter(sourceList);

    // 유니크 모드에서 N이 보유 수를 넘으면 자동 보정
    if (!_allowDuplicates && maxAvailable >= 2 && _targetCount > maxAvailable) {
      _targetCount = maxAvailable;
    } else if (_targetCount < 2) {
      _targetCount = 2;
    }

    // 기운 컬러 필터 옵션 (보유 풀 기준)
    final toneColors = <String?>[null, ...{for (final s in sourceList) s.lastToneColor}];

    final combinedCount = provider.combinedKeys.length;

    return Scaffold(
      appBar: AppBar(
        title: Text(isKo ? '보관함' : (isJa ? '保管箱' : 'Key Box')),
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
                isKo
                    ? '조합 키 ($combinedCount)'
                    : (isJa ? '組合せ ($combinedCount)' : 'Keys ($combinedCount)'),
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
            tooltip: isKo ? '99 그랜드 도감' : (isJa ? '99 グランド図鑑' : '99 Grand Codex'),
          ),
          const RotatingKeyHomeButton(),
          const SizedBox(width: 4),
        ],
      ),
      body: sourceList.isEmpty
          ? _buildEmptyState(provider, combinedCount)
          : Column(
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
                              isKo ? '프리셋' : 'Preset',
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
                                      isKo ? '중복 허용' : (isJa ? '重複許可' : 'Dupes'),
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
                                    isKo
                                        ? (_allowDuplicates
                                            ? '중첩 연성 모드 (빈도 가중치 반영)'
                                            : '고유 번호 연성 모드')
                                        : (_allowDuplicates ? 'Restoration + Weighted' : 'Unique Mode'),
                                    style: TextStyle(
                                      color: _allowDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isKo
                                        ? '고정: ${_selectedNumbers.length} / 보유: $maxAvailable'
                                        : 'Fixed: ${_selectedNumbers.length} / Pool: $maxAvailable',
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
                                isKo ? '연성하기' : 'Combine',
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
            ),
    );
  }

  Widget _buildEmptyState(DokkeyProvider provider, int combinedCount) {
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inventory_2_outlined, size: 64, color: DokkeyTheme.textMuted),
            const SizedBox(height: 16),
            Text(
              isKo ? '아직 모은 숫자가 없습니다.' : 'No numbers collected yet.',
              style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(
              isKo ? '운세 카드 · 수수께끼 · 꿈풀이에서 행운의 숫자를 모아보세요!' : 'Collect lucky numbers from draws, riddles & dreams!',
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
                isKo
                    ? '완성된 조합 키 보관함 열기 ($combinedCount)'
                    : (isJa ? '組合せキー保管箱 ($combinedCount)' : 'View Combined Keys ($combinedCount)'),
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
