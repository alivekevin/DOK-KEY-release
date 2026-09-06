import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/image_share_service.dart';
import '../models/dokkey_models.dart';
import 'oriental_card_painter.dart';

enum PosterTheme { talisman, polaroid, neon }

class ShareCardDialog extends StatefulWidget {
  final DrawResult result;

  const ShareCardDialog({super.key, required this.result});

  @override
  State<ShareCardDialog> createState() => _ShareCardDialogState();
}

class _ShareCardDialogState extends State<ShareCardDialog> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isSaving = false;
  bool _squareFormat = false; // false = 9:16 인스타 스토리, true = 1:1 피드/카톡
  PosterTheme _theme = PosterTheme.talisman;

  static const String instagramUrl = 'https://www.instagram.com/kkaebi_ttook_ttak/';
  static const String instagramHandle = '@kkaebi_ttook_ttak';

  String _t(Map<String, String> map) {
    final lang = widget.result.lang;
    return map[lang] ?? map['en'] ?? map['ko'] ?? '';
  }

  void _onSaveImagePressed() async {
    setState(() => _isSaving = true);
    final bytes = await ImageShareService.capturePng(_cardKey);
    final fmt = _squareFormat ? '1x1' : '9x16';
    final themeName = _theme.name;
    final saved = bytes != null
        ? await ImageShareService.saveOrDownloadPng(
            bytes,
            'dokkey_${widget.result.date}_${widget.result.number}_${themeName}_$fmt.png',
          )
        : false;
    if (!mounted) return;
    setState(() => _isSaving = false);

    final okMsg = _t({
      'ko': '${_squareFormat ? "1:1" : "9:16"} 고화질 포스터가 저장되었습니다! ✨\n인스타에 $instagramHandle 를 태그해보세요!',
      'en': '${_squareFormat ? "1:1" : "9:16"} poster saved! ✨\nTag $instagramHandle on Instagram!',
      'ja': '${_squareFormat ? "1:1" : "9:16"}高画質ポスターを保存しました! ✨\n$instagramHandle をタグ付けしてみましょう！',
      'zh': '${_squareFormat ? "1:1" : "9:16"} 高清海报已保存！✨\n欢迎在Instagram上@$instagramHandle ！',
      'hi': '${_squareFormat ? "1:1" : "9:16"} पोस्टर सहेजा गया! ✨\nइंस्टाग्राम पर $instagramHandle को टैग करें!',
      'de': '${_squareFormat ? "1:1" : "9:16"} Poster gespeichert! ✨\nMarkiere $instagramHandle auf Instagram!',
    });

    final failMsg = _t({
      'ko': '저장에 실패했습니다. 다시 시도해주세요.',
      'en': 'Save failed. Please try again.',
      'ja': '保存に失敗しました。もう一度お試しください。',
      'zh': '保存失败，请重试。',
      'hi': 'सहेजने में विफल। कृपया पुनः प्रयास करें।',
      'de': 'Speichern fehlgeschlagen. Bitte erneut versuchen.',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved ? okMsg : failMsg),
        backgroundColor: saved ? DokkeyTheme.cardDark : DokkeyTheme.dokFire,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  Future<void> _openInstagram() async {
    final uri = Uri.parse(instagramUrl);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  void _copyShareCaption() {
    final igTagNotice = _t({
      'ko': '📌 깨비 공식 인스타그램: $instagramHandle\n#DOKKEY #독키 #깨비 #깨비뚝딱 #오늘의운세 #행운의열쇠',
      'en': '📌 Official Instagram: $instagramHandle\n#DOKKEY #Kkaebi #DailyFortune #LuckyKeys',
      'ja': '📌 クケビ公式インスタグラム: $instagramHandle\n#DOKKEY #ドッキ #クケビ #今日の運勢 #幸運の鍵',
      'zh': '📌 官方Instagram: $instagramHandle\n#DOKKEY #鬼怪 #每日运势 #幸运钥匙',
      'hi': '📌 आधिकारिक इंस्टाग्राम: $instagramHandle\n#DOKKEY #Kkaebi #दैनिक_राशिफल',
      'de': '📌 Offizielles Instagram: $instagramHandle\n#DOKKEY #Kkaebi #Tageshoroskop #Glücksschlüssel',
    });

    final fullCaption = '${widget.result.shareCaption}\n\n$igTagNotice';
    Clipboard.setData(ClipboardData(text: fullCaption));

    final copyMsg = _t({
      'ko': '공유 문구와 인스타 태그가 복사되었습니다! 📋',
      'en': 'Caption & IG tag copied! 📋',
      'ja': '共有文とインスタタグをコピーしました! 📋',
      'zh': '文案和IG标签已复制！📋',
      'hi': 'कैप्शन और आईजी टैग कॉपी किया गया! 📋',
      'de': 'Text & IG-Tag kopiert! 📋',
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(copyMsg),
        backgroundColor: DokkeyTheme.surfaceDark,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 1. Theme Selector Chips (3가지 스타일 - 6개국어 지원)
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: DokkeyTheme.surfaceDark.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: DokkeyTheme.borderDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _ThemeChip(
                    label: _t({
                      'ko': '📜 황금 부적',
                      'en': '📜 Talisman',
                      'ja': '📜 黄金お札',
                      'zh': '📜 黄金符咒',
                      'hi': '📜 ताबीज',
                      'de': '📜 Talisman',
                    }),
                    selected: _theme == PosterTheme.talisman,
                    accentColor: const Color(0xFFE5A93C),
                    onTap: () => setState(() => _theme = PosterTheme.talisman),
                  ),
                  const SizedBox(width: 4),
                  _ThemeChip(
                    label: _t({
                      'ko': '📷 폴라로이드',
                      'en': '📷 Polaroid',
                      'ja': '📷 ポラロイド',
                      'zh': '📷 拍立得',
                      'hi': '📷 पोलरॉइड',
                      'de': '📷 Polaroid',
                    }),
                    selected: _theme == PosterTheme.polaroid,
                    accentColor: const Color(0xFFEAEFF8),
                    onTap: () => setState(() => _theme = PosterTheme.polaroid),
                  ),
                  const SizedBox(width: 4),
                  _ThemeChip(
                    label: _t({
                      'ko': '🌌 네온 불꽃',
                      'en': '🌌 Neon Fire',
                      'ja': '🌌 ネオン鬼火',
                      'zh': '🌌 霓虹鬼火',
                      'hi': '🌌 नियॉन',
                      'de': '🌌 Neon',
                    }),
                    selected: _theme == PosterTheme.neon,
                    accentColor: const Color(0xFF00E5FF),
                    onTap: () => setState(() => _theme = PosterTheme.neon),
                  ),
                ],
              ),
            ),

            // 2. Format Toggle (9:16 인스타 스토리 / 1:1 피드·카톡)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: DokkeyTheme.surfaceDark.withOpacity(0.95),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DokkeyTheme.borderDark),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _FormatToggle(
                    label: _t({
                      'ko': '9:16 (스토리)',
                      'en': '9:16 (Story)',
                      'ja': '9:16 (ストーリー)',
                      'zh': '9:16 (快拍)',
                      'hi': '9:16 (स्टोरी)',
                      'de': '9:16 (Story)',
                    }),
                    selected: !_squareFormat,
                    onTap: () => setState(() => _squareFormat = false),
                  ),
                  const SizedBox(width: 4),
                  _FormatToggle(
                    label: _t({
                      'ko': '1:1 (피드·카톡)',
                      'en': '1:1 (Feed)',
                      'ja': '1:1 (フィード)',
                      'zh': '1:1 (帖子)',
                      'hi': '1:1 (फ़ीड)',
                      'de': '1:1 (Feed)',
                    }),
                    selected: _squareFormat,
                    onTap: () => setState(() => _squareFormat = true),
                  ),
                ],
              ),
            ),

            // 3. Poster Canvas wrapped with RepaintBoundary
            RepaintBoundary(
              key: _cardKey,
              child: _buildPosterByTheme(context),
            ),
            const SizedBox(height: 14),

            // 4. Action Buttons
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Save Button
                ElevatedButton.icon(
                  onPressed: _isSaving ? null : _onSaveImagePressed,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DokkeyTheme.gold,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: _isSaving
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                        )
                      : const Icon(Icons.download_rounded, size: 18),
                  label: Text(
                    _t({
                      'ko': '포스터 저장',
                      'en': 'Save Poster',
                      'ja': 'ポスター保存',
                      'zh': '保存海报',
                      'hi': 'पोस्टर सहेजें',
                      'de': 'Poster speichern',
                    }),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                // Copy Caption Button
                OutlinedButton.icon(
                  onPressed: _copyShareCaption,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: DokkeyTheme.textMain,
                    side: BorderSide(color: DokkeyTheme.borderDark),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(
                    _t({
                      'ko': '문구 복사',
                      'en': 'Copy Caption',
                      'ja': '文をコピー',
                      'zh': '复制文案',
                      'hi': 'कैप्शन कॉपी',
                      'de': 'Text kopieren',
                    }),
                  ),
                ),

                // Instagram Official Channel Button
                ElevatedButton.icon(
                  onPressed: _openInstagram,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFC13584),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: const Icon(Icons.camera_alt_outlined, size: 16),
                  label: Text(
                    _t({
                      'ko': '인스타 방문',
                      'en': 'Instagram',
                      'ja': 'インスタ訪問',
                      'zh': '访问IG',
                      'hi': 'इंस्टाग्राम',
                      'de': 'Instagram',
                    }),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),

                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded, color: DokkeyTheme.textMuted),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// 테마별 포스터 분기 렌더링
  Widget _buildPosterByTheme(BuildContext context) {
    switch (_theme) {
      case PosterTheme.talisman:
        return _buildTalismanPoster(context);
      case PosterTheme.polaroid:
        return _buildPolaroidPoster(context);
      case PosterTheme.neon:
        return _buildNeonPoster(context);
    }
  }

  // ==========================================
  // 📜 THEME 1: 황금 도깨비 부적 (Talisman)
  // ==========================================
  Widget _buildTalismanPoster(BuildContext context) {
    final talismanHeader = _t({
      'ko': '황금 부적 · 액운 타파',
      'en': 'LUCKY TALISMAN',
      'ja': '開運招福 · 厄除け',
      'zh': '萬福來 · 厄運退',
      'hi': 'शुभ ताबीज',
      'de': 'GLÜCKS-TALISMAN',
    });

    return Container(
      width: 320,
      constraints: BoxConstraints(
        minHeight: _squareFormat ? 320 : 580,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF2A090B),
            Color(0xFF451115),
            Color(0xFF1A0406),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE5A93C), width: 2.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFE5A93C).withValues(alpha: 0.35),
            blurRadius: 30,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner talisman border
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFB33927).withValues(alpha: 0.5), width: 1.2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Talisman Header Top Stamp (언어별 완벽 매핑)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFF9E2A2B),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: const Color(0xFFE5A93C), width: 1),
                      ),
                      child: Text(
                        talismanHeader,
                        style: const TextStyle(
                          color: Color(0xFFFFF1C5),
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                    Text(
                      widget.result.date,
                      style: const TextStyle(
                        color: Color(0xFFE5A93C),
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Center Art with Talisman Frame
                OrientalCardWidget(
                  card: widget.result.card,
                  number: widget.result.number,
                  tone: widget.result.tone,
                  width: 165,
                  height: 245,
                ),
                const SizedBox(height: 14),

                // Badges
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _Badge(label: '🗝️ ${widget.result.card.name}', color: const Color(0xFFE5A93C)),
                    const SizedBox(width: 6),
                    _Badge(label: widget.result.tone.name, color: const Color(0xFFFF6B6B)),
                  ],
                ),
                const SizedBox(height: 12),

                // Headline Box
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF140304).withValues(alpha: 0.85),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5A93C).withValues(alpha: 0.5)),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '“${widget.result.headline}”',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFFFF6D6),
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '⚡ ${widget.result.tip}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Color(0xFFE2A97B),
                          fontSize: 10.5,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Footer with Official Instagram Handle
                _buildInstagramFooter(accentColor: const Color(0xFFE5A93C)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // 📷 THEME 2: 감성 폴라로이드 (Polaroid)
  // ==========================================
  Widget _buildPolaroidPoster(BuildContext context) {
    return Container(
      width: 320,
      constraints: BoxConstraints(
        minHeight: _squareFormat ? 320 : 580,
      ),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D24),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF3B4252), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.6),
            blurRadius: 28,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Polaroid Photo Card Frame
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF2E3440),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF4C566A)),
            ),
            child: Column(
              children: [
                OrientalCardWidget(
                  card: widget.result.card,
                  number: widget.result.number,
                  tone: widget.result.tone,
                  width: 170,
                  height: 250,
                ),
                const SizedBox(height: 8),
                Text(
                  '${widget.result.card.name} · #${widget.result.number.toString().padLeft(2, '0')}',
                  style: const TextStyle(
                    color: Color(0xFFD8DEE9),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Daily Quote / Headline
          Text(
            '“${widget.result.headline}”',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFFECEFF4),
              fontSize: 13,
              fontWeight: FontWeight.bold,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            widget.result.tip,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF88C0D0),
              fontSize: 11,
              fontStyle: FontStyle.italic,
            ),
          ),
          const SizedBox(height: 12),

          // Footer with Official Instagram Handle
          _buildInstagramFooter(accentColor: const Color(0xFF88C0D0)),
        ],
      ),
    );
  }

  // ==========================================
  // 🌌 THEME 3: 네온 도깨비불 (Neon Keys)
  // ==========================================
  Widget _buildNeonPoster(BuildContext context) {
    return Container(
      width: 320,
      constraints: BoxConstraints(
        minHeight: _squareFormat ? 320 : 580,
      ),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF080D1F),
            Color(0xFF101B3D),
            Color(0xFF050710),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFF00E5FF), width: 2),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00E5FF).withValues(alpha: 0.35),
            blurRadius: 36,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Cyberpunk Neon Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: const [
                  Icon(Icons.bolt_rounded, color: Color(0xFF00E5FF), size: 16),
                  SizedBox(width: 4),
                  Text(
                    'DOK-KEY NEON',
                    style: TextStyle(
                      color: Color(0xFF00E5FF),
                      fontWeight: FontWeight.w900,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.6)),
                ),
                child: Text(
                  widget.result.date,
                  style: const TextStyle(
                    color: Color(0xFF00E5FF),
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Center Art
          OrientalCardWidget(
            card: widget.result.card,
            number: widget.result.number,
            tone: widget.result.tone,
            width: 165,
            height: 245,
          ),
          const SizedBox(height: 14),

          // Badges
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _Badge(label: '#LUCKY_${widget.result.number.toString().padLeft(2, '0')}', color: const Color(0xFFFFD700)),
              const SizedBox(width: 8),
              _Badge(label: '${widget.result.timeslot.emoji} ${widget.result.timeslot.name}', color: const Color(0xFF00E5FF)),
            ],
          ),
          const SizedBox(height: 12),

          // Cyber Glass Box
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF0B142B).withValues(alpha: 0.9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF00E5FF).withValues(alpha: 0.4)),
            ),
            child: Column(
              children: [
                Text(
                  '“${widget.result.headline}”',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.bold,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '💡 ${widget.result.tip}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Color(0xFF90CAF9),
                    fontSize: 10.5,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Footer with Official Instagram Handle
          _buildInstagramFooter(accentColor: const Color(0xFF00E5FF)),
        ],
      ),
    );
  }

  /// 공통 인스타그램 하단 브랜딩 & QR 코드
  Widget _buildInstagramFooter({required Color accentColor}) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // QR Code
            Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: accentColor, width: 1.2),
              ),
              child: QrImageView(
                data: 'https://alivekevin.github.io/DOK-KEY-release/web/',
                version: QrVersions.auto,
                size: 48.0,
                gapless: true,
                eyeStyle: const QrEyeStyle(
                  eyeShape: QrEyeShape.square,
                  color: Color(0xFF141822),
                ),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Color(0xFF141822),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DOK-KEY : TTOOK-TTAK!',
                  style: TextStyle(
                    color: accentColor,
                    fontSize: 9.5,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Official IG: $instagramHandle',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  _t({
                    'ko': '인스타 태그하고 깨비의 행운 받기 ✨',
                    'en': 'Tag to get Kkaebi\'s luck ✨',
                    'ja': 'タグ付けしてクケビの幸運をゲット ✨',
                    'zh': '标记以获得鬼怪的幸运 ✨',
                    'hi': 'टैग करें और सौभाग्य पाएं ✨',
                    'de': 'Markieren für Kkaebi-Glück ✨',
                  }),
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 8.5,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color accentColor;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.selected,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? accentColor.withValues(alpha: 0.25) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? accentColor : DokkeyTheme.borderDark,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: selected ? (accentColor == const Color(0xFFEAEFF8) ? Colors.white : accentColor) : DokkeyTheme.textMuted,
          ),
        ),
      ),
    );
  }
}

class _FormatToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FormatToggle({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: selected ? DokkeyTheme.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.bold,
            color: selected ? Colors.black : DokkeyTheme.textMuted,
          ),
        ),
      ),
    );
  }
}
