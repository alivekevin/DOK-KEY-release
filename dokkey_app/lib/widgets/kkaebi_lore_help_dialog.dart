import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../core/sound_service.dart';
import '../core/pricing.dart';
import '../providers/dokkey_provider.dart';
import 'kkaebi_face_widget.dart';

/// 📖 깨비는 누구? & DOK-KEY 완벽 가이드북 다이얼로그 (6개국어 완벽 지원)
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
    final pricing = ProPricing.of(lang);

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
                          _t(lang,
                            ko: '깨비 이야기 & DOK-KEY 가이드',
                            en: 'Kkaebi Lore & DOK-KEY Guide',
                            ja: 'クケビの物語 ＆ 利用ガイド',
                            zh: '吉鬼的故事 ＆ 使用指南',
                            de: 'Kkaebi-Geschichte & DOK-KEY Guide',
                            hi: 'कैबी की कहानी और DOK-KEY गाइड',
                          ),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _t(lang,
                            ko: '당신만의 수호 도깨비와 행운의 열쇠 이야기',
                            en: 'The Secret of Your Guardian Dokkaebi & Lucky Keys',
                            ja: '守護トッケビと幸運の鍵の秘密',
                            zh: '专属于您的守护精灵与幸运钥匙之秘',
                            de: 'Das Geheimnis Ihres Schutzgeistes & der Glücksschlüssel',
                            hi: 'आपके रक्षक डोक्केबी और भाग्यशाली चाबियों का रहस्य',
                          ),
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
                    text: _t(lang,
                      ko: '깨비는 누구?',
                      en: 'Who is Kkaebi?',
                      ja: 'クケビとは？',
                      zh: '吉鬼是谁？',
                      de: 'Wer ist Kkaebi?',
                      hi: 'कैबी कौन है?',
                    ),
                  ),
                  Tab(
                    icon: const Icon(Icons.menu_book_rounded, size: 18),
                    text: _t(lang,
                      ko: 'DOK-KEY 도움말',
                      en: 'App Guide',
                      ja: 'DOK-KEY 説明書',
                      zh: '系统说明书',
                      de: 'DOK-KEY Anleitung',
                      hi: 'DOK-KEY गाइड',
                    ),
                  ),
                ],
              ),
            ),

            // Tab View Body
            Expanded(
              child: TabBarView(
                controller: _tabCtrl,
                children: [
                  _buildLoreTab(context, lang),
                  _buildHelpTab(context, lang, pricing),
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
                      _t(lang, ko: '확인', en: 'OK', ja: '確認', zh: '确认', de: 'OK', hi: 'ठीक है'),
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

  /// 😈 탭 1: 깨비는 누구? (유래, 상징, 4대 역할)
  Widget _buildLoreTab(BuildContext context, String lang) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // 1. 유래와 탄생 (Etymology & Origin)
        _buildSectionCard(
          icon: '✨',
          title: _t(lang,
            ko: '깨비의 유래와 탄생',
            en: 'Origin of Kkaebi',
            ja: 'クケビの由来と誕生',
            zh: '吉鬼的渊源与诞生',
            de: 'Herkunft & Entstehung von Kkaebi',
            hi: 'कैबी की उत्पत्ति और जन्म',
          ),
          color: DokkeyTheme.gold,
          content: _t(lang,
            ko: '「깨비」는 한국의 오랜 민담과 설화 속에서 인간과 어울려 온 신비롭고 정겨운 존재인 **\'도깨비(Dokkaebi)\'**의 줄임말이자 애칭입니다.\n\n'
                '무서운 악귀가 아닌, 착한 이에게 복을 주고 액운을 쫓아주는 해학적인 도깨비의 **\'독(DOK)\'**과 오늘 하루의 문을 여는 **\'열쇠(KEY)\'**가 만나 당신만의 온디바이스 수호신 **"깨비"**가 탄생했습니다!',
            en: '“Kkaebi” is the affectionate name for **“Dokkaebi”**, the legendary guardian spirit in Korean folklore.\n\n'
                'Far from a terrifying demon, Dokkaebi is a humorous spirit that rewards the kind-hearted and wards off misfortune. By combining **“DOK”** (Dokkaebi) and **“KEY”** (unlocking your daily fortune), your personal on-device companion spirit **“DOK-KEY (Kkaebi)”** was born!',
            ja: '「クケビ」は、韓国の伝統説話に登場する親しみ深く神秘的な守護精霊**「トッケビ (Dokkaebi)」**の愛称です。\n\n'
                '悪霊ではなく、心優しき者に福を授け厄を払うトッケビの**「DOK」**と、今日一日の扉を開く**「KEY (鍵)」**が融合して、あなただけの守護神**「DOK-KEY (クケビ)」**が誕生しました！',
            zh: '“吉鬼 (Kkaebi)”源自韩国古老民间传说中与人类相伴的神秘守护精灵**“Dokkaebi (都软鬼/吉鬼)”**的亲切简称。\n\n'
                '它绝非可怕的恶灵，而是为善良之人带来福运、驱除邪祟的风趣守护神。将吉鬼的**“DOK”**与开启每日之门的**“KEY (钥匙)”**相融合，专属于您的设备端守护灵**“DOK-KEY (吉鬼)”**就此诞生！',
            de: '„Kkaebi“ ist der Kosenahme für **„Dokkaebi“**, den legendären und freundlichen Schutzgeist der koreanischen Folklore.\n\n'
                'Er ist kein böser Dämon, sondern ein humorvoller Geist, der gute Menschen beschenkt und Unheil abwehrt. Aus der Verbindung von **„DOK“** (Dokkaebi) und **„KEY“** (dem Schlüssel zum neuen Tag) wurde Ihr persönlicher Begleiter **„DOK-KEY (Kkaebi)“** erschaffen!',
            hi: '"कैबी" (Kkaebi) कोरियाई लोककथाओं के प्रसिद्ध और मित्रवत रक्षक देव **"डोक्केबी" (Dokkaebi)** का प्यार भरा नाम है।\n\n'
                'यह कोई डरावना प्राणी नहीं, बल्कि अच्छे लोगों को वरदान देने और नकारात्मकता दूर करने वाला बुद्धिमान रक्षक है। **"DOK"** (डोक्केबी) और **"KEY"** (दिन खोलने वाली सुनहरी चा비) के मेल से आपका निजी संरक्षक **"DOK-KEY (कैबी)"** बना!',
          ),
        ),
        const SizedBox(height: 14),

        // 2. 깨비의 모습과 상징 (Appearance & Symbols)
        _buildSectionCard(
          icon: '🗝️',
          title: _t(lang,
            ko: '깨비의 뿔과 황금 열쇠의 비밀',
            en: 'Horn & Golden Key Symbols',
            ja: '角と黄金の鍵の秘密',
            zh: '鬼角与黄金钥匙的奥秘',
            de: 'Das Geheimnis von Horn & Goldschlüssel',
            hi: 'सींग और सुनहरी चाबी का रहस्य',
          ),
          color: DokkeyTheme.mintCalm,
          content: _t(lang,
            ko: '• **도깨비 뿔 📡**: 천 년 동안 사람들의 소원과 고민을 감지하며 자라난 신비한 안테나입니다.\n'
                '• **황금 열쇠 🔑**: 굳게 닫힌 고민과 막힌 운을 시원하게 열어주는 행운의 마스터키입니다.\n'
                '• **장난기 많은 성격 😈**: 때로는 짓궂게 장난을 치지만, 누구보다 당신의 성장과 행복을 진심으로 응원합니다.',
            en: '• **Dokkaebi Horn 📡**: A mystical antenna grown over a thousand years to sense your wishes and worries.\n'
                '• **Golden Key 🔑**: The master key that unlocks closed fortunes and new daily opportunities.\n'
                '• **Playful Spirit 😈**: Mischievous and witty, yet your most loyal supporter in daily life.',
            ja: '• **トッケビの角 📡**: 千年の間、人々の願いや悩みを感知して成長した神秘のアンテナです。\n'
                '• **黄金の鍵 🔑**: 閉ざされた悩みや運命の扉を開くマスターキーです。\n'
                '• **お茶目な性格 😈**: いたずら好きですが、誰よりもあなたの幸せを心から応援しています。',
            zh: '• **守护鬼角 📡**: 千年间感知人类心愿与烦恼的神奇天线。\n'
                '• **黄金钥匙 🔑**: 开启封闭运势与每日机遇的万能钥匙。\n'
                '• **活泼机智 😈**: 虽爱开玩笑，却全心全意守护您的幸福与成长。',
            de: '• **Dokkaebi-Horn 📡**: Eine mystische Antenne, die Wünsche und Sorgen wahrnimmt.\n'
                '• **Goldschlüssel 🔑**: Der Generalschlüssel für Glück und neue Lebenschancen.\n'
                '• **Schalkhafter Geist 😈**: Verspielt, aber Ihr treuester und warmherzigster Begleiter.',
            hi: '• **रहस्यमयी सींग 📡**: इच्छाओं और चिंताओं को समझने वाला दिव्य एंटीना।\n'
                '• **सुनहरी चाबी 🔑**: किस्मत और नए अवसरों के द्वार खोलने वाली मास्टर की।\n'
                '• **चंचल स्वभाव 😈**: मजाकिया लेकिन आपकी खुशियों और सफलता का सच्चा समर्थक।',
          ),
        ),
        const SizedBox(height: 14),

        // 3. DOK-KEY에서 깨비가 존재하는 4가지 의미 (Core Roles)
        _buildSectionCard(
          icon: '👑',
          title: _t(lang,
            ko: 'DOK-KEY에서 깨비의 4대 역할',
            en: 'Kkaebi’s 4 Core Roles in DOK-KEY',
            ja: 'DOK-KEYにおけるクケビの4大役割',
            zh: '吉鬼在DOK-KEY中的四大使命',
            de: 'Kkaebis 4 Hauptaufgaben in DOK-KEY',
            hi: 'DOK-KEY में कैबी की 4 मुख्य भूमिकाएँ',
          ),
          color: DokkeyTheme.dokFire,
          content: _t(lang,
            ko: '1️⃣ **문(Door)을 여는 자**: 매일 아침 1-Draw로 하루를 여는 수호 카드와 행운의 번호를 선물합니다.\n\n'
                '2️⃣ **마음(Heart)을 빚는 자**: 지치고 불안한 날, 5단계 따뜻한 위로와 지혜의 통찰을 전합니다.\n\n'
                '3️⃣ **지혜(Wisdom)를 겨루는 자**: 9+4종 오락실 게임과 수수께끼로 당신의 두뇌를 깨웁니다.\n\n'
                '4️⃣ **수호(Protection)를 약속하는 자**: 18종 황금 부적으로 일상과 비밀번호를 든든하게 지켜줍니다.',
            en: '1️⃣ **Door Opener**: Bestows your daily guardian card & lucky numbers every morning.\n\n'
                '2️⃣ **Heart Healer**: Provides 5-step deep comfort and wise counsel when you feel weary.\n\n'
                '3️⃣ **Wisdom Challenger**: Sparks your mind with 9+4 arcade games & daily riddles.\n\n'
                '4️⃣ **Guardian**: Shields your passcodes & routine with 18 sacred golden talismans.',
            ja: '1️⃣ **扉を開く者**: 毎朝1-Drawでその日の守護カードと幸運の数字を届けます。\n\n'
                '2️⃣ **心を癒す者**: 不安な日、5段階の温かい慰めと知恵の言葉を授けます。\n\n'
                '3️⃣ **知恵を競う者**: 9+4種のゲームとなぞなぞで脳を目覚めさせます。\n\n'
                '4️⃣ **守護を誓う者**: 18種の黄金のお札であなたの日常と暗証番号を護ります。',
            zh: '1️⃣ **启门者**: 每日清晨通过1-Draw赐予专属守护卡与幸运数字。\n\n'
                '2️⃣ **抚心者**: 在疲惫不安的日子里，提供5段温情对话抚慰心灵。\n\n'
                '3️⃣ **启智者**: 通过9+4种街机与益智挑战锻炼脑力与专注力。\n\n'
                '4️⃣ **守护者**: 凭借18种黄金符咒护佑您的日常与隐私密码。',
            de: '1️⃣ **Türöffner**: Schenkt Ihnen jeden Morgen eine Schutzkarte & Glückszahlen per 1-Draw.\n\n'
                '2️⃣ **Seelentröster**: Spendet in 5 Schritten tiefen Trost und weisen Rat.\n\n'
                '3️⃣ **Weisheitsprüfer**: Schärft Ihren Geist mit 9+4 Arcade-Spielen & Rätseln.\n\n'
                '4️⃣ **Beschützer**: Schützt Ihren Alltag und Passwörter mit 18 goldenen Talismanen.',
            hi: '1️⃣ **द्वार खोलने वाला**: हर सुबह 1-Draw से आपकी दैनिक रक्षक कार्ड और भाग्यशाली संख्या प्रदान करता है।\n\n'
                '2️⃣ **दिल को सुकून देने वाला**: थकावट के दिनों में 5 चरणों में सच्ची सांत्वना और बुद्धि देता है।\n\n'
                '3️⃣ **बुद्धि जगाने वाला**: 9+4 आर्केड गेम्स और पहेलियों से मस्तिष्क को सक्रिय करता है।\n\n'
                '4️⃣ **सुरक्षा देने वाला**: 18 सुनहरे ताबीजों से आपके पासकोड और दिनचर्या की रक्षा करता है।',
          ),
        ),
      ],
    );
  }

  /// 🗝️ 탭 2: DOK-KEY 시스템 도움말
  Widget _buildHelpTab(BuildContext context, String lang, ProPricing pricing) {
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        // 1. 데일리 운세 드로우
        _buildSectionCard(
          icon: '🎴',
          title: _t(lang,
            ko: '1. 데일리 1-Draw & 황금 열쇠',
            en: '1. Daily 1-Draw & Keys',
            ja: '1. デイリー 1-Draw ＆ 黄金の鍵',
            zh: '1. 每日 1-Draw 抽取与钥匙',
            de: '1. Tägliche 1-Draw Ziehung & Schlüssel',
            hi: '1. दैनिक 1-Draw और चाबियाँ',
          ),
          color: DokkeyTheme.gold,
          content: _t(lang,
            ko: '• 매일 1회(자정 00:00 리셋) 무료로 카드를 드로우합니다.\n'
                '• 66종(33x2) 십이지신 및 동양 신화 신수 카드 중 오늘의 수호 카드가 배정됩니다.\n'
                '• 무료 열쇠는 7일간 보관되며, PRO 플랜 이용자는 10년 보관 & 1일 +3회 추가 뽑기가 가능합니다.',
            en: '• Draw 1 free guardian card daily (resets at midnight 00:00).\n'
                '• 66 cards (33 Zodiac + 33 Mythic Spirits) provide your daily guidance & number.\n'
                '• Free keys are stored for 7 days; PRO pass offers 10-year validity & +3 extra draws.',
            ja: '• 毎日1回（午前0時リセット）無料でカードを引けます。\n'
                '• 66種（十二支33種＋神話33種）から今日の守護カードが決定します。\n'
                '• 無料鍵は7日間保管、PROユーザーは10年保管＆1日+3回追加ドローが可能です。',
            zh: '• 每日1次（午夜00:00重置）免费抽取守护卡。\n'
                '• 66种（生肖33种＋东方神话33种）卡牌决定今日指引与幸运数字。\n'
                '• 免费钥匙保存7天；PRO专业版享10年长期保存及每日+3次额外抽取。',
            de: '• Ziehen Sie täglich 1 kostenlose Schutzkarte (Zurücksetzung um Mitternacht 00:00).\n'
                '• 66 Karten (33 Tierkreis + 33 Mythengeister) bestimmen Ihren Tagesrat & Ihre Zahl.\n'
                '• Gratis-Schlüssel bleiben 7 Tage gültig; PRO bietet 10 Jahre Gültigkeit & +3 Extra-Ziehungen.',
            hi: '• प्रतिदिन 1 मुफ्त रक्षक कार्ड निकालें (मध्यरात्रि 00:00 बजे रीसेट)।\n'
                '• 66 कार्ड (33 राशियाँ + 33 पौराणिक आत्माएँ) दैनिक मार्गदर्शन और संख्या प्रदान करते हैं।\n'
                '• मुफ्त चाबियाँ 7 दिन रहती हैं; PRO पास 10 वर्ष की वैधता और +3 अतिरिक्त ड्रॉ देता है।',
          ),
        ),
        const SizedBox(height: 14),

        // 2. 열쇠 연성 & 보관함
        _buildSectionCard(
          icon: '🔐',
          title: _t(lang,
            ko: '2. 마법 열쇠 연성 & 도어락 비밀번호',
            en: '2. Key Fusion & Passcodes',
            ja: '2. 鍵の錬成 ＆ パスコード生成',
            zh: '2. 魔法钥匙炼成与门锁密码',
            de: '2. Schlüsselschmiede & Passcodes',
            hi: '2. की-फ्यूजन और पासकोड निर्माण',
          ),
          color: DokkeyTheme.mintCalm,
          content: _t(lang,
            ko: '• 보관함(KeyBox)에 모인 행운의 숫자들을 조합(4자리 / 6자리)하여 안전한 현관문 도어락이나 나만의 비밀번호를 연성합니다.\n'
                '• 깨비의 수호 에너지가 담겨 기억하기 쉽고 의미 있는 번호키가 완성됩니다.',
            en: '• Combine collected lucky numbers in the KeyBox into secure 4-digit or 6-digit door lock passcodes.\n'
                '• Imbued with Dokkaebi protection for safe, memorable, and auspicious passcodes.',
            ja: '• 保管箱（KeyBox）に集めた数字を組み合わせて（4桁／6桁）安全な暗証番号を錬成します。\n'
                '• クケビの守護エネルギーが宿り、覚えやすく縁起の良い番号が作れます。',
            zh: '• 在保管箱(KeyBox)中组合收集的数字（4位/6位），炼成安全的门锁密码。\n'
                '• 蕴含吉鬼守护能量，打造易记且吉祥的专属安全密码。',
            de: '• Kombinieren Sie gesammelte Glückszahlen im KeyBox zu sicheren 4- oder 6-stelligen Türschloss-Codes.\n'
                '• Mit Schutzenergie versehen für sichere und einprägsame Zahlenkombinationen.',
            hi: '• की-बॉक्स में एकत्रित संख्याओं को मिलाकर सुरक्षित 4-अंकीय या 6-अंकीय डोर लॉक पासकोड बनाएं।\n'
                '• डोक्केबी की सुरक्षा ऊर्जा से युक्त, याद रखने में आसान और शुभ पासकोड।',
          ),
        ),
        const SizedBox(height: 14),

        // 3. 18종 황금 부적
        _buildSectionCard(
          icon: '📜',
          title: _t(lang,
            ko: '3. 18종 온디바이스 황금 부적 컬렉션',
            en: '3. 18 Sacred Golden Talismans',
            ja: '3. 18種の黄金お札コレクション',
            zh: '3. 18种黄金符咒图鉴',
            de: '3. 18 goldene Schutztalismane',
            hi: '3. 18 सुनहरे ताबीज संग्रह',
          ),
          color: const Color(0xFFFFB300),
          content: _t(lang,
            ko: '• 카드를 드로우할 때마다 고유한 능력치를 가진 황금 부적이 자동으로 도감에 수집됩니다.\n'
                '• 재물운, 시험합격운, 만사형통, 심신안정 등 18종의 부적을 모두 모아보세요.',
            en: '• Each card draw automatically registers unique golden talismans in your codex.\n'
                '• Collect all 18 talismans for wealth, health, tranquility, and success buffs.',
            ja: '• カードを引くたびに固有の力を持つ黄金のお札が図鑑に自動収集されます。\n'
                '• 金運、合格運、心身安定など18種のお札を集めてコレクションを完成させましょう。',
            zh: '• 每次抽取卡牌时，具有独特赋能的黄金符咒将自动收录至图鉴。\n'
                '• 收集财运、考试必胜、万事亨通、心神安宁等全部18种符咒。',
            de: '• Jeder Kartenzug schaltet automatisch goldene Talismane in Ihrem Kodex frei.\n'
                '• Sammeln Sie alle 18 Talismane für Wohlstand, Gesundheit, Seelenruhe und Erfolg.',
            hi: '• प्रत्येक कार्ड ड्रॉ आपके संग्रह में अद्वितीय सुनहरे ताबीज स्वतः जोड़ता है।\n'
                '• धन, सफलता, शांति और स्वास्थ्य के सभी 18 ताबीज एकत्र करें।',
          ),
        ),
        const SizedBox(height: 14),

        // 4. 9+4종 깨비 오락실
        _buildSectionCard(
          icon: '🕹️',
          title: _t(lang,
            ko: '4. 9+4종 깨비 오락실 & 두뇌 챌린지',
            en: '4. 9+4 Arcade & Brain Games',
            ja: '4. 9+4種のクケビゲームセンター',
            zh: '4. 9+4种街机与益智挑战',
            de: '4. 9+4 Arcade- & Denkspiele',
            hi: '4. 9+4 आर्केड और माइंड गेम्स',
          ),
          color: const Color(0xFFB388FF),
          content: _t(lang,
            ko: '• 9종 클래식 아케이드 (슈팅, 동굴탈출, 버블, 벽돌깨기, 정글러너 등)\n'
                '• 4종 보너스 두뇌 게임 (신수 직소 퍼즐, 깨비 스도쿠, 대각선 X-스도쿠, 육각 지뢰찾기, 크로스 마방진)\n'
                '• 하이스코어를 달성하고 깨비 친밀도를 빠르게 올려보세요!',
            en: '• 9 classic arcade games (Shooter, Cave Escape, Bubble, Breakout, Jungle Runner, etc.)\n'
                '• 4 bonus brain puzzles (Jigsaw, Sudoku, X-Sudoku, Hex Mines, Cross Magic Square)\n'
                '• Play without limits and boost Kkaebi affection levels!',
            ja: '• 9種のクラシックゲーム（シューティング、洞窟脱出、バブル、ブロック崩しなど）\n'
                '• 4種のボーナス頭脳パズル（ジグソー、数独、X数独、六角マインスイーパ、魔方陣）\n'
                '• ハイスコアを記録してクケビとの親密度をアップさせましょう！',
            zh: '• 9种经典街机（雷霆射击、地穴逃生、泡泡龙、弹珠消砖块、丛林酷跑等）\n'
                '• 4种益智头脑风暴（神兽拼图、数独、对角线X-数独、六角扫雷、阴阳九宫格）\n'
                '• 挑战最高纪录，快速提升吉鬼亲密度！',
            de: '• 9 klassische Arcade-Spiele (Shooter, Höhlenflucht, Bubble, Breakout, Dschungel-Runner usw.)\n'
                '• 4 Bonus-Denkspiele (Jigsaw-Puzzle, Sudoku, X-Sudoku, Hex-Mines, Magisches Quadrat)\n'
                '• Erzielen Sie Highscores und steigern Sie Kkaebis Zuneigung!',
            hi: '• 9 क्लासिक आर्केड गेम्स (शूटर, केव एस्केप, बबल, ब्रिक-ब्रेकर, जंगल रनर आदि)\n'
                '• 4 माइंड पहेलियाँ (जिगसॉ पहेली, सुडोकू, X-सुडोकू, हेक्स माइनस्वीपर, मैजिक स्क्वायर)\n'
                '• असीमित खेलें और कैबी आत्मीयता स्तर तेजी से बढ़ाएं!',
          ),
        ),
        const SizedBox(height: 14),

        // 5. PRO 멤버십
        _buildSectionCard(
          icon: '👑',
          title: _t(lang,
            ko: '5. DOK-KEY PRO 멤버십 안내',
            en: '5. DOK-KEY PRO Pass',
            ja: '5. DOK-KEY PRO メンバーシップ',
            zh: '5. DOK-KEY 专业版 (PRO) 特权',
            de: '5. DOK-KEY PRO Mitgliedschaft',
            hi: '5. DOK-KEY PRO मेंबरशिप',
          ),
          color: DokkeyTheme.gold,
          content: _t(lang,
            ko: '• 1년 이용권: ${pricing.yearly} / 1년\n'
                '• 평생 소장권: ${pricing.lifetime}\n'
                '• 혜택: 99슬롯 확장, 10년 키 보관, 1일 4뽑기(+3회 추가), 광고 전면 제거, 오락실 전체 무제한 이용',
            en: '• 1-Year Pass: ${pricing.yearly} / Year\n'
                '• Lifetime Pass: ${pricing.lifetime}\n'
                '• Perks: 99 key slots, 10-year storage, +3 daily draws, ad-free, unlimited arcade.',
            ja: '• 1年プラン: ${pricing.yearly} / 年\n'
                '• 永久プラン: ${pricing.lifetime}\n'
                '• 特典: 99スロット拡張、10年保管、1日+3回追加ドロー、広告完全非表示、全ゲーム無制限',
            zh: '• 1年订阅: ${pricing.yearly} / 年\n'
                '• 终身版: ${pricing.lifetime}\n'
                '• 特权: 99格钥匙槽、10年长期保存、每日+3次抽取、全无广告、街机游戏无限畅玩',
            de: '• 1-Jahr-Abo: ${pricing.yearly} / Jahr\n'
                '• Lifetime-Pass: ${pricing.lifetime}\n'
                '• Vorteile: 99 Slots, 10 Jahre Speicherung, +3 tägliche Ziehungen, werbefrei, alle Spiele unbegrenzt',
            hi: '• 1 वर्ष का पास: ${pricing.yearly} / वर्ष\n'
                '• लाइफटाइम पास: ${pricing.lifetime}\n'
                '• लाभ: 99 स्लॉट, 10 वर्ष की स्टोरेज, +3 दैनिक ड्रॉ, विज्ञापन-मुक्त, सभी गेम्स असीमित',
          ),
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

  /// 6개국어 헬퍼 함수
  String _t(
    String lang, {
    required String ko,
    required String en,
    required String ja,
    required String zh,
    required String de,
    required String hi,
  }) {
    switch (lang) {
      case 'ko':
        return ko;
      case 'ja':
        return ja;
      case 'zh':
        return zh;
      case 'de':
        return de;
      case 'hi':
        return hi;
      case 'en':
      default:
        return en;
    }
  }
}
