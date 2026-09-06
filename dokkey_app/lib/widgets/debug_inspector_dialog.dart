import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../models/dokkey_models.dart';
import '../providers/dokkey_provider.dart';
import 'kkaebi_face_widget.dart';

/// 🔬 콘텐츠 원클릭 검증 인스펙터 (v4.1.0 PHASE 3 Developer Cheat Mode)
/// 설정창 버전 번호 5회 연속 탭으로 진입.
/// 1. 카드 강제 선택기  2. 수수께끼 전수 테스터  3. 꿈풀이 키워드 테스터
/// 4. 숫자 풀 치트 인젝터  5. 언어 즉시 스위처  6. 깨비 감정 강제 트리거
class DebugInspectorDialog extends StatefulWidget {
  const DebugInspectorDialog({super.key});

  static void show(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => const DebugInspectorDialog(),
    );
  }

  @override
  State<DebugInspectorDialog> createState() => _DebugInspectorDialogState();
}

class _DebugInspectorDialogState extends State<DebugInspectorDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  int _selectedFaceIndex = 5;
  final _injectCtrl = TextEditingController(text: '07');
  final _dreamSearchCtrl = TextEditingController();

  static const List<(int, String)> _faces = [
    (1, '평온'),
    (2, '반가움'),
    (3, '기쁨'),
    (4, '윙크'),
    (5, '미소'),
    (6, '분노'),
    (7, '슬픔'),
    (8, '놀라움'),
  ];

  KkaebiFaceMode _faceModeForIndex(int idx) {
    switch (idx) {
      case 1:
        return KkaebiFaceMode.neutral;
      case 2:
        return KkaebiFaceMode.greeting;
      case 3:
        return KkaebiFaceMode.joy;
      case 4:
        return KkaebiFaceMode.wink;
      case 5:
        return KkaebiFaceMode.idle;
      case 6:
        return KkaebiFaceMode.angry;
      case 7:
        return KkaebiFaceMode.sadness;
      case 8:
        return KkaebiFaceMode.jackpot;
      default:
        return KkaebiFaceMode.idle;
    }
  }

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 6, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _injectCtrl.dispose();
    _dreamSearchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 20),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 640),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DokkeyTheme.mintCalm, width: 2),
        ),
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.science_rounded, color: DokkeyTheme.mintCalm, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '콘텐츠 인스펙터 (CHEAT MODE)',
                    style: TextStyle(
                      color: DokkeyTheme.mintCalm,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, size: 18, color: DokkeyTheme.textMuted),
                  ),
                ],
              ),
            ),
            TabBar(
              controller: _tabCtrl,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicatorColor: DokkeyTheme.mintCalm,
              labelColor: DokkeyTheme.mintCalm,
              unselectedLabelColor: DokkeyTheme.textMuted,
              labelStyle: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: '🃏 카드'),
                Tab(text: '🧩 수수께끼'),
                Tab(text: '🌙 꿈풀이'),
                Tab(text: '🔢 숫자 주입'),
                Tab(text: '🌐 언어'),
                Tab(text: '😈 감정'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildCardSelector(provider),
                  _buildRiddleBrowser(provider),
                  _buildDreamBrowser(provider),
                  _buildNumberInjector(provider),
                  _buildLanguageSwitcher(provider),
                  _buildFaceTriggers(provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. 카드 강제 선택기: 99종 그랜드 도감 카드를 오늘의 카드로 강제 지정
  Widget _buildCardSelector(DokkeyProvider provider) {
    final cards = provider.getAllCodexCards();
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: cards.length,
      itemBuilder: (ctx, idx) {
        final card = cards[idx];
        final isCurrent = provider.todayResult?.card.id == card.id;
        return ListTile(
          dense: true,
          leading: Container(
            width: 34,
            height: 34,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: DokkeyTheme.parseHex('#F0A500').withOpacity(0.15),
              border: Border.all(color: DokkeyTheme.gold.withOpacity(0.6)),
            ),
            child: Text(
              '${idx + 1}',
              style: TextStyle(color: DokkeyTheme.goldLight, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            card.name,
            style: TextStyle(color: DokkeyTheme.textMain, fontSize: 13),
          ),
          subtitle: Text(
            card.id,
            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
          ),
          trailing: isCurrent
              ? Chip(
                  label: Text('TODAY', style: TextStyle(fontSize: 9, color: Colors.black)),
                  backgroundColor: DokkeyTheme.gold,
                  visualDensity: VisualDensity.compact,
                )
              : TextButton(
                  onPressed: () async {
                    await provider.forceTodayCard(card.id);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('오늘의 카드 강제 지정: ${card.name}'),
                          backgroundColor: DokkeyTheme.surfaceDark,
                        ),
                      );
                    }
                  },
                  child: Text('강제 지정', style: TextStyle(fontSize: 11, color: DokkeyTheme.mintCalm)),
                ),
        );
      },
    );
  }

  // 2. 수수께끼 전수 테스터
  Widget _buildRiddleBrowser(DokkeyProvider provider) {
    final riddles = List<RiddleModel>.generate(
      15,
      (i) => provider.getTodayRiddle(i),
    );
    return ListView.builder(
      padding: const EdgeInsets.all(12),
      itemCount: riddles.length,
      itemBuilder: (ctx, idx) {
        final r = riddles[idx];
        return Card(
          color: DokkeyTheme.surfaceDark,
          margin: const EdgeInsets.only(bottom: 8),
          child: Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: const EdgeInsets.symmetric(horizontal: 12),
              childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 10),
              title: Text(
                '${idx + 1}. ${r.question}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: DokkeyTheme.textMain, fontSize: 12),
              ),
              subtitle: Text(
                '정답: ${r.options[r.answerIndex]}',
                style: TextStyle(color: DokkeyTheme.mintCalm, fontSize: 11),
              ),
              children: [
                ...r.options.asMap().entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.only(bottom: 3),
                        child: Row(
                          children: [
                            Icon(
                              e.key == r.answerIndex ? Icons.check_circle : Icons.radio_button_unchecked,
                              size: 13,
                              color: e.key == r.answerIndex ? DokkeyTheme.mintCalm : DokkeyTheme.textMuted,
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                e.value,
                                style: TextStyle(color: DokkeyTheme.textMain, fontSize: 11.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 6),
                Text(
                  '정답 반응: ${r.correctReaction}',
                  style: TextStyle(color: DokkeyTheme.mintCalm, fontSize: 10.5),
                ),
                const SizedBox(height: 4),
                Text(
                  '오답 반응: ${r.wrongReaction}',
                  style: TextStyle(color: DokkeyTheme.dokFire, fontSize: 10.5),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // 3. 꿈풀이 키워드 테스터
  Widget _buildDreamBrowser(DokkeyProvider provider) {
    final symbols = provider.dreamSymbols;
    final query = _dreamSearchCtrl.text.trim();
    final filtered = query.isEmpty
        ? symbols
        : symbols.where((s) => s.matchesQuery(query)).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(10),
          child: TextField(
            controller: _dreamSearchCtrl,
            onChanged: (_) => setState(() {}),
            style: TextStyle(color: DokkeyTheme.textMain, fontSize: 12),
            decoration: InputDecoration(
              hintText: '키워드 검색 (예: 호랑이한테 쫓기는 꿈)',
              hintStyle: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
              prefixIcon: Icon(Icons.search, size: 18, color: DokkeyTheme.mintCalm),
              isDense: true,
              filled: true,
              fillColor: DokkeyTheme.surfaceDark,
              border: OutlineInputBorder(),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: filtered.length,
            itemBuilder: (ctx, idx) {
              final s = filtered[idx];
              final fortuneColor = s.isAuspicious
                  ? DokkeyTheme.gold
                  : (s.isOminous ? DokkeyTheme.dokFire : DokkeyTheme.mintCalm);
              final fortuneLabel = s.isAuspicious ? '길몽' : (s.isOminous ? '흉몽' : '평몽');
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: DokkeyTheme.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: fortuneColor.withOpacity(0.4)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          s.label,
                          style: TextStyle(
                            color: DokkeyTheme.textMain,
                            fontWeight: FontWeight.bold,
                            fontSize: 12.5,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(fortuneLabel, style: TextStyle(color: fortuneColor, fontSize: 10.5, fontWeight: FontWeight.bold)),
                        const Spacer(),
                        Text(
                          '#${s.luckyNumberStr}',
                          style: TextStyle(color: DokkeyTheme.gold, fontSize: 11, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '키워드: ${s.keywords.join(", ")}',
                      style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      s.advice,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: DokkeyTheme.textMain, fontSize: 10.5),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // 4. 숫자 풀 치트 인젝터
  Widget _buildNumberInjector(DokkeyProvider provider) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '원하는 번호를 즉시 보관함에 주입하여 조합을 테스트합니다.',
            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _injectCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 2,
                  style: TextStyle(color: DokkeyTheme.textMain, fontSize: 18, fontWeight: FontWeight.w900),
                  decoration: InputDecoration(
                    counterText: '',
                    hintText: '01~99',
                    hintStyle: TextStyle(color: DokkeyTheme.textMuted),
                    prefixIcon: Icon(Icons.pin, color: DokkeyTheme.gold),
                    filled: true,
                    fillColor: DokkeyTheme.surfaceDark,
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              ElevatedButton.icon(
                onPressed: () async {
                  await provider.injectNumber(_injectCtrl.text.trim());
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('#${_injectCtrl.text.trim()} 보관함 주입 완료! 🔢'),
                        backgroundColor: DokkeyTheme.surfaceDark,
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.bolt_rounded),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DokkeyTheme.mintCalm,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                label: const Text('주입', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ['07', '21', '33', '49', '66', '77', '88', '99'].map((n) {
              return OutlinedButton(
                onPressed: () async {
                  await provider.injectNumber(n);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('#$n 주입 완료! 🔢'), backgroundColor: DokkeyTheme.surfaceDark),
                    );
                  }
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: DokkeyTheme.goldLight,
                  side: BorderSide(color: DokkeyTheme.gold),
                ),
                child: Text('#$n'),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Text(
            '보관함 보유: ${provider.sourceNumbers.length}개 · 도감 수집: ${provider.codexMasterProgress}/66',
            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // 5. 언어 즉시 스위처
  Widget _buildLanguageSwitcher(DokkeyProvider provider) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '재시작 없이 즉시 언어를 전환합니다.',
            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LangButton(label: 'KO', current: provider.lang == 'ko', onTap: () => provider.setLanguage('ko')),
              const SizedBox(width: 8),
              _LangButton(label: 'EN', current: provider.lang == 'en', onTap: () => provider.setLanguage('en')),
              const SizedBox(width: 8),
              _LangButton(label: 'JA', current: provider.lang == 'ja', onTap: () => provider.setLanguage('ja')),
              const SizedBox(width: 8),
              _LangButton(label: 'ZH', current: provider.lang == 'zh', onTap: () => provider.setLanguage('zh')),
              const SizedBox(width: 8),
              _LangButton(label: 'HI', current: provider.lang == 'hi', onTap: () => provider.setLanguage('hi')),
            ],
          ),
        ],
      ),
    );
  }

  // 6. 깨비 감정 강제 트리거
  Widget _buildFaceTriggers(DokkeyProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          KkaebiFaceWidget(
            key: ValueKey('face_$_selectedFaceIndex'),
            size: 140,
            mode: _faceModeForIndex(_selectedFaceIndex),
            enableGlow: true,
            enableFloat: true,
          ),
          const SizedBox(height: 8),
          Text(
            'face_${_selectedFaceIndex.toString().padLeft(2, '0')}',
            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: _faces.map((f) {
              final (idx, name) = f;
              final selected = _selectedFaceIndex == idx;
              return GestureDetector(
                onTap: () => setState(() => _selectedFaceIndex = idx),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? DokkeyTheme.mintCalm.withOpacity(0.25) : DokkeyTheme.surfaceDark,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected ? DokkeyTheme.mintCalm : DokkeyTheme.borderDark,
                    ),
                  ),
                  child: Text(
                    '$idx $name',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? DokkeyTheme.mintCalm : DokkeyTheme.textMuted,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),
          Text(
            '원샷 시퀀스: jackpot [8]→[3]→[5] / angry [5]→[6]→[1] / sadness [5]→[7]→[5]',
            textAlign: TextAlign.center,
            style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _LangButton extends StatelessWidget {
  final String label;
  final bool current;
  final VoidCallback onTap;

  const _LangButton({required this.label, required this.current, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: current ? DokkeyTheme.mintCalm : DokkeyTheme.surfaceDark,
        foregroundColor: current ? Colors.black : DokkeyTheme.textMuted,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
      child: Text(label, style: const TextStyle(fontWeight: FontWeight.w900)),
    );
  }
}
