import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import 'chain_timer/chain_timer_page.dart';
import 'velocity_grid/velocity_grid_page.dart';
import 'tally_clicker/tally_clicker_page.dart';

/// ⏱️ DOK-KEY 시네마틱 타임 랩 허브 (Cinematic Time Lab Hub)
class TimelabHubPage extends StatelessWidget {
  const TimelabHubPage({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TimelabHubPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0C10),
      appBar: AppBar(
        backgroundColor: const Color(0xFF141822),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⏱️', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 8),
            Text(
              '시네마틱 타임 랩',
              style: TextStyle(
                color: DokkeyTheme.goldLight,
                fontWeight: FontWeight.w900,
                fontSize: 17,
              ),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero Banner
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF261909), Color(0xFF141E30)],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: DokkeyTheme.gold, width: 1.8),
                  boxShadow: [
                    BoxShadow(
                      color: DokkeyTheme.gold.withOpacity(0.25),
                      blurRadius: 24,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const Text('⏳', style: TextStyle(fontSize: 36)),
                    const SizedBox(height: 8),
                    const Text(
                      'CINEMATIC TIME LAB',
                      style: TextStyle(
                        fontFamily: 'monospace',
                        color: Color(0xFFFFE66D),
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      '밀리초 단위의 초정밀 디지털 카운트다운과 9-레인 동시 계측 스톱워치.\n3대 시네마틱 테마와 SFX 사운드로 시간의 긴장감을 극대화합니다.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Color(0xFFE2E8F0), fontSize: 12.5, height: 1.5),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              const Text(
                '🔥 타임 랩 전문 모듈',
                style: TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Module 1 Card: The Defuser (3단 시퀀스 체인 타이머)
              _buildModuleCard(
                context,
                title: '3단 시퀀스 체인 타이머',
                tag: 'THE DEFUSER',
                icon: '💣',
                accentColor: const Color(0xFFFF0055),
                desc: '3-Phase 시퀀스 파이프라인 [타이머 ➔ SFX ➔ 지연 대기 ➔ 다음 타이머]와 1~9회 세트 루프 카운트다운.',
                badge: '밀리초 풀스크린 뷰',
                onTap: () {
                  SoundService().playCardFlip();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ChainTimerPage()),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Module 2 Card: The Velocity Grid (9-레인 그리드 스톱워치)
              _buildModuleCard(
                context,
                title: '9-레인 그리드 스톱워치',
                tag: 'THE VELOCITY GRID',
                icon: '⚡',
                accentColor: const Color(0xFF00E5FF),
                desc: '1~9인 가변형 벤토 그리드. 하단 일괄 START/GO 동시 출발 & 주자 터치 즉시 랭킹/랩타임 Freeze & Lock.',
                badge: '원터치 랭킹 계측',
                onTap: () {
                  SoundService().playCardFlip();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const VelocityGridPage()),
                  );
                },
              ),

              const SizedBox(height: 14),

              // Module 3 Card: The Tactical Clicker (택티컬 탭 카운터)
              _buildModuleCard(
                context,
                title: '택티컬 탭 카운터',
                tag: 'THE TACTICAL CLICKER',
                icon: '🔢',
                accentColor: const Color(0xFF00FF66),
                desc: '화면 어디를 두드려도 반응하는 풀스크린 네온 계수기. 0~99,999 카운트, 목표치(TARGET) 설정 & 10·100단위 마일스톤 피드백.',
                badge: '초직관 탭 계수기',
                onTap: () {
                  SoundService().playCardFlip();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const TallyClickerPage()),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Theme Presets Info
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF141923),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: const Color(0xFF2A364F)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('🎨 탑재된 3대 테마 프리셋', style: TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 13.5)),
                    const SizedBox(height: 8),
                    _buildThemeInfoRow('🟢 클래식 디지털', '매트 카본 텍스처 · 7-세그먼트 그린 LCD · 릴레이 틱 SFX'),
                    const SizedBox(height: 6),
                    _buildThemeInfoRow('🔴 사이버 디퓨저', '다크 HUD 글래스 · 네온 레드 글리치 · 심장박동음 & 폭발 쉐이크'),
                    const SizedBox(height: 6),
                    _buildThemeInfoRow('🔵 우주 발사', '딥 스페이스 궤도선 · 사이언 블루 · 10초 전 플래시 & 부스터 럼블'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildThemeInfoRow(String title, String desc) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(desc, style: const TextStyle(color: Color(0xFF94A3B8), fontSize: 11.5, height: 1.3)),
        ),
      ],
    );
  }

  Widget _buildModuleCard(
    BuildContext context, {
    required String title,
    required String tag,
    required String icon,
    required Color accentColor,
    required String desc,
    required String badge,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: const Color(0xFF141923),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: accentColor.withOpacity(0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withOpacity(0.18),
                blurRadius: 16,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 24)),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                          Text(tag, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10.5, letterSpacing: 0.5)),
                        ],
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: accentColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: accentColor.withOpacity(0.5)),
                    ),
                    child: Text(badge, style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                desc,
                style: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12.5, height: 1.45),
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerRight,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('모듈 가동하기', style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12.5)),
                    const SizedBox(width: 4),
                    Icon(Icons.arrow_forward_rounded, size: 14, color: accentColor),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
