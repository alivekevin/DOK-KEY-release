import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import '../screens/kkaebi_chat_screen.dart';
import 'kkaebi_face_widget.dart';
import 'kkaebi_cinematic_dialog.dart';
import 'profile_onboarding_sheet.dart';
import 'kkaebi_affection_dialog.dart';

/// 초경량 무중단 진입 깨비 플로팅 캐릭터 (FAB)
/// 우하단에서 미소↔윙크하며 살아 숨쉬고, 탭 시 시네마틱 소환 후
/// 프로필 미등록자 -> 프로필 온보딩 모달, 등록자 -> 깨비 대화방(속마음 문답)으로 스마트 분기합니다.
class KkaebiFloatingMascot extends StatefulWidget {
  const KkaebiFloatingMascot({super.key});

  @override
  State<KkaebiFloatingMascot> createState() => _KkaebiFloatingMascotState();
}

class _KkaebiFloatingMascotState extends State<KkaebiFloatingMascot>
    with SingleTickerProviderStateMixin {
  late AnimationController _floatCtrl;
  late Animation<double> _floatAnim;
  bool _tooltipDismissed = false;

  @override
  void initState() {
    super.initState();
    _floatCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: 0.0, end: -8.0).animate(
      CurvedAnimation(parent: _floatCtrl, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _floatCtrl.dispose();
    super.dispose();
  }

  void _onTapMascot(BuildContext context) {
    setState(() => _tooltipDismissed = true);
    final provider = context.read<DokkeyProvider>();
    final hasProfile = provider.hasProfile;

    // 1단계: 미니 시네마틱 소환 애니메이션 실행 ("금 나와라 뚝딱!")
    KkaebiCinematicDialog.show(
      context,
      onComplete: () {
        if (!mounted) return;
        if (!hasProfile) {
          // 2-A: 프로필 미등록 사용자 -> 사주 정보 입력 모달
          showDialog(
            context: context,
            barrierDismissible: true,
            builder: (_) => const ProfileOnboardingSheet(),
          );
        } else {
          // 2-B: 프로필 등록 완료 사용자 -> 깨비 속마음 문답(대화방)으로 바로 안내!
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const KkaebiChatScreen()),
          );
        }
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final hasProfile = provider.hasProfile;
    final profileName = provider.context.displayNickname;

    String tooltipText;
    if (!hasProfile) {
      tooltipText = isKo
          ? '깨비에게 생일을 알려줄래? 🔮'
          : (isJa ? 'クケビに生年月日を教えてね 🔮' : 'Tell Kkaebi your birthday! 🔮');
    } else {
      tooltipText = isKo
          ? (profileName.isNotEmpty ? '$profileName아, 깨비와 이야기할래? 💬' : '깨비에게 속마음을 물어봐! 💬')
          : (isJa ? 'クケビとお話ししよう 💬' : 'Talk with Kkaebi! 💬');
    }

    return AnimatedBuilder(
      animation: _floatAnim,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _floatAnim.value),
          child: child,
        );
      },
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomRight,
        children: [
          // 1. 말풍선 툴팁 (닫지 않았을 때)
          if (!_tooltipDismissed)
            Positioned(
              bottom: 68,
              right: 0,
              child: GestureDetector(
                onTap: () => _onTapMascot(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.cardDark,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: DokkeyTheme.gold.withOpacity(0.6), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        tooltipText,
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontSize: 13.0,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () => setState(() => _tooltipDismissed = true),
                        child: Icon(Icons.close_rounded, size: 13, color: DokkeyTheme.textMuted),
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // 2. 친밀도 레벨 미니 뱃지 (탭하면 친밀도 상세 모달 팝업)
          Positioned(
            top: -12,
            right: 0,
            child: GestureDetector(
              onTap: () {
                KkaebiAffectionDialog.show(context);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      DokkeyTheme.dokFire.withValues(alpha: 0.85),
                      DokkeyTheme.gold.withValues(alpha: 0.95),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 0.8),
                  boxShadow: [
                    BoxShadow(
                      color: DokkeyTheme.gold.withValues(alpha: 0.4),
                      blurRadius: 6,
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('💖', style: TextStyle(fontSize: 8.5)),
                    const SizedBox(width: 3),
                    Text(
                      'Lv.${provider.kkaebiLevel} ${provider.kkaebiTitle}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. 우하단 플로팅 깨비 원형 FAB (도깨비 마스터 달성 시 황금 테두리 해금)
          GestureDetector(
            onTap: () => _onTapMascot(context),
            onLongPress: () => KkaebiAffectionDialog.show(context),
            child: Container(
              padding: provider.codexMasterAchieved ? const EdgeInsets.all(2.5) : EdgeInsets.zero,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: provider.codexMasterAchieved
                    ? const SweepGradient(
                        colors: [
                          Color(0xFFFFE29A),
                          Color(0xFFB8860B),
                          Color(0xFFF5BD42),
                          Color(0xFFFFE29A),
                        ],
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: provider.kkaebiLevel >= 4
                        ? DokkeyTheme.dokFire.withValues(alpha: 0.6)
                        : DokkeyTheme.gold.withOpacity(provider.codexMasterAchieved ? 0.6 : 0.35),
                    blurRadius: provider.kkaebiLevel >= 4 ? 22 : (provider.codexMasterAchieved ? 20 : 14),
                    spreadRadius: provider.kkaebiLevel >= 4 ? 3 : (provider.codexMasterAchieved ? 2 : 1),
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Container(
                width: 58,
                height: 58,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: provider.codexMasterAchieved
                      ? null
                      : RadialGradient(
                          center: Alignment.topLeft,
                          colors: [
                            DokkeyTheme.gold.withOpacity(0.35),
                            DokkeyTheme.cardDark,
                          ],
                        ),
                  color: provider.codexMasterAchieved ? DokkeyTheme.cardDark : null,
                  border: provider.codexMasterAchieved
                      ? null
                      : Border.all(
                          color: provider.kkaebiLevel >= 4 ? DokkeyTheme.dokFire : DokkeyTheme.gold,
                          width: 1.8,
                        ),
                ),
                child: ClipOval(
                  child: Padding(
                    padding: const EdgeInsets.all(2.0),
                    child: KkaebiFaceWidget(
                      size: 52,
                      mode: KkaebiFaceMode.idle,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}