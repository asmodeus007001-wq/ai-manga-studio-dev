# Windows 설치파일 빌드

이 폴더는 요청서 §11의 **Inno Setup 기반 Windows 설치파일**을 빌드하기 위한 구성입니다. Linux WebDev 샌드박스에서는 Inno Setup 컴파일러와 Windows 실행 환경이 없으므로 `.exe` 자체는 생성하지 않습니다.

## Windows PC 준비

다음 항목을 준비해야 합니다.

1. Inno Setup 6 설치
2. Windows x64 `node.exe`를 `installer/runtime/node.exe`에 배치
3. `patientx-cfz/comfyui-rocm`을 `installer/comfyui/`에 독립 설치
4. ComfyUI의 custom nodes, checkpoint, VAE, IPAdapter, ControlNet, Detailer 모델을 요청서 §3-3~§3-5의 정확한 경로에 배치
5. WebDev 프로젝트에서 `pnpm build` 실행 후 `dist/`를 패키징 스크립트가 찾을 수 있게 준비

## 빌드 순서

PowerShell에서 저장소 루트 기준으로 실행합니다.

```powershell
# WebDev 프로젝트에서 먼저 실행
pnpm check
pnpm test
pnpm build

# 저장소 루트에서 번들 준비
powershell -ExecutionPolicy Bypass -File .\scripts\prepare-windows-bundle.ps1 `
  -WebProject "C:\path\to\ai-manga-studio-resumed"

# Inno Setup Compiler에서 실행
iscc .\installer\AI-Manga-Studio.iss
```

완성 파일은 `installer/output/AI-Manga-Studio-Setup-0.1.0.exe`에 생성됩니다.

## 설치 검증

설치 후 다음을 확인해야 합니다.

- 기본 설치 경로 선택, 바탕화면 바로가기, 시작 메뉴 등록
- 설치 완료 후 앱 실행
- 독립 ComfyUI가 `127.0.0.1:8188`에서 실행
- Windows 설정의 앱 및 기능에서 제거 가능
- 제거 시 `data/` 사용자 작업물이 보존됨
- 서명하지 않은 설치파일의 SmartScreen 경고와 “추가 정보 → 실행” 절차 캡처
- 결과를 `verification/gate-4/`에 스크린샷·로그·정확한 조작 순서로 저장

현재 저장소에는 **빌드 구성만 있으며 실제 `.exe`, Windows 실행 로그, SmartScreen 캡처는 아직 없습니다.**
