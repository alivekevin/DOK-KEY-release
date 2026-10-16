# AGENTS.md — DOK-KEY Project Architecture & Safe Operations

> **CRITICAL INSTRUCTIONS FOR AI AGENTS:**
> Read and strictly follow the deployment and architecture rules in this repository.

## Architecture
1. **Root Directory (`/`)**: Official Cinematic Landing Page.
   - File: `index.html` (Must contain `TYPE: DOK-KEY-OFFICIAL-LANDING`).
   - Live URL: `https://alivekevin.github.io/DOK-KEY-release/`
   - Local URL: `http://localhost/dokkey/`
   - **DO NOT OVERWRITE** with Flutter web build output.

2. **Subdirectory (`/web/`)**: Flutter Web Demo application.
   - Files: `web/index.html`, `web/main.dart.js`, `web/assets/`, `web/canvaskit/`, etc.
   - Live URL: `https://alivekevin.github.io/DOK-KEY-release/web/`
   - Local URL: `http://localhost/dokkey/web/`
   - All Flutter Web builds MUST be deployed ONLY into `web/`.

## Prohibitions
- NEVER expose internal APK download links in public HTML/CSS UI (internal build contains 10x reward testing logic).
- NEVER overwrite root `index.html` when updating the web demo.
- Always preserve `c:\xampp\htdocs\dokkey\` and `C:\Works\DOK-KEY-release\` 1:1 synchronization.

## Standard Deployment Command
Use `deploy_web.ps1` for safe deployments:
```powershell
powershell -ExecutionPolicy Bypass -File deploy_web.ps1
```
