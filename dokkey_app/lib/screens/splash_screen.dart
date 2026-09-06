import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/brand_config.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';
import '../widgets/dokkaebi_fire_particles.dart';
import '../widgets/kkaebi_face_widget.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _scaleAnim = Tween<double>(begin: 0.88, end: 1.02).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _fadeAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.1, 0.8, curve: Curves.easeIn)),
    );

    _controller.forward();

    // Navigate to Home after fast snappy intro (1.3s)
    Future.delayed(const Duration(milliseconds: 1300), () {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (_, __, ___) => const HomeScreen(),
          transitionsBuilder: (_, anim, __, child) => FadeTransition(opacity: anim, child: child),
          transitionDuration: const Duration(milliseconds: 400),
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();

    // v4.7.0 Wisdom-First: 브랜드 슬로건은 brand_slogans.json 단일 소스에서 로드
    final mainSlogan = BrandConfig.mainSlogan(provider.lang);
    final subSlogan = BrandConfig.subSlogan(provider.lang);

    return Scaffold(
      backgroundColor: DokkeyTheme.bgDark,
      body: Stack(
        children: [
          DokkaebiFireParticles(
            baseColor: DokkeyTheme.gold,
            child: SizedBox.expand(),
          ),
          Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return FadeTransition(
                  opacity: _fadeAnim,
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        KkaebiFaceWidget(
                          size: 140,
                          mode: KkaebiFaceMode.greeting,
                          enableGlow: true,
                          glowColor: DokkeyTheme.gold,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          'DOK-KEY',
                          style: TextStyle(
                            color: DokkeyTheme.goldLight,
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 6.0,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          mainSlogan,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DokkeyTheme.goldLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.6,
                            height: 1.5,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          subSlogan,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: DokkeyTheme.textMuted,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(height: 18),

                        // Zero-Delay 맥락 인사 (시간대 × 방문이력)
                        if (provider.greeting.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 32),
                            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                            constraints: const BoxConstraints(maxWidth: 420),
                            decoration: BoxDecoration(
                              color: DokkeyTheme.cardDark.withOpacity(0.85),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(color: DokkeyTheme.gold.withOpacity(0.35)),
                            ),
                            child: Text(
                              provider.greeting,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: DokkeyTheme.goldLight,
                                fontSize: 12.5,
                                height: 1.5,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
