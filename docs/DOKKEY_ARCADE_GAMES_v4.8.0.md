# 🕹️ DOK-KEY 아케이드 게임 시스템 구현 기획서 (v4.8.0)

* **문서 버전**: v4.8.0 (Kkaebi Arcade — 9-Game Lineup)
* **작성일**: 2026-09-10
* **구현 상태**: **As-Built Complete** — analyze 0/0 · 테스트 **97/97** · Web(base-href)+APK(66.0MB) 빌드 성공
* **엔진**: 순수 Flutter Canvas (`CustomPainter` + `Ticker` delta-time) — Flame/외부 엔진 0 의존
* **선행 문서**: v4.7.1 (UI/UX 재조정 및 6개국어 무결성 검증)

---

## 1. 아키텍처 원칙 (3계층 분리)

1. **Game State Model** — 순수 로직, 테스트 가능 (플랫폼 채널 호출 없음)
2. **Game Controller Loop** — `GameLoopMixin` (TickerProvider delta-time, `clamp(0, 0.05)` 가드)
3. **CustomPainter Renderer** — 프레임마다 전면 재렌더링 (`shouldRepaint: true`)

**공용 셸**: `lib/games/core/game_shell.dart` — 파티클 시스템, 사인 trauma 화면 쉐이크, HUD, 결과 다이얼로그, 리워드 디스패치, 고득점 저장(`pref_hs_<gameId>`).

## 2. 9게임 라인업 구현 내역

| # | 게임 | 파일 | 핵심 구현 |
|---|---|---|---|
| 1 | 💬 상식 문답 | `kkaebi_trivia_game.dart` | 20문항 × 6개국어 DB(`trivia.json`), 10초 카운트다운, 정답 친밀도 +10, 시간보너스 점수 |
| 2 | 🔢 스도쿠 | `kkaebi_sudoku_game.dart` | 4×4/9×9 백트래킹 생성기, 충돌 하이라이트, 연필 메모, 깨비 지혜 힌트(1회) |
| 3 | 🧱 테트리스 | `kkaebi_tetris_game.dart` | 7종 테트로미노, 스와이프+D-패드, 고스트 피스, 콤보 줄삭제+황금 불꽃 파티클, 하드드롭 |
| 4 | 💥 벽돌깨기 | `kkaebi_breakout_game.dart` | 방망이 각도 반사(맞은 위치 비율), 파워업 5종(멀티볼·화염구·와이드·레이저·코인 벽돌) |
| 5 | 🔮 버블슈터 | `kkaebi_bubble_game.dart` | 헥사 그리드, 3+ 매칭 flood-fill, 연쇄 낙하(cluster drop), 벽 바운스, 6발마다 천장 하강 |
| 6 | 🚀 우주 슈팅 | `kkaebi_shooter_game.dart` | 3층 패럴랙스 성운, 터치 드래그 함선, 듀얼 빔, 편대 웨이브, 보스전(HP바) |
| 7 | 🌿 정글 탐험 | `kkaebi_jungle_game.dart` | 플랫포머(중력/점프), 사다리 등반, 가시 함정, 황금 열쇠 → 석문 오픈 |
| 8 | 🏃 동굴 탈출 | `kkaebi_cave_game.dart` | 원터치 점프/더블점프 러너, 추격 바위(간격 감소), 뾰족암/구덩이, 거리 점수 |
| 9 | ⛵ 바다 항해 | `kkaebi_sea_game.dart` | 보트 기울기 물리(\|θ\|>45° 전복), 물 유입 게이지, 포물선 날치 회피, 황금 항구 클리어 |

## 3. 트리거 & 통합

* **대화방 순환 트리거**: 대화방 퀵칩 최전면 `[🎮 게임할래?]` — 탭마다 트리비아→스도쿠→테트리스→벽돌→버블→슈팅→정글→동굴→항해→🎮허브 순환.
* **홈 앱바**: 🎮 아이콘으로 허브 직접 진입.
* **허브(`kkaebi_arcade_hub.dart`)**: 3×3 카드 그리드, 게임별 BEST 점수, 일일 무료 플레이 3/3(무료)·∞(PRO), 코인 잔액 표시.

## 4. 경제 시스템

* **코인**: 신규 메타 재화(`pref_coins`) — 게임 점수/10 (10~100) 지급, 허브에 잔액 표시.
* **친밀도**: `addKkaebiAffection` 연동 (게임당 +5~30).
* **열쇠**: 클리어 시 +1.
* **쿼터**: 무료 일 3회 / PRO 무제한 — `consumeArcadePlay()` 게이트, 초과 시 ProPassDialog 유도.

## 5. 검증 결과

* `flutter analyze` 0/0 · `flutter test` **97/97 통과** · Web(base-href)·APK(66.0MB) 빌드 성공
* 에셋 최적화 병행: 3D 턴테이블 16종 PNG→WebP (4.3MB→0.7MB), 부적 18종 PNG→WebP (19.1MB→2.7MB) → **에셋 총량 29.8MB → 8.5MB (−71%)**

---

## 6. 18종 부적 시스템 & BM v5 검증 기록

| 검증 항목 | 결과 |
|---|---|
| 18종 부적 레지스트리 무결성 (index 1~18, ID 유니크, 6개국어명) | ✅ |
| 18종 WebP 에셋 존재 (683×1024 RGBA) | ✅ |
| 매칭 엔진: 키워드(재물→wealth, 숙면→sleep) | ✅ |
| 매칭 엔진: 감정 폴백(passion→victory), 기본 폴백(wealth) | ✅ |
| 카테고리: daily 10 / seasonal 4 / special 4 = 18 | ✅ |
| 드로우 → 부적 자동 발급 → 온디바이스 수집 저장 | ✅ |
| 중복 발급 방지 (컬렉션 유니크) | ✅ |
| BM 무료: 9슬롯/1뽑기/광고 있음 | ✅ |
| BM PRO: 99슬롯/4뽑기/광고제거/부적33슬롯 | ✅ |
| 부적 슬롯 게이팅: 무료 19~20(2개) 체험 / 21~33 PRO | ✅ |
| 조합키 삭제 후 도감·원천번호 보존 | ✅ |

## 7. 용어 정제 검증

| 용어 | lib 전체 스캔 | 데이터 전체 스캔 |
|---|---|---|
| 수묵과 | 0건 | 0건 |
| 영구 | 0건 | 0건 |
| 무제한 | 0건 | 0건 |
| 무조건 | 0건 | — |
| 10년(클라우드) | 0건 | — |
