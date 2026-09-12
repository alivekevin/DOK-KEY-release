import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../providers/dokkey_provider.dart';
import 'kkaebi_face_widget.dart';

/// 📖 깨비는 누구? & DOK-KEY 완벽 가이드북 다이얼로그
class KkaebiLoreHelpDialog extends StatefulWidget {
  final int initialTab;

  const KkaebiLoreHelpDialog({super.key, this.initialTab = 0});

  static void show(BuildContext context, {int initialTab = 0}) {
    SoundService().playCardFlip();
    showDialog(
      context: context,
      builder: (_) => KkaebiLoreHelpDialog(initialTab: initialTab),
    );
  }

  @override
  State<KkaebiLoreHelpDialog> createState() => _KkaebiLoreHelpDialogState();
}

class _KkaebiLoreHelpDialogState extends State<KkaebiLoreHelpDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(
      length: 2,
      vsync: this,
      initialIndex: widget.initialTab.clamp(0, 1),
    );
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DokkeyProvider>();
    final lang = provider.lang;
    final isKo = lang == 'ko';
    final isJa = lang == 'ja';
    final isZh = lang == 'zh';
    final isDe = lang == 'de';
    final isHi = lang == 'hi';

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        decoration: BoxDecoration(
          color: DokkeyTheme.cardDark,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: DokkeyTheme.gold.withValues(alpha: 0.6), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: DokkeyTheme.gold.withValues(alpha: 0.15),
              blurRadius: 36,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 16, 12),
              decoration: BoxDecoration(
                color: DokkeyTheme.surfaceDark,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(23)),
                border: Border(bottom: BorderSide(color: DokkeyTheme.borderDark)),
              ),
              child: Row(
                children: [
                  const KkaebiFaceWidget(size: 32, mode: KkaebiFaceMode.greeting),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isKo
                              ? '깨비 이야기 & DOK-KEY 가이드'
                              : (isJa
                                  ? 'クケビの物語 ＆ 利用ガイド'
                                  : (isZh
                                      ? '吉鬼的故事 ＆ 使用指南'
                                      : (isDe
                                          ? 'Kkaebi-Geschichte & DOK-KEY Guide'
                                          : (isHi
                                              ? 'कैबी की कहानी और गाइड'
                                              : 'Kkaebi Lore & DOK-KEY Guide')))),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          isKo
                              ? '당신만의 수호 도깨비와 행운의 열쇠 이야기'
                              : (isJa
                                  ? '守護トッケビと幸運の鍵の秘密'
                                  : 'The Secret of Your Guardian Dokkaebi & Lucky Keys'),
                          style: TextStyle(
                            color: DokkeyTheme.goldLight,
                            fontSize: 11.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: Colors.white70),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            // Tab Bar
            Container(
              color: DokkeyTheme.surfaceDark,
              child: TabBar(
                controller: _tabCtrl,
                indicatorColor: DokkeyTheme.gold,
                indicatorWeight: 3,
                labelColor: DokkeyTheme.goldLight,
                unselectedLabelColor: DokkeyTheme.textMuted,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                tabs: [
                  Tab(
                    icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                    text: isKo
                        ? '깨비는 누구?'
                        : (isJa
                            ? 'クケビとは？'
                            : (isZh ? '吉鬼是谁？' : (isDe ? 'Wer ist Kkaebi?' : (isHi ? 'कैबी कौन है?' : 'Who is Kkaebi?')))),
                  ),
                  Tab(
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    text: isKo
                        ? 'DOK-KEY 도움말'
                        : (isJa
                            ? 'DOK-KEY 説明書'
                            : (isZh ? '系统帮助' : (isDe ? 'DOK-KEY Hilfe' : (isHi ? 'DOK-KEY मदद' : 'App Guide')))),
                  ),
                ],
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildLoreTab(context, isKo, isJa, isZh, isDe, isHi),
                  _buildHelpTab(context, isKo, isJa, isZh, isDe, isHi),
                ],
              ),
            ),

            // Footer Close Button
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: DokkeyTheme.surfaceDark,
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(23)),
                border: Border(top: BorderSide(color: DokkeyTheme.borderDark)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'DOK-KEY v4.9.5 · Dokkey Studio',
                    style: TextStyle(color: DokkeyTheme.textMuted, fontSize: 11),
                  ),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DokkeyTheme.gold,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      isKo ? '확인' : 'OK',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 😈 탭 1: 깨비는 누구? (유래, 정체성, 4대 의미)
  Widget _buildLoreTab(BuildContext context, bool isKo, bool isJa, bool isZh, bool isDe, bool isHi) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // 1. 유래와 탄생 (Etymology & Origin)
        _buildSectionCard(
          icon: '✨',
          title: isKo
              ? '깨비의 유래와 탄생'
              : (isJa ? 'クケビの由来と誕生' : (isZh ? '吉鬼的渊源与诞生' : 'Origin of Kkaebi')),
          color: DokkeyTheme.gold,
          content: isKo
              ? '「깨비」는 한국의 오랜 민담과 설화 속에서 인간과 어울려 온 신비롭고 정겨운 존재인 **\'도깨비(Dokkaebi)\'**의 줄임말이자 애칭입니다.\n\n'
                '무서운 악귀가 아닌, 착한 이에게 복을 주고 액운을 쫓아주는 해학적인 도깨비의 **\'독(DOK)\'**과 오늘 하루의 문을 여는 **\'열쇠(KEY)\'**가 만나 당신만의 온디바이스 수호신 **"깨비"**가 탄생했습니다!'
              : (isJa
                  ? '「クケビ」は、韓国の伝統説話に登場する親しみ深く神秘的な守護精霊**「トッケビ (Dokkaebi)」**の愛称です。\n\n'
                    '悪霊ではなく、心優しき者に福を授け厄を払うトッケビの**「DOK」**と、今日一日の扉を開く**「KEY (鍵)」**が融合して、あなただけの守護神**「DOK-KEY (クケビ)」**が誕生しました！'
                  : '“Kkaebi” is the affectionate short name for **“Dokkaebi”**, the legendary and friendly guardian spirit in Korean folklore.\n\n'
                    'Combining **“DOK”** (from Dokkaebi, who blesses good hearts and banishes misfortune) and **“KEY”** (the key that unlocks your new day), your personal companion spirit **“DOK-KEY (Kkaebi)”** was born!'),
        ),
        const SizedBox(height: 14),

        // 2. 깨비의 모습과 상징 (Appearance & Symbols)
        _buildSectionCard(
          icon: '🗝️',
          title: isKo
              ? '깨비의 뿔과 황금 열쇠의 비밀'
              : (isJa ? '角と黄金の鍵の秘密' : 'Horn & Golden Key Symbols'),
          color: DokkeyTheme.mintCalm,
          content: isKo
              ? '• **도깨비 뿔 📡**: 천 년 동안 사람들의 소원과 고민을 감지하며 자라난 신비한 안테나입니다.\n'
                '• **황금 열쇠 🔑**: 굳게 닫힌 고민과 막힌 운을 시원하게 열어주는 행운의 마스터키입니다.\n'
                '• **장난기 많은 성격 😈**: 때로는 짓궂게 장난을 치지만, 누구보다 당신의 성장과 행복을 진심으로 응원합니다.'
              : (isJa
                  ? '• **トッケビの角 📡**: 千年の間、人々の願いや悩みを感知して成長した神秘のアンテナです。\n'
                    '• **黄金の鍵 🔑**: 閉ざされた悩みや運命の扉を開くマスターキーです。\n'
                    '• **お茶目な性格 😈**: いたずら好きですが、誰よりもあなたの幸せを心から応援しています。'
                  : '• **Dokkaebi Horn 📡**: A mystical antenna grown over a thousand years to sense your wishes and worries.\n'
                    '• **Golden Key 🔑**: The master key that unlocks closed fortunes and new daily opportunities.\n'
                    '• **Playful Spirit 😈**: Mischievous and witty, yet your most loyal supporter in daily life.'),
        ),
        const SizedBox(height: 14),

        // 3. DOK-KEY에서 깨비가 존재하는 4가지 의미 (Core Roles)
        _buildSectionCard(
          icon: '👑',
          title: isKo
              ? 'DOK-KEY에서 깨비의 4대 역할'
              : (isJa ? 'DOK-KEYにおけるクケビの4大役割' : 'Kkaebi’s 4 Core Roles in DOK-KEY'),
          color: DokkeyTheme.dokFire,
          content: isKo
              ? '1️⃣ **문(Door)을 여는 자**: 매일 아침 1-Draw로 하루를 여는 수호 카드와 행운의 번호를 선물합니다.\n\n'
                '2️⃣ **마음(Heart)을 빚는 자**: 지치고 불안한 날, 5단계 따뜻한 위로와 지혜의 통찰을 전합니다.\n\n'
                '3️⃣ **지혜(Wisdom)를 겨루는 자**: 9+4종 오락실 게임과 수수께끼로 당신의 두뇌를 깨웁니다.\n\n'
                '4️⃣ **수호(Protection)를 약속하는 자**: 18종 황금 부적으로 일상과 비밀번호를 든든하게 지켜줍니다.'
              : (isJa
                  ? '1️⃣ **扉を開く者**: 毎朝1-Drawでその日の守護カードと幸運の数字を届けます。\n\n'
                    '2️⃣ **心を癒す者**: 不安な日、5段階の温かい慰めと知恵の言葉を授けます。\n\n'
                    '3️⃣ **知恵を競う者**: 9+4種のゲームとなぞなぞで脳を目覚めさせます。\n\n'
                    '4️⃣ **守護を誓う者**: 18種の黄金のお札であなたの日常と暗証番号を護ります。'
                  : '1️⃣ **Door Opener**: Bestows your daily guardian card & lucky numbers every morning.\n\n'
                    '2️⃣ **Heart Healer**: Provides 5-step deep comfort and wise counsel when you feel weary.\n\n'
                    '3️⃣ **Wisdom Challenger**: Sparks your mind with 9+4 arcade games & daily riddles.\n\n'
                    '4️⃣ **Guardian**: Shields your passcodes & routine with 18 sacred golden talismans.'),
        ),
      ],
    );
  }

  /// 🗝️ 탭 2: DOK-KEY 시스템 도움말
  Widget _buildHelpTab(BuildContext context, bool isKo, bool isJa, bool isZh, bool isDe, bool isHi) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // 1. 데일리 운세 드로우
        _buildSectionCard(
          icon: '🎴',
          title: isKo
              ? '1. 데일리 1-Draw & 황금 열쇠'
              : (isJa ? '1. デイリー 1-Draw ＆ 黄金の鍵' : '1. Daily 1-Draw & Keys'),
          color: DokkeyTheme.gold,
          content: isKo
              ? '• 매일 1회(자정 00:00 리셋) 무료로 카드를 드로우합니다.\n'
                '• 66종(33x2) 십이지신 및 동양 신화 신수 카드 중 오늘의 수호 카드가 배정됩니다.\n'
                '• 무료 열쇠는 7일간 보관되며, PRO 플랜 이용자는 10년 보관 & 1일 +3회 추가 뽑기가 가능합니다.'
              : (isJa
                  ? '• 毎日1回（午前0時リセット）無料でカードを引けます。\n'
                    '• 66種（十二支33種＋神話33種）から今日の守護カードが決定します。\n'
                    '• 無料鍵は7日間保管、PROユーザーは10年保管＆1日+3回追加ドローが可能です。'
                  : '• Draw 1 free guardian card daily (resets at midnight 00:00).\n'
                    '• 66 cards (33 Zodiac + 33 Mythic Spirits) provide your daily guidance & number.\n'
                    '• Free keys are stored for 7 days; PRO pass offers 10-year validity & +3 extra draws.'),
        ),
        const SizedBox(height: 14),

        // 2. 열쇠 연성 & 보관함
        _buildSectionCard(
          icon: '🔐',
          title: isKo
              ? '2. 마법 열쇠 연성 & 도어락 비밀번호'
              : (isJa ? '2. 鍵の錬成 ＆ パスコード生成' : '2. Key Fusion & Passcodes'),
          color: DokkeyTheme.mintCalm,
          content: isKo
              ? '• 보관함(KeyBox)에 모인 행운의 숫자들을 조합(4자리 / 6자리)하여 안전한 현관문 도어락이나 나만의 비밀번호를 연성합니다.\n'
                '• 깨비의 수호 에너지가 담겨 기억하기 쉽고 의미 있는 번호키가 완성됩니다.'
              : (isJa
                  ? '• 保管箱（KeyBox）に集めた数字を組み合わせて（4桁／6桁）安全な暗証番号を錬成します。\n'
                    '• クケビの守護エネルギーが宿り、覚えやすく縁起の良い番号が作れます。'
                  : '• Combine collected lucky numbers in the KeyBox into secure 4-digit or 6-digit door lock passcodes.\n'
                    '• Imbued with Dokkaebi protection for safe and memorable security.'),
        ),
        const SizedBox(height: 14),

        // 3. 18종 황금 부적
        _buildSectionCard(
          icon: '📜',
          title: isKo
              ? '3. 18종 온디바이스 황금 부적 컬렉션'
              : (isJa ? '3. 18種の黄金お札コレクション' : '3. 18 Sacred Golden Talismans'),
          color: const Color(0xFFFFB300),
          content: isKo
              ? '• 카드를 드로우할 때마다 고유한 능력치를 가진 황금 부적이 자동으로 도감에 수집됩니다.\n'
                '• 재물운, 시험합격운, 만사형통, 심신안정 등 18종의 부적을 모두 모아보세요.'
              : (isJa
                  ? '• カードを引くたびに固有の力を持つ黄金のお札が図鑑に自動収集されます。\n'
                    '• 金運、合格運、心身安定など18種のお札を集めてコレクションを完成させましょう。'
                  : '• Each card draw automatically registers unique golden talismans in your codex.\n'
                    '• Collect all 18 talismans for wealth, health, tranquility, and success buffs.'),
        ),
        const SizedBox(height: 14),

        // 4. 9+4종 깨비 오락실
        _buildSectionCard(
          icon: '🕹️',
          title: isKo
              ? '4. 9+4종 깨비 오락실 & 두뇌 챌린지'
              : (isJa ? '4. 9+4種のクケビゲームセンター' : '4. 9+4 Arcade & Brain Games'),
          color: const Color(0xFFB388FF),
          content: isKo
              ? '• 9종 클래식 아케이드 (슈팅, 동굴탈출, 버블, 벽돌깨기, 정글러너 등)\n'
                '• 4종 보너스 두뇌 게임 (신수 직소 퍼즐, 깨비 스도쿠, 대각선 X-스도쿠, 육각 지뢰찾기, 크로스 마방진)\n'
                '• 하이스코어를 달성하고 깨비 친밀도를 빠르게 올려보세요!'
              : (isJa
                  ? '• 9種のクラシックゲーム（シューティング、洞窟脱出、バブル、ブロック崩しなど）\n'
                    '• 4種のボーナス頭脳パズル（ジグソー、数独、X数独、六角マインスイーパ、魔方陣）\n'
                    '• ハイスコアを記録してクケビとの親密度をアップさせましょう！'
                  : '• 9 classic arcade games (Shooter, Cave Escape, Bubble, Breakout, Jungle Runner, etc.)\n'
                    '• 4 bonus brain puzzles (Jigsaw, Sudoku, X-Sudoku, Hex Mines, Cross Magic Square)\n'
                    '• Play without limits and boost Kkaebi affection levels!'),
        ),
        const SizedBox(height: 14),

        // 5. PRO 멤버십
        _buildSectionCard(
          icon: '👑',
          title: isKo
              ? '5. DOK-KEY PRO 멤버십 안내'
              : (isJa ? '5. DOK-KEY PRO メンバーシップ' : '5. DOK-KEY PRO Pass'),
          color: DokkeyTheme.gold,
          content: isKo
              ? '• 1년 이용권: ₩12,000 / 1년 (\$9.99)\n'
                '• 평생 소장권: ₩59,000 (\$49.99)\n'
                '• 혜택: 99슬롯 확장, 10년 키 보관, 1일 4뽑기(+3회 추가), 광고 전면 제거, 오락실 전체 무제한 이용'
              : (isJa
                  ? '• 1年プラン: ¥1,400 / 年 (\$9.99)\n'
                    '• 永久プラン: ¥7,000 (\$49.99)\n'
                    '• 特典: 99スロット拡張、10年保管、1日+3回追加ドロー、広告完全非表示、全ゲーム無制限'
                  : '• 1-Year Pass: \$9.99 / Year (₩12,000)\n'
                    '• Lifetime Pass: \$49.99 (₩59,000)\n'
                    '• Perks: 99 key slots, 10-year storage, +3 daily draws, ad-free, unlimited arcade.'),
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String icon,
    required String title,
    required Color color,
    required String content,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DokkeyTheme.surfaceDark,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.bold,
                    fontSize: 14.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            content,
            style: const TextStyle(
              color: Color(0xFFD4DCED),
              fontSize: 12.5,
              height: 1.55,
            ),
          ),
        ],
      ),
    );
  }
}
