/// 🌐 시네마틱 타임 랩 (Cinematic Time Lab) 6개국어 번역 사전
/// ko(한국어), en(영어), ja(일본어), zh(중국어), de(독일어), hi(힌디어)
class TimelabI18n {
  TimelabI18n._();

  static String t(
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

  // --- Hub & General ---
  static String timeLabTitle(String lang) => t(lang,
      ko: '시네마틱 타임 랩',
      en: 'Cinematic Time Lab',
      ja: 'シネマティック・タイムラボ',
      zh: '电影级时间实验室',
      de: 'Cinematic Time Lab',
      hi: 'सिनेमैटिक टाइम लैब');

  static String hubHeroDesc(String lang) => t(lang,
      ko: '밀리초 단위의 초정밀 디지털 카운트다운과 9-레인 동시 계측 스톱워치, 택티컬 탭 카운터.\n3대 시네마틱 테마와 SFX 사운드로 시간의 긴장감을 극대화합니다.',
      en: 'Ultra-precise millisecond countdowns, 9-lane grid stopwatch, and tactical tally clicker.\nMaximizing temporal tension with 3 cinematic themes and SFX.',
      ja: 'ミリ秒単位の超精密カウントダウン、9レーン同時計測ストップウォッチ、タクティカルカウンター。\n3大シネマティックテーマとSFXで極限の緊張感を体験。',
      zh: '毫秒级超精确倒计时、9泳道多路秒表及战术计数器。\n融合3大电影级主题与音效，将时间的紧迫感拉满。',
      de: 'Präzise Millisekunden-Countdowns, 9-Bahnen-Stoppuhr und taktischer Klicker.\nMaximale Zeitspannung mit 3 filmreifen Themes und Soundeffekten.',
      hi: 'मिलीसेकंड डिजिटल काउंटडाउन, 9-लेन ग्रिड स्टॉपवॉच और टैक्टिकल टैली क्लिकर।\n3 सिनेमाई थीम और ध्वनि प्रभावों के साथ समय का रोमांच।');

  static String specializedModules(String lang) => t(lang,
      ko: '🔥 타임 랩 전문 모듈',
      en: '🔥 Time Lab Pro Modules',
      ja: '🔥 タイムラボ専門モジュール',
      zh: '🔥 专用时间模块',
      de: '🔥 Time Lab Spezialmodule',
      hi: '🔥 टाइम लैब विशेष मॉड्यूल');

  static String launchModule(String lang) => t(lang,
      ko: '모듈 가동하기',
      en: 'Launch Module',
      ja: 'モジュール起動',
      zh: '启动模块',
      de: 'Modul starten',
      hi: 'मॉड्यूल शुरू करें');

  // --- Module 1: The Defuser ---
  static String module1Title(String lang) => t(lang,
      ko: '3단 시퀀스 체인 타이머',
      en: '3-Phase Sequence Timer',
      ja: '3段階シーケンスタイマー',
      zh: '3段序列连环计时器',
      de: '3-Phasen-Sequenztimer',
      hi: '3-फेज सीक्वेंस टाइमर');

  static String module1Desc(String lang) => t(lang,
      ko: '3-Phase 시퀀스 파이프라인 [타이머 ➔ SFX ➔ 지연 대기 ➔ 다음 타이머]와 1~9회 세트 루프 카운트다운.',
      en: '3-Phase sequence pipeline [Timer ➔ SFX ➔ Delay ➔ Next Timer] with 1-9 set loops.',
      ja: '3段階シーケンスパイプライン【タイマー ➔ 効果音 ➔ 遅延待機 ➔ 次のタイマー】＆ 1〜9回セットループ。',
      zh: '3阶段序列工作流【计时 ➔ 音效 ➔ 延迟等待 ➔ 下一阶段】与1~9组循环倒计时。',
      de: '3-Phasen-Ablauf [Timer ➔ Sound ➔ Verzögerung ➔ Nächster Timer] mit 1-9 Satz-Schleifen.',
      hi: '3-फेज सीक्वेंस पाइपलाइन [टाइमर ➔ SFX ➔ देरी ➔ अगला टाइमर] और 1-9 सेट लूप।');

  static String module1Badge(String lang) => t(lang,
      ko: '밀리초 풀스크린 뷰',
      en: 'Millisecond Fullscreen',
      ja: 'ミリ秒全画面表示',
      zh: '毫秒全屏视图',
      de: 'Millisekunden Vollbild',
      hi: 'मिलीसेकंड फ़ुलस्क्रीन');

  // --- Module 2: The Velocity Grid ---
  static String module2Title(String lang) => t(lang,
      ko: '9-레인 그리드 스톱워치',
      en: '9-Lane Grid Stopwatch',
      ja: '9レーン・グリッドストップウォッチ',
      zh: '9泳道网格秒表',
      de: '9-Bahnen-Grid-Stoppuhr',
      hi: '9-लेन ग्रिड स्टॉपवॉच');

  static String module2Desc(String lang) => t(lang,
      ko: '1~9인 가변형 벤토 그리드. 하단 일괄 START/GO 동시 출발 & 주자 터치 즉시 랭킹/랩타임 Freeze & Lock.',
      en: '1-9 runners Bento grid. Simultaneous START/GO & touch freeze for instant ranking and lap times.',
      ja: '1〜9人可変ベントーグリッド。一括START/GO同時スタート ＆ タッチ即座に順位・ラップタイム固定。',
      zh: '1~9人自适应便当网格。底部一键START/GO全员出发，触碰选手即刻锁定排名与分段用时。',
      de: '1-9 Teilnehmer Bento-Grid. Gleichzeitiger START/GO & Berührung friert Rang und Rundenzeit ein.',
      hi: '1-9 धावक बेंटो ग्रिड। एक साथ START/GO और स्पर्श करते ही रैंकिंग व लैप टाइम लॉक।');

  static String module2Badge(String lang) => t(lang,
      ko: '원터치 랭킹 계측',
      en: 'One-Touch Ranking',
      ja: 'ワンタッチ順位計測',
      zh: '一键排名测速',
      de: 'One-Touch-Rangliste',
      hi: 'वन-टच रैंकिंग');

  // --- Module 3: Tactical Clicker ---
  static String module3Title(String lang) => t(lang,
      ko: '택티컬 탭 카운터',
      en: 'Tactical Tally Clicker',
      ja: 'タクティカル・タップカウンター',
      zh: '战术轻触计数器',
      de: 'Tactical Tally Clicker',
      hi: 'टैक्टिकल टैली क्लिकर');

  static String module3Desc(String lang) => t(lang,
      ko: '화면 어디를 두드려도 반응하는 풀스크린 네온 계수기. 0~99,999 카운트, 목표치(TARGET) 설정 & 10·100단위 마일스톤 피드백.',
      en: 'Fullscreen neon tally clicker reacting anywhere on screen. 0-99,999 count, TARGET goal, and milestone SFX.',
      ja: '画面のどこを叩いても即反応する全画面ネオンカウンター。0〜99,999、目標(TARGET)設定＆マイルストーン通知。',
      zh: '全屏感应式霓虹轻触计数器。0~99,999计数、目标值(TARGET)设定及10/100里程碑音效震动。',
      de: 'Reaktiver Vollbild-Klicker überall auf dem Display. 0-99.999 Zähler, TARGET-Ziele & Meilenstein-Feedback.',
      hi: 'स्क्रीन पर कहीं भी टैप करें। 0-99,999 गिनती, लक्ष्य (TARGET) सेटिंग और मील का पत्थर फीडबैक।');

  static String module3Badge(String lang) => t(lang,
      ko: '초직관 탭 계수기',
      en: 'Intuitive Clicker',
      ja: '直感タップ計数器',
      zh: '超直观轻触计次',
      de: 'Intuitiver Klicker',
      hi: 'अल्ट्रा-आसान क्लिकर');

  // --- Themes ---
  static String themesTitle(String lang) => t(lang,
      ko: '🎨 탑재된 3대 테마 프리셋',
      en: '🎨 3 Cinematic Theme Presets',
      ja: '🎨 搭載された3大テーマプリセット',
      zh: '🎨 内置3大电影级主题',
      de: '🎨 3 Filmreife Theme-Presets',
      hi: '🎨 3 सिनेमाई थीम प्रीसेट');

  static String themeClassic(String lang) => t(lang,
      ko: '클래식 디지털',
      en: 'Classic Digital',
      ja: 'クラシック・デジタル',
      zh: '经典数字液晶',
      de: 'Klassisch Digital',
      hi: 'क्लासिक डिजिटल');

  static String themeClassicDesc(String lang) => t(lang,
      ko: '매트 카본 텍스처 · 7-세그먼트 그린 LCD · 릴레이 틱 SFX',
      en: 'Matte carbon texture · 7-Segment green LCD · Relay tick SFX',
      ja: 'マットカーボン質感 · 7セグメント緑LCD · リレーティックSFX',
      zh: '哑光碳纤维质感 · 7段数码管绿色LCD · 继电器滴答音效',
      de: 'Matte Carbon-Textur · 7-Segment-LCD Grün · Relais-Tick-Sound',
      hi: 'मैट कार्बन टेक्सचर · 7-सेगमेंट हरा LCD · रिले टिक ध्वनि');

  static String themeCyber(String lang) => t(lang,
      ko: '사이버 디퓨저',
      en: 'Cyber Defuser',
      ja: 'サイバー・デフューザー',
      zh: '赛博拆弹雷达',
      de: 'Cyber Defuser',
      hi: 'साइबर डिफ्यूज़र');

  static String themeCyberDesc(String lang) => t(lang,
      ko: '다크 HUD 글래스 · 네온 레드 글리치 · 심장박동음 & 폭발 쉐이크',
      en: 'Dark HUD glass · Neon red glitch · Heartbeat & blast shake',
      ja: 'ダークHUDガラス · ネオンレッドグリッチ · 心拍音＆爆発シェイク',
      zh: '深色HUD高透玻璃 · 霓虹红故障波 · 心跳音与爆炸震颤',
      de: 'Dunkles HUD-Glas · Neon-Rot-Glitch · Herzschlag & Explosions-Shake',
      hi: 'डार्क HUD ग्लास · नियॉन लाल गड़बड़ी · दिल की धड़कन और विस्फोट कंपन');

  static String themeOrbital(String lang) => t(lang,
      ko: '우주 발사',
      en: 'Orbital Launch',
      ja: '軌道ロケット発射',
      zh: '深空轨道发射',
      de: 'Orbital Launch',
      hi: 'कक्षीय प्रक्षेपण');

  static String themeOrbitalDesc(String lang) => t(lang,
      ko: '딥 스페이스 궤도선 · 사이언 블루 · 10초 전 플래시 & 부스터 럼블',
      en: 'Deep space trajectory · Cyan blue · T-10s flash & booster rumble',
      ja: 'ディープスペース軌道 · シアンブルー · 10秒前フラッシュ＆ブースター轟音',
      zh: '深空轨道网格 · 极光青蓝 · T-10秒闪烁与推进器轰鸣',
      de: 'Tiefraum-Orbit · Cyan-Blau · T-10s Flash & Booster-Grollen',
      hi: 'गहरे अंतरिक्ष की कक्षा · सियान नीला · 10 सेकंड पहले फ्लैश और बूस्टर गड़गड़ाहट');

  // --- Clicker Page Controls ---
  static String tapAnywhere(String lang) => t(lang,
      ko: '화면 어디든 탭하여 +1 카운트',
      en: 'Tap anywhere on screen to count +1',
      ja: '画面のどこでもタップして +1 カウント',
      zh: '轻触屏幕任意位置 +1 计数',
      de: 'Überall auf das Display tippen für +1',
      hi: 'स्क्रीन पर कहीं भी टैप करके +1 गिनें');

  static String resetHold(String lang) => t(lang,
      ko: 'RESET (길게)',
      en: 'RESET (Hold)',
      ja: 'リセット (長押し)',
      zh: '重置 (长按)',
      de: 'RESET (Halten)',
      hi: 'रीसेट (दबाए रखें)');

  static String resetting(String lang) => t(lang,
      ko: '초기화 중...',
      en: 'Resetting...',
      ja: 'リセット中...',
      zh: '正在重置...',
      de: 'Wird zurückgesetzt...',
      hi: 'रीसेट हो रहा है...');

  static String resetDone(String lang) => t(lang,
      ko: '🔄 카운터가 0으로 초기화되었습니다.',
      en: '🔄 Counter reset to 0.',
      ja: '🔄 カウンターが0にリセットされました。',
      zh: '🔄 计数已重置为0。',
      de: '🔄 Zähler auf 0 zurückgesetzt.',
      hi: '🔄 काउंटर 0 पर रीसेट हो गया।');

  static String targetSettingTitle(String lang) => t(lang,
      ko: '목표 수치 (Target) 설정',
      en: 'Set Target Goal',
      ja: '目標値 (Target) の設定',
      zh: '设置目标数值 (Target)',
      de: 'Zielwert (Target) festlegen',
      hi: 'लक्ष्य (Target) निर्धारित करें');

  static String targetSettingDesc(String lang) => t(lang,
      ko: '목표 카운트에 도달하면 화려한 시네마틱 피날레와 진동이 울립니다.',
      en: 'When target is reached, cinematic finale sound and vibration trigger.',
      ja: '目標回数に達すると、シネマティックフィナーレ音と振動が発動します。',
      zh: '达成目标计次时将触发华丽的电影级通关音效与震动。',
      de: 'Beim Erreichen des Ziels ertönt ein epischer Sound mit Vibration.',
      hi: 'लक्ष्य पर पहुंचने पर सिनेमाई समापन ध्वनि और कंपन होगा।');

  static String targetHint(String lang) => t(lang,
      ko: '예: 100 (0 입력 시 해제)',
      en: 'e.g. 100 (Enter 0 to clear)',
      ja: '例: 100 (0入力で解除)',
      zh: '例如: 100 (输入0清除目标)',
      de: 'z.B. 100 (0 zum Löschen)',
      hi: 'उदा. 100 (हटाने के लिए 0 दर्ज करें)');

  static String clearTarget(String lang) => t(lang,
      ko: '목표 해제',
      en: 'Clear Target',
      ja: '目標解除',
      zh: '清除目标',
      de: 'Ziel löschen',
      hi: 'लक्ष्य हटाएं');

  static String saveSetting(String lang) => t(lang,
      ko: '설정 완료',
      en: 'Save',
      ja: '完了',
      zh: '保存设定',
      de: 'Speichern',
      hi: 'सहेजें');

  static String selectThemeTitle(String lang) => t(lang,
      ko: '🎨 시네마틱 테마 선택',
      en: '🎨 Select Cinematic Theme',
      ja: '🎨 シネマティックテーマ選択',
      zh: '🎨 选择电影级主题',
      de: '🎨 Cinematic Theme auswählen',
      hi: '🎨 सिनेमाई थीम चुनें');

  // --- Stopwatch Controls & Records ---
  static String runnersCount(String lang, int count) => t(lang,
      ko: '$count인 레인',
      en: '$count Lanes',
      ja: '$countレーン',
      zh: '$count人赛道',
      de: '$count Bahnen',
      hi: '$count लेन');

  static String startAll(String lang) => t(lang,
      ko: 'GO! 동시 출발',
      en: 'START ALL',
      ja: '一斉スタート',
      zh: '全员出发',
      de: 'ALLE STARTEN',
      hi: 'सभी शुरू करें');

  static String finishAll(String lang) => t(lang,
      ko: '전원 완주',
      en: 'ALL FINISHED',
      ja: '全員ゴール',
      zh: '全员完赛',
      de: 'ALLE IM ZIEL',
      hi: 'सभी समाप्त');

  static String saveToVault(String lang) => t(lang,
      ko: '기록 보관함에 저장',
      en: 'Save Record',
      ja: '記録を保存',
      zh: '保存到纪录簿',
      de: 'Ergebnis speichern',
      hi: 'रिकॉर्ड सहेजें');

  static String viewRecords(String lang) => t(lang,
      ko: '기록 보관함',
      en: 'Saved Records',
      ja: '記録一覧',
      zh: '查看纪录',
      de: 'Gespeicherte Rekorde',
      hi: 'सहेजे गए रिकॉर्ड');

  // --- Chain Timer Settings ---
  static String settingsHeader(String lang) => t(lang,
      ko: '시퀀스 체인 & 종료음 설정',
      en: 'Sequence Chain & Sound Settings',
      ja: 'シーケンス連動 ＆ 終了音設定',
      zh: '序列链与结束音效设置',
      de: 'Sequenz-Chain & Sound-Optionen',
      hi: 'सीक्वेंस चेन और ध्वनि सेटिंग्स');

  static String setLoopCount(String lang) => t(lang,
      ko: '세트 루프 반복 횟수',
      en: 'Set Loop Count',
      ja: 'セットループ繰り返し回数',
      zh: '组数循环重复次数',
      de: 'Satz-Wiederholungen',
      hi: 'सेट लूप संख्या');

  static String activeStepsCount(String lang) => t(lang,
      ko: '활성화 단계 수',
      en: 'Active Step Count',
      ja: '有効ステップ数',
      zh: '启用阶段数',
      de: 'Aktive Phasenanzahl',
      hi: 'सक्रिय चरणों की संख्या');

  static String delayAfterStep(String lang) => t(lang,
      ko: '완료 후 지연 대기 (Delay)',
      en: 'Post-Step Delay',
      ja: '完了後の待機遅延 (Delay)',
      zh: '完成后的过渡延迟 (Delay)',
      de: 'Pause danach (Delay)',
      hi: 'चरण के बाद की देरी (Delay)');

  static String pickCustomSound(String lang) => t(lang,
      ko: '내 폰의 음악/음원 선택 (.mp3, .wav)',
      en: 'Pick Audio File (.mp3, .wav)',
      ja: 'スマホの音楽/音源を選択 (.mp3, .wav)',
      zh: '选择手机内的音频文件 (.mp3, .wav)',
      de: 'Eigene Audiodatei (.mp3, .wav)',
      hi: 'ऑडियो फ़ाइल चुनें (.mp3, .wav)');

  static String stepLabel(String lang, int step) => t(lang,
      ko: '$step단계',
      en: 'Phase $step',
      ja: '第$step段階',
      zh: '第$step阶段',
      de: 'Phase $step',
      hi: 'चरण $step');
}
