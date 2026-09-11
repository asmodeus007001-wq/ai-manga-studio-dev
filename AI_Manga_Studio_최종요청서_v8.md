# AI Manga Studio — Manus 개발 요청서 (최종 통합본 v8)

> **이 문서는 `v6`, `v7 수정제안`, `Manus_최종_보완_요청서`를 전부 대체하는 단일 최종본입니다.** 세 문서를 따로 참고할 필요 없이 이 문서 하나만 보고 진행하세요. 정보 수집·모델 비교·버그 진단은 Claude가 이미 끝냈습니다 — Manus는 아래 확정값을 그대로 실행하면 됩니다.

---

## 0. 지난 1단계 보고서에 대한 답변 (반드시 먼저 읽을 것)

`AI_Manga_Studio___1단계_결과_보고서.md`에서 Manus가 보고한 내용을 확인했습니다: 이번 세션의 샌드박스에는 기존 프로젝트, ComfyUI, 워크플로우 JSON, patch 파일, 검증 스크립트가 **하나도 없었다**는 것. 이건 Manus의 실수가 아니라 구조적인 문제였습니다 — Manus 세션은 상태를 유지하지 않는 클라우드 샌드박스이고, 채팅으로 보낸 파일은 다음 세션에 남지 않으며, Owl(사용자)이 Manus에게 하루에 보낼 수 있는 파일은 최대 4개로 제한되어 있습니다. 이 프로젝트는 40개 이상 섹션에 워크플로우 JSON, 대용량 실행파일, 로그 파일까지 필요하므로 채팅 첨부만으로는 애초에 불가능했습니다.

**그래서 이번 v8부터는 Git 저장소(또는 zip 패키지)를 파일 전달의 단일 통로로 삼습니다.** 아래 §1을 이번 세션의 **가장 먼저** 실행하세요.

---

## 1. 세션 연속성 확보 — 저장소를 단일 소스로 사용 (매 세션 최우선 행동)

### 1-1. 원칙

- 이 프로젝트의 모든 코드·문서·진행상태는 저장소 하나를 단일 소스로 사용합니다. **저장소 push/pull은 채팅 파일 전송과 완전히 별개의 통로이므로 하루 4개 파일 제한과 무관합니다.**
- Manus는 **매 세션 시작 시 가장 먼저** 저장소를 clone(최초 1회) 또는 pull(이후 매번)하고, 성공/실패를 세션 첫 응답에 보고합니다. 실패 시 즉시 예외 보고 후 지시를 기다립니다.
- 저장소의 `PROGRESS.md`를 먼저 읽고 이전 단계까지의 상태를 파악한 뒤, **이번에 지시받은 단계 섹션만** 실행합니다.
- **대용량 바이너리(모델 체크포인트, LoRA, `.safetensors`, `.bin`, `.onnx`, 수십MB 이상 파일)는 저장소에 절대 커밋하지 않습니다.** 모델은 §7(Model Manager)의 다운로드 링크로만 다루고, 실물 파일은 Owl님의 PC가 직접 받습니다.
- 저장소에 있어야 할 산출물이 이번 단계 실행에 필요한데 없다면, 임의로 새로 추정하지 말고 예외 보고 후 입력을 요청합니다.
- 각 단계 종료 시 `PROGRESS.md`를 갱신(완료 항목/남은 작업/이번 단계에서 발견된 이슈/다음 세션이 알아야 할 컨텍스트)하고 커밋합니다.

### 1-2. Owl님이 한 번만 하면 되는 설정 — 명령어 없이 GitHub Desktop으로

1. [github.com](https://github.com)에서 무료 계정 생성 후 로그인
2. "New repository" → 이름 `ai-manga-studio-dev` → **Private** 선택 → Create
3. [desktop.github.com](https://desktop.github.com)에서 **GitHub Desktop** 설치(Windows) 후 로그인
4. GitHub Desktop → "Clone a repository" → 방금 만든 저장소 선택 → PC의 폴더 하나로 내려받음
5. 그 폴더 안에 아래 §0의 첨부 파일 전체(이 문서, 워크플로우 JSON 5개, 검증 스크립트, `DxDiag.txt`)와, 가지고 계신 기존 `patch_*.py` / 기존 ComfyUI 관련 파일이 있다면 **탐색기에서 끌어다 놓기**
6. GitHub Desktop 왼쪽에 변경 파일 목록이 뜸 → 커밋 메시지("초기 자료 업로드") 입력 → **Commit to main** → **Push origin**
7. 완료. 이제 Manus에게는 **저장소 URL만 알려주면** 됩니다. 이후 파일 추가도 4~6번 반복(끌어다 놓기 → Commit → Push)이면 되고, **이건 하루 4개 파일 제한과 무관**합니다.

**저장소를 만들고 싶지 않다면(대안):** 매 게이트 직전에 그 시점까지 필요한 파일 전체를 zip 1개로 압축해서 전달하는 방식으로 대체합니다(1일 4개 중 1개만 사용하므로 한도 문제 없음). 다만 Manus가 이전 세션에 만든 코드를 Owl님이 매번 내려받아 다시 넘겨줘야 하므로 저장소 방식보다 손이 더 갑니다.

---

## 2. 작업 분류와 검증 게이트 — 모든 단계를 Owl님이 테스트하지 않는다

### 2-1. 두 그룹으로 분류

- **[Manus 자체]**: Manus 샌드박스 안에서 코드 실행·단위 테스트·정적 검증만으로 완결 가능한 항목. Manus가 직접 실행하고 로그를 저장소에 커밋합니다.
- **[Owl PC 필수]**: 실제 GPU 이미지 생성, Windows 설치/제거, SmartScreen 확인 등 Owl님의 로컬 Windows 11 + RX 6600 PC에서만 확인 가능한 항목. Manus는 코드·스크립트·설치파일까지만 만들고, Owl님이 실행한 결과(스크린샷/로그)를 저장소에 올리면 그걸로 최종 판정합니다.
- Manus는 GPU가 없는 Linux 클라우드 샌드박스에서 동작하며 Owl님의 실제 PC에 원격으로 접근할 수 없습니다. 이 전제를 항상 유지하세요.

### 2-2. 검증 게이트 5개 — 이 지점에서만 Owl님이 실제로 테스트

| 게이트 | 커버 단계 | Manus가 자체 완결 | Owl님이 반드시 확인 |
|---|---|---|---|
| (게이트 아님) | 2단계 한국어 NLU | CPU 추론이라 샌드박스 자체 테스트·모델 비교까지 가능 | — |
| (게이트 아님) | 4단계 백엔드 코드, 6·7단계 UI 구조 | 로직/API·죽은 버튼·레이아웃 정합성 | — |
| **게이트 1** | 3단계 말미 | 그래프 검증 스크립트 통과 | 4개 워크플로우 `/prompt` 실제 큐 실행 확인, NoobAI-XL + VAE 적용 확인(검은 화면/NaN 없음), `comfyui-rocm` 설치·안정성 확인 |
| **게이트 2** | 4~5단계 말미 | — | 캐릭터 일관성(여러 패널 연속) + Inpainting 결과 동시 확인 |
| **게이트 3** | 6~7단계 말미 | — | 전체 UI + Manga Editor 실사용 시나리오 1회 통합 테스트 |
| **게이트 4** | 8~9단계 | — | 설치/제거 + SmartScreen을 한 번의 설치 사이클로 같이 확인 |
| **게이트 5** | 10~11단계 | — | 확장 기능 + 최종 통합 테스트 |

게이트 제출 시 항상 3종 세트 고정: **(1) 스크린샷, (2) 콘솔/로그 파일, (3) 실행한 정확한 명령어 또는 조작 순서.** 저장소의 `/verification/gate-N/` 폴더에 올리고 `PROGRESS.md`에 링크합니다.

---

## 3. 확정 사양 (전부 단일 값 — 선택지 없음, 재질문 금지)

### 3-1. 하드웨어/환경

| 항목 | 값 |
|---|---|
| OS | Windows 11 Home 64-bit |
| CPU / RAM | AMD Ryzen 5 5600X / 32GB |
| GPU | AMD Radeon RX 6600, VRAM 8GB, gfx1032 |

### 3-2. ComfyUI 백엔드 — `patientx-cfz/comfyui-rocm` 포크로 고정

- 저장소: `https://github.com/patientx-cfz/comfyui-rocm`
- **이미 Owl님 PC에서 네이티브로 정상 동작 확인됨**: `PyTorch 2.12.0+rocm7.14.0`, RX 6600 정상 인식, VRAM 7.84GB free. **추가로 ZLUDA/DirectML을 설치하지 않습니다.**
- AI Manga Studio는 이 포크를 §8의 독립 경로에 별도 설치합니다(기존 ComfyUI와 물리적으로 분리).
- 사전 설치물: Git, Python 3.12, Visual C++ Runtime(`vc_redist.x64.exe`), Visual Studio Build Tools — 포크 README 절차대로.

### 3-3. 체크포인트/VAE

| 항목 | 값 |
|---|---|
| 체크포인트 | **NoobAI-XL Epsilon-pred v1.1** (Civitai `civitai.com/models/833294`, Epsilon-pred 계열 중 최신 버전. **V-Pred 계열은 받지 않음**) |
| VAE | `sdxl-vae-fp16-fix.safetensors`(madebyollin, Hugging Face) — `VAELoader`로 명시적 로드, 체크포인트 내장 VAE 사용 금지 |
| 보조 체크포인트 | Animagine XL 4.0(기존 보유분, 현재 워크플로우 4개가 사용 중) — 삭제하지 않고 Model Adapter 보조 옵션으로 유지 |

### 3-4. 캐릭터 일관성용 모델 파일 (정확한 파일명 — 세트로 맞출 것)

| 역할 | 파일 | 저장 위치 |
|---|---|---|
| Face ID 임베딩 | `ip-adapter-faceid-plusv2_sdxl.bin` | `ComfyUI/models/ipadapter/` |
| Face ID 전용 LoRA (필수, 짝이 다르면 오류) | `ip-adapter-faceid-plusv2_sdxl_lora.safetensors` | `ComfyUI/models/loras/` |
| Face ID용 CLIP Vision 인코더 | `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` | `ComfyUI/models/clip_vision/` |
| 전신/의상 보조 IPAdapter | `ip-adapter-plus_sdxl_vit-h.safetensors` | `ComfyUI/models/ipadapter/`(위 인코더 재사용) |
| 포즈 ControlNet | `OpenPoseXL2.safetensors` | `ComfyUI/models/controlnet/` |
| 포즈 검출기 | `yolox_l.onnx`, `dw-ll_ucoco_384_bs5.torchscript.pt` | `ComfyUI/models/dwpose/`(또는 커스텀노드 지정 경로) |
| 얼굴 Detailer bbox | `bbox/face_yolov8m.pt` | Impact Pack 지정 경로 |
| 손 Detailer bbox | `bbox/hand_yolov8s.pt` | Impact Pack 지정 경로 |

타입/인코더가 안 맞으면 텐서 크기 불일치 오류가 나므로 표의 조합을 임의로 바꾸지 않습니다.

### 3-5. 필수 커스텀 노드

| 노드 | 저장소 |
|---|---|
| IPAdapter | `cubiq/ComfyUI_IPAdapter_plus` |
| ControlNet 전처리(DWPose 등) | `Fannovel16/comfyui_controlnet_aux` |
| Face/Hand Detailer | `ltdrdata/ComfyUI-Impact-Pack` + `ltdrdata/ComfyUI-Impact-Subpack` |

`validate_stage2.py`(§4-3에 동봉)로 설치 여부를 확인하고 결과를 보고합니다.

### 3-6. 기존 환경 보호

기존 ComfyUI(별도 폴더, 기존 워크플로우 보유)는 절대 건드리지 않습니다(삭제/덮어쓰기/초기화 금지). AI Manga Studio는 §8에 따라 완전 독립 설치.

### 3-7. 패널 생성 방식

멀티패널 동시 생성 금지. 패널은 1장씩 순차 생성하며, 직전 패널의 캐릭터 참조/Seed/Metadata를 이어받습니다. "후보 4장 동시 생성"은 같은 컷 후보 선택용으로만 사용.

### 3-8. 출력 형식 설정 (프로젝트 생성 시 사용자가 선택)

```
Project Settings
├── Layout Type: [세로 스크롤 웹툰] / [페이지 넘김 만화책]
├── Color Mode: [컬러] / [흑백 선화 + 톤]
└── Export Resolution / Page Size
```

### 3-9. 로컬 한국어 LLM

| 항목 | 값 |
|---|---|
| 모델 | **Qwen3-8B-Instruct, GGUF `Q4_K_M`** (Hugging Face 공식/신뢰 배포본) |
| 실행 | `llama.cpp`(또는 `llama-cpp-python`)로 **CPU 전용**, thinking mode 끔 |
| RAM | Q4_K_M 기준 약 5~6GB — 32GB 환경에서 여유 충분, GPU와 리소스 경쟁 없음 |
| 비교 테스트 대상 | EXAONE(LG AI연구원 최신), Bllossom GGUF — 실제 한국어 문장 샘플로 비교 후 **더 나은 쪽 하나로 최종 확정**해서 보고. "둘 다 옵션으로 남긴다"는 답은 인정하지 않음 |
| OpenAI 대체 경로 | `OPENAI_API_KEY` 있으면 우선 사용 가능하나, **키 없이도 로컬 LLM 경로만으로 항상 완전히 정상 동작해야 함** |
| UI 요구사항 | 처리 경로(로컬 LLM/OpenAI)를 화면에 항상 표시. 해석 못한 표현을 버리지 말고 "이 부분은 이렇게 해석했다"를 보여줌. **생성 버튼을 누르기 전 최종 영어 프롬프트를 미리 보여주고, 확인/수정 후에만 생성 시작** |

기존의 고정 80개 구문 사전 방식(`translate_helper.py`)은 폐기합니다.

### 3-10. 설치 프로그램 도구 — Inno Setup으로 고정

NSIS 대비 Pascal 스크립트가 짧고 표준 마법사(경로 선택/바탕화면 바로가기/시작메뉴/제거 등록)를 기본 제공해 개인용 데스크톱 툴에 더 적합합니다. **NSIS는 검토하지 않습니다.** (이 요구사항의 목적은 §11 참고.)

### 3-11. 코드 서명 — 하지 않는다

2024년 3월부터 마이크로소프트가 EV 인증서의 SmartScreen 즉시 통과 혜택을 없앴습니다. EV·OV 모두 다운로드량이 쌓여야 평판이 쌓이는 구조이며, 연 $250~600(OV $65~400) 비용 대비 개인 PC 한 대에 설치하는 툴에는 실익이 없습니다. **서명 인증서를 구매하지 않습니다.** 대신:
- 설치 파일에 제품명/버전/게시자/아이콘 메타데이터는 정상적으로 채웁니다(Inno Setup 표준 방식).
- 설치 화면 또는 안내 문서에 SmartScreen 경고 시 "추가 정보 → 실행" 우회 절차를 스크린샷과 함께 포함합니다.
- 배포용 설치 파일을 실제로 실행해보고 경고 문구를 캡처해서 보고합니다.

---

## 4. 이미 해결된 것 — 통합 워크플로우 버그 (Claude가 사전 수정 완료)

### 4-1. 발견된 정확한 오류

`RX6600_AnimagineXL_통합_자연어_IPAdapter_ControlNet.json`을 노드 단위로 직접 파싱해서 검사한 결과, 단순 링크 스와프가 아니라 **top-level `links` 배열의 target(node, slot)과 각 노드 `inputs[].link`가 서로 다른 값을 가리키는 상태**였습니다(예: link 10이 노드 자체 기록으로는 IPAdapterAdvanced의 `image` 입력을 가리키지만, `links` 배열의 실제 항목은 target을 VAEDecode의 slot 2로 기록하고 있고 타입도 LATENT로 되어 있는 등 — 총 18건). 동봉한 `validate_workflow_links.py`로 재현·확인 가능합니다.

### 4-2. 조치 — 재구성 완료, 바로 사용 가능

첨부한 **`RX6600_AnimagineXL_통합_자연어_IPAdapter_ControlNet_FIXED.json`**은 아래 연결로 전체 링크를 새로 배선하고 무결성 검사를 통과한 상태입니다.

```
LoadImage(캐릭터 참조).IMAGE       → IPAdapterAdvanced.image
IPAdapterUnifiedLoader.MODEL       → IPAdapterAdvanced.model
IPAdapterUnifiedLoader.IPADAPTER   → IPAdapterAdvanced.ipadapter
IPAdapterAdvanced.MODEL(출력)       → KSampler.model
CLIPTextEncode(+/-)                → ControlNetApplyAdvanced(positive/negative)
ControlNetApplyAdvanced(출력)       → KSampler(positive/negative)
EmptyLatentImage.LATENT            → KSampler.latent_image
KSampler.LATENT                    → VAEDecode.samples
CheckpointLoaderSimple.VAE         → VAEDecode.vae   (samples와 링크 id 공유하지 않음)
VAEDecode.IMAGE                    → SaveImage.images
```

포즈 참조(LoadImage `pose_reference.png` → DWPreprocessor → ControlNetApplyAdvanced)는 기존 설계대로 기본은 `mode: 4`(비활성/우회)로 꺼져 있으며, 이 상태에서는 ControlNetApplyAdvanced가 conditioning을 그대로 통과시키므로 CLIPTextEncode 결과가 곧바로 KSampler에 전달됩니다. 사용자가 포즈 참조 이미지를 넣고 이 노드들을 활성화하면 ControlNet이 추가로 적용됩니다.

### 4-3. Manus가 이번 단계에서 할 일 (재진단 불필요, 검증만)

1. 동봉한 **`validate_workflow_links.py`**를 저장소의 워크플로우 검증 스크립트로 채택(또는 이를 베이스로 `fix_workflow_links.py`/`validate_stage2.py`에 통합)하고, 4개 워크플로우(§2-7 확정본) 전부에 대해 실행해 전부 PASS인지 재확인합니다. (Claude가 이미 4개 전부 PASS를 확인했으나, Manus 환경에서도 동일 결과가 나오는지 재현 확인 필요.)
2. **앞으로 워크플로우 JSON을 새로 만들거나 수정할 때마다 출고 전에 반드시** 이 스크립트(또는 동등 검증)를 통과시킵니다. 통과 못하면 절대 전달하지 않습니다.
3. **게이트 1**에서 Owl님이 ComfyUI API `/prompt`에 실제로 큐를 넣어 4개 워크플로우 전부 에러 없이 끝까지 실행되는지 확인합니다. JSON 문법이 맞다고 그래프가 맞는 게 아니라는 걸 이번에 확인했으므로, 정적 검증과 실제 큐 실행 둘 다 필요합니다.
4. 위 3개 정상 워크플로우 + 이번 수정본 4개 전부에 대해, `CheckpointLoaderSimple` 위젯 값을 §3-3의 NoobAI-XL Epsilon-pred v1.1 파일명으로 교체하고 `VAELoader`로 `sdxl-vae-fp16-fix`를 별도 로드하도록 반영합니다.

### 4-4. 코드 구조 정리 (patch_*.py 근본 해결)

- 기존 patch/fix 파일(약 50개)의 목적을 먼저 인벤토리로 정리합니다(저장소에 있다면 그걸 기준으로, 없다면 Owl님에게 요청).
- §9 UI를 새로 만드는 작업을 기회로 삼아 패치를 쌓지 않는 단일하고 깔끔한 코드베이스로 재작성합니다.
- 반복 발생했던 버그(흰 화면, 캐시 문제, 사라진 버튼 등)는 증상만 패치하지 말고 근본 원인을 구조적으로 고칩니다.

---

## 5. Scene 이해 및 캐릭터 시스템

### 5-1. Semantic Scene Parser

```
Scene
├── Characters
│   ├── Identity / Biological Sex / Gender Expression
│   ├── Face, Body Type, Physical Traits, Hair, Eyes
│   ├── Clothing (Top/Bottom/Outer/Underwear/Socks/Shoes/Gloves/Hat/Accessories로 세분화)
│   ├── Pose, Expression, Gaze, Position
├── Environment (Location, Background, Props, Lighting)
├── Camera (Position, Angle, Shot Type, Perspective, Composition)
├── Style
├── References
└── Generation Settings
```

Common Scene Data는 모델이 바뀌어도 유지되며, Model Adapter가 체크포인트별 Prompt/Tag/Conditioning으로 변환합니다(§5-5). "상의만 변경"처럼 부분 수정 지시가 오면 다른 요소는 최대한 유지합니다.

### 5-2. 캐릭터 속성 분리

Biological Sex / Gender Expression / Face / Body Type / Physical Traits / Clothing / Pose / Expression을 서로 독립적으로 관리합니다.

### 5-3. Multi-character 처리 (자동 검사는 §6-확장, MVP 아님)

여러 캐릭터 등장 시 캐릭터별 Reference/Conditioning을 가능하면 독립 처리합니다.

### 5-4. Reference Image 시스템

Character Appearance / Face / Pose / Clothing / Background / Style / Composition·Camera / Prop·Accessory Reference를 독립적으로 제공하며 동시 조합 가능해야 합니다.

### 5-5. 모델 추상화 구조

```
Common Scene Data → Model Adapter → Model-specific Prompt/Conditioning → Workflow Adapter → ComfyUI
```

### 5-6. Character Consistency & Story State

- 기본 전략(LoRA 없이): §3-4 파일 세트로 **IP-Adapter FaceID Plus v2(weight 0.70~0.85) + ControlNet OpenPose + 고정 Seed/Generation Metadata**.
- FaceID 정확도가 부족하면 §3-4의 `ip-adapter-plus_sdxl_vit-h.safetensors`(전신/의상 참조)를 함께 적용해 보강합니다.
- 확장 전략(선택, 필수 아님): 등장 빈도 높은 주인공에 한해 15~50장으로 캐릭터 전용 LoRA 학습(로컬 1~4시간, VRAM 여유 시 야간 실행).
- **Story State**: 캐릭터별 현재 의상/액세서리/위치/소품/스토리 진행 상태 저장.
- **Generation Metadata**: 매 생성마다 Model/VAE/LoRA/ControlNet/IPAdapter/Prompt/Negative/Seed/Steps/CFG/Sampler/Resolution/Reference Images/Workflow/Timestamp 저장.
- **Generation History & Undo**: 패널별 버전 관리, Inpainting은 Original→Repair 1→Repair 2 단계별 되돌리기, 원본은 항상 보존.

### 5-7. VRAM 8GB 관리

Low VRAM / CPU Offload / Sequential Loading / Model Unload / Tiled VAE 활용. 체크포인트는 fp8/GGUF 양자화 기본, CLIP/Text Encoder는 CPU 오프로드, ControlNet/IPAdapter는 필요한 패널에서만 순차 로딩 후 언로드. 각 워크플로우에 예상 VRAM 사용량 등급을 표시합니다.

---

## 6. 검수 및 보정 (MVP)

생성된 이미지에서 손/손가락/발/신발/얼굴/눈/귀/머리카락/액세서리/의상/소품 오류를 검사하되, 문제가 있어도 전체 재생성하지 않고 필요한 부분만 Inpainting합니다. 영역 밖 얼굴/의상/배경/구도는 최대한 보존합니다.

## 6-확장. Automatic Visual Verification + Multi-character 자동 검사 (MVP 이후)

Vision AI/VLM으로 Character Count/Position/Face/Hair/Clothing/Pose/Expression/Gaze/Background/Hands/Feet를 체크리스트(✓/✗)로 보여주고, Full Regenerate/Partial Repair/Accept 중 선택하게 합니다. §5-3의 Character Missing/Duplicate/Attribute Swap/Clothing Swap/Face Swap/Pose Swap/Position Swap 검사도 이 VLM 파이프라인에 포함합니다. 자동 반복 보정은 최대 1~3회로 제한합니다.

---

## 7. Model Manager / 설치 자동화 / 오류 처리

### 7-1. 설치 자동화

Python/runtime, Git, ComfyUI(§3-2 포크), Custom Node(§3-5), Checkpoint/VAE/ControlNet/IPAdapter(§3-3, §3-4), Upscaler, Face/Hand/Pose 모델, Workflow JSON까지 자동 구성합니다. 이미 설치된 것은 재설치하지 않습니다.

### 7-2. Model Manager 화면 — 자동 다운로드 실패 시 수동 삽입 UX

설치된/부족한 모델 관리 화면. Model Name/File Name/Type/Purpose/Status(Installed/Missing)/VRAM 예상 요구량/실제 경로/권장도를 표시합니다. 각 "Missing" 모델 카드에는 **아래 4개 버튼을 반드시 포함**해서, 자동 다운로드가 실패하거나 처음부터 불가능한 경우에도 Owl님이 직접 쉽게 채울 수 있게 합니다.

1. **[파일명 복사]** — 정확한 파일명을 클립보드로 복사
2. **[다운로드 페이지 열기]** — 공식 다운로드 URL을 새 브라우저 탭에서 열기
3. **[저장 폴더 열기]** — 해당 모델의 정확한 목표 경로(`ComfyUI/models/ipadapter/` 등)를 Windows 탐색기로 즉시 열기(`explorer.exe <path>`) — 다운받은 파일을 그 창에 끌어다 놓기만 하면 되게 함
4. **[재스캔]** — 폴더 내용을 다시 검사해 Installed/Missing 상태 갱신

Civitai(NoobAI-XL 등)처럼 **로그인/연령 확인/라이선스 동의가 필요한 모델은 자동 다운로드를 아예 시도하지 않고**, 처음부터 위 수동 절차로 안내합니다(시도 후 실패 메시지가 뜨는 방식보다 우선). **Drag & Drop 자동 배치는 파일명 패턴 + 메타데이터 헤더 검사 휴리스틱 수준으로 기대치를 설정**하고, 애매하면 사용자에게 선택지를 보여줍니다("자동 배치"가 아니라 "배치 제안"에 가깝게 설계).

### 7-3. 라이선스 확인

자동 다운로드 전 상업적 이용·재배포·자동 다운로드 가능 여부를 확인합니다. 불명확하면 정확한 모델명·파일명·용도·공식 다운로드 위치·저장 폴더·설치 확인 방법을 안내하고 §7-2의 수동 설치 흐름으로 넘깁니다.

### 7-4. 오류 메시지 및 설치 실패 대응

원인 분류: VRAM 부족/Model Missing/Custom Node Missing/Backend Error/ControlNet Error/Workflow Error/Invalid Model/Unsupported Configuration. `Problem/Cause/Required File/Required Version/Required Path/Solution/Retry` 형식으로 안내하고, 가능하면 자동 수정 후 재시도합니다.

---

## 8. ComfyUI 설치 방식 — 완전 독립형

- AI Manga Studio는 §3-2의 `patientx-cfz/comfyui-rocm` 포크를 자체 폴더에 완전히 별도 경로로 설치합니다. 기존 ComfyUI와 물리적으로 완전히 분리합니다.
- 기존 ComfyUI의 Workflow, Checkpoint, LoRA, Custom Node, 설정은 조회만 하고 절대 삭제/이동/덮어쓰기하지 않습니다.
- 기존 폴더의 Animagine XL 4.0 등은 복사해서 재사용하되 원본은 그대로 둡니다(심볼릭 링크/복사 중 더 안정적인 방식을 선택해 보고서에 명시).

---

## 9. UI/UX 사양

### 9-0. 목표 수준

죽은 버튼 금지, 라벨만 봐도 기능을 알 수 있게, 여백/정렬/타이포그래피 일관성, 로딩·진행 상태의 명확한 시각 피드백.

### 9-1. 레이아웃 참고

`https://betterwaifu.com/ko/create` — 화면 구성·정렬 방식만 참고(콘텐츠·문구·브랜딩과 무관). 좌측 컨트롤 패널 / 중앙 캔버스(미리보기) / 우측 기록·갤러리 패널 3분할. 좌측 패널은 위→아래로 "무엇을 그릴지 → 어떻게 그릴지 → 참조 이미지 → 출력 형식 → 고급 설정 → 생성 버튼" 순서. 각 옵션 카테고리는 collapsible. 상단에 페이지 전환 탭 고정.

### 9-2. 화면 구성 상세

**상단 바(고정)**: 좌 — 로고/프로젝트명, 프로젝트 선택 드롭다운. 우 — [만들기] [패널 편집기] [내 작업 기록] 탭, 다크모드 토글.

**좌측 컨트롤 패널**(스크롤 가능, 섹션별 접기/펼치기):

| 섹션 | 포함 기능 | 비고 |
|---|---|---|
| 1) 한국어 프롬프트 입력 | 자연어 텍스트박스 + "해석 보기" 버튼 | 해석 결과(장면 구조 태그+처리 경로) 펼침, 직접 수정 가능 |
| 2) 캐릭터 참조 | 등록된 캐릭터 목록, 새 캐릭터 등록, 이번 패널 적용 캐릭터 선택(다중 가능) | IP-Adapter 참조 이미지와 연결 |
| 3) 워크플로우/모델 | 자동 판단된 워크플로우 표시, 수동 오버라이드, 체크포인트 선택 | 기본 "자동" |
| 4) 포즈/구도 | ControlNet(OpenPose) 참조 이미지 업로드 또는 프리셋 포즈 | |
| 5) 출력 형식 | 레이아웃(세로스크롤/페이지 만화책), 컬러모드(컬러/흑백+톤), 컷 비율(4:5, 2:3, 9:16, 1:1)+커스텀 | 프로젝트 생성 시 1회, 패널별 변경 가능 |
| 6) 생성 매수 | "1장"/"후보 4장 중 선택" 토글 | 배치는 후보 선택용 |
| 7) 고급 설정(기본 접힘) | Steps, CFG, Sampler, Seed(고정/랜덤) | 초보자는 기본값으로 동작 |

- **생성 버튼**은 좌측 패널 하단 항상 고정. 누르면 "최종 프롬프트 미리보기" 팝업이 항상 뜨고, 확인해야 생성 시작.

**중앙 캔버스**: 현재 패널 미리보기, 진행률 표시. 결과 위에서 인페인팅 영역 지정. 이전/다음 패널 이동, 페이지 내 컷 순서 재배열(드래그).

**우측 기록/갤러리 패널**: 세션 생성 이미지 히스토리(그리드), 즐겨찾기, 프로젝트별 필터. 썸네일에 Seed/프롬프트/워크플로우 메타데이터(재사용 버튼 포함).

**만화 에디터 화면**(별도 탭): 페이지 레이아웃, Panel 생성/리사이즈/이동/순서변경, 말풍선, 대사, SFX 배치, Export(웹툰용 롱스트립/페이지 PDF·이미지 시퀀스). 대사·말풍선은 AI 이미지 생성과 완전히 분리된 별도 편집 레이어. "Open in ComfyUI" 버튼 제공.

### 9-3. 필수 요건

- 모든 버튼/토글은 실제 백엔드 기능과 연결(죽은 버튼 금지).
- §9-2 위치를 벗어나 임의 재배치하지 않습니다.
- UI 구현 완료 시 UI 항목 ↔ 실제 기능 매핑표를 체크리스트로 제출합니다.

---

## 10. 프로젝트/파일 구조

```
Project/
├── project.json
├── characters/
├── styles/
├── references/
├── scenes/
├── panels/
├── pages/
├── prompts/
├── outputs/
├── metadata/
└── backups/
```

프로젝트 전체 Export/Import가 가능하게 해서 다른 PC에서도 복구 가능한 구조로 만듭니다.

---

## 11. 패키징 및 배포 — "게임처럼 설치·삭제가 쉬운" 설치 파일 (MVP 이후)

이 요구사항의 배경: 이 프로젝트는 개발 중 여러 차례 수정하며 재설치/삭제를 반복하게 됩니다. Owl님이 매번 편하게 지우고 다시 깔 수 있어야 개발 자체가 수월해지고, 최종 사용자 경험으로도 그대로 이어집니다.

- 최종 산출물은 **Inno Setup**으로 만든 실행 가능한 설치 프로그램(.exe) 1개.
- 설치 마법사: 설치 경로 선택(기본값), 바탕화면 바로가기(기본 체크), 시작 메뉴 등록, 진행률, 완료 후 "지금 실행".
- **Windows "설정 → 앱 및 기능"에서 표준 방식으로 완전히 제거 가능.** 별도 `Uninstall.exe` 포함.
- 제거 시 사용자 작업물(생성 이미지, 프로젝트 파일)은 기본 보존. "프로그램 파일만 삭제/작업물까지 삭제" 2가지 옵션 확인창 제공.
- §8의 완전 독립형 설치(ComfyUI 포함 일체형)로 구현.
- 아이콘, 제품명, 버전 정보, 게시자 이름을 정상적으로 채웁니다. **코드 서명은 하지 않습니다(§3-11).**
- 기존 `AI_Webtoon_Studio_Setup_v2_3.exe`, `MangaSceneStudio_Setup.exe`의 설치 경험 수준을 유지하되, 대상 범위를 완전 독립형 프로그램 전체로 확장합니다.

---

## 12. SmartScreen 대응 (MVP 이후, §3-11과 연동)

- 서명 없이 배포하므로 SmartScreen 경고가 뜹니다. 설치 안내 문서(또는 설치 화면 자체)에 "추가 정보 → 실행" 우회 절차를 스크린샷과 함께 포함합니다.
- 배포용 설치 파일을 다른 PC(또는 가상환경)에서 다운로드→실행까지 재현해보고 어떤 경고가 뜨는지 캡처해서 보고에 포함합니다.

---

## 13. 단계별 진행 순서 (게이트 매핑 포함)

| 단계 | 내용 | 검증 |
|---|---|---|
| 1 | 저장소 clone/pull 확인, `PROGRESS.md` 확인, 기존 산출물 인벤토리, patch_*.py 통폐합 구조 설계, `comfyui-rocm` 기반 독립형 설치 구조 확정 | [Manus 자체] |
| 2 | 한국어 NLU(§3-9) 파이프라인 + 프롬프트 미리보기 UI | [Manus 자체] |
| 3 | `validate_workflow_links.py` 채택·확장, 4개 워크플로우(§4에서 이미 수정 완료) 검증, `/prompt` 실제 큐 테스트 | **게이트 1** |
| 4 | 캐릭터 시스템/Scene Parser/Reference 시스템 백엔드(§5) | [Manus 자체](코드) |
| 5 | 검수·보정 파이프라인 MVP(§6) | **게이트 2** |
| 6 | 전체 UI 구현 — 기능별로 쪼개서 진행(§9) | [Manus 자체](구조) |
| 7 | Manga Editor(페이지/말풍선/대사/SFX/Export)(§9-2, §10) | **게이트 3** |
| 8 | (MVP 완료 후) 패키징(Inno Setup) + 설치/삭제 테스트(§11) | **게이트 4** |
| 9 | (MVP 완료 후) SmartScreen 안내 문서 작성(§12) | **게이트 4**(동시 확인) |
| 10 | (MVP 완료 후) 확장 기능(Multi-character 자동검사, VLM 검수, 캐릭터 LoRA) | **게이트 5** |
| 11 | 통합 테스트 + 최종 보고 | **게이트 5**(동시 확인) |

---

## 14. 완료 기준 (DoD) — MVP / 확장 분리, 검증 주체 태그 포함

### MVP

- [Manus 자체] Qwen3-8B GGUF Q4_K_M 로컬 파싱 파이프라인 동작(OpenAI 키 없이도 정상 동작 확인), EXAONE/Bllossom 비교 후 최종 1개로 확정된 근거
- [Manus 자체] 생성 전 프롬프트 미리보기/수정 UI 동작
- [게이트 1] `통합_자연어_IPAdapter_ControlNet` 재구성 확인 + 그래프 검증 스크립트 통과 결과 (파일은 이미 §4에서 제공됨 — 재검증만)
- [게이트 1] `/prompt` 실제 큐 실행 성공 로그/스크린샷(4개 워크플로우 전부)
- [Manus 자체] `patch_*.py` 정리 후 코드 구조 설명
- [게이트 2] §3-4 파일 세트로 Character Consistency 여러 패널 연속 생성 확인
- [게이트 2] Generation Metadata/History/Undo 동작 확인
- [게이트 2] Targeted Inpainting이 지정 영역 밖을 보존하는지 확인
- [Manus 자체] UI 전 항목 ↔ 실제 기능 매핑 체크리스트
- [게이트 3] Manga Editor와 Export(롱스트립/PDF) 동작 확인
- [Manus 자체] 프로젝트 Export/Import 동작 확인
- [게이트 1] 기존 ComfyUI 환경 손상 없이 보존됨 확인
- [Manus 자체] `validate_stage2.py` 기준 §3-5 커스텀노드/§3-3·3-4 모델 설치 확인 결과(경로·존재 여부까지는 자체 확인, 실제 로딩은 게이트 1에서)
- [게이트 1] NoobAI-XL Epsilon-pred v1.1 + `sdxl-vae-fp16-fix` 적용 확인(검은 이미지/NaN 없음), 4개 워크플로우 전부 반영 확인
- [게이트 1] `patientx-cfz/comfyui-rocm` 설치 및 실제 안정성 확인

### 확장(MVP 안정화 이후)

- [게이트 5] Multi-character 오류 자동 검사 동작 확인
- [게이트 5] Automatic Visual Verification(VLM 기반) 동작 확인, 자동 반복 보정 1~3회 제한 확인
- [Manus 자체] Model Manager 화면 설치 상태·Drag&Drop 배치 제안·§7-2의 4버튼 수동 설치 UX 동작 확인
- [Manus 자체] 오류 메시지 분류 및 해결 방법 안내 동작 확인
- [게이트 5] 캐릭터 전용 LoRA 학습 파이프라인(선택 기능) 동작 확인
- [게이트 4] Inno Setup 설치 파일(.exe) 1개 배포, 완전 독립형 설치, 바탕화면 바로가기·시작메뉴 등록 확인 스크린샷
- [게이트 4] Windows "앱 및 기능"에서 정상 제거되는지(작업물 보존 옵션 포함) 확인 스크린샷
- [게이트 4] SmartScreen 경고 실제 재현 캡처 + 우회 안내 문서

---

## 15. 보고 형식

각 단계 완료 시 함께 제출: (1) §14 해당 항목의 상태(완료/부분완료/미완료+사유), (2) `validate_workflow_links.py` 실행 결과, (3) 가능한 경우 실제 생성 성공 스크린샷/로그, (4) §1의 저장소 clone/pull 성공 여부(매 세션 첫 응답), (5) 예외 사유로 보고가 필요한 사항(있는 경우에만). 게이트 항목은 §2-2의 3종 세트(스크린샷/로그/조작 순서)를 저장소 `/verification/gate-N/`에 커밋.

---

## 부록 A. 지금 함께 전달하는 파일 (저장소에 올릴 것)

| 파일 | 상태 |
|---|---|
| 이 문서(`AI_Manga_Studio_최종요청서_v8.md`) | 이번 세션의 유일한 지시서 — v6/v7/보완요청서 대체 |
| `RX6600_AnimagineXL_기본생성.json` | 검증 완료(§2-7 원본대로 PASS) |
| `RX6600_AnimagineXL_참조이미지_img2img.json` | 검증 완료(PASS) |
| `RX6600_AnimagineXL_ImpactPack_얼굴손_Detailer.json` | 검증 완료(PASS) |
| `RX6600_AnimagineXL_통합_자연어_IPAdapter_ControlNet_FIXED.json` | **이번에 새로 수정·검증 완료(PASS)** — §4 참고 |
| `validate_workflow_links.py` | 워크플로우 그래프 무결성 검사 스크립트 — §4-3 채택 |
| `DxDiag.txt` | 하드웨어 실측 참고 자료 |

Owl님이 가지고 있는 기존 `patch_*.py`, 기존 ComfyUI 폴더 관련 자료가 있다면 같은 저장소에 추가로 올려주세요(§3-6 검증용).

## 부록 B. 자연어 처리 예시 — Manus 참고용 (§3-9 검증 시나리오)

Manus는 2단계 자체 검증 시 아래와 같은 다양한 난이도의 한국어 문장으로 로컬 LLM 파서를 테스트하고 결과를 보고합니다(사전 매칭이 아니라 실제 이해인지 확인하는 목적).

- 단순: "카페에서 커피 마시는 여학생, 정면"
- 중간: "비 오는 골목에서 우산을 쓴 채 뒤돌아보는 남자, 로우앵글"
- 복합/모호: "어제랑 비슷한데 표정만 좀 더 놀란 느낌으로, 배경은 그대로"(직전 Scene State 참조 필요)
- 부분 수정: "상의만 교복 재킷으로 바꿔줘"(다른 요소 유지 필요)
