import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import 'core/timelab_i18n.dart';
import 'chain_timer/chain_timer_page.dart';
import 'velocity_grid/velocity_grid_page.dart';
import 'tally_clicker/tally_clicker_page.dart';

/// ⏱️ DOK-KEY 시네마틱 타임 랩 허브 (Cinematic Time Lab Hub) - 6개국어 완벽 지원
class TimelabHubPage extends StatelessWidget {
  const TimelabHubPage({super.key});

  static void show(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TimelabHubPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = context.watch<DokkeyProvider>().lang;

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
              TimelabI18n.timeLabTitle(lang),
              style: const TextStyle(
                color: Color(0xFFFFD54F),
                fontWeight: FontWeight.w900,
                fontSize: 19,
                letterSpacing: 0.3,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    offset: Offset(0, 1.5),
                    blurRadius: 4,
                  ),
                ],
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
                      color: DokkeyTheme.gold.withValues(alpha: 0.25),
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
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2.0,
                        shadows: [
                          Shadow(
                            color: Colors.black,
                            offset: Offset(0, 1.5),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      TimelabI18n.hubHeroDesc(lang),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13.0,
                        height: 1.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              Text(
                TimelabI18n.specializedModules(lang),
                style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              // Module 1 Card: The Defuser (3단 시퀀스 체인 타이머)
              _buildModuleCard(
                context,
                title: TimelabI18n.module1Title(lang),
                tag: 'THE DEFUSER',
                icon: '💣',
                accentColor: const Color(0xFFFF0055),
                desc: TimelabI18n.module1Desc(lang),
                badge: TimelabI18n.module1Badge(lang),
                launchLabel: TimelabI18n.launchModule(lang),
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
                title: TimelabI18n.module2Title(lang),
                tag: 'THE VELOCITY GRID',
                icon: '⚡',
                accentColor: const Color(0xFF00E5FF),
                desc: TimelabI18n.module2Desc(lang),
                badge: TimelabI18n.module2Badge(lang),
                launchLabel: TimelabI18n.launchModule(lang),
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
                title: TimelabI18n.module3Title(lang),
                tag: 'THE TACTICAL CLICKER',
                icon: '🔢',
                accentColor: const Color(0xFF00FF66),
                desc: TimelabI18n.module3Desc(lang),
                badge: TimelabI18n.module3Badge(lang),
                launchLabel: TimelabI18n.launchModule(lang),
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
                    Text(
                      TimelabI18n.themesTitle(lang),
                      style: const TextStyle(color: Color(0xFFFFD700), fontWeight: FontWeight.w900, fontSize: 13.5),
                    ),
                    const SizedBox(height: 8),
                    _buildThemeInfoRow('🟢 ${TimelabI18n.themeClassic(lang)}', TimelabI18n.themeClassicDesc(lang)),
                    const SizedBox(height: 6),
                    _buildThemeInfoRow('🔴 ${TimelabI18n.themeCyber(lang)}', TimelabI18n.themeCyberDesc(lang)),
                    const SizedBox(height: 6),
                    _buildThemeInfoRow('🔵 ${TimelabI18n.themeOrbital(lang)}', TimelabI18n.themeOrbitalDesc(lang)),
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
    required String launchLabel,
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
            border: Border.all(color: accentColor.withValues(alpha: 0.6), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: accentColor.withValues(alpha: 0.18),
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
                  Expanded(
                    child: Row(
                      children: [
                        Text(icon, style: const TextStyle(fontSize: 24)),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                              ),
                              Text(
                                tag,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 10.5, letterSpacing: 0.5),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                      ),
                      child: Text(
                        badge,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: accentColor, fontSize: 10, fontWeight: FontWeight.bold),
                      ),
                    ),
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
                    Text(launchLabel, style: TextStyle(color: accentColor, fontWeight: FontWeight.bold, fontSize: 12.5)),
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
