# 🚨 DOK-KEY 배포 아키텍처 및 작업 가이드라인 (DEPLOYMENT_RULES.md)

> **[중요]** 모든 개발 AI 및 작업자는 DOK-KEY 웹 배포 및 코드 수정 작업 시 본 규칙을 엄격히 준수해야 합니다.

---

## 🏛️ 1. 2-Tier 배포 아키텍처 구조

DOK-KEY는 **공식 랜딩 페이지(루트)**와 **Flutter 웹 데모(하위 web/)**가 명확히 분리된 2-Tier 구조로 운영됩니다:

| 구분 | 접속 URL | 저장 디렉터리 | 주요 파일 및 역할 |
|---|---|---|---|
| **루트 (Tier 1)** | `https://alivekevin.github.io/DOK-KEY-release/`<br>`http://localhost/dokkey/` | 루트 (`/`) | `index.html`<br>• 3D 시네마틱 오프닝 무비<br>• Google Play 정식 출시 다운로드 안내<br>• 별점/리뷰 배너<br>• 깨비 윙크/미소 인터랙션 |
| **웹 데모 (Tier 2)** | `https://alivekevin.github.io/DOK-KEY-release/web/`<br>`http://localhost/dokkey/web/` | `web/` | `web/index.html`, `web/main.dart.js`, `web/assets/`<br>• 스마트 인터랙티브 로더 (프로그레스 바, 순환 팁)<br>• Flutter CanvasKit 99종 그랜드 도감 게임 엔진 |

---

## ⛔ 2. 절대 엄수 금지 규칙 (Never Violate)

1. **루트 `index.html` 덮어쓰기 절대 금지**
   - Flutter 빌드 결과물(`build/web/index.html`)을 루트의 `index.html`에 덮어쓰지 마십시오.
   - 루트 `index.html` 상단에는 `<!-- TYPE: DOK-KEY-OFFICIAL-LANDING -->` 서명이 반드시 유지되어야 합니다.

2. **Flutter Web 빌드 결과물은 반드시 `web/` 하위로만 배포**
   - Flutter Web을 새로 빌드하거나 리소스를 갱신할 때는 반드시 `web/` 디렉터리에만 복사해야 합니다.
   - Base Href는 반드시 `<base href="/DOK-KEY-release/web/">` (또는 동적 스크립트) 기준이어야 합니다.

3. **내부 검수용 APK 직접 다운로드 링크 외부 노출 금지**
   - 내부 검수용 APK 파일(`app-release.apk`)은 지인 공유용으로 서버에 파일 자체만 보존하되,
   - 공식 랜딩 페이지(`index.html`) 및 웹 데모(`web/index.html`)의 공개 UI(배너, 본문, 푸터 등)에 다운로드 링크를 절대 노출하지 마십시오.

4. **`main.dart.js` Web 호환성 패치 유지**
   - Dart의 `Platform.environment['FLUTTER_TEST']` 호출이 웹 브라우저에서 `Unsupported operation: Platform._environment` 예외를 일으키지 않도록 패치 상태를 유지해야 합니다.

5. **로컬(XAMPP)과 원격(Git) 디렉터리 1:1 일치 유지**
   - 로컬 테스트 경로: `c:\xampp\htdocs\dokkey\`
   - 깃 배포 저장소: `C:\Works\DOK-KEY-release\`
   - 두 디렉터리의 루트(`index.html`)와 `web/` 내부 리소스는 항상 동일하게 동기화되어야 합니다.

---

## 🚀 3. 안전한 표준 배포 방법

배포 시 개별 파일을 수동으로 복사하지 말고, 프로젝트에 포함된 자동 검증 스크립트를 사용하십시오:

```powershell
# 프로젝트 루트에서 실행 (검증, 패치, 로컬 동기화, Git 커밋/푸시 일괄 처리)
powershell -ExecutionPolicy Bypass -File deploy_web.ps1
```
