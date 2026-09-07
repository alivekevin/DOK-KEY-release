import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/brand_config.dart';
import '../core/image_share_service.dart';
import '../core/theme.dart';
import '../models/dokkey_models.dart';
import '../providers/dokkey_provider.dart';

/// 🎴 황금 명언 부적 카드 (v4.7.0 — 히어로 공유용 9:16 포스터)
class QuotePosterDialog extends StatefulWidget {
  final QuoteModel quote;

  const QuotePosterDialog({super.key, required this.quote});

  static Future<void> show(BuildContext context, QuoteModel quote) {
    return showDialog(
      context: context,
      builder: (_) => QuotePosterDialog(quote: quote),
    );
  }

  @override
  State<QuotePosterDialog> createState() => _QuotePosterDialogState();
}

class _QuotePosterDialogState extends State<QuotePosterDialog> {
  final GlobalKey _posterKey = GlobalKey();
  bool _isSaving = false;

  Future<void> _savePoster(String lang) async {
    setState(() => _isSaving = true);
    final bytes = await ImageShareService.capturePng(_posterKey);
    final saved = bytes != null
        ? await ImageShareService.saveOrDownloadPng(
            bytes, 'dokkey_quote_${widget.quote.id}.png')
        : false;
    if (!mounted) return;
    setState(() => _isSaving = false);
    final okMsg = lang == 'ko'
        ? '명언 부적 카드가 저장/다운로드되었습니다! 🎴'
        : 'Amulet card saved! 🎴';
    final failMsg = lang == 'ko' ? '저장에 실패했습니다.' : 'Save failed.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? okMsg : failMsg),
        backgroundColor: saved ? DokkeyTheme.cardDark : DokkeyTheme.dokFire,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final q = widget.quote;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RepaintBoundary(
              key: _posterKey,
              child: Container(
                width: 320,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF3A2A10), Color(0xFF141822), Color(0xFF0F1116)],
                  ),
                  borderRadius: BorderRadius.circular(26),
                  border: Border.all(color: DokkeyTheme.gold, width: 2.5),
                  boxShadow: [
                    BoxShadow(
                      color: DokkeyTheme.gold.withOpacity(0.3),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // 부적 두름 헤더 (언어별 로컬라이징 도장 — 타언어 혼입 방지)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: DokkeyTheme.gold),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${BrandConfig.posterStamp(lang)} · DOK-KEY',
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontSize: 11,
                          letterSpacing: 3,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(height: 22),
                    const Text('👺', style: TextStyle(fontSize: 40)),
                    const SizedBox(height: 18),
                    Text(
                      '"${q.text}"',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFF3E5AB),
                        fontSize: 18,
                        height: 1.7,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      '- ${q.authorLabel}${q.source.trim().isNotEmpty ? " <${q.source}>" : ""}',
                      style: TextStyle(color: DokkeyTheme.gold, fontSize: 12.5),
                    ),
                    const SizedBox(height: 20),
                    if (q.hasKkaebiComment)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '👺 ${q.kkaebiComment}',
                          style: TextStyle(
                            color: DokkeyTheme.textMain,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    const SizedBox(height: 18),
                    Divider(color: DokkeyTheme.borderDark),
                    const SizedBox(height: 10),
                    Text(
                      BrandConfig.mainSlogan(lang),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: DokkeyTheme.textMuted,
                        fontSize: 10.5,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '#DOK_KEY · ${BrandConfig.posterFooter(lang)}',
                      style: TextStyle(
                        color: DokkeyTheme.gold,
                        fontSize: 10,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // 저장 버튼
            ElevatedButton.icon(
              onPressed: _isSaving ? null : () => _savePoster(lang),
              icon: const Icon(Icons.save_alt_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: DokkeyTheme.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              label: Text(
                _isSaving
                    ? (lang == 'ko' ? '생성 중...' : 'Rendering...')
                    : (lang == 'ko' ? '부적 카드 저장 (9:16)' : 'Save Amulet Card'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                final text = '"${q.text}" - ${q.authorLabel}\n#DOK_KEY';
                Clipboard.setData(ClipboardData(text: text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(lang == 'ko' ? '명언이 복사되었습니다! 📋' : 'Quote copied! 📋'),
                    backgroundColor: DokkeyTheme.surfaceDark,
                  ),
                );
              },
              child: Text(
                lang == 'ko' ? '텍스트 복사' : 'Copy text',
                style: TextStyle(color: DokkeyTheme.textMuted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(lang == 'ko' ? '닫기' : 'Close',
                  style: TextStyle(color: DokkeyTheme.gold)),
            ),
          ],
        ),
      ),
    );
  }
}
