# DOK-KEY 슬로건·정체성 대개편 마스터 기획서

* **문서 버전**: v4.7.0 (Wisdom-First Rebrand Blueprint)
* **작성일**: 2026-09-06
* **구현 상태**: **As-Built Complete (P1~P4 전 단계 구현·검증 완료)** — `flutter analyze` 0/0, 테스트 **60/60 통과**(재편 신규 7종 포함), Web·APK(66.4MB) 릴리즈 빌드 성공, 6개국어 무결성 ALL PASSED
* **성격**: 앱 + 웹 전역에 적용되는 브랜드 정체성·정보구조(IA)·콘텐츠 위계 재편 기획
* **선행 문서**: v4.6.0 종합 구현 기획서 및 로드맵 (`docs/DOKKEY_v4_6_0_IMPLEMENTATION_AND_NEXT_ROADMAP.md`)
* **배포 대상**: `C:\Works\DOK-KEY` (개발) / `C:\Works\DOK-KEY-release` (릴리즈·웹 랜딩)

### 0.0 As-Built 구현 기록 (Implementation Record)

| Phase | 구현 내역 | 상태 |
| :--- | :--- | :--- |
| **P1 슬로건·코어** | `assets/data/common/brand_slogans.json`(6개국어 메인/서브/목적/OG/웹히어로), `core/brand_config.dart`(WisdomFirstConfig 플래그 포함), `core/daily_quote_engine.dart`(결정론 선정+14일 중복 방지+시간대/감정 보정), 스플래시·main 타이틀·설정·시네마틱(A5)·대화방(A7) 슬로건 교체 | ✅ |
| **P2 홈 IA** | `widgets/quote_hero_section.dart` 신설(명언+3D 턴테이블 깨비+감정 FX+깨비의 한마디 말풍선+저장/부적 공유), 홈 5단계 재배치(히어로→수수께끼→운세 축소→도감 3줄 진행바→연성소), 상단 스트릭·친밀도 유지, 3개국어 순환 토글을 **6개국어 선택 시트**로 교체 | ✅ |
| **P3 명언 DB v2** | quotes.json 스키마 확장(author/source/theme/emotion/time_slot/kkaebi_comment) + **고전 인용 명언 50종 추가 = 150종 × 6개국어**(노자·공자·맹자·손자·이순신·허난설헌·세네카·마르쿠스 아우렐리우스·괴테·니체·탈무드·헬렌 켈러 등 공적 영역), 깨비의 한마디 150×6 작성, FX 감정 바인딩 | ✅ |
| **P4 웹·공유·위젯** | release `index.html` 랜딩 전면 개편(타이틀/OG/히어로/섹션 위계), **`share/index.html` 명언 공유 뷰어 신설**(quote_id+lang 파라미터, OG 갱신, 앱 CTA), 명언 부적 포스터(`quote_poster_dialog.dart` 9:16 황금 부적), **안드로이드 홈 위젯**(home_widget + Kotlin `KkaebiQuoteWidgetProvider` + 4×2 레이아웃 + 딥링크 + 매니페스트 등록) | ✅ |
| **검증** | `test/rebrand_test.dart` 7종(슬로건 6개국어 일치·금지어 0건·엔진 결정론·14일 중복 방지·FX 매핑·IA 순서·6언어 시트), 무결성 150종×6 패리티 확장, content_quality_check NO ISSUES | ✅ 60/60 |

* **롤백**: `_backups/backup_20260906_232125_pre_slogan_rebrand/` + `WisdomFirstConfig.enabled=false` 이중 안전망 유지.

---

## 0. 백업 및 롤백 전략 (Rollback Safety)

### 0.1 생성된 백업 지점 (완료)

| 항목 | 값 |
| :--- | :--- |
| 백업 경로 | `C:\Works\DOK-KEY\_backups\backup_20260906_232125_pre_slogan_rebrand\` |
| 백업 범위 | `lib/` 전체, `test/` 전체, `pubspec.yaml`, `assets/data/` (48개 JSON), `docs/` 전체 |
| 용량 | 약 1.5 MB |
| 생성 시점 | 슬로건 개편 작업 개시 직전 (v4.6.0 As-Built 상태, 테스트 53/53 통과점) |

### 0.2 롤백 절차 (언제든 1분 내 복구)

```text
1. 작업 중단 → flutter analyze/test가 깨진 상태라도 무시
2. XCopy 복구:
   robocopy "_backups\backup_20260906_232125_pre_slogan_rebrand\lib" "dokkey_app\lib" /MIR
   copy /Y "_backups\backup_20260906_232125_pre_slogan_rebrand\pubspec.yaml" "dokkey_app\pubspec.yaml"
   robocopy "_backups\backup_20260906_232125_pre_slogan_rebrand\assets_data" "dokkey_app\assets\data" /MIR
3. flutter clean && flutter pub get && flutter test  (53/53 복구 확인)
4. 필요 시 release 저장소도 동일 절차로 복구
```

### 0.3 단계별 세이프가드

* 각 Phase 종료 시점마다 `_backups\backup_<ts>_phase<N>_done` 스냅샷 추가 생성.
* 신규 IA는 `WisdomFirstConfig.enabled` (core/brand_config.dart, 기본 true) 런타임 플래그로 감싸서,
  롤백 시 플래그 false 한 줄로 기존 운세 중심 홈으로 즉시 복귀 가능하게 설계.

---

## 1. 개편 배경 및 브랜드 정체성 (From Fortune to Wisdom)

* **기존 정체성**: "오늘 하루를 여는 단 하나의 열쇠" — 운세 드로우가 최상단, 명언은 홈 하단 티커.
* **개편 정체성**: **"매일 아침 깨비가 건네는 한 줄의 지혜로 하루를 여는 멘탈 웰니스 & 지혜 플랫폼"**
* 전략 근거:
  1. 점술 앱은 호불호/스토어 심사 리스크가 있으나, 명언·격언 중심은 전 연령·글로벌 거부감 없이 '데일리 힐링/자기계발'로 포지셔닝.
  2. 명언은 **위젯·SNS 공유에 가장 강한 콘텐츠** (한 줄이 완결되는 콘텐츠).
  3. 기존 자산(운세·수수께끼·도감·숫자)은 그대로 유지하되 **명언의 맥락 속 부속 콘텐츠**로 재배치 → 기존 유저 이탈 없이 확장.

---

## 2. 글로벌 슬로건 체계 (6개국어)

### 2.1 슬로건 정의

| 구분 | KO | EN | JA | ZH | HI | DE |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **메인** | 어둠을 밝히는 도깨비불처럼, 매일 마음에 켜지는 한 줄의 지혜 | Illuminating your day with Kkaebi's Wisdom & Daily Words | 心に灯す一言の知恵、クケビが届ける今日の言葉 | 如照亮黑夜的 도깨비불，每天点亮心间的一句智慧 | अंधकार रोशन करने वाली धीमी लौ की तरह, रोज़ दिल में जगने वाली ज्ञान की एक पंक्ति | Wie ein Koboldfeuer in der Nacht — ein Weisheitswort, das täglich dein Herz erleuchtet |
| **서브** | 3D 깨비가 건네는 오늘의 명언 · 수수께끼 · 인생 운세 | Kkaebi's daily quotes, riddles & life fortune | クケビが届ける今日の名言・なぞなぞ・人生運勢 | 3D 도깨비불 送来的今日名言・谜题・人生运势 | 3D 도깨비불 की देन: आज का सुवचन, पहेली और जीवन भविष्यवाणी | 3D-Kkaebis tägliche Weisheit, Rätsel & Lebensweissagung |

* 슬로건 데이터는 신규 `assets/data/common/brand_slogans.json`(6개국어)으로 분리 — 코드 하드코딩 금지.

### 2.2 슬로건 적용 지점 매트릭스 (파일 레벨)

| # | 적용 지점 | 파일 | 기존 문구 | 신규 문구 |
| :--- | :--- | :--- | :--- | :--- |
| A1 | 스플래시 슬로건 | `lib/screens/splash_screen.dart` | 오늘 하루를 여는 단 하나의 열쇠 | **메인 슬로건** + 서브 슬로건 2줄 구성 |
| A2 | 홈 히어로 섹션 (신설) | `lib/screens/home_screen.dart` | (운세 드로우가 최상단) | **명언 히어로가 최상단**, 드로우는 3순위로 이동 |
| A3 | 홈 앱바 부제 | `lib/screens/home_screen.dart` | DOK-KEY 로고만 | 로고 옆 Lv.친밀도 배지 + 명언 아이콘 |
| A4 | 앱 타이틀 | `lib/main.dart` + `pubspec.yaml` | DOK-KEY - Global Daily Fortune | DOK-KEY — Daily Wisdom with Kkaebi |
| A5 | 시네마틱 드로우 부제 | `lib/widgets/draw_cinematic_dialog.dart` | 운세의 문이 열렸습니다 | "오늘의 명언이 고른 카드입니다" (명언-운세 연결 서사) |
| A6 | 공유 포스터 헤더 | `lib/widgets/share_card_dialog.dart` | DOK-KEY 데일리 운세 | 황금 명언 부적 카드 (템플릿 3종 재활용) |
| A7 | 대화방 웰컴 | `lib/screens/kkaebi_chat_screen.dart` | 깨비 인사 | 명언 한 줄 + 깨비의 한마디로 시작 |
| A8 | 설정 앱 정보 | `lib/widgets/settings_dialog.dart` | Zero-Login Architecture | 슬로건 1줄 + 앱 목적 설명 |
| A9 | Pro 패스 부제 | `lib/widgets/pro_pass_dialog.dart` | 프리미엄 기능 나열 | "지혜의 여정을 10년 안심하고 걷는 패스" |
| A10 | 위젯(신규 5순위) | Android HomeWidget | — | 명언 한 줄 + 깨비 표정 (§6) |
| W1 | 웹 랜딩 타이틀/OG | `DOK-KEY-release/index.html` | 오늘 하루를 여는 단 하나의 열쇠 | 메인 슬로건 + OG 재작성 (§7) |
| W2 | 웹 랜딩 히어로 문구 | `index.html` hero 섹션 | 1-Draw 데일리 운세 드로우 | "하루 한 줄, 나를 바꾸는 도깨비 명언" |
| W3 | 공유 뷰어 (신설) | `DOK-KEY-release/share/index.html` | 없음 | `/share?quote_id=xxx` 명언 카드 렌더러 |
| W4 | 스토어 등록 정보 | 스토어 콘솔 | 운세 앱 설명 | 지혜·힐링 중심 설명문 (§2.1 재활용) |

---

## 3. 홈 화면 IA 5단계 재배치 (App Information Architecture)

### 3.1 신규 홈 골격 (운세 → 명언 최상단 전환)

```text
[상단바] DOK-KEY 로고 | 💖 Lv.3 친밀한 깨비 | [🧭 캘린더] [🔔] [⚙️]
──────────────────────────────────────────────────────────────
1순위  📜 HERO : 오늘의 명언 카드 (신규 QuoteHeroSection)
       ├ 명언 본문 (큰 타이포) + 출처/저자
       ├ 3D 턴테이블 깨비 (kkaebi_3d_mascot_widget 재사용) + 깨비의 한마디 말풍선
       ├ 감정 매칭: 명언 톤 → 깨비 표정/풀스크린 FX 자동 연출
       └ [🎧 음성 듣기] [💖 마음에 저장] [📤 부적 카드 공유]
2순위  🧩 오늘의 수수께끼 카드 (기존 RiddleDialog 진입 배너 상향, 정답 시 명언 해설 연결)
3순위  🔮 오늘의 운세 (기존 드로우 오브를 "명언의 흐름 확인" 카드로 축소 재배치)
4순위  📖 도감 현황 (33 신수 / 33 신격 / 33 커스텀 진행바 3줄)
5순위  🔢 행운 숫자 연성소 + 조합 보관함 진입 (기존 KeyBox 배너 하단 이동)
[하단] 명언 아카이브 미니 티커 (어제의 명언 회상) — 기존 명언 티커 승격
+ 우하단 FAB 플로팅 깨비 (유지) + 좌상단 회전 홈 버튼 (유지)
```

### 3.2 이동·재배치 지도 (기존 코드 → 신규 위치)

| 기존 요소 | 기존 위치 | 신규 위치 | 비고 |
| :--- | :--- | :--- | :--- |
| 열쇠 드로우 오브(버튼) | 홈 최상단 중앙 | 3순위 카드 내부 (축소 버전) | `DrawOrb` 위젯화 후 재배치 |
| 명언 티커 | 홈 최하단 | 1순위 히어로로 승격 | `QuoteHeroSection` 신규 위젯 |
| 수수께끼 배너 | 홈 중단 | 2순위 (히어로 바로 아래) | 정답 시 명언 해설 + 숫자 드롭 |
| 도감 배너 | 홈 중단 | 4순위 (진행바 3줄로 축소) | CodexService 수치 연동 |
| KeyBox/연성 배너 | 홈 중단 | 5순위 | 무료 9/99 슬롯 상태 표시 병행 |
| 친밀도 배지 | 대화방만 | 상단바 상시 노출 | KkaebiAffectionEngine 연동 |
| 시즌 파티클 | 전역 배경 | 히어로 섹션 밀도 강화 | SeasonalParticles 재사용 |

---

## 4. 명언 데이터 아키텍처 (Quote Engine v2)

### 4.1 `quotes.json` 스키마 v2 확장

```json
{
  "id": "quo_001",
  "text": { "ko": "...", "en": "...", "ja": "...", "zh": "...", "hi": "...", "de": "..." },
  "author": "도종환",
  "source": "<흔들리며 피는 꽃>",
  "theme": "growth",                 // growth | comfort | challenge | gratitude | zen | fortune
  "emotion": "calm",                 // 8대 감정 매핑 (ScreenEmotionFxOverlay 연동)
  "time_slot": ["morning", "night"], // 적합 시간대
  "kkaebi_comment": { "ko": "오늘 힘든 일이 있어도 다 피어나기 위함이야!", "...": "..." },
  "voice_script": "hueon-ji-eum-hwa", // TTS용 발음 스크립트(후속)
  "tone_tags": ["calm"]
}
```

* 기존 100종(v4.6.0 검증 완료)은 그대로 승계하되, 신규 필드(author/theme/emotion/kkaebi_comment)를 6개국어로 확충 → **최종 365일 로테이션 커버**(Phase 2에서 인용 명언 365종으로 확장).

### 4.2 데일리 명언 선정 엔진 (`core/daily_quote_engine.dart` 신규)

```text
quote_seed = sha256(userUuid:today:theme_rotation:visits)
1) theme_rotation: 성장→위로→도전→감사→명상 순으로 요일 기반 순환
2) 시간대 보정: time_slot에 현재 시간대가 포함된 명언 우선
3) 감정 보정: 어제 대화/운세 톤이 낮으면 comfort 테마 가중치 ×2 (친밀도 Lv.3↑ 가중치 추가)
4) 중복 방지: 최근 14일 노출 이력 제외 후 결정론적 선택
```

* **감정 매칭 규칙**: 명언.emotion → 깨비 표정(KkaebiFaceMode) + ScreenEmotionFxOverlay 1회 연출 (§5 매트릭스).
* **음성 듣기**: 1차는 기기 TTS(flutter_tts), 2차는 전용 보이스 MP3 (선택).

### 4.3 `core/brand_config.dart` (신규)

* 슬로건 6개국어, 앱 목적 문구, OG 문구, WisdomFirstConfig.enabled 플래그, 히어로 레이아웃 상수 집중 관리.

---

## 5. 오늘 구현 기능(v4.6.0)과의 통합 설계

| v4.6.0 기능 | 명언 중심 재편에서의 역할 |
| :--- | :--- |
| **5단계 친밀도 (KkaebiAffectionEngine)** | Lv별 명언 깊이 차등 — Lv.1 짧은 격언 → Lv.5 저자·배경 스토리 해금. 상단바 상시 배지 |
| **운세 캘린더 (스트릭 다이어리)** | "명상 스트릭"으로 확장 — 명언 읽기+운세 체크 시 도장, 3/7/30일 연속 명언 북마크 보너스 |
| **인스타 포스터 3종** | 4번째 템플릿 "황금 명언 부적" 추가 — 명언+저자+3D 깨비 포즈, 히어로 공유 버튼과 직결 |
| **3D 360° 턴테이블 깨비** | 히어로 섹션 주인공 — 명언 톤에 맞는 회전+표정, 터치 시 깨비의 한마디 발화 |
| **8대 감정 풀스크린 FX** | 명언.emotion 트리거 자동 연출 + 감정 쇼케이스 버튼(§5.1) |
| **시즌/시간대 파티클** | 히어로 섹션 전용 앰비언스 (명상 모드: 파티클 저강도) |
| **회전 홈 버튼** | 유지 — 서브 화면에서도 히어로(명언)로 복귀하는 표준 |

### 5.1 8대 감정 ↔ 명언 바인딩 매트릭스 (구현된 FX 재사용)

| 감정(FX) | 명언 테마 | 히어로 연출 | 사운드/햅틱 (기존 자산) |
| :--- | :--- | :--- | :--- |
| 분노 Rage | 도전/역발상 | 화면 균열 + 지진 쉐이크 | 징(gong.wav) + heavy |
| 환희 Joy | 감사/축복 | 황금 폭죽 + 코인 파티클 | 엽전(coin.wav) + 풍경(chime) |
| 침착 Calm | 명상/중도 | 서리 테두리 + 물결 | 가야금(gayageum.wav) |
| 공포 Mystery | 불가해/신비 | 0.2초 암전 + 붉은 안개 | 저역 심장박동(기존 thud 변형) |
| 혼돈 Chaos | 역설/기지 | 소용돌이 워프 | 왜웅 왜곡음(신규 합성 1종) |
| 슬픔 Sad | 위로/이별 | 유리창 빗물 | 빗소리(신규 합성 1종) |
| 설렘 Meeting | 인연/시작 | 핑크·골드 오로라 + 하트 | 챠밍 벨(chime 변형) |
| 각성 Fire | 각성/추진 | 푸른 도깨비불 + 번개 아크 | 스파크음(unlock 변형) + sharp 햅틱 |

### 5.2 감정 쇼케이스 버튼 (신규 검토 항목 — 채택 설계)

* **위치 ①**: 히어로 명언 카드 우측 상단 [🎭] 아이콘 → 8감정 원클릭 그리드 시트 (일반 유저 공개, 학습용).
* **위치 ②**: 설정 → "깨비 감정 실험실" (디버그 인스펙터의 감정 탭을 일반 공개 이식).
* 각 버튼 = `ScreenEmotionFxOverlay.play(mode)` + 대표 명언 1줄 동시 출력 (기능 시연 + 콘텐츠 노출 동시 달성).

---

## 6. 안드로이드 홈 위젯 (5순위 — 명언 중심 재설계)

* **레이아웃**: 4×2(명언+출처+깨비 표정+친밀도), 2×2(깨비 아바타+한 줄 명언), 4×1(명언 티커+럭키넘버).
* **갱신**: `home_widget` + WorkManager (매일 00:00 / 07:00). 데이터는 로컬 365일 명언 DB → **오프라인 100% 표출**.
* **딥링크**: `dokkey://quote/today` · `dokkey://riddle` · `dokkey://chat` (Web은 URL 해시로 동일 동작).
* **표출 문구**: 점괘 금지 — 명언 원문 + 저자만 (스토어 심사·브랜드 품격 유지).

---

## 7. 웹 생태계 개편 (`DOK-KEY-release`)

### 7.1 랜딩 페이지 (`index.html`) 전면 개편

| 요소 | 기존 | 신규 |
| :--- | :--- | :--- |
| `<title>` | DOK-KEY (독키) — 오늘 하루를 여는 단 하나의 열쇠 | DOK-KEY 도깨비키 — 깨비가 전하는 오늘의 명언 & 지혜 |
| OG title/desc | 1-Draw 데일리 운세 드로우 | 매일 아침 나를 깨우는 한 줄의 격언, 3D 깨비와 나누는 수수께끼와 마음 운세 |
| 히어로 문구 | 운세 드로우 CTA 최상단 | **"하루 한 줄, 나를 바꾸는 도깨비 명언"** 대형 타이포 + 오늘의 명언 자동 삽입 |
| 콘텐츠 섹션 순서 | 운세 → 도감 → 숫자 | 명언 → 수수께끼 → 운세 → 도감 → 숫자 (앱 IA와 동일 위계) |
| SEO 키워드 | 운세, 사주, 로또 | 명언, 격언, 인생의 지혜, 마음 치유, 3D 도깨비, 데일리 명상 |

### 7.2 명언 공유 뷰어 (`share/index.html` 신설)

* 앱의 [📤 공유] → `https://alivekevin.github.io/DOK-KEY-release/share/?quote_id=quo_042&lang=ko` 생성.
* 페이지 동작: 로컬 `quotes.json`(CDN 복제)에서 ID 조회 → 황금 명언 카드 렌더(앱 포스터 템플릿 1종 CSS 재현) → 하단 [앱에서 깨비와 대화하기] CTA(스토어/웹앱 딥링크).
* OG 이미지는 공유 시점에 앱이 생성한 PNG를 첨부하는 하이브리드(웹 뷰어는 텍스트 폴백).
* 6개국어: `lang` 파라미터로 전체 문구 현지화.

---

## 8. 구현 로드맵 (단계별 실행 계획)

| Phase | 범위 | 주요 작업 (파일 레벨) | 검증 게이트 | 롤백 포인트 |
| :--- | :--- | :--- | :--- | :--- |
| **P1** | 슬로건 & 코어 | `brand_slogans.json` 신설, `brand_config.dart`, 스플래시·main·settings·Pro패스 문구 교체, `daily_quote_engine.dart` 골격 | analyze 0 / 기존 53 테스트 통과 | 백업 v4.6.0 |
| **P2** | 홈 IA 재배치 | `QuoteHeroSection` 신규 위젯, home_screen 5단계 재배치, 드로우 오브 위젯화 이동, 친밀도 배지 상단화 | 위젯 테스트(히어로 노출 순서) + 골든 테스트 | P1 스냅샷 |
| **P3** | 명언 DB v2 | quotes.json v2 스키마 확장(6개국어 100→150종, author/theme/emotion/kkaebi_comment), 감정 매칭 엔진, FX 바인딩, 감정 쇼케이스 버튼 | 무결성 검증기 확장 + FX 스냅샷 테스트 | P2 스냅샷 |
| **P4** | 웹 & 공유 | release index.html 개편, `/share/index.html` 뷰어, OG/SEO, 포스터 4종(명언 부적), 위젯(5순위, home_widget) | 웹 라이트하우스(OG 검증) + APK 딥링크 테스트 | P3 스냅샷 |

* 각 Phase 완료 시: `flutter analyze 0` + `flutter test 100%` + Web/APK 빌드 + 양쪽 디렉터리 동기화(`DOK-KEY` ↔ `DOK-KEY-release`).

---

## 9. 리스크 및 완화책

| 리스크 | 완화책 |
| :--- | :--- |
| 기존 유료 사용자(운세 목적) 혼란 | 운세는 3순위에 **기능 그대로 유지**, 히어로 문구에서 "명언과 통하는 오늘의 흐름"으로 연결 서사 제공 |
| 명언 저작권 | 인용은 출처 표기 원칙 + 짧은 인용(단문) 범위, 저자 불명 격언은 "옛말/격언" 표기 |
| IA 변경에 따른 테스트 대량 수정 | 위젯 테스트는 `WisdomFirstConfig` 플래그 기반으로 신규/구버전 이중 검증 |
| 웹-앱 슬로건 불일치 재발 | 슬로건을 JSON 단일 소스로 관리 → 웹 빌드 스크립트가 JSON에서 OG를 자동 생성 |
| 성능 (히어로 + FX 동시 렌더) | FX는 1회성 오버레이, 파티클은 기존 단일 패스 엔진 재사용 (프레임 드랍 0% 유지) |

---

## 10. 테스트 계획 (v4.7.0 신규분)

1. **슬로건 일치 테스트**: brand_slogans.json ↔ 스플래시/웹 OG/위젯 문구가 6개국어 완전 일치하는지 자동 검증 (validate 스크립트 확장).
2. **IA 순서 테스트**: 홈 위젯 트리에서 히어로(명언) → 수수께끼 → 운세 → 도감 → 숫자 순서 고정 검증.
3. **명언 엔진 테스트**: 동일 유저+동일 날짜 = 동일 명언(결정론), 14일 내 중복 없음, 감정 보정 동작.
4. **FX 바인딩 테스트**: 8 감정 × 명언 매핑 누락 0건.
5. **웹 뷰어 테스트**: quote_id 100종 전부 렌더, 6개국어 lang 파라미터, CTA 링크 유효성.
6. **롤백 드릴**: 플래그 false → 기존 IA 복귀 스냅샷 테스트.
