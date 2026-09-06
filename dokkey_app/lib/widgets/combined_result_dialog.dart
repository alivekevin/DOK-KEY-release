import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/key_combiner_engine.dart';
import '../core/theme.dart';
import '../models/vault_models.dart';
import '../providers/dokkey_provider.dart';
import '../screens/combined_keys_screen.dart';
import 'kkaebi_face_widget.dart';

/// ✨ 조합 완성 열쇠 결과 다이얼로그 (v4.1.0)
/// 연성 성공 시 깨비 [8 놀람]→[3 기쁨] 환호, 중복 연성 시 "중첩 기운 발동!" 스페셜
class CombinedResultDialog extends StatefulWidget {
  final CombinedKeyItem combinedKey;
  final bool allowDuplicates;

  const CombinedResultDialog({
    super.key,
    required this.combinedKey,
    this.allowDuplicates = false,
  });

  @override
  State<CombinedResultDialog> createState() => _CombinedResultDialogState();
}

class _CombinedResultDialogState extends State<CombinedResultDialog> {
  late final TextEditingController _tagCtrl;
  bool _tagEdited = false;

  bool get _hasDuplicates =>
      KeyCombinerEngine.hasDuplicates(widget.combinedKey.numbers);

  @override
  void initState() {
    super.initState();
    _tagCtrl = TextEditingController(text: widget.combinedKey.userTag ?? '');
  }

  @override
  void dispose() {
    _tagCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final formattedStr = widget.combinedKey.formattedNumbers;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: _hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: (_hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold)
                  .withOpacity(0.25),
              blurRadius: 28,
              spreadRadius: 4,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Kkaebi Jackpot Face ([8 놀람] → [3 기쁨] → [5 미소])
            Center(
              child: Container(
                width: 84,
                height: 84,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (_hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold)
                          .withOpacity(0.4),
                      DokkeyTheme.cardDark,
                    ],
                  ),
                  border: Border.all(
                    color: _hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold,
                    width: 1.8,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: (_hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold)
                          .withOpacity(0.45),
                      blurRadius: 16,
                    ),
                  ],
                ),
                child: ClipOval(
                  child: KkaebiFaceWidget(
                    size: 78,
                    mode: KkaebiFaceMode.jackpot,
                    enableGlow: true,
                  ),
                ),
              ),
            ),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _hasDuplicates ? Icons.bolt_rounded : Icons.auto_awesome_rounded,
                  color: _hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold,
                  size: 22,
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '${widget.combinedKey.numbers.length} Keys 조합 완료',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: _hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold,
                      letterSpacing: 1.0,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _hasDuplicates
                  ? '✨ 중첩 기운 발동! 도깨비 중첩비기가 탄생했다깨비! ✨'
                  : '엄청난 기운의 조합 열쇠가 탄생했다깨비! (7일 보관)',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.textMuted,
                fontSize: 12,
                fontWeight: _hasDuplicates ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const SizedBox(height: 20),

            // Number Chips Wrap
            Center(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                alignment: WrapAlignment.center,
                children: widget.combinedKey.numbers.map((numStr) {
                  return Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DokkeyTheme.surfaceDark,
                      border: Border.all(
                        color: _hasDuplicates ? DokkeyTheme.dokFire : DokkeyTheme.gold,
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        numStr,
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 18),

            // Formatted Preview
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: DokkeyTheme.surfaceDark,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: DokkeyTheme.borderDark),
              ),
              child: Center(
                child: Text(
                  formattedStr,
                  style: TextStyle(
                    color: DokkeyTheme.textMain,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            // Custom Tag Editor (커스텀 태그 편집)
            TextField(
              controller: _tagCtrl,
              maxLength: 20,
              style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13),
              decoration: InputDecoration(
                counterText: '',
                labelText: '커스텀 태그 (예: 이번 주 로또, 도깨비 중첩비기)',
                labelStyle: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                prefixIcon: Icon(Icons.label_outline_rounded,
                    color: DokkeyTheme.gold, size: 18),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DokkeyTheme.borderDark),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: DokkeyTheme.gold),
                ),
                filled: true,
                fillColor: DokkeyTheme.surfaceDark,
                isDense: true,
              ),
              onChanged: (_) => _tagEdited = true,
            ),
            const SizedBox(height: 16),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                Clipboard.setData(ClipboardData(text: formattedStr));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$formattedStr 복사되었습니다! 📋'),
                    backgroundColor: DokkeyTheme.surfaceDark,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
              style: ElevatedButton.styleFrom(
                backgroundColor: DokkeyTheme.gold,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              label: const Text('클립보드 복사 (Copy)', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CombinedKeysScreen()),
                );
              },
              icon: Icon(Icons.vpn_key_rounded, size: 18, color: DokkeyTheme.goldLight),
              style: OutlinedButton.styleFrom(
                foregroundColor: DokkeyTheme.goldLight,
                side: BorderSide(color: DokkeyTheme.gold.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              label: const Text('🔑 저장된 조합 키 보러가기'),
            ),
            const SizedBox(height: 4),

            TextButton(
              onPressed: () {
                if (_tagEdited) {
                  context.read<DokkeyProvider>().updateCombinedKeyTag(
                        widget.combinedKey.id,
                        _tagCtrl.text.trim(),
                      );
                }
                Navigator.of(context).pop();
              },
              child: Text('닫기', style: TextStyle(color: DokkeyTheme.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}
