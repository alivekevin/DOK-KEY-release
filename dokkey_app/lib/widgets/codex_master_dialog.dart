import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'confetti_burst.dart';
import 'kkaebi_face_widget.dart';

/// 🏆 도감 완성 업적 다이얼로그 (v4.1.0 PHASE 6)
/// 66종 정례 카드를 전부 수집하면 한정 칭호 "도깨비 마스터" + 황금 테두리 아바타 해금
class CodexMasterDialog extends StatelessWidget {
  const CodexMasterDialog({super.key});

  static Future<void> show(BuildContext context) {
    SoundService().playGong();
    ConfettiBurst.show(context, color: DokkeyTheme.gold);
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const CodexMasterDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isKo = context.read<DokkeyProvider>().lang == 'ko';
    final isJa = context.read<DokkeyProvider>().lang == 'ja';

    final title = isKo ? '도깨비 마스터 🏆' : (isJa ? 'ドッケビマスター 🏆' : 'Goblin Master 🏆');
    final subtitle = isKo
        ? '황금 열쇠 66장을 모두 모았다깨비!\n전설의 황금 테두리 아바타가 해금됐다!'
        : (isJa
            ? '黄金の鍵66枚をすべて集めたケビ！\n伝説の黄金枠アバターが解禁された！'
            : 'All 66 golden keys collected!\nLegendary golden avatar unlocked!');
    final cta = isKo ? '황금의 시대를 열어보자!' : (isJa ? '黄金の時代を開こう！' : 'Start the golden era!');

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(26),
        constraints: const BoxConstraints(maxWidth: 380),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF3A2A10), Color(0xFF191D24)],
          ),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            width: 2.5,
            color: const Color(0xFFF5BD42),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF5BD42).withOpacity(0.35),
              blurRadius: 34,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const SweepGradient(
                  colors: [Color(0xFFFFE29A), Color(0xFFB8860B), Color(0xFFF5BD42), Color(0xFFFFE29A)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF5BD42).withOpacity(0.6),
                    blurRadius: 22,
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: DokkeyTheme.cardDark,
                ),
                child: const KkaebiFaceWidget(
                  size: 104,
                  mode: KkaebiFaceMode.jackpot,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFFFFE29A),
                fontSize: 21,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: DokkeyTheme.textMain,
                fontSize: 13,
                height: 1.6,
              ),
            ),
            const SizedBox(height: 22),
            ElevatedButton(
              onPressed: () {
                context.read<DokkeyProvider>().consumeCodexMasterCelebration();
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF5BD42),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: Text(cta, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ],
        ),
      ),
    );
  }
}
