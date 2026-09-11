import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../core/sound_service.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import 'core/game_shell.dart';

/// 💬 게임 1: 깨비의 상식 & 과학 문답 (Trivia Chat - 3진 아웃 서바이벌 모드)
/// 4지선다 · 10초 카운트다운 · 생명 3개(3진 아웃) · 10문제 돌파 시 최종 클리어.
class KkaebiTriviaGame extends StatefulWidget {
  const KkaebiTriviaGame({super.key});

  static const String gameId = 'trivia';

  @override
  State<KkaebiTriviaGame> createState() => _KkaebiTriviaGameState();
}

class _KkaebiTriviaGameState extends State<KkaebiTriviaGame>
    with GameLoopMixin {
  List<Map<String, dynamic>> _questions = [];
  int _current = 0;
  int _score = 0;
  int _correct = 0;
  int _lives = 3; // ❤️ 생명 3개 (3진 아웃)
  int? _selected;
  bool _answered = false;
  bool _finished = false;
  double _timeLeft = 10.0;
  int _best = 0;
  bool _loading = true;

  static const int _targetQuestions = 10; // 10문제 돌파 시 클리어

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<DokkeyProvider>();
    final raw =
        await rootBundle.loadString('assets/data/locales/${provider.lang}/trivia.json');
    _questions = (json.decode(raw) as List).cast<Map<String, dynamic>>();
    _questions.shuffle(RandomProvider.random);
    _best = await ArcadeScores.get(KkaebiTriviaGame.gameId);
    if (mounted) {
      setState(() => _loading = false);
    }
  }

  void _onAnswer(int idx) {
    if (_answered || _finished) return;
    final q = _questions[_current];
    final correct = idx == (q['answer_index'] as num).toInt();
    setState(() {
      _selected = idx;
      _answered = true;
    });

    if (correct) {
      _score += 100 + (_timeLeft * 10).floor();
      _correct++;
      SoundService().playSuccessChime();
      HapticFeedback.mediumImpact();
      context.read<DokkeyProvider>().addKkaebiAffection(10, reason: 'trivia');
      particles.burst(
        x: 180,
        y: 240,
        color: const Color(0xFFFFD700),
        count: 30,
        speed: 240,
      );
    } else {
      _lives--;
      shake.add(0.4);
      SoundService().playRiddleWrong();
      HapticFeedback.heavyImpact();
      particles.burst(
        x: 180,
        y: 240,
        color: const Color(0xFFFF5252),
        count: 20,
        speed: 180,
      );
    }

    Future.delayed(const Duration(milliseconds: 1100), () {
      if (!mounted) return;
      if (_lives <= 0) {
        _finish(cleared: false);
      } else if (_current + 1 >= min(_targetQuestions, _questions.length)) {
        _finish(cleared: true);
      } else {
        _next();
      }
    });
  }

  void _next() {
    if (!mounted) return;
    setState(() {
      _current++;
      _selected = null;
      _answered = false;
      _timeLeft = 10.0;
    });
  }

  Future<void> _finish({required bool cleared}) async {
    if (_finished) return;
    setState(() => _finished = true);
    final provider = context.read<DokkeyProvider>();
    await ArcadeScores.submit(KkaebiTriviaGame.gameId, _score);
    final best = await ArcadeScores.get(KkaebiTriviaGame.gameId);
    await dispatchGameReward(context,
        gameId: KkaebiTriviaGame.gameId, score: _score, cleared: cleared);
    if (!mounted) return;
    final isKo = provider.lang == 'ko';
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => GameResultDialog(
        gameId: KkaebiTriviaGame.gameId,
        title: isKo ? '깨비 상식 문답' : (provider.lang == 'ja' ? 'クケビ常識クイズ' : 'Kkaebi Trivia'),
        score: _score,
        best: best,
        cleared: cleared,
        onRetry: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const KkaebiTriviaGame()),
          );
        },
        onExit: () {
          Navigator.of(ctx).pop();
          Navigator.of(context).pop();
        },
      ),
    );
  }

  // MARK: GameLoop
  @override
  void onUpdate(double dt) {
    if (_loading || _answered || _finished) return;
    _timeLeft -= dt;
    if (_timeLeft <= 0) {
      _timeLeft = 0;
      _onAnswer(-1); // 시간 초과 = 오답 & 생명 차감
    }
  }

  @override
  void onPaint(Canvas canvas, Size size) {
    // 배경: 밤하늘 명상 그라데이션
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          colors: [Color(0xFF141C2A), Color(0xFF0C1017)],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';

    // 생명 하트 문자열 (예: ❤️❤️❤️, ❤️❤️🖤, ❤️🖤🖤)
    final heartsStr = List.generate(3, (i) => i < _lives ? '❤️' : '🖤').join(' ');

    return Scaffold(
      backgroundColor: DokkeyTheme.bgDark,
      body: gameCanvas(
        overlayBuilder: () => SafeArea(
          child: _loading
              ? Center(child: CircularProgressIndicator(color: DokkeyTheme.gold))
              : Column(
                  children: [
                    GameHud(
                      title: isKo ? '상식 서바이벌' : 'Trivia Survival',
                      score: _score,
                      rightLabel: '$heartsStr  (${_current + 1}/$_targetQuestions)',
                      onQuit: () => Navigator.of(context).pop(),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(6),
                        child: LinearProgressIndicator(
                          value: _timeLeft / 10.0,
                          minHeight: 7,
                          backgroundColor: const Color(0xFF222B38),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _timeLeft > 4 ? const Color(0xFF00E676) : const Color(0xFFFF5252),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 고시인성 질문 카드
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E2638),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: const Color(0xFFFFD700).withOpacity(0.55),
                                    width: 1.8),
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black45,
                                    blurRadius: 10,
                                    offset: Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFD700),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          '💡 문제 ${_current + 1} / $_targetQuestions',
                                          style: const TextStyle(
                                            color: Colors.black,
                                            fontWeight: FontWeight.w900,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '생명: $heartsStr',
                                        style: const TextStyle(fontSize: 13),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '${_questions[_current]['question']}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 17.5,
                                      fontWeight: FontWeight.w800,
                                      height: 1.45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            // 고시인성 4지선다 보기
                            ...List.generate(
                              (_questions[_current]['options'] as List).length,
                              (idx) {
                                final opts =
                                    (_questions[_current]['options'] as List).cast<String>();
                                final correctIdx =
                                    (_questions[_current]['answer_index'] as num).toInt();
                                Color border = const Color(0xFF3B4861);
                                Color bg = const Color(0xFF1B2230);
                                IconData? trailing;
                                if (_answered) {
                                  if (idx == correctIdx) {
                                    border = const Color(0xFF00E676);
                                    bg = const Color(0xFF00E676).withOpacity(0.25);
                                    trailing = Icons.check_circle_rounded;
                                  } else if (idx == _selected) {
                                    border = const Color(0xFFFF5252);
                                    bg = const Color(0xFFFF5252).withOpacity(0.25);
                                    trailing = Icons.cancel_rounded;
                                  }
                                } else if (idx == _selected) {
                                  border = const Color(0xFFFFD700);
                                  bg = const Color(0xFFFFD700).withOpacity(0.2);
                                }
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 9),
                                  child: InkWell(
                                    onTap: () => _onAnswer(idx),
                                    borderRadius: BorderRadius.circular(14),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      decoration: BoxDecoration(
                                        color: bg,
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: border, width: 1.8),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 26,
                                            height: 26,
                                            alignment: Alignment.center,
                                            decoration: BoxDecoration(
                                              color: border.withOpacity(0.25),
                                              shape: BoxShape.circle,
                                              border: Border.all(color: border, width: 1.2),
                                            ),
                                            child: Text(
                                              '${idx + 1}',
                                              style: TextStyle(
                                                color: _answered && idx == correctIdx
                                                    ? const Color(0xFF00E676)
                                                    : const Color(0xFFFFD700),
                                                fontWeight: FontWeight.w900,
                                                fontSize: 13,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              opts[idx],
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontWeight: FontWeight.w700,
                                                fontSize: 15,
                                                height: 1.25,
                                              ),
                                            ),
                                          ),
                                          if (trailing != null)
                                            Icon(
                                              trailing,
                                              size: 20,
                                              color: idx == correctIdx
                                                  ? const Color(0xFF00E676)
                                                  : const Color(0xFFFF5252),
                                            ),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                            const SizedBox(height: 36),
                            // 🎯 중앙 정답수 캡슐 버튼 배너
                            Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF0F3934), Color(0xFF134E48)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(color: const Color(0xFF2DD4BF), width: 1.8),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF0D9488).withOpacity(0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.check_circle_rounded, color: Color(0xFF2DD4BF), size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      isKo ? '정답수 : ' : 'Correct : ',
                                      style: const TextStyle(
                                        color: Color(0xFFCCFBF1),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Text(
                                      '$_correct / $_targetQuestions',
                                      style: const TextStyle(
                                        color: Color(0xFFFFE66D),
                                        fontWeight: FontWeight.w900,
                                        fontSize: 19,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            // 📜 서바이벌 룰 & 안내 카드
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF141A24),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(color: const Color(0xFF3B4861), width: 1.5),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      const Text('📜', style: TextStyle(fontSize: 18)),
                                      const SizedBox(width: 8),
                                      Text(
                                        isKo ? '3진 아웃 서바이벌 룰 안내' : 'Survival Game Rules',
                                        style: const TextStyle(
                                          color: Color(0xFFFFD700),
                                          fontWeight: FontWeight.w900,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    isKo
                                        ? '• 오답 또는 10초 시간초과 시 생명(❤️) 1개가 차감됩니다. (3회 오답 시 게임 오버)\n• 정답을 빨리 맞힐수록 남은 시간(초) × 10점의 보너스 점수를 획득합니다.\n• 총 10문제를 끝까지 생존 돌파하면 최종 클리어 보상(코인·친밀도·열쇠)을 획득합니다!'
                                        : '• 3 Mistakes (Wrong answer or timeout) = Game Over\n• Fast answers earn bonus points (remaining seconds × 10pt)\n• Survive and clear all 10 questions to win coins & keys!',
                                    style: const TextStyle(
                                      color: Color(0xFFE2E8F0),
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w600,
                                      height: 1.6,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// RandomProvider: 시드 랜덤 제공 (테스트 재현성)
class RandomProvider {
  static final Random random = Random();
}
