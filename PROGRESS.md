# AI Manga Studio — 진행 상황

## 세션 정보

- 기준 지시서: `AI_Manga_Studio_최종요청서_v8.md`
- 저장소: `https://github.com/asmodeus007001-wq/ai-manga-studio-dev`
- 현재 브랜치: `main`
- 이번 세션: 1단계 초기 인벤토리 및 구조 설계

## 1단계 상태

**부분 완료 — 저장소 및 입력 자료 확인 완료.**

### 완료 항목

- 저장소 clone 성공 여부 확인: **성공**
- v8 지시서 전체(§0 및 부록 포함) 열람 완료
- 부록 A 필수 파일 인벤토리 완료
- `validate_workflow_links.py`로 부록 A의 4개 워크플로우 정적 그래프 검증 완료: **전부 PASS**
- 기존 `patch_*.py`/`fix_*.py` 파일 존재 여부 확인
- 이후 구현을 위한 독립형 `comfyui-rocm` 설치 구조 설계 방향 기록

### 부록 A 파일 존재 여부

| 파일 | 상태 |
|---|---|
| `AI_Manga_Studio_최종요청서_v8.md` | 있음 |
| `RX6600_AnimagineXL_기본생성.json` | 있음 |
| `RX6600_AnimagineXL_참조이미지_img2img.json` | 있음 |
| `RX6600_AnimagineXL_ImpactPack_얼굴손_Detailer.json` | 있음 |
| `RX6600_AnimagineXL_통합_자연어_IPAdapter_ControlNet_FIXED.json` | 있음 |
| `validate_workflow_links.py` | 있음 |
| `DxDiag.txt` | 있음 |
| `PROGRESS.md` | 이번 단계에서 새로 생성 |

### 정적 검증 결과

실행 명령:

```bash
python3 validate_workflow_links.py \
  RX6600_AnimagineXL_기본생성.json \
  RX6600_AnimagineXL_참조이미지_img2img.json \
  RX6600_AnimagineXL_ImpactPack_얼굴손_Detailer.json \
  RX6600_AnimagineXL_통합_자연어_IPAdapter_ControlNet_FIXED.json
```

결과:

- `RX6600_AnimagineXL_기본생성.json`: **PASS**
- `RX6600_AnimagineXL_참조이미지_img2img.json`: **PASS**
- `RX6600_AnimagineXL_ImpactPack_얼굴손_Detailer.json`: **PASS**
- `RX6600_AnimagineXL_통합_자연어_IPAdapter_ControlNet_FIXED.json`: **PASS**

## 예외 및 요청 입력

- 저장소에 `patch_*.py` 또는 `fix_*.py` 파일이 **없음**. 기존 패치 파일 약 50개의 인벤토리 및 통폐합은 현재 입력 자료만으로 수행할 수 없음. 기존 패치/ComfyUI 관련 자료가 있다면 저장소에 추가 요청.
- `PROGRESS.md`가 없어서 이번 단계에서 생성함.
- 실제 Windows 11 + RX 6600 환경, ComfyUI API `/prompt` 실행, ROCm 안정성, 모델 로딩은 이 Linux CPU 샌드박스에서 확인할 수 없으며 게이트 1에서 사용자 PC 검증이 필요함.
- 문서가 언급하는 이전 세션 문서·보고서(`v6`, `v7`, `Manus_최종_보완_요청서`, `AI_Manga_Studio___1단계_결과_보고서.md`)는 존재하는 것으로 가정하거나 검색하지 않음.

## 독립형 설치 구조 설계 방향

- 기존 ComfyUI를 변경하지 않고 AI Manga Studio 전용 루트 아래에 `comfyui-rocm` 포크를 별도 설치한다.
- 애플리케이션 코드와 독립 ComfyUI 런타임, 모델 디렉터리, 워크플로우, 사용자 프로젝트 데이터를 물리적으로 분리한다.
- 기존 ComfyUI의 자산은 삭제·이동·덮어쓰기하지 않고, 재사용 시 복사 또는 안정성이 확인된 링크 방식을 별도로 결정한다.
- 워크플로우 파일은 애플리케이션의 버전 관리 영역에 두고, 변경·출고 전 `validate_workflow_links.py` 검증을 필수화한다.
- 사용자 산출물은 `Project/` 구조(`characters`, `styles`, `references`, `scenes`, `panels`, `pages`, `prompts`, `outputs`, `metadata`, `backups`)에 저장하여 런타임 업데이트와 분리한다.
- 모델 체크포인트, LoRA, `.safetensors`, `.bin`, `.onnx` 등 대용량 바이너리는 저장소에 커밋하지 않고 Model Manager의 다운로드/수동 삽입 흐름으로 관리한다.

## 다음 단계

1. 기존 `patch_*.py` 및 ComfyUI 관련 자료가 있다면 저장소에 추가된 뒤 인벤토리 작성.
2. 2단계에서 Qwen3-8B GGUF Q4_K_M CPU 전용 NLU 파이프라인과 프롬프트 미리보기 UI 설계·구현.
3. 3단계에서 워크플로우 검증을 확장하고, 게이트 1용 `/prompt` 실행 절차와 로그 수집 구조를 준비.


## 추가 업로드 확인 — 2026-09-11

- 원격 `origin/main`의 `8073df6 Add files via upload`를 병합함.
- 추가된 자료: 과거 요청서/보고서 Markdown 9개와 기존 설치 프로그램 2개.
- 설치 프로그램 기본 무결성 확인:
  - `AI_Webtoon_Studio_Setup_v2.3.exe`: PE32 Windows Nullsoft Installer, 6,287,043 bytes
  - `MangaSceneStudio_Setup.exe`: PE32 Windows Nullsoft Installer, 170,652 bytes
- 추가 업로드 이후에도 4개 워크플로우 정적 검증은 **전부 PASS**.
- `patch_*.py`, `fix_*.py`, 파일명에 `ComfyUI`가 포함된 자료는 여전히 **없음**.
- 과거 요청서/보고서는 파일로 존재함을 확인했지만, 프로젝트 실행 지시서는 계속 `AI_Manga_Studio_최종요청서_v8.md` 하나만 기준으로 사용함.
- 원격 업로드에서 `PROGRESS.md`가 삭제되어 있었으나, 세션 진행 기록 보존을 위해 로컬 기록을 유지함.

병합 커밋: `c304cba merge: incorporate uploaded project materials`

## 원격 추가 기록 — 2026-09-12

### 완료

- Git 저장소 clone 및 요청서 v8 확인
- 한국어 장면 해석·워크플로우 선택·캐릭터·검수 UI 기반 구현 확인
- Manga Editor의 페이지·패널·순서 변경·복제·삭제 구현 확인
- 대사·SFX 편집 레이어의 위치(X/Y)·크기 저장 및 미리보기 구현 확인
- 현재 페이지 및 전체 프로젝트 PNG/PDF Export 구현 확인
- WebDev 프로젝트 타입 검사, 10개 Vitest 테스트, production build 통과
- `validate_workflow_links.py`와 필수 워크플로우 파일 존재 여부 확인

### 이번 점검 결과

| 항목 | 상태 | 비고 |
|---|---|---|
| Manga Editor MVP | 완료 | WebDev 체크포인트 `0bdbea5f` |
| PNG/PDF Export | 완료 | 브라우저에서 Export 미리보기 확인 |
| 워크플로우 정적 검증 | 확인 필요 | 검증 스크립트 실행 출력 로그를 별도 저장해야 함 |
| 독립형 ComfyUI 설치 | 미완료 | Linux 샌드박스에는 Windows RX6600 환경과 ComfyUI 모델이 없음 |
| Inno Setup `.exe` | 미완료 | Inno Setup은 Windows 전용이며 이 샌드박스에는 컴파일러가 없음 |
| 게이트 1/2/4/5 실기기 검증 | 미완료 | Owl님의 Windows 11 + RX6600 PC에서만 가능 |

### 다음 작업

1. Windows PC에서 `scripts/prepare-windows-bundle.ps1` 실행
2. `installer/AI-Manga-Studio.iss`를 Inno Setup Compiler로 빌드
3. 설치·제거·SmartScreen 결과를 `verification/gate-4/`에 저장
4. ComfyUI 4개 워크플로우 실제 `/prompt` 실행 로그를 `verification/gate-1/`에 저장

### 중요한 제한

현재 제공 가능한 것은 웹 앱 체크포인트와 Windows 패키징 구성입니다. 실제 `.exe`는 Inno Setup 및 독립 ComfyUI/모델 파일을 갖춘 Windows 환경에서 생성·검증해야 하며, 이를 완료했다고 가장하지 않습니다.
## Cross-session operating policy — 2026-09-12

- Manus completes all sandbox-capable coding, static checks, tests, builds, browser checks, workflow validation, documentation, and packaging preparation autonomously.
- Only Windows 11 + RX6600 + ComfyUI runtime behavior, actual image generation/model loading, Inno Setup compilation, install/uninstall, and SmartScreen reproduction are user-PC checkpoints.
- The conversation link is a resume pointer; durable state is stored in this repository, the WebDev project, its latest checkpoint, and the managed database.
- Resume order: project instructions → `git pull` → `PROGRESS.md` → `SESSION_HANDOFF.md` → existing WebDev project/checkpoint. Never create a replacement WebDev project.
- Final product target: AI-image-generation-optimized manga production software with a verified Windows Inno Setup installer and v8 behavior.
