import 'package:flutter/material.dart';
import '../core/theme.dart';
import '../models/vault_models.dart';

/// 보관함 숫자 아이템 (v4.1.0)
/// - 중복 획득 배지: x2 / x3 / x5+ 단계별 승급 테두리 (은 → 황금 → 황금 광휘)
/// - 기운별 컬러 칩 + 획득 시점 헤드라인
/// - 핀(Pin/즐겨찾기) 토글
class KeyBoxItemWidget extends StatelessWidget {
  final SourceNumberItem item;
  final bool isSelected;
  final VoidCallback onToggleSelect;
  final VoidCallback onTapCard;
  final VoidCallback? onTogglePin;

  const KeyBoxItemWidget({
    super.key,
    required this.item,
    required this.isSelected,
    required this.onToggleSelect,
    required this.onTapCard,
    this.onTogglePin,
  });

  List<Color> _tierBorder() {
    if (item.count >= 5) {
      return [const Color(0xFFFFE29A), const Color(0xFFB8860B), const Color(0xFFF5BD42)];
    }
    if (item.count >= 3) return [const Color(0xFFF5BD42), const Color(0xFFB8860B)];
    if (item.count >= 2) return [DokkeyTheme.goldLight];
    return [];
  }

  @override
  Widget build(BuildContext context) {
    final toneColor = DokkeyTheme.parseHex(item.lastToneColor);
    final dateStr =
        '${item.lastAcquiredAt.year}.${item.lastAcquiredAt.month.toString().padLeft(2, '0')}.${item.lastAcquiredAt.day.toString().padLeft(2, '0')}';
    final tier = _tierBorder();
    final isGoldTier = item.count >= 3;

    return Container(
      decoration: BoxDecoration(
        color: isSelected
            ? DokkeyTheme.gold.withOpacity(0.08)
            : (isGoldTier ? DokkeyTheme.gold.withOpacity(0.04) : DokkeyTheme.cardDark),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isSelected
              ? DokkeyTheme.gold
              : (isGoldTier ? DokkeyTheme.gold.withOpacity(0.7) : DokkeyTheme.borderDark),
          width: isSelected
              ? 1.5
              : (isGoldTier ? 1.4 : 1.0),
        ),
        boxShadow: item.count >= 5
            ? [
                BoxShadow(
                  color: DokkeyTheme.gold.withOpacity(0.18),
                  blurRadius: 12,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTapCard,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                // 1. Left: Circular Number Emblem (황금 테두리 승급 그라데이션)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: tier.length > 1
                        ? SweepGradient(colors: tier)
                        : null,
                    color: tier.length > 1 ? null : toneColor.withOpacity(0.15),
                    border: Border.all(
                      color: tier.isNotEmpty ? tier.first : toneColor,
                      width: tier.length > 1 ? 2.2 : 1.5,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: DokkeyTheme.cardDark,
                      ),
                      child: Center(
                        child: Text(
                          '#${item.numberStr}',
                          style: TextStyle(
                            color: toneColor,
                            fontWeight: FontWeight.w900,
                            fontSize: 14.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // 2. Middle: Date + Tone Badge + Headline Summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            dateStr,
                            style: TextStyle(
                              color: DokkeyTheme.textMuted,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (item.lastToneName.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: toneColor.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                item.lastToneName,
                                style: TextStyle(
                                  color: toneColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          if (item.lastCardName.isNotEmpty) ...[
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                item.lastCardName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: DokkeyTheme.textMain,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                          if (item.isPinned) ...[
                            const SizedBox(width: 5),
                            Icon(Icons.push_pin_rounded,
                                size: 12, color: DokkeyTheme.gold),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        item.lastHeadline.isNotEmpty
                            ? '"${item.lastHeadline}"'
                            : '깨비의 행운 번호 ${item.numberStr}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DokkeyTheme.textMain,
                          fontSize: 13,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // 3. Right: Duplicate Tier Badge + Pin + Selection Checkbox
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (item.count > 1)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          gradient: item.count >= 5
                              ? const LinearGradient(
                                  colors: [Color(0xFFFFE29A), Color(0xFFB8860B)])
                              : null,
                          color: item.count >= 5
                              ? null
                              : DokkeyTheme.dokFire.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: item.count >= 5
                                ? const Color(0xFFB8860B)
                                : DokkeyTheme.dokFire.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'x${item.count}${item.count >= 5 ? ' 👑' : ''}',
                          style: TextStyle(
                            color: item.count >= 5
                                ? Colors.black
                                : DokkeyTheme.dokFire,
                            fontWeight: FontWeight.w900,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (onTogglePin != null)
                      GestureDetector(
                        onTap: onTogglePin,
                        child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                            item.isPinned
                                ? Icons.push_pin_rounded
                                : Icons.push_pin_outlined,
                            size: 17,
                            color: item.isPinned ? DokkeyTheme.gold : DokkeyTheme.textMuted,
                          ),
                        ),
                      ),
                    // Circular Selection Checkbox
                    GestureDetector(
                      onTap: onToggleSelect,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isSelected ? DokkeyTheme.gold : Colors.transparent,
                          border: Border.all(
                            color: isSelected ? DokkeyTheme.gold : DokkeyTheme.borderDark,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded, size: 16, color: Colors.black)
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
