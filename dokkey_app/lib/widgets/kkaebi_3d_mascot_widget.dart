import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import 'screen_emotion_fx_overlay.dart';
import 'kkaebi_easter_egg_dialog.dart';

/// 3D 도깨비 마스코트 인터랙티브 뷰어
/// - 상하 카메라 완전 고정 (수평 좌/우/앞/뒤 360° 턴테이블 회전)
/// - 8대 감정 표출 + 풀스크린 액션 트리거
/// - 레이아웃 말풍선 클리핑 방지 처리
class Kkaebi3DMascotWidget extends StatefulWidget {
  final double size;
  final EmotionType? initialEmotion;
  final bool enableInteraction;
  final bool enableAutoFloat;
  final bool showSpeechBubble;
  final String? customSpeech;
  final Function(EmotionType)? onEmotionTriggered;
  final VoidCallback? onTap;

  const Kkaebi3DMascotWidget({
    super.key,
    this.size = 200,
    this.initialEmotion,
    this.enableInteraction = true,
    this.enableAutoFloat = true,
    this.showSpeechBubble = false,
    this.customSpeech,
    this.onEmotionTriggered,
    this.onTap,
  });

  @override
  State<Kkaebi3DMascotWidget> createState() => Kkaebi3DMascotWidgetState();
}

class Kkaebi3DMascotWidgetState extends State<Kkaebi3DMascotWidget>
    with TickerProviderStateMixin {
  // 수평 회전 각도 (0 ~ 2*pi, 상하는 완전 고정)
  double _yaw = 0.0;
  double _dragStartX = 0.0;
  double _yawOnDragStart = 0.0;

  // 감정 모드
  EmotionType _currentEmotion = EmotionType.normal;
  Timer? _emotionResetTimer;

  // 콤보 탭 (광클 폭주 & 12타 이스터에그 트리거용)
  int _tapComboCount = 0;
  Timer? _comboResetTimer;

  // 호흡 및 3D 플로팅 애니메이션
  late AnimationController _idleCtrl;
  late Animation<double> _floatAnim;
  late Animation<double> _shadowScaleAnim;

  // 스프링 복귀 애니메이션
  AnimationController? _springCtrl;
  Animation<double>? _springYawAnim;

  // 말풍선 상태
  String? _speechText;
  bool _isSpeechVisible = false;
  Timer? _speechTimer;

  // 8방향 턴테이블 WebP 경로 매핑 (0° ~ 315°)
  static const List<String> _turnTableAssets = [
    'assets/images/kkaebi_3d/kkaebi_turn_000.webp', // 0도 (정면)
    'assets/images/kkaebi_3d/kkaebi_turn_045.webp', // 45도 (우측 전방)
    'assets/images/kkaebi_3d/kkaebi_turn_090.webp', // 90도 (우측면)
    'assets/images/kkaebi_3d/kkaebi_turn_135.webp', // 135도 (우측 후방)
    'assets/images/kkaebi_3d/kkaebi_turn_180.webp', // 180도 (후면)
    'assets/images/kkaebi_3d/kkaebi_turn_225.webp', // 225도 (좌측 후방)
    'assets/images/kkaebi_3d/kkaebi_turn_270.webp', // 270도 (좌측면)
    'assets/images/kkaebi_3d/kkaebi_turn_315.webp', // 315도 (좌측 전방)
  ];

  // 8대 감정 WebP 경로 매핑
  static const Map<EmotionType, String> _emotionAssets = {
    EmotionType.normal: 'assets/images/kkaebi_3d/kkaebi_emo_normal.webp',
    EmotionType.joy: 'assets/images/kkaebi_3d/kkaebi_emo_joy.webp',
    EmotionType.shy: 'assets/images/kkaebi_3d/kkaebi_emo_shy.webp',
    EmotionType.sad: 'assets/images/kkaebi_3d/kkaebi_emo_sad.webp',
    EmotionType.fire: 'assets/images/kkaebi_3d/kkaebi_emo_fire.webp',
    EmotionType.rage: 'assets/images/kkaebi_3d/kkaebi_emo_rage.webp',
    EmotionType.curious: 'assets/images/kkaebi_3d/kkaebi_emo_curious.webp',
    EmotionType.shock: 'assets/images/kkaebi_3d/kkaebi_emo_shock.webp',
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialEmotion != null) {
      _currentEmotion = widget.initialEmotion!;
    }
    _speechText = widget.customSpeech;
    _isSpeechVisible = widget.showSpeechBubble;

    _idleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    if (widget.enableAutoFloat) {
      _idleCtrl.repeat(reverse: true);
    }

    _floatAnim = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOutSine),
    );

    _shadowScaleAnim = Tween<double>(begin: 1.0, end: 0.85).animate(
      CurvedAnimation(parent: _idleCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void didUpdateWidget(covariant Kkaebi3DMascotWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialEmotion != null && widget.initialEmotion != oldWidget.initialEmotion) {
      triggerEmotion(widget.initialEmotion!);
    }
    if (widget.customSpeech != null) {
      _speechText = widget.customSpeech;
    }
  }

  @override
  void dispose() {
    _idleCtrl.dispose();
    _springCtrl?.dispose();
    _emotionResetTimer?.cancel();
    _comboResetTimer?.cancel();
    _speechTimer?.cancel();
    super.dispose();
  }

  /// 외부에서 특정 감정 연출을 즉시 작동시키는 함수
  void triggerEmotion(EmotionType emotion, {bool triggerScreenFx = false, String? message}) {
    setState(() {
      _currentEmotion = emotion;
      if (message != null) {
        _speechText = message;
        _isSpeechVisible = true;
      }
    });

    widget.onEmotionTriggered?.call(emotion);

    if (triggerScreenFx) {
      ScreenEmotionFxOverlay.show(context, emotion);
    }

    _emotionResetTimer?.cancel();
    _emotionResetTimer = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) {
        setState(() {
          _currentEmotion = EmotionType.normal;
        });
      }
    });

    if (message != null) {
      _speechTimer?.cancel();
      _speechTimer = Timer(const Duration(milliseconds: 3500), () {
        if (mounted) {
          setState(() {
            _isSpeechVisible = false;
          });
        }
      });
    }
  }

  /// 💥 12연타 사다리 번호 소환 메시지 (6개국어)
  static String _ladderSummonText(String lang) {
    switch (lang) {
      case 'ja':
        return '💥 魔棒召喚！運命のあみだくじ番号オープン~! ✨';
      case 'zh':
        return '💥 妖棒召唤！幸运梯子号码开启~! ✨';
      case 'hi':
        return '💥 जादुई छड़ी आह्वान! भाग्यशाली लैडर नंबर खुला~! ✨';
      case 'de':
        return '💥 Zauberkeule beschworen! Glücks-Leiterzahl offen~! ✨';
      case 'en':
        return '💥 Magic bat summoned! Lucky ladder number open~! ✨';
      default:
        return '💥 도깨비 방망이 소환! 행운의 사다리 번호 오픈~! ✨';
    }
  }

  /// 사용자의 탭/터치 인터랙션 (12타 이스터에그 포함)
  void _onTapMascot() {
    HapticFeedback.lightImpact();
    SoundService().playSuccessChime();

    _tapComboCount++;
    _comboResetTimer?.cancel();
    _comboResetTimer = Timer(const Duration(milliseconds: 3200), () {
      _tapComboCount = 0;
    });

    // 💥 12회 탭: 히든 이스터에그 발동 (1시간 고정 사다리 숫자 게임 모달 오픈!)
    if (_tapComboCount >= 12) {
      _tapComboCount = 0;
      SoundService().playAlchemyFanfare();
      HapticFeedback.heavyImpact();
      triggerEmotion(
        EmotionType.joy,
        triggerScreenFx: false,
        message: _ladderSummonText(context.read<DokkeyProvider>().lang),
      );
      KkaebiEasterEggDialog.show(context);
      widget.onTap?.call();
      return;
    }

    // ⚡ 11회 탭: 최종 이스터에그 소환 직전 예고 연출
    if (_tapComboCount == 11) {
      HapticFeedback.mediumImpact();
      triggerEmotion(
        EmotionType.shock,
        triggerScreenFx: false,
        message: '어라...? 방망이에서 신비한 숫자의 빛이 뿜어져 나온다...?! ✨',
      );
      widget.onTap?.call();
      return;
    }

    // ⚡ 10회 탭: 2차 폭주 (2회전 지진/화면 깨짐 FX)
    if (_tapComboCount == 10) {
      HapticFeedback.heavyImpact();
      triggerEmotion(
        EmotionType.rage,
        triggerScreenFx: true,
        message: '우와아앗! 도깨비 대폭주 2단계!! ⚡💥🔥',
      );
      widget.onTap?.call();
      return;
    }

    // 7~9회 탭: 호기심 및 도깨비불 점화
    if (_tapComboCount == 7) {
      triggerEmotion(
        EmotionType.curious,
        message: '또 찌르는 거야?! 방망이가 들썩거리는데...?! 🌀',
      );
      widget.onTap?.call();
      return;
    }
    if (_tapComboCount == 8) {
      triggerEmotion(
        EmotionType.fire,
        message: '도깨비불이 활활 타오른다! 🔥✨',
      );
      widget.onTap?.call();
      return;
    }
    if (_tapComboCount == 9) {
      triggerEmotion(
        EmotionType.shy,
        message: '간지럽다고 했잖아~! 헤헤 💖',
      );
      widget.onTap?.call();
      return;
    }

    // ⚡ 5회 탭: 1차 폭주 (1회전 지진/화면 깨짐 FX)
    if (_tapComboCount == 5) {
      HapticFeedback.mediumImpact();
      triggerEmotion(
        EmotionType.rage,
        triggerScreenFx: true,
        message: '으아앗! 날 그만 찔러! 도깨비 폭주 1단계다~! ⚡💥',
      );
      widget.onTap?.call();
      return;
    }

    // 3회 탭: 도깨비불 각성
    if (_tapComboCount == 3) {
      triggerEmotion(
        EmotionType.fire,
        triggerScreenFx: false,
        message: '도깨비불이 솟아오른다! 🔥✨',
      );
      widget.onTap?.call();
      return;
    }

    // 일반 1, 2, 4, 6회 탭
    final randomMessages = [
      '안녕! 오늘도 좋은 기운이 가득해! ✨',
      '날 돌려보거나 만져봐도 돼! 🌀',
      '금 나와라 뚝딱~! 💰',
      '무엇이 궁금하니? 🔮',
      '헤헤, 간지러워~! 💖',
    ];
    final randomMsg = randomMessages[math.Random().nextInt(randomMessages.length)];
    triggerEmotion(EmotionType.joy, message: randomMsg);

    widget.onTap?.call();
  }

  void _onPanStart(DragStartDetails details) {
    if (!widget.enableInteraction) return;
    _dragStartX = details.localPosition.dx;
    _yawOnDragStart = _yaw;
    _springCtrl?.stop();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!widget.enableInteraction) return;
    final dx = details.localPosition.dx - _dragStartX;

    setState(() {
      // 상하는 완전 고정, 좌우 드래그로만 360도 수평 회전
      _yaw = (_yawOnDragStart + (dx * 0.015)) % (math.pi * 2);
      if (_yaw < 0) _yaw += math.pi * 2;
    });
  }

  void _onPanEnd(DragEndDetails details) {
    if (!widget.enableInteraction) return;

    // 드래그 속도가 빠르면 회전 관성 및 Joy 감정 유발
    final velocityX = details.velocity.pixelsPerSecond.dx;
    if (velocityX.abs() > 800) {
      triggerEmotion(EmotionType.joy, message: '우와아~! 핑글핑글 신난다! 🌀🎉');
    }

    // 드래그 종료 시 부드럽게 정면 각도로 스냅 복귀
    _springCtrl?.dispose();
    _springCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final currentYaw = _yaw;
    double targetYaw = 0.0;
    if (currentYaw > math.pi) {
      targetYaw = math.pi * 2;
    }

    _springYawAnim = Tween<double>(begin: currentYaw, end: targetYaw).animate(
      CurvedAnimation(parent: _springCtrl!, curve: Curves.easeOutBack),
    )..addListener(() {
        setState(() {
          _yaw = (_springYawAnim!.value) % (math.pi * 2);
        });
      });

    _springCtrl!.forward();
  }

  /// 현재 각도(0~2*pi)에 해당하는 8방향 에셋 인덱스 계산 (0~7)
  int _getTurnIndex(double angle) {
    final step = (math.pi * 2) / 8; // 45도 = pi/4
    final normalized = (angle + (step / 2)) % (math.pi * 2);
    final idx = (normalized / step).floor() % 8;
    return idx;
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;
    final turnIdx = _getTurnIndex(_yaw);

    // 표시할 이미지 에셋 결정 (감정이 Normal이 아니면 감정 에셋 우선, 아니면 8방향 턴테이블 회전)
    String currentAsset;
    if (_currentEmotion != EmotionType.normal) {
      currentAsset = _emotionAssets[_currentEmotion] ?? _turnTableAssets[0];
    } else {
      currentAsset = _turnTableAssets[turnIdx];
    }

    return GestureDetector(
      onTap: _onTapMascot,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 1. 말풍선 (표시 옵션이 켜져 있고 텍스트가 있을 때 상단에 자연스럽게 배치되어 잘림 방지)
          if (widget.showSpeechBubble && _isSpeechVisible && _speechText != null && _speechText!.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: AnimatedOpacity(
                opacity: _isSpeechVisible ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: Container(
                  constraints: BoxConstraints(maxWidth: size * 1.5),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark.withValues(alpha: 0.95),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _currentEmotion == EmotionType.rage
                          ? const Color(0xFFFF5252)
                          : DokkeyTheme.gold,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.45),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Text(
                    _speechText!,
                    style: TextStyle(
                      color: DokkeyTheme.goldLight,
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
            ),

          // 2. 3D 턴테이블 캐릭터 & 바닥 그림자 스택
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                // 바닥 3D 그림자
                Positioned(
                  bottom: 0,
                  child: AnimatedBuilder(
                    animation: _idleCtrl,
                    builder: (context, child) {
                      final scale = widget.enableAutoFloat ? _shadowScaleAnim.value : 1.0;
                      return Transform.scale(
                        scale: scale,
                        child: Container(
                          width: size * 0.65,
                          height: size * 0.14,
                          decoration: BoxDecoration(
                            shape: BoxShape.rectangle,
                            borderRadius: BorderRadius.all(Radius.elliptical(size * 0.32, size * 0.07)),
                            gradient: RadialGradient(
                              colors: [
                                (_currentEmotion == EmotionType.fire
                                        ? const Color(0xFF00E5FF)
                                        : (_currentEmotion == EmotionType.rage
                                            ? const Color(0xFFFF1744)
                                            : DokkeyTheme.gold))
                                    .withValues(alpha: 0.35),
                                Colors.black.withValues(alpha: 0.5),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // 3D 캐릭터 본체 (상하 X축 틸트 없이 완벽한 Y축 수평 턴테이블)
                AnimatedBuilder(
                  animation: _idleCtrl,
                  builder: (context, child) {
                    final floatY = widget.enableAutoFloat ? _floatAnim.value : 0.0;

                    // Matrix4: 상하 틸트(rotateX) 제거, Y축 수평 회전만 부드럽게 적용
                    final matrix = Matrix4.identity()
                      ..setEntry(3, 2, 0.0010)
                      ..rotateY((_yaw % (math.pi / 4)) - (math.pi / 8))
                      ..scale(1.0 + (_currentEmotion == EmotionType.rage ? 0.06 : 0.0));

                    return Transform.translate(
                      offset: Offset(0, floatY),
                      child: Transform(
                        transform: matrix,
                        alignment: Alignment.center,
                        child: Container(
                          width: size,
                          height: size,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              if (_currentEmotion == EmotionType.fire)
                                BoxShadow(
                                  color: const Color(0xFF00E5FF).withValues(alpha: 0.5),
                                  blurRadius: 24,
                                  spreadRadius: 4,
                                )
                              else if (_currentEmotion == EmotionType.rage)
                                BoxShadow(
                                  color: const Color(0xFFFF1744).withValues(alpha: 0.6),
                                  blurRadius: 28,
                                  spreadRadius: 6,
                                )
                              else if (_currentEmotion == EmotionType.joy)
                                BoxShadow(
                                  color: DokkeyTheme.gold.withValues(alpha: 0.45),
                                  blurRadius: 20,
                                  spreadRadius: 2,
                                ),
                            ],
                          ),
                          child: Image.asset(
                            currentAsset,
                            fit: BoxFit.contain,
                            filterQuality: FilterQuality.medium,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
