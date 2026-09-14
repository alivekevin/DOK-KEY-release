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

  static String personShort(String lang, int count) => t(lang,
      ko: '$count인',
      en: '$count',
      ja: '$count人',
      zh: '$count人',
      de: '$count',
      hi: '$count');

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

  // --- Chain Timer Page (런타임 화면) ---
  static String musicPlayingBadge(String lang) => t(lang,
      ko: '🎵 음악 재생 중',
      en: '🎵 Music playing',
      ja: '🎵 音楽再生中',
      zh: '🎵 音乐播放中',
      de: '🎵 Musik läuft',
      hi: '🎵 संगीत चल रहा है');

  static String delayWaitingBadge(String lang) => t(lang,
      ko: '⏸ DELAY 대기',
      en: '⏸ Delay wait',
      ja: '⏸ 遅延待ち',
      zh: '⏸ 延迟等待',
      de: '⏸ Verzögerung',
      hi: '⏸ देरी प्रतीक्षा');

  static String skipLabel(String lang) => t(lang,
      ko: '스킵',
      en: 'Skip',
      ja: 'スキップ',
      zh: '跳过',
      de: 'Skip',
      hi: 'स्किप');

  static String addSetLabel(String lang) => t(lang,
      ko: '+세트',
      en: '+Set',
      ja: '+セット',
      zh: '+组',
      de: '+Satz',
      hi: '+सेट');

  static String musicAutoNext(String lang) => t(lang,
      ko: '음악이 끝난 후 다음 단계로 자동 이동합니다.',
      en: 'Moves to the next step automatically when the music ends.',
      ja: '音楽終了後、次のステップへ自動移動します。',
      zh: '音乐结束后将自动进入下一阶段。',
      de: 'Nach dem Musikende wird automatisch zur nächsten Phase gewechselt.',
      hi: 'संगीत समाप्त होने पर अगले चरण पर स्वतः जाएँ।');

  static String skipToNextLabel(String lang) => t(lang,
      ko: '다음 단계로 즉시 넘어가기 (스킵)',
      en: 'Skip to the next step now',
      ja: '次のステップへ即スキップ',
      zh: '立即跳到下一阶段',
      de: 'Sofort zur nächsten Phase',
      hi: 'अभी अगले चरण पर जाएँ');

  static String pipelineTitle(String lang) => t(lang,
      ko: '3-Phase 시퀀스 체인 파이프라인',
      en: '3-Phase Sequence Pipeline',
      ja: '3段階シーケンスチェーンパイプライン',
      zh: '3阶段序列工作流',
      de: '3-Phasen-Sequenz-Pipeline',
      hi: '3-फेज सीक्वेंस पाइपलाइन');

  static String phaseUnit(String lang, int count) => t(lang,
      ko: '$count단',
      en: '$count-Phase',
      ja: '$count段階',
      zh: '$count段',
      de: '$count Phasen',
      hi: '$count-फेज');

  static String stepItemLabel(String lang, int n) => t(lang,
      ko: '단계 $n',
      en: 'Phase $n',
      ja: 'ステップ$n',
      zh: '阶段$n',
      de: 'Phase $n',
      hi: 'फेज $n');

  static String secondsShort(String lang, int s) => t(lang,
      ko: '${s}초',
      en: '${s}s',
      ja: '${s}秒',
      zh: '${s}秒',
      de: '${s}s',
      hi: '${s} सेकंड');

  static String waitShort(String lang, int s) => t(lang,
      ko: '+${s}s 대기',
      en: '+${s}s wait',
      ja: '+${s}s待機',
      zh: '+${s}s等待',
      de: '+${s}s Pause',
      hi: '+${s}s प्रतीक्षा');

  static String durationEditTitle(String lang, int n) => t(lang,
      ko: '⏱️ 단계 $n 시간 & 지연(Delay) 설정',
      en: '⏱️ Phase $n — Duration & Delay',
      ja: '⏱️ 第$n段階 時間＆遅延設定',
      zh: '⏱️ 第$n阶段 时间与延迟设置',
      de: '⏱️ Phase $n — Dauer & Verzögerung',
      hi: '⏱️ चरण $n — समय और देरी सेटिंग');

  static String timerDurationLabel(String lang) => t(lang,
      ko: '타이머 시간',
      en: 'Timer duration',
      ja: 'タイマー時間',
      zh: '计时器时长',
      de: 'Timer-Dauer',
      hi: 'टाइमर अवधि');

  static String saveDoneLabel(String lang) => t(lang,
      ko: '저장 완료',
      en: 'Done',
      ja: '保存完了',
      zh: '保存完成',
      de: 'Fertig',
      hi: 'पूर्ण');

  static String resetLabel(String lang) => t(lang,
      ko: '리셋',
      en: 'Reset',
      ja: 'リセット',
      zh: '重置',
      de: 'Zurücksetzen',
      hi: 'रीसेट');

  static String pauseLabel(String lang) => t(lang,
      ko: '일시 정지',
      en: 'Pause',
      ja: '一時停止',
      zh: '暂停',
      de: 'Pause',
      hi: 'रोकें');

  static String pauseAllLabel(String lang) => t(lang,
      ko: '일괄 일시정지',
      en: 'Pause All',
      ja: '一斉一時停止',
      zh: '全部暂停',
      de: 'Alles pausieren',
      hi: 'सभी रोकें');

  static String resumeLabel(String lang) => t(lang,
      ko: '이어하기',
      en: 'Resume',
      ja: '再開',
      zh: '继续',
      de: 'Fortsetzen',
      hi: 'जारी रखें');

  static String startSequenceLabel(String lang) => t(lang,
      ko: '시퀀스 시작',
      en: 'Start Sequence',
      ja: 'シーケンス開始',
      zh: '开始序列',
      de: 'Sequenz starten',
      hi: 'सीक्वेंस शुरू करें');

  // --- Chain Timer Settings Page ---
  static String settingsFlowTitle(String lang) => t(lang,
      ko: '3-Phase 시네마틱 체인 플로우',
      en: '3-Phase Cinematic Chain Flow',
      ja: '3段階シネマティックチェーンフロー',
      zh: '3阶段电影级链式流程',
      de: '3-Phasen-Cinematic-Flow',
      hi: '3-फेज सिनेमाई चेन फ़्लो');

  static String settingsDescPro(String lang) => t(lang,
      ko: '각 단계별 타이머 시간, 내 폰의 음악/효과음, 완료 후 지연시간(Delay)을 완벽하게 커스텀 설정할 수 있습니다.',
      en: 'Fully customize each step duration, your own music/SFX, and post-completion delays.',
      ja: 'ステップごとの時間、スマホ内の音楽/効果音、完了後の遅延時間を完全にカスタム設定できます。',
      zh: '可完全自定义每阶段的时长、手机内音乐/音效及完成后的延迟时间。',
      de: 'Dauer, eigene Musik/SFX und Verzögerung jeder Phase frei konfigurierbar.',
      hi: 'हर चरण की अवधि, अपना संगीत/SFX और समापन के बाद की देरी पूरी तरह कस्टमाइज़ करें।');

  static String settingsDescFree(String lang) => t(lang,
      ko: '무료 티어는 1단계 타이머를 이용할 수 있습니다. 2~3단계 커스텀 체인 및 내 폰 사운드 지정은 PRO 전용입니다 👑',
      en: 'The free tier offers a single-phase timer. 2-3 phase custom chains & custom sounds are PRO-only 👑',
      ja: '無料プランでは1段階タイマーのみ。2〜3段階チェーン＆カスタムサウンドはPRO限定です 👑',
      zh: '免费版仅提供单阶段计时器。2~3阶段自定义链与自定义音效为PRO专享 👑',
      de: 'Die Gratis-Version bietet einen Ein-Phasen-Timer. 2-3 Phasen & eigene Sounds sind PRO-only 👑',
      hi: 'फ्री टियर में सिंगल-फेज टाइमर। 2-3 फेज चेन और कस्टम साउंड केवल PRO 👑');

  static String chainStepCountLabel(String lang) => t(lang,
      ko: '체인 단계 수',
      en: 'Chain Step Count',
      ja: 'チェーン段階数',
      zh: '链式阶段数',
      de: 'Chain-Phasenanzahl',
      hi: 'चेन चरण संख्या');

  static String setRepeatTitle(String lang) => t(lang,
      ko: '세트 완주 반복 횟수',
      en: 'Set Loop Repetitions',
      ja: 'セット完走リピート回数',
      zh: '组循环重复次数',
      de: 'Satz-Wiederholungen',
      hi: 'सेट लूप दोहराव');

  static String setRepeatDesc(String lang) => t(lang,
      ko: '1~9회 세트 루프 지원',
      en: 'Supports 1-9 set loops',
      ja: '1〜9回セットループ対応',
      zh: '支持1~9组循环',
      de: 'Unterstützt 1-9 Satz-Schleifen',
      hi: '1-9 सेट लूप समर्थन');

  static String setsCount(String lang, int n) => t(lang,
      ko: '$n 세트',
      en: '$n Sets',
      ja: '$nセット',
      zh: '$n组',
      de: '$n Sätze',
      hi: '$n सेट');

  static String saveAndReturnLabel(String lang) => t(lang,
      ko: '설정 완료 및 타이머로 돌아가기',
      en: 'Save & Return to Timer',
      ja: '設定を保存してタイマーへ戻る',
      zh: '保存并返回计时器',
      de: 'Speichern & zum Timer zurück',
      hi: 'सहेजें और टाइमर पर जाएँ');

  static String statusActive(String lang) => t(lang,
      ko: '가동 중',
      en: 'Active',
      ja: '稼働中',
      zh: '启用中',
      de: 'Aktiv',
      hi: 'सक्रिय');

  static String statusInactive(String lang) => t(lang,
      ko: '비활성',
      en: 'Inactive',
      ja: '非稼働',
      zh: '未启用',
      de: 'Inaktiv',
      hi: 'निष्क्रिय');

  static String proOnlyBadge(String lang) => t(lang,
      ko: '👑 PRO 전용',
      en: '👑 PRO Only',
      ja: '👑 PRO限定',
      zh: '👑 PRO专享',
      de: '👑 Nur PRO',
      hi: '👑 केवल PRO');

  static String endSoundLabel(String lang) => t(lang,
      ko: '종료 시 효과음',
      en: 'Completion SFX',
      ja: '終了時効果音',
      zh: '结束音效',
      de: 'Abschluss-Sound',
      hi: 'समापन ध्वनि');

  static String previewSfxTooltip(String lang) => t(lang,
      ko: '효과음 미리듣기',
      en: 'Preview sound',
      ja: '効果音プレビュー',
      zh: '试听音效',
      de: 'Sound anhören',
      hi: 'ध्वनि पूर्वावलोकन');

  static String soundPickerTitle(String lang, int n) => t(lang,
      ko: '🔊 단계 $n 종료 효과음 선택',
      en: '🔊 Phase $n Completion SFX',
      ja: '🔊 第$n段階 終了音選択',
      zh: '🔊 第$n阶段 结束音效选择',
      de: '🔊 Phase $n Abschluss-Sound',
      hi: '🔊 चरण $n समापन ध्वनि चुनें');

  static String currentlyRegistered(String lang, String name) => t(lang,
      ko: '현재 등록: 📁 $name',
      en: 'Current: 📁 $name',
      ja: '現在登録: 📁 $name',
      zh: '当前注册: 📁 $name',
      de: 'Aktuell: 📁 $name',
      hi: 'वर्तमान: 📁 $name');

  static String builtinPackTitle(String lang) => t(lang,
      ko: '⚡ 시네마틱 내장 사운드 팩',
      en: '⚡ Built-in Cinematic SFX Pack',
      ja: '⚡ 内蔵シネマティックサウンドパック',
      zh: '⚡ 内置电影级音效包',
      de: '⚡ Eingebaute SFX-Pakete',
      hi: '⚡ अंतर्निहित सिनेमाई ध्वनि पैक');

  static String audioLoadedToast(String lang, String name) => t(lang,
      ko: '🎵 "$name" 오디오 등록 및 로드 완료!',
      en: '🎵 "$name" audio registered & loaded!',
      ja: '🎵「$name」オーディオ登録完了！',
      zh: '🎵 已注册并加载音频「$name」！',
      de: '🎵 "$name" registriert & geladen!',
      hi: '🎵 "$name" ऑडियो पंजीकृत और लोड!');

  // --- Preset Sound Names (모델 & 설정 공용) ---
  static String soundDefault(String lang) => t(lang,
      ko: '⚡ 테마 기본 사운드',
      en: '⚡ Theme default SFX',
      ja: '⚡ テーマ基本効果音',
      zh: '⚡ 主题默认音效',
      de: '⚡ Theme-Standard-Sound',
      hi: '⚡ थीम डिफ़ॉल्ट ध्वनि');

  static String soundGate(String lang) => t(lang,
      ko: '🚪 묵직한 철문 개방',
      en: '🚪 Heavy iron gate',
      ja: '🚪 重厚な鉄門開放',
      zh: '🚪 沉重的铁门开启',
      de: '🚪 Schweres Eisentor',
      hi: '🚪 भारी लोहे का द्वार');

  static String soundBlast(String lang) => t(lang,
      ko: '💥 시한폭탄 대폭발',
      en: '💥 Time bomb blast',
      ja: '💥 時限爆弾大爆発',
      zh: '💥 定时炸弹大爆炸',
      de: '💥 Bombenexplosion',
      hi: '💥 बम विस्फोट');

  static String soundBuzzer(String lang) => t(lang,
      ko: '🏁 레이싱 출발 부저',
      en: '🏁 Racing start buzzer',
      ja: '🏁 レーススタートブザー',
      zh: '🏁 赛车出发蜂鸣',
      de: '🏁 Rennstart-Buzzer',
      hi: '🏁 रेस स्टार्ट बज़र');

  static String soundBeep(String lang) => t(lang,
      ko: '📡 관제탑 비프음',
      en: '📡 Control tower beep',
      ja: '📡 管制塔ビープ音',
      zh: '📡 塔台提示音',
      de: '📡 Tower-Beep',
      hi: '📡 नियंत्रण मीनार बीप');

  static String soundGong(String lang) => t(lang,
      ko: '🔔 황금 징 피날레',
      en: '🔔 Golden gong finale',
      ja: '🔔 黄金ゴングフィナーレ',
      zh: '🔔 黄金铜锣终曲',
      de: '🔔 Goldenes Gong-Finale',
      hi: '🔔 स्वर्ण गॉन्ग समापन');

  static String soundMagic(String lang) => t(lang,
      ko: '🪄 도깨비 방망이 마법',
      en: '🪄 Kkaebi magic bat',
      ja: '🪄 トッケビの魔法の棒',
      zh: '🪄 小妖魔棒魔法',
      de: '🪄 Goblin-Zauberkeule',
      hi: '🪄 क्काएबी जादुई छड़ी');

  // --- Velocity Grid Page & Records ---
  static String runnerName(String lang, int n) => t(lang,
      ko: '주자 $n',
      en: 'Runner $n',
      ja: 'ランナー$n',
      zh: '选手$n',
      de: 'Läufer $n',
      hi: 'धावक $n');

  static String defaultRecordTitle(String lang, int lanes) => t(lang,
      ko: '스톱워치 기록 ($lanes인)',
      en: 'Stopwatch Record ($lanes)',
      ja: 'ストップウォッチ記録 ($lanes人)',
      zh: '秒表记录 ($lanes人)',
      de: 'Stoppuhr-Rekord ($lanes)',
      hi: 'स्टॉपवॉच रिकॉर्ड ($lanes)');

  static String touchToFinish(String lang) => t(lang,
      ko: '터치하여 완주',
      en: 'Tap to finish',
      ja: 'タップでゴール',
      zh: '点按完赛',
      de: 'Zum Zielen tippen',
      hi: 'फ़िनिश के लिए टैप करें');

  static String waitingLabel(String lang) => t(lang,
      ko: '대기 중',
      en: 'Waiting',
      ja: '待機中',
      zh: '等待中',
      de: 'Warten',
      hi: 'प्रतीक्षा');

  static String startGoLabel(String lang) => t(lang,
      ko: 'START / GO (동시 출발)',
      en: 'START / GO',
      ja: 'START/GO（一斉スタート）',
      zh: 'START/GO（全员出发）',
      de: 'START / GO',
      hi: 'START/GO (एक साथ)');

  static String recordTitlePrompt(String lang) => t(lang,
      ko: '기록의 제목을 입력해 주세요:',
      en: 'Enter a record title:',
      ja: '記録のタイトルを入力してください:',
      zh: '请输入记录标题：',
      de: 'Titel des Rekords eingeben:',
      hi: 'रिकॉर्ड शीर्षक दर्ज करें:');

  static String recordTitleHint(String lang) => t(lang,
      ko: '예: 50m 달리기 결승전',
      en: 'e.g. 50m sprint final',
      ja: '例: 50m走決勝',
      zh: '例如: 50米跑决赛',
      de: 'z.B. 50m-Sprintfinale',
      hi: 'उदा. 50 मी दौड़ फ़ाइनल');

  static String cancelLabel(String lang) => t(lang,
      ko: '취소',
      en: 'Cancel',
      ja: 'キャンセル',
      zh: '取消',
      de: 'Abbrechen',
      hi: 'रद्द करें');

  static String recordSavedToast(String lang, String title) => t(lang,
      ko: '✅ "$title" 기록이 보관함에 안전하게 저장되었습니다!',
      en: '✅ "$title" saved safely to the vault!',
      ja: '✅「$title」記録を安全に保存しました！',
      zh: '✅ 已将「$title」安全保存到纪录簿！',
      de: '✅ "$title" sicher gespeichert!',
      hi: '✅ "$title" सुरक्षित रूप से सहेजा गया!');

  static String saveRecordLabel(String lang) => t(lang,
      ko: '저장하기',
      en: 'Save',
      ja: '保存する',
      zh: '保存',
      de: 'Speichern',
      hi: 'सहेजें');

  static String allFinishedTitle(String lang) => t(lang,
      ko: '전원 완주! 공식 기록표',
      en: 'All Finished! Official Results',
      ja: '全員ゴール！公式記録表',
      zh: '全员完赛！官方成绩表',
      de: 'Alle im Ziel! Offizielle Ergebnisse',
      hi: 'सभी समाप्त! आधिकारिक परिणाम');

  static String remeasureLabel(String lang) => t(lang,
      ko: '다시 측정',
      en: 'Measure Again',
      ja: '再計測',
      zh: '重新测量',
      de: 'Neu messen',
      hi: 'फिर से मापें');

  static String closeLabel(String lang) => t(lang,
      ko: '닫기',
      en: 'Close',
      ja: '閉じる',
      zh: '关闭',
      de: 'Schließen',
      hi: 'बंद करें');

  /// 순위 라벨 (1~3위는 메달 이모지 포함, 언어별 서수)
  static String rankLabel(String lang, int rank) {
    final medal = rank == 1 ? '🥇' : (rank == 2 ? '🥈' : (rank == 3 ? '🥉' : null));
    final ordinal = t(lang,
      ko: '$rank위',
      en: rank == 1 ? '1st' : (rank == 2 ? '2nd' : (rank == 3 ? '3rd' : '#$rank')),
      ja: '$rank位',
      zh: '第$rank名',
      de: '$rank.',
      hi: '#$rank');
    return medal != null ? '$medal $ordinal' : ordinal;
  }

  static String emptyRecords(String lang) => t(lang,
      ko: '저장된 기록이 없습니다',
      en: 'No saved records yet',
      ja: '保存された記録はありません',
      zh: '暂无保存的记录',
      de: 'Noch keine gespeicherten Rekorde',
      hi: 'अभी कोई रिकॉर्ड नहीं');

  static String emptyRecordsDesc(String lang) => t(lang,
      ko: '스톱워치 완주 후 [기록 저장]을 누르면\n이곳에 영구 보관됩니다.',
      en: 'Finish a race and tap [Save Record]\nto keep it here permanently.',
      ja: 'レース終了後【記録を保存】をタップすると\nここに永久保存されます。',
      zh: '比赛结束后点击【保存记录】\n即可永久保存在这里。',
      de: 'Nach dem Ziel [Ergebnis speichern] tippen,\num dauerhaft zu sichern.',
      hi: 'रेस पूरा कर [रिकॉर्ड सहेजें] दबाएँ,\nयहाँ स्थायी रूप से सहेजा जाएगा।');

  static String deleteRecordTitle(String lang) => t(lang,
      ko: '기록 삭제',
      en: 'Delete Record',
      ja: '記録を削除',
      zh: '删除记录',
      de: 'Rekord löschen',
      hi: 'रिकॉर्ड हटाएं');

  static String deleteRecordConfirm(String lang) => t(lang,
      ko: '이 스톱워치 기록을 완전히 삭제하시겠습니까?',
      en: 'Permanently delete this stopwatch record?',
      ja: 'このストップウォッチ記録を完全に削除しますか？',
      zh: '确定要彻底删除这条秒表记录吗？',
      de: 'Diesen Stoppuhr-Rekord endgültig löschen?',
      hi: 'क्या यह स्टॉपवॉच रिकॉर्ड हमेशा के लिए हटाएं?');

  static String deleteLabel(String lang) => t(lang,
      ko: '삭제',
      en: 'Delete',
      ja: '削除',
      zh: '删除',
      de: 'Löschen',
      hi: 'हटाएं');

  static String shareTooltip(String lang) => t(lang,
      ko: '공유하기',
      en: 'Share',
      ja: '共有',
      zh: '分享',
      de: 'Teilen',
      hi: 'साझा करें');

  static String shareHeader(String lang) => t(lang,
      ko: '⏱️ [DOK-KEY] 스톱워치 공식 기록표',
      en: '⏱️ [DOK-KEY] Official Stopwatch Results',
      ja: '⏱️【DOK-KEY】ストップウォッチ公式記録',
      zh: '⏱️【DOK-KEY】秒表官方成绩表',
      de: '⏱️ [DOK-KEY] Offizielle Stoppuhr-Ergebnisse',
      hi: '⏱️ [DOK-KEY] आधिकारिक स्टॉपवॉच परिणाम');

  static String shareFooter(String lang) => t(lang,
      ko: '🔥 DOK-KEY 시네마틱 타임 랩에서 측정됨',
      en: '🔥 Measured with DOK-KEY Cinematic Time Lab',
      ja: '🔥 DOK-KEYシネマティック・タイムラボで計測',
      zh: '🔥 由DOK-KEY电影级时间实验室测量',
      de: '🔥 Gemessen mit DOK-KEY Cinematic Time Lab',
      hi: '🔥 DOK-KEY सिनेमाई टाइम लैब द्वारा मापा गया');
}
