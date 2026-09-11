# AI Manga Studio — Manus 개발 요청서 (완전 통합 최종본 v6)

> v5까지의 모든 "A 또는 B", "상황에 따라 판단" 표현을 제거하고 **단일 결정**으로 확정한 버전입니다. Manus는 판단하지 말고 이 문서의 지정값을 그대로 실행하세요. 정보 수집·비교판단은 이미 Claude가 끝냈습니다 — Manus는 제작에만 집중하면 됩니다.

---

## 0. 프로젝트 정체성

한국어로 장면을 설명하면 캐릭터 일관성을 유지한 채 여러 컷을 이어서 만들고, 말풍선·대사·효과음까지 배치해 완성된 웹툰 한 편으로 뽑아내는 로컬 제작 툴.

```
한국어 자연어 입력 → 장면 이해 → 캐릭터/참조/포즈 제어 → 이미지 생성
→ 검수 → 부분 보정 → 캐릭터 일관성 유지 → 여러 패널 → 페이지 배치
→ 대사/효과음 → 만화 Export
```

---

## 1. 작업 방식 원칙

1. 이 문서 전체를 한 번에 던지지 않는다. §12 순서대로 세션을 나눠 진행하고, 단계 완료 시 결과물(코드 diff 요약, 스크린샷, 검증 로그)을 먼저 제출한 뒤 넘어간다. 단계를 넘길 때는 해당 섹션만 발췌 전달한다.
2. **이 문서의 모든 항목은 이미 확정값이다. 대안 제시·재질문 금지.**
3. 예외(반드시 보고): (a) 아래 확정값이 실측에서 실제로 동작하지 않는 경우, (b) 라이선스상 자동화 불가한 경우, (c) 문서에 없는 새로운 모호함. 이 경우 무엇을 발견했는지 + 대안 후보를 보고하고 지시를 기다린다.
4. §13 DoD는 MVP/확장으로 나뉘어 있다. 각 항목 상태(완료/부분완료/미완료+사유)를 표시해 제출한다.

---

## 2. 확정 사양 (전부 단일 값 — 선택지 없음)

### 2-1. 하드웨어/환경

| 항목 | 값 |
|---|---|
| OS | Windows 11 Home 64-bit |
| CPU / RAM | AMD Ryzen 5 5600X / 32GB |
| GPU | AMD Radeon RX 6600, VRAM 8GB, gfx1032 |

### 2-2. ComfyUI 백엔드 — `patientx-cfz/comfyui-rocm` 포크로 고정

- 저장소: `https://github.com/patientx-cfz/comfyui-rocm`
- 이유: 원래 쓰이던 `patientx/ComfyUI-Zluda`는 저장소 관리자 본인이 이 포크로 대체됐다고 명시함. gfx103x(6600/6700/6800 포함) 계열용 ROCm nightly 휠 자동 설치, 포터블 venv 자가 완결, 패키지 자동 업데이트를 기본 제공하며 사용자 환경에서 실제로 동작 확인된 경로(`PyTorch 2.12.0+rocm7.14.0`)와 일치한다.
- **ZLUDA/DirectML은 별도로 설치하지 않는다.** 이 포크가 이미 gfx1032를 다루는 유일하게 유지되는 경로이므로 이원화하지 않는다. 단, 이 포크의 GitHub Issues/Discussions에서 gfx1032 관련 회귀가 보고되면(§1-3 예외 a) 즉시 보고한다.
- AI Manga Studio는 이 포크를 **독립 경로에 별도로 설치**한다(§7, 기존 ComfyUI와 물리적으로 분리).
- 사전 설치물: Git, Python 3.12, Visual C++ Runtime(`vc_redist.x64.exe`), Visual Studio Build Tools — 전부 이 포크의 README 절차대로 자동/수동 설치.

### 2-3. 체크포인트/VAE

| 항목 | 값 |
|---|---|
| 체크포인트 | **NoobAI-XL Epsilon-pred v1.1** (Civitai `civitai.com/models/833294`, Epsilon-pred 계열 중 가장 최신 버전 — 설치 시점에 페이지에서 Epsilon-pred 태그가 붙은 버전 중 번호가 가장 높은 것을 받는다. V-Pred 계열은 받지 않는다). |
| VAE | `sdxl-vae-fp16-fix.safetensors` (madebyollin, Hugging Face) — `VAELoader`로 명시적 로드, 체크포인트 내장 VAE는 사용하지 않는다. |
| 보조 체크포인트 | Animagine XL 4.0(기존 보유분) — 삭제하지 않고 Model Adapter 보조 옵션으로 유지. |

### 2-4. 캐릭터 일관성용 모델 파일 (정확한 파일명 — 반드시 세트로 맞출 것)

| 역할 | 파일 | 저장 위치 |
|---|---|---|
| Face ID 임베딩 | `ip-adapter-faceid-plusv2_sdxl.bin` | `ComfyUI/models/ipadapter/` |
| Face ID 전용 LoRA (필수, 짝이 다르면 오류) | `ip-adapter-faceid-plusv2_sdxl_lora.safetensors` | `ComfyUI/models/loras/` |
| Face ID용 CLIP Vision 인코더 | `CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors` | `ComfyUI/models/clip_vision/` |
| 전신/의상 보조 IPAdapter | `ip-adapter-plus_sdxl_vit-h.safetensors` | `ComfyUI/models/ipadapter/` (위와 같은 ViT-H 인코더 재사용) |
| 포즈 ControlNet | `OpenPoseXL2.safetensors` | `ComfyUI/models/controlnet/` |
| 포즈 검출기 | `yolox_l.onnx`, `dw-ll_ucoco_384_bs5.torchscript.pt` | `ComfyUI/models/dwpose/` (또는 해당 커스텀노드 지정 경로) |
| 얼굴 Detailer bbox | `bbox/face_yolov8m.pt` | Impact Pack 지정 경로 |
| 손 Detailer bbox | `bbox/hand_yolov8s.pt` | Impact Pack 지정 경로 |

**타입/인코더가 안 맞으면 텐서 크기 불일치 오류가 나므로, 위 표의 조합을 임의로 바꾸지 않는다.**

### 2-5. 필수 커스텀 노드 (저장소 고정)

| 노드 | 저장소 |
|---|---|
| IPAdapter | `cubiq/ComfyUI_IPAdapter_plus` |
| ControlNet 전처리(DWPose 등) | `Fannovel16/comfyui_controlnet_aux` |
| Face/Hand Detailer | `ltdrdata/ComfyUI-Impact-Pack` + `ltdrdata/ComfyUI-Impact-Subpack` |

`validate_stage2.py`(또는 동등 스크립트)로 위 3개 저장소 기준 설치 여부를 확인하고 결과를 보고한다.

### 2-6. 기존 환경 보호

기존 ComfyUI(별도 폴더, Workflow 3개 보유)는 절대 건드리지 않는다(삭제/덮어쓰기/초기화 금지). AI Manga Studio는 §7에 따라 완전 독립 설치.

### 2-7. 검증된/오류있는 워크플로우

- 검증 완료(제 그래프 대조 검증 결과 이상 없음): `RX6600_AnimagineXL_기본생성.json`, `RX6600_AnimagineXL_참조이미지_img2img.json`, `RX6600_AnimagineXL_ImpactPack_얼굴손_Detailer.json`. 이 3개를 기준 템플릿으로 삼되, 아래 2가지를 반영: (1) `CheckpointLoaderSimple` 위젯 값을 NoobAI-XL Epsilon-pred v1.1 파일명으로 교체, (2) `VAELoader`로 `sdxl-vae-fp16-fix` 별도 로드.
- 오류 확인됨: `RX6600_AnimagineXL_통합_자연어_IPAdapter_ControlNet.json` — 단순 링크 스와프가 아니라 여러 링크 id가 서로 다른 슬롯/타입을 참조하며 얽힌 상태(예: `IPAdapterAdvanced.image`가 실제로는 KSampler→VAEDecode 사이 LATENT 링크를 참조, `VAEDecode`의 `samples`/`vae` 두 입력이 링크 id를 공유). **부분 수정하지 말고 §3-2 절차대로 재구성한다.**

### 2-8. 패널 생성 방식

멀티패널 동시 생성 금지. 패널은 1장씩 순차 생성, 직전 패널의 캐릭터 참조/Seed/Metadata를 이어받는다. "후보 4장 동시 생성"은 같은 컷 후보 선택용으로만 사용.

### 2-9. 로컬 한국어 LLM

| 항목 | 값 |
|---|---|
| 모델 | **Qwen3-8B-Instruct, GGUF `Q4_K_M` 양자화** (Hugging Face의 공식/신뢰 GGUF 배포본, 예: Unsloth 또는 Qwen 공식 GGUF 리포지토리) |
| 실행 | `llama.cpp`(또는 `llama-cpp-python`)로 **CPU 전용** 구동, thinking mode는 끈다 |
| RAM 여유 확인 | Q4_K_M 기준 약 5~6GB RAM 필요 — 32GB 환경에서 여유 충분, GPU와 리소스 경쟁 없음 |
| 비교 테스트 대상(2순위, 채택 여부만 결정) | EXAONE(LG AI연구원 최신 버전), Bllossom GGUF — 실제 한국어 문장 샘플로 Qwen3-8B와 비교 후 **더 나은 쪽 하나로 최종 확정**해서 보고. "두 개 다 옵션으로 남긴다"는 답은 인정하지 않는다. |
| OpenAI 대체 경로 | `OPENAI_API_KEY` 있으면 우선 사용 가능하나, 키 없이도 로컬 LLM 경로만으로 항상 완전히 정상 동작해야 한다. |

### 2-10. 설치 프로그램 도구 — Inno Setup으로 고정

NSIS 대비 Pascal 스크립트가 짧고 표준 마법사(경로 선택/바탕화면 바로가기/시작메뉴/제거 등록)를 기본 제공해 이 규모의 개인용 데스크톱 툴에 더 적합하다. **NSIS는 검토하지 않는다.**

### 2-11. 코드 서명 — 하지 않는다

2024년 3월부터 마이크로소프트가 EV 인증서의 SmartScreen 즉시 통과 혜택을 없앴다. 현재는 EV·OV 모두 다운로드량이 쌓여야 평판이 쌓이는 동일한 구조이며, 연 $250~600(OV는 $65~400)의 비용 대비 개인이 자기 PC 한 대에 설치하는 툴에는 실익이 없다. **서명 인증서를 구매하지 않는다.** 대신:
- 설치 파일에 제품명/버전/게시자/아이콘 메타데이터는 정상적으로 채운다(Inno Setup 표준 방식).
- 설치 화면 또는 안내 문서에 SmartScreen 경고가 뜰 경우의 "추가 정보 → 실행" 우회 절차를 스크린샷과 함께 포함한다.
- 실제 배포용 설치 파일을 한 번 실행해보고 경고 문구를 캡처해서 보고한다.

---

## 3. 이번에 반드시 해결할 핵심 결함 3가지

### 3-1. 한국어 자연어 이해 방식 교체 (최우선)

고정 80개 구문 사전 방식(`translate_helper.py`)은 폐기한다. §2-9에서 확정한 모델로 한국어 문장을 §4 Scene 구조로 분석 후 영어 프롬프트로 변환한다.

- 해석 못한 표현을 버리지 말고 "이 부분은 이렇게 해석했다"를 사용자에게 보여준다.
- 처리 경로(로컬 LLM/OpenAI)를 화면에 항상 표시한다.
- **생성 버튼을 누르기 전 최종 영어 프롬프트를 미리 보여주고, 확인/수정 후에만 생성이 시작되게 한다.**

### 3-2. 워크플로우 그래프 링크 오류 수정 + 재발 방지

`통합_자연어_IPAdapter_ControlNet.json`은 다음 순서로 재구성한다:

1. §2-7에서 검증된 `참조이미지_img2img.json`의 연결 패턴(체크포인트→CLIP/VAE 분기, KSampler 입출력 순서)을 기준 템플릿으로 삼는다.
2. `IPAdapterUnifiedLoader`→`IPAdapterAdvanced`(캐릭터 참조)와 `ControlNetLoader`+`DWPreprocessor`→`ControlNetApplyAdvanced`(포즈 참조)를 **새로 배선**한다. 기존 고장난 파일의 링크 id를 재사용하지 않는다.
3. 목표 연결:
   ```
   LoadImage(캐릭터 참조).IMAGE → IPAdapterAdvanced.image
   IPAdapterUnifiedLoader.MODEL → IPAdapterAdvanced.model
   IPAdapterAdvanced.MODEL(출력) → KSampler.model
   CLIPTextEncode(+/-) → ControlNetApplyAdvanced(positive/negative) → KSampler(positive/negative)
   VAEDecode.samples ← KSampler.LATENT (vae 입력과 링크 id를 절대 공유하지 않는지 확인)
   ```

**앞으로 워크플로우 JSON을 만들거나 수정할 때마다 출고 전에 반드시:**

1. 각 노드 입력의 `link` id가 가리키는 최상위 `links` 배열 항목의 target 노드/슬롯 일치, 타입 일치, 동일 노드의 서로 다른 입력이 link id를 공유하지 않는지 검사하는 스크립트를 실행한다(`fix_workflow_links.py`, `validate_stage2.py` 재사용/확장). 통과 못하면 절대 전달하지 않는다.
2. ComfyUI API `/prompt`에 실제로 큐를 넣어 에러 없이 끝까지 실행되는지 확인한다.

### 3-3. 코드 구조 정리 (patch_*.py 근본 해결)

- 기존 patch/fix 파일(50개 가까이)의 목적을 먼저 인벤토리로 정리한다.
- §8 UI를 새로 만드는 작업을 기회로 삼아 패치를 쌓지 않는 단일하고 깔끔한 코드베이스로 재작성한다.
- 반복 발생했던 버그(흰 화면, 캐시 문제, 사라진 버튼 등)는 증상만 패치하지 말고 근본 원인을 구조적으로 고친다.

---

## 4. Scene 이해 및 캐릭터 시스템

### 4-1. Semantic Scene Parser

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

Common Scene Data는 모델이 바뀌어도 유지되며, Model Adapter가 체크포인트별 Prompt/Tag/Conditioning으로 변환한다(§4-5). "상의만 변경"처럼 부분 수정 지시가 오면 다른 요소는 최대한 유지한다.

### 4-2. 캐릭터 속성 분리

Biological Sex / Gender Expression / Face / Body Type / Physical Traits / Clothing / Pose / Expression을 서로 독립적으로 관리한다.

### 4-3. Multi-character 처리 (자동 검사는 §5-확장으로 이관, MVP 아님)

여러 캐릭터 등장 시 캐릭터별 Reference/Conditioning을 가능하면 독립 처리한다.

### 4-4. Reference Image 시스템

Character Appearance / Face / Pose / Clothing / Background / Style / Composition·Camera / Prop·Accessory Reference를 독립적으로 제공하며 동시 조합 가능해야 한다.

### 4-5. 모델 추상화 구조

```
Common Scene Data → Model Adapter → Model-specific Prompt/Conditioning → Workflow Adapter → ComfyUI
```

### 4-6. Character Consistency & Story State

- 기본 전략(LoRA 없이): §2-4의 파일 세트로 **IP-Adapter FaceID Plus v2(weight 0.70~0.85) + ControlNet OpenPose + 고정 Seed/Generation Metadata**.
- FaceID 정확도가 부족하면 §2-4의 `ip-adapter-plus_sdxl_vit-h.safetensors`(전신/의상 참조)를 함께 적용해 보강한다.
- 확장 전략(선택, 필수 아님): 등장 빈도 높은 주인공에 한해 15~50장으로 캐릭터 전용 LoRA 학습(로컬 1~4시간, VRAM 여유 시 야간 실행).
- **Story State**: 캐릭터별 현재 의상/액세서리/위치/소품/스토리 진행 상태 저장.
- **Generation Metadata**: 매 생성마다 Model/VAE/LoRA/ControlNet/IPAdapter/Prompt/Negative/Seed/Steps/CFG/Sampler/Resolution/Reference Images/Workflow/Timestamp 저장.
- **Generation History & Undo**: 패널별 버전 관리, Inpainting은 Original→Repair 1→Repair 2 단계별 되돌리기, 원본은 항상 보존.

### 4-7. VRAM 8GB 관리

Low VRAM / CPU Offload / Sequential Loading / Model Unload / Tiled VAE 활용. 체크포인트는 fp8/GGUF 양자화 기본, CLIP/Text Encoder는 CPU 오프로드, ControlNet/IPAdapter는 필요한 패널에서만 순차 로딩 후 언로드. 각 워크플로우에 예상 VRAM 사용량 등급 표시.

---

## 5. 검수 및 보정 (MVP)

생성된 이미지에서 손/손가락/발/신발/얼굴/눈/귀/머리카락/액세서리/의상/소품 오류를 검사하되, 문제가 있어도 전체 재생성하지 않고 필요한 부분만 Inpainting한다. 영역 밖 얼굴/의상/배경/구도는 최대한 보존한다.

## 5-확장. Automatic Visual Verification + Multi-character 자동 검사 (MVP 이후)

Vision AI/VLM으로 Character Count/Position/Face/Hair/Clothing/Pose/Expression/Gaze/Background/Hands/Feet를 체크리스트(✓/✗)로 보여주고, Full Regenerate/Partial Repair/Accept 중 선택하게 한다. §4-3의 Character Missing/Duplicate/Attribute Swap/Clothing Swap/Face Swap/Pose Swap/Position Swap 검사도 이 VLM 파이프라인에 포함한다. 자동 반복 보정은 최대 1~3회로 제한.

---

## 6. Model Manager / 설치 자동화 / 오류 처리

### 6-1. 설치 자동화

Python/runtime, Git, ComfyUI(§2-2 포크), Custom Node(§2-5), Checkpoint/VAE/ControlNet/IPAdapter(§2-3, §2-4), Upscaler, Face/Hand/Pose 모델, Workflow JSON까지 자동 구성. 이미 설치된 것은 재설치하지 않는다.

### 6-2. Model Manager 화면

설치된/부족한 모델 관리 화면. Model Name/File Name/Type/Purpose/Status(Installed/Missing)/VRAM 예상 요구량/실제 경로/권장도 표시. **Drag & Drop 자동 배치는 파일명 패턴+메타데이터 헤더 검사 휴리스틱 수준으로 기대치를 설정**하고, 애매하면 사용자에게 선택지를 보여준다("자동 배치"가 아니라 "배치 제안"에 가깝게 설계).

### 6-3. 라이선스 및 수동 설치 안내

자동 다운로드 전 상업적 이용·재배포·자동 다운로드 가능 여부 확인. 불명확하면 정확한 모델명·파일명·용도·공식 다운로드 위치·저장 폴더·설치 확인 방법을 안내하고 수동 설치(Drag & Drop) 지원.

### 6-4. 오류 메시지 및 설치 실패 대응

원인 분류: VRAM 부족/Model Missing/Custom Node Missing/Backend Error/ControlNet Error/Workflow Error/Invalid Model/Unsupported Configuration. Problem/Cause/Required File/Required Version/Required Path/Solution/Retry 형식으로 안내하고 가능하면 자동 수정 후 재시도.

---

## 7. ComfyUI 설치 방식 — 완전 독립형

- AI Manga Studio는 §2-2의 `patientx-cfz/comfyui-rocm` 포크를 자체 폴더에 완전히 별도 경로로 설치한다. 기존 ComfyUI와 물리적으로 완전히 분리.
- 기존 ComfyUI의 Workflow 3개, Checkpoint, LoRA, Custom Node, 설정은 조회만 하고 절대 삭제/이동/덮어쓰기하지 않는다.
- 기존 폴더의 Animagine XL 4.0 등은 복사해서 재사용하되 원본은 그대로 둔다(심볼릭 링크/복사 중 더 안정적인 방식을 선택해 보고서에 명시).

---

## 8. UI/UX 사양

### 8-0. 목표 수준

죽은 버튼 금지, 라벨만 봐도 기능을 알 수 있게, 여백/정렬/타이포그래피 일관성, 로딩·진행 상태의 명확한 시각 피드백.

### 8-1. 레이아웃 참고

`https://betterwaifu.com/ko/create` — 화면 구성·정렬 방식만 참고(콘텐츠·문구·브랜딩과 무관). 좌측 컨트롤 패널/중앙 캔버스(미리보기)/우측 기록·갤러리 패널 3분할. 좌측 패널은 위→아래로 "무엇을 그릴지 → 어떻게 그릴지 → 참조 이미지 → 출력 형식 → 고급 설정 → 생성 버튼" 순서. 각 옵션 카테고리는 collapsible. 상단에 페이지 전환 탭 고정.

### 8-2. 화면 구성 상세

**상단 바 (고정)**: 좌 — 로고/프로젝트명, 프로젝트 선택 드롭다운. 우 — [만들기] [패널 편집기] [내 작업 기록] 탭, 다크모드 토글.

**좌측 컨트롤 패널** (스크롤 가능, 섹션별 접기/펼치기):

| 섹션 | 포함 기능 | 비고 |
|---|---|---|
| 1) 한국어 프롬프트 입력 | 자연어 텍스트박스 + "해석 보기" 버튼 | 해석 결과(장면 구조 태그+처리 경로) 펼침, 직접 수정 가능 |
| 2) 캐릭터 참조 | 등록된 캐릭터 목록, 새 캐릭터 등록, 이번 패널 적용 캐릭터 선택(다중 가능) | IP-Adapter 참조 이미지와 연결 |
| 3) 워크플로우/모델 | 자동 판단된 워크플로우 표시, 수동 오버라이드, 체크포인트 선택 | 기본 "자동" |
| 4) 포즈/구도 | ControlNet(OpenPose) 참조 이미지 업로드 또는 프리셋 포즈 | |
| 5) 출력 형식 | 레이아웃(세로스크롤/페이지 만화책), 컬러모드(컬러/흑백+톤), 컷 비율(4:5, 2:3, 9:16, 1:1)+커스텀 | 프로젝트 생성 시 1회, 패널별 변경 가능 |
| 6) 생성 매수 | "1장"/"후보 4장 중 선택" 토글 | 배치는 후보 선택용 |
| 7) 고급 설정 (기본 접힘) | Steps, CFG, Sampler, Seed(고정/랜덤) | 초보자는 기본값으로 동작 |

- **생성 버튼**은 좌측 패널 하단 항상 고정. 누르면 "최종 프롬프트 미리보기" 팝업이 항상 뜨고, 확인해야 생성 시작.

**중앙 캔버스**: 현재 패널 미리보기, 진행률 표시. 결과 위에서 인페인팅 영역 지정. 이전/다음 패널 이동, 페이지 내 컷 순서 재배열(드래그).

**우측 기록/갤러리 패널**: 세션 생성 이미지 히스토리(그리드), 즐겨찾기, 프로젝트별 필터. 썸네일에 Seed/프롬프트/워크플로우 메타데이터(재사용 버튼 포함).

**만화 에디터 화면** (별도 탭): 페이지 레이아웃, Panel 생성/리사이즈/이동/순서변경, 말풍선, 대사, SFX 배치, Export(웹툰용 롱스트립/페이지 PDF·이미지 시퀀스). 대사·말풍선은 AI 이미지 생성과 완전히 분리된 별도 편집 레이어. "Open in ComfyUI" 버튼 제공.

### 8-3. 필수 요건

- 모든 버튼/토글은 실제 백엔드 기능과 연결(죽은 버튼 금지).
- §8-2 위치를 벗어나 임의 재배치하지 않는다.
- UI 구현 완료 시 UI 항목 ↔ 실제 기능 매핑표를 체크리스트로 제출.

---

## 9. 프로젝트/파일 구조

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

프로젝트 전체 Export/Import 가능하게 해서 다른 PC에서도 복구 가능한 구조로 만든다.

---

## 10. 패키징 및 배포 (MVP 이후)

- 최종 산출물은 **Inno Setup**으로 만든 실행 가능한 설치 프로그램(.exe) 1개.
- 설치 마법사: 설치 경로 선택(기본값), 바탕화면 바로가기(기본 체크), 시작 메뉴 등록, 진행률, 완료 후 "지금 실행".
- Windows "설정 → 앱 및 기능"에서 표준 방식으로 제거 가능. 별도 `Uninstall.exe` 포함.
- 제거 시 사용자 작업물(생성 이미지, 프로젝트 파일)은 기본 보존. "프로그램 파일만 삭제/작업물까지 삭제" 2가지 옵션 확인창 제공.
- §7의 완전 독립형 설치(ComfyUI 포함 일체형)로 구현.
- 아이콘, 제품명, 버전 정보, 게시자 이름을 정상적으로 채운다. **코드 서명은 하지 않는다(§2-11).**
- 기존 `AI_Webtoon_Studio_Setup_v2_3.exe`, `MangaSceneStudio_Setup.exe`의 설치 경험 수준을 유지하되, 대상 범위를 완전 독립형 프로그램 전체로 확장한다.

---

## 11. SmartScreen 대응 (MVP 이후, §2-11과 연동)

- 서명 없이 배포하므로 SmartScreen 경고가 뜬다. 설치 안내 문서(또는 설치 화면 자체)에 "추가 정보 → 실행" 우회 절차를 스크린샷과 함께 포함한다.
- 실제 배포용 설치 파일을 다른 PC(또는 가상환경)에서 다운로드→실행까지 재현해보고 어떤 경고가 뜨는지 캡처해서 보고에 포함한다.

---

## 12. 단계별 진행 순서

| 단계 | 내용 |
|---|---|
| 1 | 기존 산출물 인벤토리, patch_*.py 통폐합 구조 설계, `patientx-cfz/comfyui-rocm` 기반 독립형 설치 구조 확정 |
| 2 | 한국어 NLU(Qwen3-8B GGUF Q4_K_M, §2-9) 파이프라인 + 프롬프트 미리보기 UI (§3-1) |
| 3 | 워크플로우 그래프 검증 스크립트 작성 + 4개 워크플로우 검증/재구성 + `/prompt` 실제 큐 테스트 (§3-2) |
| 4 | 캐릭터 시스템/Scene Parser/Reference 시스템 백엔드 (§4) |
| 5 | 검수·보정 파이프라인 MVP (§5) |
| 6 | 전체 UI 구현 — 기능별로 쪼개서 진행 (§8) |
| 7 | Manga Editor(페이지/말풍선/대사/SFX/Export) (§8-2, §9) |
| 8 | (MVP 완료 후) 패키징(Inno Setup) + 설치/삭제 테스트 (§10) |
| 9 | (MVP 완료 후) SmartScreen 안내 문서 작성 (§11) |
| 10 | (MVP 완료 후) 확장 기능(Multi-character 자동검사, VLM 검수, 캐릭터 LoRA) |
| 11 | 통합 테스트 + 최종 보고 |

---

## 13. 완료 기준 (DoD) — MVP / 확장 분리

### MVP

- [ ] Qwen3-8B GGUF Q4_K_M 로컬 파싱 파이프라인 동작 (OpenAI 키 없이도 정상 동작 확인), EXAONE/Bllossom 비교 후 최종 1개로 확정된 근거
- [ ] 생성 전 프롬프트 미리보기/수정 UI 동작
- [ ] `통합_자연어_IPAdapter_ControlNet` 재구성 완료 + 그래프 검증 스크립트 통과 결과
- [ ] `/prompt` 실제 큐 실행 성공 로그/스크린샷 (4개 워크플로우 전부)
- [ ] `patch_*.py` 정리 후 코드 구조 설명
- [ ] §2-4 파일 세트로 Character Consistency 여러 패널 연속 생성 확인
- [ ] Generation Metadata/History/Undo 동작 확인
- [ ] Targeted Inpainting이 지정 영역 밖을 보존하는지 확인
- [ ] UI 전 항목 ↔ 실제 기능 매핑 체크리스트
- [ ] Manga Editor와 Export(롱스트립/PDF) 동작 확인
- [ ] 프로젝트 Export/Import 동작 확인
- [ ] 기존 ComfyUI 환경 손상 없이 보존됨 확인
- [ ] `validate_stage2.py` 기준 §2-5 커스텀노드/§2-3·2-4 모델 설치 확인 결과
- [ ] NoobAI-XL Epsilon-pred v1.1 + `sdxl-vae-fp16-fix` 적용 확인(검은 이미지/NaN 없음), 4개 워크플로우 전부 반영 확인
- [ ] `patientx-cfz/comfyui-rocm` 설치 및 실제 안정성 확인

### 확장 (MVP 안정화 이후)

- [ ] Multi-character 오류 자동 검사 동작 확인
- [ ] Automatic Visual Verification(VLM 기반) 동작 확인, 자동 반복 보정 1~3회 제한 확인
- [ ] Model Manager 화면 설치 상태·Drag&Drop 배치 제안 동작 확인
- [ ] 오류 메시지 분류 및 해결 방법 안내 동작 확인
- [ ] 캐릭터 전용 LoRA 학습 파이프라인(선택 기능) 동작 확인
- [ ] Inno Setup 설치 파일(.exe) 1개 배포, 완전 독립형 설치, 바탕화면 바로가기·시작메뉴 등록 확인 스크린샷
- [ ] Windows "앱 및 기능"에서 정상 제거되는지(작업물 보존 옵션 포함) 확인 스크린샷
- [ ] SmartScreen 경고 실제 재현 캡처 + 우회 안내 문서

---

## 14. 보고 형식

각 단계 완료 시 함께 제출: (1) §13 해당 항목의 상태(완료/부분완료/미완료+사유), (2) 워크플로우 그래프 검증 스크립트 실행 결과, (3) 가능한 경우 실제 생성 성공 스크린샷/로그, (4) §1-3 예외 사유로 보고가 필요한 사항(있는 경우에만).

---

**요약**: 모든 선택지를 단일 값으로 확정했다 — 백엔드는 `patientx-cfz/comfyui-rocm`, 체크포인트는 NoobAI-XL Epsilon-pred v1.1, 캐릭터 일관성 파일은 §2-4의 정확한 파일명 세트, 로컬 LLM은 Qwen3-8B Q4_K_M(EXAONE/Bllossom 비교 후 최종 1개 확정), 설치 프로그램은 Inno Setup, 코드 서명은 하지 않는다. Manus는 이 값들을 그대로 실행하고, §1-3 예외 상황에서만 보고한다.
