import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/dokkey_provider.dart';

/// 프로필 온보딩 시트 (v3.0.0) — 옵션 입력 키(연령대·성별·닉네임) 1회 유도
/// 건너뛰기가 항상 가능하며, 모든 값은 기기 로컬에만 저장된다.
class ProfileOnboardingSheet extends StatefulWidget {
  const ProfileOnboardingSheet({super.key});

  @override
  State<ProfileOnboardingSheet> createState() => _ProfileOnboardingSheetState();
}

class _ProfileOnboardingSheetState extends State<ProfileOnboardingSheet> {
  final _nicknameCtrl = TextEditingController();
  String _ageGroup = 'anon';
  String _gender = 'anon';

  static const _ageOptions = [
    ('anon', 'auto'), // auto label per lang below
    ('teens', '10대'),
    ('20s', '20대'),
    ('30s', '30대'),
    ('40s', '40대'),
    ('50s+', '50대+'),
  ];

  static const _genderOptions = [
    ('anon', '-'),
    ('m', '남'),
    ('f', '여'),
    ('other', '기타'),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final provider = context.read<DokkeyProvider>();
      setState(() {
        if (provider.context.hasNickname) {
          _nicknameCtrl.text = provider.context.nickname;
        }
        if (provider.context.ageGroup != 'anon') {
          _ageGroup = provider.context.ageGroup;
        }
        if (provider.context.gender != 'anon') {
          _gender = provider.context.gender;
        }
      });
    });
  }

  @override
  void dispose() {
    _nicknameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit({bool skip = false}) async {
    final provider = context.read<DokkeyProvider>();
    if (skip) {
      provider.markOnboardingShown();
      if (Navigator.of(context).canPop()) Navigator.of(context).pop();
      return;
    }
    final nickname = _nicknameCtrl.text.trim();
    if (nickname.length > 12) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('닉네임은 12자 이하로 입력해주세요'), backgroundColor: DokkeyTheme.cardDark),
      );
      return;
    }
    await provider.updateProfile(
      ageGroup: _ageGroup,
      gender: _gender,
      nickname: nickname,
    );
    provider.markOnboardingShown();
    if (mounted && Navigator.of(context).canPop()) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final isKo = provider.lang == 'ko';
    final isJa = provider.lang == 'ja';
    final isEditing = provider.hasProfile;

    String title = isEditing
        ? (isKo ? '내 프로필 수정' : (isJa ? 'プロフィール編集' : 'Edit Profile'))
        : (isKo ? '깨비가 널 알아가는 중...' : (isJa ? 'クケビがあなたを覚え中...' : 'Kkaebi is getting to know you...'));
    String subtitle = isEditing
        ? (isKo
            ? '수정된 정보는 기기 로컬에만 안전하게 보관됩니다'
            : (isJa ? '修正された情報は端末にのみ保存されます' : 'Updated profile is saved securely on your device.'))
        : (isKo
            ? '모든 정보는 기기에만 저장되며 건너뛰어도 전부 이용할 수 있습니다'
            : (isJa
                ? 'すべての情報は端末にのみ保存され、スキップしても全機能を利用できます'
                : 'Everything stays on your device. Skipping still unlocks the whole app.'));

    final isInteracting = _ageGroup != 'anon' || _gender != 'anon' || _nicknameCtrl.text.isNotEmpty;
    final mascotImage = isInteracting ? 'assets/images/2d_processed/kkebi_cast.png' : 'assets/images/2d_processed/kkebi_idle.png';

    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 420),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: DokkeyTheme.gold.withOpacity(0.5), width: 1.5),
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 92,
                  height: 92,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        DokkeyTheme.gold.withOpacity(0.3),
                        DokkeyTheme.cardDark,
                      ],
                    ),
                    border: Border.all(color: DokkeyTheme.gold, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: DokkeyTheme.gold.withOpacity(0.35),
                        blurRadius: 16,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      mascotImage,
                      fit: BoxFit.contain,
                      errorBuilder: (_, __, ___) => Image.asset(
                        'assets/images/kkaebi_mascot.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Center(
                child: Text(
                  title,
                  style: TextStyle(
                    color: DokkeyTheme.goldLight,
                    fontWeight: FontWeight.bold,
                    fontSize: 17,
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Center(
                child: Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                ),
              ),
              const SizedBox(height: 20),

              // Nickname
              TextField(
                controller: _nicknameCtrl,
                maxLength: 12,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => _submit(),
                style: TextStyle(color: DokkeyTheme.textMain),
                decoration: InputDecoration(
                  counterText: '',
                  labelText: isKo ? '선호 닉네임' : (isJa ? 'ニックネーム' : 'Nickname'),
                  labelStyle: TextStyle(color: DokkeyTheme.textMuted),
                  prefixIcon: Icon(Icons.badge_outlined, color: DokkeyTheme.gold),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DokkeyTheme.borderDark)),
                  focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: DokkeyTheme.gold)),
                  filled: true,
                  fillColor: DokkeyTheme.surfaceDark,
                ),
              ),
              const SizedBox(height: 14),

              // Age group
              Text(
                isKo ? '연령대' : (isJa ? '年代' : 'Age group'),
                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: _ageOptions.map((o) {
                  final label = o.$1 == 'anon'
                      ? (isKo ? '비공개' : (isJa ? '非公開' : 'Skip'))
                      : o.$2;
                  final selected = _ageGroup == o.$1;
                  return ChoiceChip(
                    label: Text(label, style: TextStyle(fontSize: 12)),
                    selected: selected,
                    selectedColor: DokkeyTheme.gold.withOpacity(0.35),
                    backgroundColor: DokkeyTheme.surfaceDark,
                    labelStyle: TextStyle(color: selected ? DokkeyTheme.goldLight : DokkeyTheme.textMuted),
                    side: BorderSide(color: selected ? DokkeyTheme.gold : DokkeyTheme.borderDark),
                    onSelected: (_) => setState(() => _ageGroup = o.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),

              // Gender
              Text(
                isKo ? '성별' : (isJa ? '性別' : 'Gender'),
                style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: _genderOptions.map((o) {
                  final label = o.$1 == 'anon'
                      ? (isKo ? '비공개' : (isJa ? '非公開' : 'Skip'))
                      : (isKo ? o.$2 : (isJa ? o.$2 : switch (o.$1) { 'm' => 'M', 'f' => 'F', _ => 'Other' }));
                  final selected = _gender == o.$1;
                  return ChoiceChip(
                    label: Text(label, style: TextStyle(fontSize: 12)),
                    selected: selected,
                    selectedColor: DokkeyTheme.gold.withOpacity(0.35),
                    backgroundColor: DokkeyTheme.surfaceDark,
                    labelStyle: TextStyle(color: selected ? DokkeyTheme.goldLight : DokkeyTheme.textMuted),
                    side: BorderSide(color: selected ? DokkeyTheme.gold : DokkeyTheme.borderDark),
                    onSelected: (_) => setState(() => _gender = o.$1),
                  );
                }).toList(),
              ),
              const SizedBox(height: 22),

              ElevatedButton(
                onPressed: () => _submit(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DokkeyTheme.gold,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  isEditing
                      ? (isKo ? '수정 완료 (저장)' : (isJa ? '変更を保存' : 'Save Changes'))
                      : (isKo ? '인사 보내기' : (isJa ? '挨拶を送る' : 'Say Hello')),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => _submit(skip: true),
                child: Text(
                  isEditing
                      ? (isKo ? '닫기' : (isJa ? '閉じる' : 'Close'))
                      : (isKo ? '다음에 할게요 (건너뛰기)' : (isJa ? 'また今度 (スキップ)' : 'Maybe later (Skip)')),
                  style: TextStyle(color: DokkeyTheme.textMuted),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
