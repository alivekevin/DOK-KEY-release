import '../core/sound_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/dokkey_models.dart';
import '../providers/dokkey_provider.dart';
import 'confetti_burst.dart';
import 'kkaebi_face_widget.dart';
import 'screen_emotion_fx_overlay.dart';

/// 도깨비 수수께끼 다이얼로그 (v4.1.0 PHASE 1/4)
/// - 상단 아바타: KkaebiFaceWidget (탭 시 윙크 힌트 버블)
/// - 정답: [8 놀람]→[3 기쁨] jackpot + 골드 폭죽 + 골드 럭키 넘버 드롭 + 출석 스탬프
/// - 오답: [7 슬픔] + "깨비가 아쉬워해요" 위로 텍스트
class RiddleDialog extends StatefulWidget {
  final RiddleModel riddle;

  const RiddleDialog({super.key, required this.riddle});

  @override
  State<RiddleDialog> createState() => _RiddleDialogState();
}

class _RiddleDialogState extends State<RiddleDialog> {
  int? _selectedIndex;
  bool _submitted = false;
  bool _isCorrect = false;
  bool _hintVisible = false;
  KkaebiFaceMode _faceMode = KkaebiFaceMode.idle;
  int? _droppedLuckyNumber;

  String _hintText(bool isKo, bool isJa) {
    final answer = widget.riddle.options.isNotEmpty
        ? widget.riddle.options[widget.riddle.answerIndex]
        : '';
    final first = answer.isNotEmpty ? answer.characters.first : '?';
    if (isKo) {
      return "힌트다깨비! 정답은 '$first'로 시작하는 말이다깨비! 😉";
    }
    if (isJa) {
      return "ヒントだケビ！答えは「$first」で始まるよ！😉";
    }
    return "Kkaebi hint! The answer starts with '$first'! 😉";
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';

    return Dialog(
      backgroundColor: DokkeyTheme.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: BorderSide(color: DokkeyTheme.gold, width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with Kkaebi Face Avatar (힌트 버블 트리거)
            Row(
              children: [
                GestureDetector(
                  onTap: _submitted
                      ? null
                      : () {
                          setState(() {
                            _hintVisible = !_hintVisible;
                            if (_hintVisible) {
                              _faceMode = KkaebiFaceMode.wink;
                              SoundService().playSuccessChime();
                              Future.delayed(const Duration(milliseconds: 900), () {
                                if (mounted && !_submitted) {
                                  setState(() => _faceMode = KkaebiFaceMode.idle);
                                }
                              });
                            }
                          });
                        },
                  child: KkaebiFaceWidget(
                    size: 46,
                    mode: _faceMode,
                    enableGlow: true,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  isKo ? '깨비의 수수께끼' : (isJa ? 'クケビのなぞなぞ' : "Kkaebi's Riddle"),
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: DokkeyTheme.gold,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.dokFire.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    isKo
                        ? '보너스 +${widget.riddle.rewardKeys} Key'
                        : '+${widget.riddle.rewardKeys} Key',
                    style: TextStyle(
                      color: DokkeyTheme.dokFire,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.close_rounded, color: DokkeyTheme.textMuted, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: isKo ? '닫기' : (isJa ? '閉じる' : 'Close'),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),

            // Hint Bubble (힌트 시스템: 깨비를 탭하면 윙크하며 힌트 제공)
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: _hintVisible && !_submitted
                  ? Container(
                      key: const ValueKey('hint'),
                      margin: const EdgeInsets.only(top: 12),
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.gold.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: DokkeyTheme.gold.withOpacity(0.4)),
                      ),
                      child: Text(
                        _hintText(isKo, isJa),
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontSize: 12,
                          height: 1.4,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(key: ValueKey('no-hint')),
            ),
            const SizedBox(height: 14),

            Text(
              widget.riddle.question,
              style: TextStyle(
                fontSize: 15.5,
                height: 1.5,
                color: DokkeyTheme.textMain,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            ...List.generate(widget.riddle.options.length, (idx) {
              final option = widget.riddle.options[idx];
              final isSelected = _selectedIndex == idx;
              Color borderCol = DokkeyTheme.borderDark;
              Color bgCol = DokkeyTheme.surfaceDark;

              if (_submitted) {
                if (idx == widget.riddle.answerIndex) {
                  borderCol = DokkeyTheme.mintCalm;
                  bgCol = DokkeyTheme.mintCalm.withOpacity(0.2);
                } else if (isSelected) {
                  borderCol = DokkeyTheme.dokFire;
                  bgCol = DokkeyTheme.dokFire.withOpacity(0.2);
                }
              } else if (isSelected) {
                borderCol = DokkeyTheme.gold;
                bgCol = DokkeyTheme.gold.withOpacity(0.15);
              }

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: InkWell(
                  onTap: _submitted
                      ? null
                      : () {
                          setState(() {
                            _selectedIndex = idx;
                          });
                        },
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: bgCol,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: borderCol, width: 1.5),
                    ),
                    child: Row(
                      children: [
                        Text(
                          '${idx + 1}.',
                          style: TextStyle(
                            color: isSelected ? DokkeyTheme.gold : DokkeyTheme.textMuted,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            option,
                            style: TextStyle(
                              color: DokkeyTheme.textMain,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            if (!_submitted)
              ElevatedButton(
                onPressed: _selectedIndex == null
                    ? null
                    : () async {
                        final correct = _selectedIndex == widget.riddle.answerIndex;
                        setState(() {
                          _submitted = true;
                          _isCorrect = correct;
                        });

                        if (correct) {
                          // [8 놀람] → [3 기쁨] 대박 환호 + 골드 폭죽 + 화면 이펙트
                          setState(() => _faceMode = KkaebiFaceMode.jackpot);
                          SoundService().playRiddleCorrect();
                          ConfettiBurst.show(context, color: DokkeyTheme.gold);
                          ScreenEmotionFxOverlay.show(context, EmotionType.joy);
                          final lucky = await provider.onRiddleCorrect();
                          if (mounted && lucky != null) {
                            setState(() => _droppedLuckyNumber = lucky);
                          }
                        } else {
                          // [5 미소] → [7 슬픔] 위로/서운함 + 비내림 효과
                          setState(() => _faceMode = KkaebiFaceMode.sadness);
                          SoundService().playRiddleWrong();
                          ScreenEmotionFxOverlay.show(context, EmotionType.sad);
                        }
                      },
                child: Text(isKo ? '정답 확인하기' : (isJa ? '正解 확인' : 'Submit Answer')),
              )
            else ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: _isCorrect
                      ? DokkeyTheme.mintCalm.withOpacity(0.15)
                      : DokkeyTheme.dokFire.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isCorrect
                          ? widget.riddle.correctReaction
                          : widget.riddle.wrongReaction,
                      style: TextStyle(
                        color: _isCorrect ? DokkeyTheme.mintCalm : DokkeyTheme.dokFire,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                    if (!_isCorrect) ...[
                      const SizedBox(height: 6),
                      Text(
                        isKo
                            ? '깨비가 아쉬워해요... 다음 수수께끼는 꼭 맞혀보거라! 🥺'
                            : (isJa
                                ? 'クケビが残念がってる...次は絶対当ててね！🥺'
                                : "Kkaebi is sad... you'll get the next one! 🥺"),
                        style: TextStyle(
                          color: DokkeyTheme.textMuted,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                    if (_isCorrect && _droppedLuckyNumber != null) ...[
                      const SizedBox(height: 10),
                      // 골드 럭키 넘버 드롭 배너
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFE29A), Color(0xFFB8860B)],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.paid_rounded, size: 16, color: Colors.black),
                            const SizedBox(width: 6),
                            Text(
                              isKo
                                  ? '골드 럭키 넘버 #${_droppedLuckyNumber!.toString().padLeft(2, '0')} 보관함 입고!'
                                  : (isJa
                                      ? 'ゴールドラッキーナンバー #${_droppedLuckyNumber!.toString().padLeft(2, '0')} 入庫！'
                                      : 'Gold Lucky No.#${_droppedLuckyNumber!.toString().padLeft(2, '0')} added!'),
                              style: const TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w900,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // 출석 스탬프 현황
              Center(
                child: Text(
                  isKo
                      ? '🧩 수수께끼 출석 스탬프: ${provider.riddleStampCount}일'
                      : (isJa
                          ? '🧩 なぞなぞ出席スタンプ: ${provider.riddleStampCount}日'
                          : '🧩 Riddle stamps: ${provider.riddleStampCount} days'),
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(
                  isKo ? '닫기' : 'Close',
                  style: TextStyle(color: DokkeyTheme.gold),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
