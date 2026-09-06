import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/brand_config.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import 'debug_inspector_dialog.dart';
import 'profile_onboarding_sheet.dart';
import 'seasonal_ambient_background.dart';

class SettingsDialog extends StatefulWidget {
  const SettingsDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const SettingsDialog(),
    );
  }

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  int _versionTapCount = 0;
  DateTime _lastVersionTap = DateTime.now();

  void _onVersionTapped() {
    final now = DateTime.now();
    if (now.difference(_lastVersionTap).inSeconds > 3) {
      _versionTapCount = 0;
    }
    _lastVersionTap = now;
    _versionTapCount++;
    HapticFeedback.selectionClick();

    if (_versionTapCount >= 5) {
      _versionTapCount = 0;
      Navigator.of(context).pop();
      DebugInspectorDialog.show(context);
    } else if (_versionTapCount >= 2) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('🔑 ${5 - _versionTapCount}번 더 탭하면 인스펙터가 열립니다...'),
          backgroundColor: DokkeyTheme.surfaceDark,
          duration: const Duration(milliseconds: 800),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final soundService = SoundService();

    final timeStr = '${provider.notifyHour.toString().padLeft(2, '0')}:${provider.notifyMinute.toString().padLeft(2, '0')}';
    final slotName = provider.todayResult?.timeslot.name ?? '';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.borderDark, width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.settings_outlined, color: DokkeyTheme.gold, size: 22),
                  const SizedBox(width: 8),
                  Text(
                    isKo ? '환경 설정' : (isJa ? '設定' : 'Settings'),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: DokkeyTheme.goldLight,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Language Selector (6 Languages)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.language_rounded, color: DokkeyTheme.gold),
                title: Text(
                  isKo ? '언어 선택 (Language)' : (isJa ? '言語設定' : (provider.lang == 'de' ? 'Sprache' : 'Language')),
                  style: TextStyle(color: DokkeyTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  'KO · EN · JA · ZH · HI · DE (6개국어 지원)',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _LangChip(code: 'ko', label: '한국어', flag: '🇰🇷', selected: provider.lang == 'ko', onTap: () => provider.setLanguage('ko')),
                    const SizedBox(width: 6),
                    _LangChip(code: 'en', label: 'English', flag: '🇺🇸', selected: provider.lang == 'en', onTap: () => provider.setLanguage('en')),
                    const SizedBox(width: 6),
                    _LangChip(code: 'ja', label: '日本語', flag: '🇯🇵', selected: provider.lang == 'ja', onTap: () => provider.setLanguage('ja')),
                    const SizedBox(width: 6),
                    _LangChip(code: 'zh', label: '中文', flag: '🇨🇳', selected: provider.lang == 'zh', onTap: () => provider.setLanguage('zh')),
                    const SizedBox(width: 6),
                    _LangChip(code: 'hi', label: 'हिन्दी', flag: '🇮🇳', selected: provider.lang == 'hi', onTap: () => provider.setLanguage('hi')),
                    const SizedBox(width: 6),
                    _LangChip(code: 'de', label: 'Deutsch', flag: '🇩🇪', selected: provider.lang == 'de', onTap: () => provider.setLanguage('de')),
                  ],
                ),
              ),
              Divider(color: DokkeyTheme.borderDark),
              // Profile (옵션 입력 키)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.badge_outlined, color: DokkeyTheme.gold),
                title: Row(
                  children: [
                    Text(
                      isKo ? '내 프로필 관리' : (isJa ? 'マイプロフィール管理' : 'My Profile'),
                      style: TextStyle(color: DokkeyTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: DokkeyTheme.gold.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: DokkeyTheme.gold.withOpacity(0.4), width: 0.8),
                      ),
                      child: Text(
                        isKo ? '수정' : (isJa ? '変更' : 'Edit'),
                        style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 9.5, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                subtitle: Text(
                  provider.hasProfile
                      ? '${isKo ? "닉네임" : (isJa ? "ニックネーム" : "Nickname")}: ${provider.context.displayNickname} · ${provider.context.ageGroup == "anon" ? (isKo ? "연령 미설정" : "Age unset") : provider.context.ageGroup} · ${provider.context.gender == "anon" ? (isKo ? "성별 미설정" : "Gender unset") : (provider.context.gender == "m" ? (isKo ? "남성" : "Male") : (provider.context.gender == "f" ? (isKo ? "여성" : "Female") : "기타"))}'
                      : (isKo ? '닉네임, 연령대, 성별을 등록해보세요 (선택)' : 'Set your nickname, age, gender (optional)'),
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
                trailing: Icon(Icons.edit_outlined, color: DokkeyTheme.gold, size: 18),
                onTap: () {
                  Navigator.of(context).pop();
                  showDialog(
                    context: context,
                    builder: (_) => const ProfileOnboardingSheet(),
                  );
                },
              ),

              Divider(color: DokkeyTheme.borderDark),

              // Theme / Brightness key (조도 키)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  provider.isLightTheme ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                  color: DokkeyTheme.gold,
                ),
                title: Text(
                  isKo ? '테마 (조도 감지)' : (isJa ? 'テーマ (明るさ検知)' : 'Theme (brightness)'),
                  style: TextStyle(color: DokkeyTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  isKo
                      ? '기기 설정을 자동 감지하며 수동 변경도 가능합니다'
                      : 'Auto-detected from your device, manual override available',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ThemeChip(
                    label: isKo ? '자동' : (isJa ? '自動' : 'Auto'),
                    icon: Icons.brightness_auto_rounded,
                    selected: provider.themeOverride == 'auto',
                    onTap: () => provider.setThemeOverride('auto'),
                  ),
                  _ThemeChip(
                    label: isKo ? '다크' : (isJa ? 'ダーク' : 'Dark'),
                    icon: Icons.dark_mode_rounded,
                    selected: provider.themeOverride == 'dark',
                    onTap: () => provider.setThemeOverride('dark'),
                  ),
                  _ThemeChip(
                    label: isKo ? '라이트' : (isJa ? 'ライト' : 'Light'),
                    icon: Icons.light_mode_rounded,
                    selected: provider.themeOverride == 'light',
                    onTap: () => provider.setThemeOverride('light'),
                  ),
                ],
              ),

              Divider(color: DokkeyTheme.borderDark),

              // Seasonal & Ambient Particles (사계절 & 시간 연동 비주얼 효과)
              SwitchListTile(
                value: provider.particlesEnabled,
                onChanged: (val) {
                  provider.setParticlesEnabled(val);
                },
                title: Text(
                  isKo ? '사계절 & 시간 앰비언트 효과' : (isJa ? '四季・時間連動エフェクト' : 'Seasonal & Time Ambience'),
                  style: TextStyle(color: DokkeyTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  isKo
                      ? '계절(벚꽃·반딧불·단풍·눈꽃)과 시간대별 은은한 배경 효과'
                      : (isJa ? '四季の花びら・ホタル・紅葉・雪と時間の光' : 'Petals, fireflies, maple leaves, snow & time glow'),
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
                activeColor: DokkeyTheme.gold,
                contentPadding: EdgeInsets.zero,
              ),

              if (provider.particlesEnabled) ...[
                const SizedBox(height: 6),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _ThemeChip(
                        label: isKo ? '자동 감지' : (isJa ? '自動' : 'Auto'),
                        icon: Icons.auto_awesome_rounded,
                        selected: provider.seasonOverride == 'auto',
                        onTap: () => provider.setSeasonOverride('auto'),
                      ),
                      const SizedBox(width: 6),
                      _ThemeChip(
                        label: isKo ? '봄 🌸' : (isJa ? '春 🌸' : 'Spring 🌸'),
                        icon: Icons.local_florist_rounded,
                        selected: provider.seasonOverride == 'spring',
                        onTap: () => provider.setSeasonOverride('spring'),
                      ),
                      const SizedBox(width: 6),
                      _ThemeChip(
                        label: isKo ? '여름 🌿' : (isJa ? '夏 🌿' : 'Summer 🌿'),
                        icon: Icons.eco_rounded,
                        selected: provider.seasonOverride == 'summer',
                        onTap: () => provider.setSeasonOverride('summer'),
                      ),
                      const SizedBox(width: 6),
                      _ThemeChip(
                        label: isKo ? '가을 🍁' : (isJa ? '秋 🍁' : 'Autumn 🍁'),
                        icon: Icons.park_rounded,
                        selected: provider.seasonOverride == 'autumn',
                        onTap: () => provider.setSeasonOverride('autumn'),
                      ),
                      const SizedBox(width: 6),
                      _ThemeChip(
                        label: isKo ? '겨울 ❄️' : (isJa ? '冬 ❄️' : 'Winter ❄️'),
                        icon: Icons.ac_unit_rounded,
                        selected: provider.seasonOverride == 'winter',
                        onTap: () => provider.setSeasonOverride('winter'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: DokkeyTheme.surfaceDark.withValues(alpha: 0.6),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: DokkeyTheme.borderDark.withValues(alpha: 0.6), width: 0.8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.palette_outlined, color: DokkeyTheme.gold, size: 13),
                      const SizedBox(width: 6),
                      Text(
                        isKo
                            ? '현재 연출: ${provider.effectiveSeason == AppSeason.spring ? "봄 (🌸 벚꽃잎)" : (provider.effectiveSeason == AppSeason.summer ? "여름 (🌿 반딧불이)" : (provider.effectiveSeason == AppSeason.autumn ? "가을 (🍁 단풍잎)" : "겨울 (❄️ 눈송이)"))} · ${provider.effectiveTimeOfDay == AppTimeOfDay.dawn ? "새벽 (🌅 청벽안개)" : (provider.effectiveTimeOfDay == AppTimeOfDay.day ? "낮 (☀️ 황금햇살)" : (provider.effectiveTimeOfDay == AppTimeOfDay.dusk ? "노을 (🌆 황혼도깨비불)" : "밤 (🌙 심야별빛)"))}'
                            : 'Active: ${provider.effectiveSeason.name.toUpperCase()} · ${provider.effectiveTimeOfDay.name.toUpperCase()}',
                        style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ],

              Divider(color: DokkeyTheme.borderDark),

              // Notification Switch
              SwitchListTile(
                value: provider.notifyEnabled,
                onChanged: (val) {
                  provider.updateNotificationSettings(val, provider.notifyHour, provider.notifyMinute);
                },
                title: Text(
                  isKo ? '모닝 데일리 알림' : (isJa ? '毎朝の通知' : 'Morning Notification'),
                  style: TextStyle(color: DokkeyTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  isKo ? '매일 아침 하루를 여는 열쇠 도착 알림' : 'Daily reminder to unlock your day',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
                activeColor: DokkeyTheme.gold,
                contentPadding: EdgeInsets.zero,
              ),

              if (provider.notifyEnabled) ...[
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(
                    isKo ? '알림 시간' : (isJa ? '通知時刻' : 'Notification Time'),
                    style: TextStyle(color: DokkeyTheme.textMain, fontSize: 14),
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: DokkeyTheme.surfaceDark,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: DokkeyTheme.gold.withOpacity(0.5)),
                    ),
                    child: Text(
                      timeStr,
                      style: TextStyle(color: DokkeyTheme.gold, fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: TimeOfDay(hour: provider.notifyHour, minute: provider.notifyMinute),
                    );
                    if (picked != null) {
                      provider.updateNotificationSettings(true, picked.hour, picked.minute);
                    }
                  },
                ),
              ],

              Divider(color: DokkeyTheme.borderDark),

              // Sound Toggle (영속화됨)
              SwitchListTile(
                value: soundService.soundEnabled,
                onChanged: (val) {
                  setState(() {
                    soundService.toggleSound();
                  });
                },
                title: Text(
                  isKo ? '효과음 및 사운드스케이프' : (isJa ? '効果音とサウンド' : 'Sound Effects'),
                  style: TextStyle(color: DokkeyTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: Text(
                  isKo ? '열쇠 회전, 카드 플립, 풍경 방울, 앰비언스' : 'Key clicks, flips, chimes & ambience',
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
                activeColor: DokkeyTheme.gold,
                contentPadding: EdgeInsets.zero,
              ),

              Divider(color: DokkeyTheme.borderDark),

              // Official Instagram Channel
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF833AB4), Color(0xFFFD1D1D), Color(0xFFFCAF45)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.camera_alt_outlined, color: Colors.white, size: 16),
                ),
                title: Text(
                  isKo ? '깨비 공식 인스타그램' : (isJa ? '公式インスタグラム' : 'Official Instagram'),
                  style: TextStyle(color: DokkeyTheme.textMain, fontWeight: FontWeight.bold, fontSize: 14),
                ),
                subtitle: const Text(
                  '@kkaebi_ttook_ttak',
                  style: TextStyle(color: Color(0xFFE5A93C), fontSize: 11, fontWeight: FontWeight.w600),
                ),
                trailing: Icon(Icons.open_in_new_rounded, color: DokkeyTheme.gold, size: 18),
                onTap: () async {
                  final uri = Uri.parse('https://www.instagram.com/kkaebi_ttook_ttak/');
                  try {
                    await launchUrl(uri, mode: LaunchMode.externalApplication);
                  } catch (_) {
                    await launchUrl(uri, mode: LaunchMode.platformDefault);
                  }
                },
              ),

              Divider(color: DokkeyTheme.borderDark),
              const SizedBox(height: 4),

              // Context Info (Zero-Delay 감지 현황)
              Text(
                isKo
                    ? '지금 깨비가 감지한 맥락: ${provider.context.slotId.name.toUpperCase()}${slotName.isNotEmpty ? ' ($slotName)' : ''} · ${provider.context.online ? '온라인' : '오프라인'} · 방문 ${provider.context.visitCount}회'
                    : (isJa
                        ? '現在のコンテキスト: ${provider.context.slotId.name.toUpperCase()} · ${provider.context.online ? "オンライン" : "オフライン"}'
                        : 'Context: ${provider.context.slotId.name.toUpperCase()} · ${provider.context.online ? "Online" : "Offline"} · ${provider.context.visitCount} visits'),
                textAlign: TextAlign.center,
                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
              ),
              const SizedBox(height: 8),

              // Version Info (5회 연속 탭 → 히든 콘텐츠 인스펙터)
              GestureDetector(
                onTap: _onVersionTapped,
                child: Center(
                  child: Column(
                    children: [
                      Text(
                        'DOK-KEY v1.0.0 • Zero-Login Architecture',
                        style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                      ),
                      SizedBox(height: 4),
                      Text(
                        BrandConfig.mainSlogan(provider.lang),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: DokkeyTheme.goldLight,
                          fontSize: 10.5,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Close
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(isKo ? '닫기' : 'Close', style: TextStyle(color: DokkeyTheme.gold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ThemeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _ThemeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? DokkeyTheme.gold.withOpacity(0.2) : DokkeyTheme.surfaceDark,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? DokkeyTheme.gold : DokkeyTheme.borderDark),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 15, color: selected ? DokkeyTheme.gold : DokkeyTheme.textMuted),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: selected ? DokkeyTheme.goldLight : DokkeyTheme.textMuted,
                fontSize: 12,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LangChip extends StatelessWidget {
  final String code;
  final String label;
  final String flag;
  final bool selected;
  final VoidCallback onTap;

  const _LangChip({
    required this.code,
    required this.label,
    required this.flag,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? DokkeyTheme.gold.withOpacity(0.25) : DokkeyTheme.surfaceDark,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? DokkeyTheme.gold : DokkeyTheme.borderDark,
            width: selected ? 1.5 : 1.0,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(flag, style: const TextStyle(fontSize: 13)),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: selected ? DokkeyTheme.goldLight : DokkeyTheme.textMuted,
                fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
