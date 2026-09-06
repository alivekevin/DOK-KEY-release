import 'package:flutter/material.dart';
import '../core/codex_service.dart';
import '../core/theme.dart';
import '../models/codex_models.dart';
import '../models/dokkey_models.dart';

class OrientalCardWidget extends StatelessWidget {
  final CardModel card;
  final int number;
  final ToneModel tone;
  final bool isFront;
  final double width;
  final double height;

  const OrientalCardWidget({
    super.key,
    required this.card,
    required this.number,
    required this.tone,
    this.isFront = true,
    this.width = 240,
    this.height = 360,
  });

  @override
  Widget build(BuildContext context) {
    final codexItem = CodexService().getCardByNumber(number);
    final toneColor = DokkeyTheme.parseHex(tone.color);

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isFront
                ? toneColor.withOpacity(0.4)
                : DokkeyTheme.gold.withOpacity(0.3),
            blurRadius: 28,
            spreadRadius: 4,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: isFront
            ? _buildFrontCard(context, codexItem, toneColor)
            : _buildBackCard(context, codexItem, toneColor),
      ),
    );
  }

  /// 🎴 앞면: 골드 번호 + 고화질 도감 일러스트 + 명칭 + 칭호
  Widget _buildFrontCard(BuildContext context, CodexCardItem? codexItem, Color toneColor) {
    final numStr = number.toString().padLeft(2, '0');
    final displayName = codexItem?.name ?? card.name;
    final displayTitle = codexItem?.title ?? card.symbol;
    final imagePath = codexItem != null
        ? (codexItem.slot <= 33
            ? 'assets/cards/${codexItem.category}/${codexItem.fileName}'
            : 'assets/cards/${codexItem.category}/ext/${codexItem.fileName}')
        : null;

    final isZodiac = number <= 33;
    final frameColor = isZodiac ? const Color(0xFF00F2FE) : const Color(0xFFF6C026);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 1. 다크 프리미엄 그라데이션 배경
        Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment.center,
              radius: 0.9,
              colors: [
                toneColor.withOpacity(0.35),
                const Color(0xFF161A28),
                const Color(0xFF0B0D14),
              ],
            ),
          ),
        ),

        // 2. 외곽 럭셔리 메탈릭 테두리
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: frameColor.withOpacity(0.7),
              width: 1.8,
            ),
          ),
        ),

        // 3. 중앙 후광 오라 (Aura)
        Center(
          child: Container(
            width: width * 0.72,
            height: width * 0.72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: frameColor.withOpacity(0.25),
                  blurRadius: 40,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),
        ),

        // 4. 고화질 도감 일러스트 (WebP) 또는 폴백 아이콘
        Positioned(
          top: height * 0.16,
          bottom: height * 0.28,
          left: width * 0.10,
          right: width * 0.10,
          child: Center(
            child: imagePath != null
                ? Image.asset(
                    imagePath,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => _buildFallbackGlyph(toneColor),
                  )
                : _buildFallbackGlyph(toneColor),
          ),
        ),

        // 5. 상단 헤더 (열쇠 번호 뱃지 & 계통 태그)
        Positioned(
          top: 18,
          left: 18,
          right: 18,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // 열쇠 번호 뱃지
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F141C).withOpacity(0.9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: frameColor, width: 1.2),
                  boxShadow: [
                    BoxShadow(color: frameColor.withOpacity(0.4), blurRadius: 8),
                  ],
                ),
                child: Text(
                  'NO. $numStr',
                  style: TextStyle(
                    color: frameColor,
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              // 도감 카테고리 태그
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isZodiac ? '신수' : '신격',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),

        // 6. 하단 정보 영역 (명칭 & 칭호)
        Positioned(
          bottom: 20,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 구분선
              Container(
                width: width * 0.5,
                height: 1.2,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      frameColor.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),

              // 카드 명칭
              Text(
                displayName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  shadows: [
                    Shadow(color: Colors.black, blurRadius: 10),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),

              // 칭호 / 수식어
              Text(
                '“$displayTitle”',
                style: TextStyle(
                  color: frameColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 📜 뒷면: 상세 도감 해설 + ID + 행운 키워드 + 3D 뒤집기 안내
  Widget _buildBackCard(BuildContext context, CodexCardItem? codexItem, Color toneColor) {
    final numStr = number.toString().padLeft(2, '0');
    final displayName = codexItem?.name ?? card.name;
    final displayDesc = codexItem?.desc ?? card.description;
    final cardId = codexItem?.id ?? 'NO.$numStr';
    final frameColor = number <= 33 ? const Color(0xFF00F2FE) : const Color(0xFFF6C026);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.85,
          colors: [
            Color(0xFF202638),
            Color(0xFF0E1118),
          ],
        ),
      ),
      child: Stack(
        children: [
          // 외곽 테두리
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: DokkeyTheme.gold.withOpacity(0.4),
                width: 1.2,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // 상단 고유 ID 뱃지
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: frameColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: frameColor.withOpacity(0.6)),
                  ),
                  child: Text(
                    '[$cardId] $displayName',
                    style: TextStyle(
                      color: frameColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // 중앙 신성한 도깨비 인장
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: DokkeyTheme.surfaceDark,
                    border: Border.all(color: DokkeyTheme.gold.withOpacity(0.8), width: 1.5),
                  ),
                  child: const Center(
                    child: Text('🔑', style: TextStyle(fontSize: 22)),
                  ),
                ),
                const SizedBox(height: 16),

                // 표준 도감체 상세 해설
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Text(
                        displayDesc,
                        style: TextStyle(
                          color: DokkeyTheme.textMain,
                          fontSize: 13.5,
                          height: 1.6,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),
                // 하단 수집 안내
                Text(
                  'DOK-KEY 99 GRAND CODEX',
                  style: TextStyle(
                    color: DokkeyTheme.textMuted.withOpacity(0.6),
                    fontSize: 9.5,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFallbackGlyph(Color color) {
    return Icon(
      Icons.auto_awesome,
      color: color.withOpacity(0.8),
      size: width * 0.35,
    );
  }
}