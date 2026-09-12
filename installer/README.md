# AI Manga Studio Windows 설치파일 만들기

현재 전달된 ZIP은 **최종 설치파일이 아니라 Windows 설치파일을 만드는 준비 키트**입니다. 사용자가 해야 할 일은 아래 순서뿐입니다.

## 1. Windows에서 프로그램 설치

Windows PC에서 다음 두 프로그램만 설치합니다.

- [Inno Setup 6](https://jrsoftware.org/isinfo.php)
- [Node.js Windows x64 ZIP](https://nodejs.org/en/download)에서 Windows x64 Binary `.zip`

## 2. ZIP 압축 풀기

`ai-manga-studio-windows-packaging-kit.zip`을 원하는 폴더에 풉니다.

예시:

```text
C:\AI-Manga-Studio\ai-manga-studio-windows-packaging-kit\
```

## 3. Node 런타임 넣기

Node.js ZIP 안의 `node.exe` 하나를 다음 위치에 복사합니다.

```text
installer\runtime\node.exe
```

## 4. ComfyUI 준비

요청서에 지정된 `patientx-cfz/comfyui-rocm`을 별도 폴더에 설치한 뒤, **설치 폴더 전체**를 다음 위치에 복사합니다.

```text
installer\comfyui\
```

이 폴더 안에 최소한 `main.py`가 있어야 합니다. 커스텀 노드와 모델도 요청서 §3-3~§3-5의 경로에 들어 있어야 합니다.

## 5. 최종 번들 만들기

PowerShell을 열고 ZIP을 푼 최상위 폴더에서 실행합니다.

```powershell
powershell -ExecutionPolicy Bypass -File .\scripts\finalize-windows-bundle.ps1
```

## 6. 설치파일 컴파일

`installer` 폴더에서 `AI-Manga-Studio.iss`를 Inno Setup Compiler로 엽니다.

- **Build → Compile** 선택
- 생성 위치: `installer\output\AI-Manga-Studio-Setup-0.1.0.exe`

## 7. 설치 및 확인

생성된 `.exe`를 실행하고 설치합니다. 설치 후 확인할 항목은 다음입니다.

- 바탕화면 또는 시작 메뉴에서 AI Manga Studio 실행
- ComfyUI 실행 후 `127.0.0.1:8188` 접속
- Windows 설정 → 앱 및 기능에서 제거 가능
- 제거 후 `data` 폴더의 사용자 작업물 보존 여부 확인
- SmartScreen이 표시되면 **추가 정보 → 실행** 선택

## 중요한 현재 상태

이 샌드박스에서는 Windows 실행 환경, Inno Setup, RX6600, 독립 ComfyUI 및 모델 파일을 제공할 수 없으므로 실제 `.exe`를 대신 생성할 수 없습니다. 따라서 사용자가 직접 해야 하는 실질적인 작업은 **Node ZIP과 ComfyUI 폴더를 준비하는 것**이며, 그 후 위의 PowerShell 1회와 Inno Setup 컴파일 1회로 설치파일을 만들 수 있습니다.
