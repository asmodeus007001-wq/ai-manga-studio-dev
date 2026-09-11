# AI Manga Studio — Manus 개발 요청서 (완전 통합 최종본 v4)

> 지금까지 4개의 문서(원본 요청서 → v2 사양 최적화판 → 보완 요청서 → v3 최종 통합판)를 실사용 결과를 바탕으로 검토·비교해서 만든 **최종 단일 문서**입니다. 이 문서 하나로 처음부터 끝까지 진행하며, 서로 충돌하는 내용이 있던 이전 문서들은 참고하지 말고 **이 문서를 유일한 기준으로** 삼아 주세요. 애매해서 질문이 필요한 지점은 이 문서 안에서 전부 결정해뒀습니다 — 임의 해석이나 질문 없이 순서대로 진행해 주세요.

---

## 0. 프로젝트 정체성

이 프로젝트는 "ComfyUI에 예쁜 껍데기를 씌운 것"이 아니라, **한국어로 장면을 설명하면 캐릭터 일관성을 유지한 채 여러 컷을 이어서 만들고, 그걸 말풍선·대사·효과음까지 배치해서 완성된 만화/웹툰 한 편으로 뽑아내는 로컬 제작 툴**입니다. 이미지 한 장의 퀄리티보다 아래 전체 파이프라인이 사용자 PC에서 안정적으로 끊김 없이 도는 것이 최종 목표입니다.

```
한국어 자연어 입력 → 장면 이해 → 캐릭터/참조/포즈 제어 → 이미지 생성
→ 검수 → 부분 보정 → 캐릭터 일관성 유지 → 여러 패널 → 페이지 배치
→ 대사/효과음 → 만화 Export
```

UI는 상용 크리에이티브 툴(예: Figma, Clip Studio Paint 수준)에 견줄 만한 완성도를 목표로 합니다. 여백·정렬·타이포그래피 일관성, 상태 변화에 대한 시각적 피드백(로딩/진행률/에러), 죽은 버튼 없음, 모든 동선이 막힘없이 이어지는 것을 "완료"의 기본 조건으로 봅니다.

---

## 1. 작업 방식 원칙

1. **이 문서 전체를 한 번에 던지지 않는다.** 아래 §9 "단계별 진행 순서"를 따라 세션을 나눠서 진행하고, 각 단계가 끝나면 결과물(코드 diff 요약, 스크린샷, 검증 로그)을 먼저 보여준 뒤 다음 단계로 넘어간다.
2. **이 문서 안에서 이미 결정된 사항은 다시 질문하지 않는다.** (백엔드, 체크포인트, ComfyUI 설치 방식, 워크플로우 구조, 캐릭터 일관성 전략 등 — 전부 아래에서 확정함)
3. 이 문서에 없는 새로운 모호함이 생겼을 때만 질문하고, 그 외에는 문서에 명시된 원칙(§2, §6)에 따라 합리적으로 판단해서 진행한다.
4. §10의 완료 기준(DoD) 체크리스트를 스스로 만들어 각 항목의 상태(완료/부분완료/미완료+사유)를 표시해서 최종 보고 시 제출한다.

---

## 2. 확정 사양 — 재검토·재질문 금지

아래 항목은 이미 실측·검증이 끝났습니다. 다시 테스트하거나 대안을 제안하지 마세요.

| 항목 | 확정 내용 |
|---|---|
| OS | Windows 11 Home 64-bit |
| CPU | AMD Ryzen 5 5600X |
| RAM | 32GB |
| GPU | AMD Radeon RX 6600, VRAM 8GB (아키텍처 gfx1032) |
| GPU 백엔드 | **ROCm 네이티브로 이미 정상 동작 확인됨** (`PyTorch 2.12.0+rocm7.14.0`, GPU native 인식, VRAM 7.84GB free 확인). ZLUDA/DirectML 추가 설치·전환 불필요. |
| 체크포인트 | **NoobAI-XL (epsilon-prediction 버전)을 기본 체크포인트로 채택한다.** Illustrious 계열 기반이며 Danbooru+e621 약 1,300만 장으로 학습되어 태그 인식 범위·정확도가 가장 넓고, 캐릭터/작가 스타일 커버리지가 크며, 2026년 기준 비교에서도 출력 안정성·캐릭터 인식 정확도 면에서 Animagine XL 4.0보다 앞선다는 평가가 우세하다. 이 프로젝트는 Scene Parser가 만든 구조화된 영어 태그를 그대로 모델에 넘기는 구조(§4)이므로 태그 충실도가 가장 중요한데, 그 목적에 가장 잘 맞는 모델이다. **반드시 epsilon-prediction 버전을 사용한다** (v-prediction 버전은 설정에 민감하고 `ModelSamplingDiscrete`에 `v_prediction` 설정이 빠지면 결과가 깨지는 리스크가 있어 기본값에서 제외한다. eps 버전은 이 리스크가 없다). Animagine XL 4.0은 완전히 폐기하지 말고 Model Adapter 구조(§4-5)를 통해 언제든 전환 가능한 보조 옵션으로만 남긴다. 실측 시 VRAM 사용량/생성시간/캐릭터 표현력/태그 반응성을 NoobAI-XL 기준으로 다시 측정해서 보고한다. |
| VAE | 체크포인트 내장 VAE 대신 **`sdxl-vae-fp16-fix`(madebyollin)를 명시적으로 로드해서 사용한다.** SDXL 계열 기본 VAE는 fp16 연산 시 NaN이 발생해 검은 이미지가 나오는 고질적 문제가 있고, ROCm/fp16 환경에서 특히 빈번하게 보고된다. 8GB VRAM에서는 fp16이 사실상 필수이므로 이 VAE 교체는 선택이 아니라 필수로 취급한다. |
| 필요 커스텀 노드 | `ComfyUI_IPAdapter_plus`, `comfyui_controlnet_aux`, `ComfyUI-Impact-Pack`, `ComfyUI-Impact-Subpack` — 설치 여부를 `validate_stage2.py`(또는 동등 스크립트)로 확인하고 결과를 보고한다. |
| 필요 모델 | `OpenPoseXL2.safetensors`, `bbox/face_yolov8m.pt`, `bbox/hand_yolov8s.pt`, NoobAI-XL epsilon-prediction 체크포인트 파일, `sdxl-vae-fp16-fix.safetensors` — 위와 동일하게 설치 여부 확인·보고 |
| 기존 환경 | 사용자 PC에 이미 별도의 ComfyUI가 설치되어 있고 기존 Workflow 3개가 존재함. **이 기존 환경은 절대 건드리지 않는다** (삭제/덮어쓰기/초기화 금지). AI Manga Studio는 §7에서 정한 대로 완전히 독립된 설치로 구성해서 애초에 충돌 가능성을 없앤다. |
| 검증된 워크플로우 3종 | `RX6600_AnimagineXL_기본생성.json`(Text-to-Image), `RX6600_AnimagineXL_참조이미지_img2img.json`(Reference img2img), `RX6600_AnimagineXL_ImpactPack_얼굴손_Detailer.json`(Face/Hand Detailer) — 그래프 연결 구조는 검증 완료, 링크 오류 없음. **단, 이 3개 파일에 아래 두 가지를 수정한다: (1) `CheckpointLoaderSimple` 위젯 값(`animagine-xl-4.0-opt.safetensors`)을 채택된 NoobAI-XL epsilon 체크포인트 파일명으로 교체, (2) `CheckpointLoaderSimple`의 VAE 출력을 그대로 쓰지 말고 `VAELoader` 노드로 `sdxl-vae-fp16-fix`를 별도 로드해서 `VAEDecode`/`VAEEncode`에 연결한다.** 나머지 노드 연결 구조는 그대로 기준 템플릿으로 삼아 아래 §4 자연어 파이프라인과 연결한다. |
| 오류 있던 워크플로우 | `RX6600_AnimagineXL_통합_자연어_IPAdapter_ControlNet.json` — §5 참고, 반드시 수정 |
| 패널 생성 방식 | 한 캔버스에 여러 컷을 동시에 그리는 멀티패널 동시 생성은 **채택하지 않는다** (캐릭터 속성이 컷 사이에서 섞이는 사고가 빈번함). 패널은 **1장씩 순차 생성**하고, 직전 패널의 캐릭터 참조/Seed/Metadata를 이어받는다. "후보 4장 동시 생성"은 같은 컷의 후보 중 하나를 고르는 용도로만 사용한다. |

---

## 3. 지금까지 미해결이었던 핵심 결함 3가지 — 이번에 반드시 해결

### 3-1. 한국어 자연어 이해 방식 교체 (최우선)

지금까지 쓰던 고정 80개 구문 사전 방식(`translate_helper.py`)은 사전에 없는 표현이 그냥 무시되는 구조라 폐기한다.

- **기본(항상 동작, 필수)**: 로컬에서 도는 한국어 지원 소형 LLM을 llama.cpp 등으로 **CPU에서** 구동한다. 한국어 문장을 §4의 Scene 구조(인물/포즈/의상/시선/배경/카메라)로 분석하고 영어 프롬프트로 변환한다. RAM 32GB 여유가 있고 이미지 생성은 GPU에서 도니 리소스 충돌이 없다.
  - **1순위: Qwen3-8B (GGUF, Q4_K_M~Q5_K_M 양자화).** Qwen2.5 세대보다 다국어·추론 능력이 개선되었고 100개 이상 언어를 지원하며 한국어 처리 품질도 앞선다고 평가된다. 구조화된 Scene 분석처럼 격식 있는 지시-따르기 작업에 특히 적합하다. 필요시 "thinking mode"를 꺼서 응답 속도를 우선한다(장면 분석은 매 생성마다 실행되므로 지연시간이 중요).
  - **2순위(한국어 특화 대안, 비교 테스트 권장)**: EXAONE(LG AI연구원, 최신 버전) 또는 Bllossom(한국어 특화 파인튜닝) GGUF 양자화 버전. 한국어 뉘앙스/구어체 표현에서 Qwen3보다 나은 경우가 있으므로, 실제 사용자 문장 샘플로 두 계열을 비교 테스트한 뒤 기본값을 정하고 결과를 보고한다.
- **선택**: `OPENAI_API_KEY`가 설정돼 있으면 우선 사용해도 되지만, **키가 없어도 로컬 LLM 경로만으로 항상 완전히 정상 동작해야 한다.** "키 없으면 조용히 사전 매칭으로 다운그레이드"하는 방식은 금지.
- 사전/모델이 해석하지 못한 표현을 그냥 버리지 말고, 최소한 "이 부분은 이렇게 해석했다"를 사용자에게 보여준다.
- 처리 경로(로컬 LLM인지 OpenAI인지)를 화면에 항상 표시한다.
- **생성 버튼을 누르기 전에 실제로 만들어진 최종 영어 프롬프트를 미리 보여주고, 사용자가 확인/직접 수정한 뒤에만 생성이 시작되게 한다.** (UI 위치는 §8 참고) 뒤에서 조용히 처리되다 이상한 결과가 나오는 걸 막는 것이 목적이다.

### 3-2. 워크플로우 그래프 링크 오류 수정 + 재발 방지

`통합_자연어_IPAdapter_ControlNet.json`에서 확인된 오류:

- `KSampler.model` 입력이 `LoadImage`(참조 이미지)의 **IMAGE** 출력에 잘못 연결됨 — MODEL 타입이 들어가야 함
- `IPAdapterAdvanced.image` 입력이 `KSampler`의 **LATENT** 출력에 잘못 연결됨 — 원래 LoadImage의 IMAGE 출력이 들어가야 함

수정 방향:

```
KSampler.model          ← IPAdapterAdvanced 노드의 MODEL 출력
IPAdapterAdvanced.image ← LoadImage(캐릭터 참조 이미지) 노드의 IMAGE 출력
```

§2에서 검증된 3개 파일은 이런 문제가 없으니 그 파일들의 연결 패턴(체크포인트 → CLIP/VAE 분기, KSampler 입출력 순서 등)을 참고해서 통합 워크플로우를 다시 정리한다.

**앞으로 워크플로우 JSON을 만들거나 수정할 때마다, 출고 전에 반드시 아래 두 가지를 통과시키고 결과를 함께 제출한다.**

1. 각 노드 입력의 `link` id가 가리키는 링크의 **target이 실제로 그 노드가 맞는지**, **타입이 노드가 기대하는 타입과 일치하는지** 검사하는 스크립트를 실행한다(`fix_workflow_links.py`, `validate_stage2.py` 재사용/확장). 이 검사를 통과하지 못한 워크플로우는 절대 전달하지 않는다.
2. 실제로 ComfyUI API `/prompt`에 큐를 넣어 **에러 없이 끝까지 실행되는지** 확인한다. JSON 문법이 맞는 것과 그래프가 맞는 것은 다르다는 점이 이미 실제로 확인됐다.

### 3-3. 코드 구조 정리 (patch_*.py 근본 해결)

`patch_*.py`, `fix_*.py` 종류가 50개 가까이 누적돼 있다. 특히 UI 관련 패치(`patch_white_ui.py`, `patch_ui_final_polish.py`, `patch_cache_blank_screen.py`, `fix_removed_scene_button.py` 등)가 반복 발생했다는 것은 원인을 근본적으로 고치지 않고 계속 덧붙였다는 뜻이다. 이번 최종본에서는:

- 기존 patch/fix 파일들의 목적을 먼저 인벤토리로 정리한다.
- §8 UI를 새로 만드는 이번 작업을 기회로 삼아, 패치를 쌓지 않는 **단일하고 깔끔한 코드베이스**로 재작성한다.
- 반복 발생했던 버그(흰 화면, 캐시 문제, 사라진 버튼 등)는 증상만 패치하지 말고 근본 원인을 찾아 구조적으로 고친다.

---

## 4. Scene 이해 및 캐릭터 시스템 (핵심 로직)

### 4-1. Semantic Scene Parser

한국어 문장을 다음 구조로 분석한다. 단순 번역이 아니라 의미 단위 분석이다.

```
Scene
├── Characters
│   ├── Identity / Biological Sex / Gender Expression
│   ├── Face, Body Type, Physical Traits, Hair, Eyes
│   ├── Clothing (Top/Bottom/Outer/Underwear/Socks/Shoes/Gloves/Hat/Accessories로 세분화, 문자열 하나로 뭉쳐 저장하지 않음)
│   ├── Pose, Expression, Gaze, Position
├── Environment (Location, Background, Props, Lighting)
├── Camera (Position, Angle, Shot Type, Perspective, Composition)
├── Style
├── References
└── Generation Settings
```

이 Common Scene Data는 모델이 바뀌어도 유지되며, Model Adapter가 이걸 체크포인트별 Prompt/Tag/Conditioning으로 변환한다 (아래 §4-5 참고). "상의만 변경"처럼 부분 수정 지시가 오면 다른 요소는 최대한 유지하면서 해당 속성만 바꾼다.

### 4-2. 캐릭터 속성 분리 (중요)

아래 속성들은 서로 독립적으로 관리한다. 예를 들어 "남성 + 여성적인 얼굴 + 여성적인 체형 + 여성 의상" 같은 복합 설정도 모델이 임의로 하나의 특징으로 뭉개지 않고 그대로 유지되어야 한다.

- Biological Sex / Gender Expression / Face / Body Type / Physical Traits / Clothing / Pose / Expression

### 4-3. Multi-character 처리

여러 캐릭터가 등장하는 장면에서 속성이 섞이지 않도록, 가능하면 캐릭터별 Reference/Conditioning을 독립적으로 처리한다. 아래 오류 유형을 자동으로 검사한다: Character Missing / Character Duplicate / Character Attribute Swap / Clothing Swap / Face Swap / Pose Swap / Position Swap.

### 4-4. Reference Image 시스템

Reference 이미지는 하나로 뭉치지 않고 아래 역할을 독립적으로 제공하며 동시에 조합 가능해야 한다: Character Appearance / Face / Pose / Clothing / Background / Style / Composition·Camera / Prop·Accessory Reference.

### 4-5. 모델 추상화 구조 (향후 확장성)

```
Common Scene Data → Model Adapter → Model-specific Prompt/Conditioning → Workflow Adapter → ComfyUI
```

특정 체크포인트 하나에 프로그램 전체가 종속되지 않도록, 새 모델이 필요해지면 Model/Workflow Adapter만 추가하는 구조로 만든다.

### 4-6. Character Consistency & Story State

- 기본 전략(LoRA 없이): **IP-Adapter FaceID Plus v2 (weight 0.70~0.85) + ControlNet OpenPose + 고정 Seed/Generation Metadata**. 캐릭터 등록 시 얼굴이 잘 보이는 참조 이미지 1장을 저장해두면 이후 패널에서 의상/포즈/배경이 바뀌어도 얼굴은 고정된다. 이 조합을 기본으로 유지하는 이유: InstantID는 별도 ControlNet을 추가로 얹어야 해서 8GB VRAM에서 부담이 크고, PuLID는 아직 SDXL/애니메이션 계열보다 Flux 계열에서 더 성숙한 상태라 이 프로젝트(SDXL 기반 애니메 체크포인트)에는 FaceID Plus v2가 VRAM 대비 가장 합리적인 선택이다.
- **주의 및 보완**: FaceID 계열은 실사 얼굴로 학습된 얼굴인식 모델(ArcFace/InsightFace) 기반이라, 극단적인 각도나 화풍이 강한 일러스트 얼굴에서는 실사 대비 정확도가 떨어질 수 있다. 얼굴만으로 일관성이 부족하다고 판단되면, **일반 IPAdapter(Plus, 얼굴 임베딩이 아닌 이미지 전체 참조 방식)를 캐릭터 전신/의상 참조용으로 함께 사용**해서 화풍·전체 인상을 보강한다(FaceID로 얼굴, 일반 IPAdapter로 전체 룩을 이중으로 잡는 방식). 그래도 부족하면 아래 확장 전략(LoRA)으로 넘어간다.
- 확장 전략(선택 옵션, 필수 아님): 등장 빈도가 매우 높은 주인공에 한해 잘 나온 결과 15~50장으로 캐릭터 전용 LoRA를 학습(로컬 1~4시간, VRAM 여유 있을 때 야간 실행 권장)해서 일관성을 더 끌어올릴 수 있다. 특히 애니메 화풍에서는 LoRA가 FaceID보다 확실한 일관성을 준다는 것이 커뮤니티 공통 평가이므로, 주인공급 캐릭터는 초기부터 LoRA 학습을 염두에 두고 참조 이미지를 충분히 모아두는 것을 권장한다.
- **Story State**: 캐릭터별로 현재 의상/액세서리/위치/소품/스토리 진행 상태를 프로젝트에 저장해서, 예를 들어 Panel 1은 교복, Panel 10은 사복, Panel 20은 전투복처럼 바뀌어도 핵심 외형은 유지되게 한다.
- **Generation Metadata**: 매 생성마다 Model/VAE/LoRA/ControlNet/IPAdapter/Prompt/Negative/Seed/Steps/CFG/Sampler/Resolution/Reference Images/Workflow/Timestamp를 저장해서 나중에 동일하거나 유사한 결과를 재현할 수 있게 한다.
- **Generation History & Undo**: 패널별로 생성 결과를 버전 관리(Generation 001, 002, 003, Final처럼)하고 이전 결과로 되돌릴 수 있게 한다. 특히 Inpainting은 수정이 원본보다 나빠질 수 있으므로 Original → Repair 1 → Repair 2 각 단계로 되돌릴 수 있어야 하며, 수정 전 원본은 항상 보존한다.

### 4-7. VRAM 8GB 관리

기본 설계가 12GB 이상을 요구하지 않게 한다. Low VRAM / CPU Offload / Sequential Loading / Model Unload / Tiled VAE 등을 활용하고, 체크포인트는 fp8/GGUF 양자화를 기본으로, CLIP/Text Encoder는 CPU 오프로드, ControlNet/IPAdapter는 필요한 패널에서만 순차 로딩 후 언로드한다. 각 워크플로우에는 예상 VRAM 사용량 등급(Recommended/Possible/Slow/Not Recommended/Unsupported)을 표시한다.

---

## 5. 검수 및 보정 (Verification & Repair)

### 5-1. 부분 보정 원칙

생성된 이미지에서 손/손가락/발/신발/얼굴/눈/귀/머리카락/액세서리/의상/소품 오류를 검사하되, 문제가 있어도 전체를 무조건 재생성하지 않고 **필요한 부분만** Inpainting한다. 사용자가 직접 수정 영역을 선택할 수도 있어야 하며, 수정 영역 밖의 얼굴/의상/배경/구도는 최대한 보존한다.

### 5-2. Automatic Visual Verification (선택 기능, MVP 이후)

Vision AI/VLM으로 생성 결과를 검사해서 Character Count/Position/Face/Hair/Clothing/Pose/Expression/Gaze/Background/Hands/Feet 등을 체크리스트 형태(✓/✗)로 보여주고, 사용자가 Full Regenerate / Partial Repair / Accept 중 선택하게 한다. 자동 반복 보정은 **최대 1~3회**로 제한해서 8GB VRAM 환경에서 무한 루프가 걸리지 않게 한다.

---

## 6. Model Manager / 설치 자동화 / 오류 처리

### 6-1. 설치 자동화

Python/runtime, Git, ComfyUI, Custom Node, Checkpoint, VAE, ControlNet, IP-Adapter, LoRA, Upscaler, Face/Hand/Pose 모델, Workflow JSON까지 최대한 자동으로 구성한다(§7 설치 방식과 연동). 이미 설치된 것은 다시 설치하지 않는다.

### 6-2. Model Manager 화면

프로그램 안에 설치된/부족한 모델을 관리하는 화면을 둔다. 각 모델마다 Model Name / File Name / Type(Checkpoint·LoRA·VAE·ControlNet 등) / Purpose / Status(Installed/Missing) / VRAM 예상 요구량 / 실제 경로 / 권장도(Recommended/Possible/Slow/Not Recommended/Unsupported)를 표시한다. 모델 파일을 프로그램 창에 **Drag & Drop**하면 파일 종류를 판단해서 알맞은 ComfyUI 모델 폴더로 자동 배치하고, 자동 판별이 애매하면 사용자에게 선택지를 보여준다.

### 6-3. 라이선스 및 수동 설치 안내

모델/커스텀노드를 무조건 자동 다운로드하지 않고 상업적 이용·재배포·자동 다운로드 가능 여부를 확인한다. 라이선스가 불명확하거나 자동 다운로드가 부적절하면, 정확한 모델명·파일명·용도·공식 다운로드 위치·저장 폴더·설치 확인 방법을 화면에 안내하고 Drag & Drop으로 수동 설치할 수 있게 한다.

### 6-4. 오류 메시지 및 설치 실패 대응

"Generation Failed" 같은 단순 메시지 대신 원인을 분류해서 보여준다: VRAM 부족 / Model Missing / Custom Node Missing / Backend Error / ControlNet Error / Workflow Error / Invalid Model / Unsupported Configuration. 각 오류에 대해 가능한 해결 방법을 함께 표시한다. 자동 설치/설정이 실패해도 프로그램이 먹통 상태로 끝나지 않도록, Problem/Cause/Required File/Required Version/Required Path/Solution/Retry 형식으로 정보를 보여주고 가능하면 자동 수정 후 재시도한다.

---

## 7. ComfyUI 설치 방식 — 완전 독립형으로 확정

이전 문서에서 "기존 ComfyUI 폴더 재사용" vs "완전 독립 설치" 중 선택지로 열어뒀던 부분을 이번에 **완전 독립 설치(Option B)로 확정**한다. 이유: §2에서 정한 "기존 ComfyUI 환경 절대 보호" 원칙과 가장 확실하게 부합하고, "환경 안 맞음" 문제를 원천 차단할 수 있다.

- AI Manga Studio는 자체 폴더에 **자체 ComfyUI 인스턴스 + 필요한 모든 Custom Node/모델**을 포함해서 설치한다. 기존에 사용자가 이미 갖고 있는 ComfyUI 설치와는 물리적으로 완전히 분리된 경로를 쓴다.
- 기존 ComfyUI의 Workflow 3개, Checkpoint, LoRA, Custom Node, 설정은 조회만 하고 절대 삭제/이동/덮어쓰기하지 않는다.
- 이미 다운로드된 모델(예: Animagine XL 4.0 등 기존에 받아둔 체크포인트)이 기존 ComfyUI 폴더에 있다면, 복사해서 재사용하되 원본은 그대로 둔다(심볼릭 링크 또는 복사 중 더 안정적인 방식을 선택해서 진행하고 어떤 방식을 썼는지 보고서에 명시). NoobAI-XL epsilon 체크포인트는 기존 폴더에 없을 가능성이 높으므로 §6-1 설치 자동화 절차에 따라 새로 받는다.

---

## 8. UI/UX 사양

### 8-0. 목표 수준

죽은 버튼 금지, 라벨만 봐도 기능을 알 수 있게, 여백/정렬/타이포그래피 일관성, 로딩·진행 상태에 대한 명확한 시각 피드백까지 포함해서 상용 크리에이티브 툴 수준의 완성도를 목표로 한다.

### 8-1. 레이아웃 참고

`https://betterwaifu.com/ko/create` — 화면 구성·정렬 방식만 참고한다(콘텐츠·문구·브랜딩과는 무관). 우리 프로젝트는 만화/웹툰 제작 툴이므로 문구와 기능은 목적에 맞게 새로 구성한다.

참고할 구조: 화면을 **좌측 컨트롤 패널 / 중앙 캔버스(미리보기) / 우측 기록·갤러리 패널**로 3분할. 좌측 패널은 위→아래로 "무엇을 그릴지 → 어떻게 그릴지 → 참조 이미지 → 출력 형식 → 고급 설정 → 생성 버튼" 순서로 배치. 각 옵션 카테고리는 접었다 펼 수 있는 섹션(collapsible)으로 구분한다. 상단에 페이지 전환 탭을 고정한다.

### 8-2. 화면 구성 상세

**상단 바 (고정)**: 좌 — 로고/프로젝트명, 프로젝트 선택 드롭다운. 우 — [만들기] [패널 편집기] [내 작업 기록] 탭, 다크모드 토글.

**좌측 컨트롤 패널** (스크롤 가능, 섹션별 접기/펼치기):

| 섹션 | 포함 기능 | 비고 |
|---|---|---|
| 1) 한국어 프롬프트 입력 | 자연어 텍스트박스 + "해석 보기" 버튼 | 누르면 하단에 해석 결과(장면 구조 태그 + 처리 경로: 로컬LLM/OpenAI)를 펼쳐서 보여줌. 여기서 직접 태그 수정 가능 |
| 2) 캐릭터 참조 | 등록된 캐릭터 목록(썸네일+이름), 새 캐릭터 등록(참조 이미지 업로드), 이번 패널에 적용할 캐릭터 선택(다중 가능) | IP-Adapter 참조 이미지와 연결 |
| 3) 워크플로우/모델 | 현재 입력에 맞게 자동 판단된 워크플로우(기본생성/img2img/IPAdapter+ControlNet/Detailer)를 표시, 수동 오버라이드 가능. 체크포인트 선택 | 기본은 "자동", 필요시 수동 전환 |
| 4) 포즈/구도 | ControlNet(OpenPose) 참조 이미지 업로드 또는 프리셋 포즈 선택 | |
| 5) 출력 형식 | 레이아웃(세로스크롤 웹툰 / 페이지 만화책), 컬러모드(컬러 / 흑백+톤), 컷 비율 프리셋(4:5, 2:3, 9:16, 1:1) + 커스텀 | 프로젝트 생성 시 1회 설정, 패널별 변경 가능 |
| 6) 생성 매수 | "1장" / "후보 4장 중 선택" 토글 | 배치 생성은 후보 선택 용도로만 |
| 7) 고급 설정 (기본 접힘) | Steps, CFG, Sampler, Seed(고정/랜덤), v-prediction 토글 | 초보자는 기본값으로 정상 동작 |

- **생성 버튼**은 좌측 패널 하단에 항상 고정 노출된다(스크롤해도 안 사라짐). 누르면 "최종 프롬프트 미리보기" 팝업이 항상 뜨고, 확인해야 실제 생성이 시작된다.

**중앙 캔버스**: 현재 패널 미리보기, 로딩 중 어느 워크플로우 노드를 처리 중인지 진행률 표시. 결과 위에서 바로 인페인팅 영역 지정 가능. 이전/다음 패널 이동, 페이지 내 컷 순서 재배열(드래그).

**우측 기록/갤러리 패널**: 세션 생성 이미지 히스토리(그리드), 즐겨찾기(북마크), 프로젝트별 필터. 각 썸네일에 Seed/프롬프트/워크플로우 메타데이터 표시(재사용 버튼 포함).

**만화 에디터 화면** (별도 탭): 페이지 레이아웃, Panel 생성/리사이즈/이동/순서변경, 말풍선, 대사, 효과음(SFX) 배치, Export(웹툰용 롱스트립 이어붙이기 / 페이지 PDF·이미지 시퀀스). 대사·말풍선은 AI 이미지 생성과 완전히 분리된 별도 편집 레이어로 처리한다(AI 모델에게 텍스트를 직접 그리게 하지 않는다). 고급 사용자를 위해 언제든 **"Open in ComfyUI"** 버튼으로 현재 워크플로우를 열 수 있게 한다.

### 8-3. 필수 요건

- 모든 버튼/토글은 실제 백엔드 기능과 연결되어 정상 동작해야 한다(죽은 버튼 금지).
- 3-2에 명시된 위치를 벗어나 임의로 재배치하지 않는다.
- UI 구현 완료 시, **UI 항목 ↔ 실제 기능 매핑표**를 만들어 각 항목이 "정상 작동 확인됨"인지 체크리스트로 제출한다.

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

프로젝트 전체를 Export/Import 할 수 있게 해서 다른 PC에서도 복구 가능한 구조로 만든다.

---

## 10. 패키징 및 배포

### 10-1. 요구사항

- 최종 산출물은 zip이 아니라 **실행 가능한 설치 프로그램(.exe) 1개**여야 한다 (Inno Setup 또는 NSIS 권장).
- 설치 마법사: 설치 경로 선택(기본값 제공), **바탕화면 바로가기 생성**(기본 체크), 시작 메뉴 등록, 설치 진행률 표시, 설치 완료 후 "지금 실행" 옵션.
- **제거**: Windows "설정 → 앱 → 앱 및 기능"(또는 제어판)에 정상 등록되어 표준 방식으로 제거 가능해야 한다. 별도 `Uninstall.exe`도 함께 설치한다.
- 제거 시 사용자가 만든 작업물(생성 이미지, 프로젝트 파일)은 **기본적으로 보존**하고, "프로그램 파일만 삭제 / 작업물까지 전부 삭제" 2가지 옵션을 확인창으로 제공한다.
- §7에서 확정한 대로 **완전 독립형 설치(ComfyUI 포함 일체형)**로 구현한다.
- 아이콘, 제품명, 버전 정보, 게시자 이름을 설치 파일에 정상적으로 채워 넣는다(§11 SmartScreen 완화와도 연결됨).

### 10-2. 기존 산출물 참고

이전에 별도로 만들어졌던 `AI_Webtoon_Studio_Setup_v2_3.exe`와 `MangaSceneStudio_Setup.exe`(기존 ComfyUI 폴더를 선택해서 커스텀 노드/워크플로우만 추가하는 방식)가 있다. 이번 최종본은 그 설치 경험 수준을 유지하되, 대상 범위를 §7에서 정한 완전 독립형 프로그램 전체로 확장한다.

---

## 11. Windows 보안 경고(SmartScreen) 대응

- 가능하면 코드 서명 인증서(EV 또는 OV)로 설치 파일에 서명한다. 비용이 발생하므로, **서명 없이 배포했을 때 실제로 뜨는 경고**와 **서명 시 필요한 절차/예상 비용**을 먼저 조사해서 알려주고, 서명 여부는 그 정보를 보고 사용자가 결정한다.
- 서명이 당장 어렵다면 최소한: 설치 파일에 제품명/버전/게시자/아이콘 등 정상 메타데이터를 채우고, 잘 알려진 툴(Inno Setup/NSIS)의 표준 방식대로 만들어 신뢰도를 높인다.
- SmartScreen 경고를 완전히 피할 수 없는 경우, 설치 안내 문서(또는 설치 화면 자체)에 "추가 정보 → 실행" 우회 절차를 스크린샷과 함께 미리 포함한다.
- 실제 배포용 설치 파일을 만든 뒤 다른 PC(또는 가상환경)에서 다운로드→실행까지 재현해보고 어떤 경고가 뜨는지 캡처해서 보고에 포함한다.

---

## 12. 단계별 진행 순서

| 단계 | 내용 |
|---|---|
| 1 | 기존 산출물(코드/워크플로우 JSON) 인벤토리 정리, `patch_*.py` 통폐합 구조 설계, §7 독립형 ComfyUI 설치 구조 확정 |
| 2 | 한국어 NLU(로컬 LLM) 파이프라인 구현 + 프롬프트 미리보기 UI (§3-1) |
| 3 | 워크플로우 그래프 검증 스크립트 작성 + 4개 워크플로우 전부 검증/수정 + `/prompt` 실제 큐 테스트 (§3-2) |
| 4 | 캐릭터 시스템/Scene Parser/Reference 시스템 백엔드 구현 (§4) |
| 5 | 검수·보정 파이프라인 구현 (§5) |
| 6 | 전체 UI 구현 — 기능별로 쪼개서 진행 (§8) |
| 7 | Manga Editor(페이지/말풍선/대사/SFX/Export) 구현 (§8-2 E, §9) |
| 8 | 패키징(설치 프로그램) 구현 + 설치/삭제 테스트 (§10) |
| 9 | SmartScreen 조사 및 대응 (§11) |
| 10 | 통합 테스트 + 최종 보고 |

---

## 13. 최종 완료 기준 (DoD)

- [ ] 한국어 로컬 LLM 파싱 파이프라인 동작 (OpenAI 키 없이도 정상 동작 확인)
- [ ] 생성 전 프롬프트 미리보기/수정 UI 동작
- [ ] `통합_자연어_IPAdapter_ControlNet.json` 링크 오류 수정 완료 + 그래프 검증 스크립트 통과 결과
- [ ] `/prompt` 실제 큐 실행 성공 로그/스크린샷 (4개 워크플로우 전부)
- [ ] `patch_*.py` 정리 후 코드 구조(폴더/모듈 구성) 설명
- [ ] Scene Parser·캐릭터 속성 분리·Multi-character 오류 검사 동작 확인
- [ ] Character Consistency(IPAdapter+ControlNet+Seed) 여러 패널 연속 생성으로 실제 확인
- [ ] Generation Metadata/History/Undo 동작 확인
- [ ] Targeted Inpainting(손/얼굴 등 부분 보정)이 지정 영역 밖을 보존하는지 확인
- [ ] Model Manager 화면에서 설치 상태·Drag&Drop 설치 동작 확인
- [ ] 오류 메시지 분류 및 해결 방법 안내 동작 확인
- [ ] UI 전 항목 ↔ 실제 기능 매핑 체크리스트 (죽은 버튼 없음)
- [ ] Manga Editor(페이지/말풍선/대사/SFX)와 Export(롱스트립/PDF) 동작 확인
- [ ] 프로젝트 Export/Import 동작 확인
- [ ] 기존 ComfyUI 환경(워크플로우 3개, 모델, 커스텀노드) 손상 없이 보존됨 확인
- [ ] 설치 파일(.exe) 1개로 배포, 완전 독립형 설치, 바탕화면 바로가기·시작메뉴 등록 확인 스크린샷
- [ ] Windows "앱 및 기능"에서 정상 제거되는지(작업물 보존 옵션 포함) 확인 스크린샷
- [ ] 서명/SmartScreen 조사 결과 및 대응 여부, 실제 경고 재현 캡처
- [ ] `validate_stage2.py` 기준 필수 커스텀노드/모델 설치 확인 결과
- [ ] NoobAI-XL epsilon-prediction 체크포인트 + `sdxl-vae-fp16-fix` VAE 적용 확인 (검은 이미지/NaN 없음), 4개 워크플로우 전부 체크포인트·VAE 교체 반영 확인
- [ ] Qwen3-8B 등 로컬 LLM 실제 성능(속도/정확도) 비교 결과 및 최종 선택 근거

---

## 14. 보고 형식

각 단계 완료 시 다음을 함께 제출한다: (1) §13 해당 항목의 상태(완료/부분완료/미완료+사유), (2) 워크플로우 그래프 검증 스크립트 실행 결과, (3) 가능한 경우 실제 생성 성공 스크린샷/로그, (4) 다음 단계로 넘어가기 전 확인이 필요한 사항(있는 경우에만).

---

**요약**: 백엔드(ROCm)·체크포인트(NoobAI-XL epsilon-prediction)·캐릭터 일관성 전략은 이미 검증·판단되어 확정. 한국어 NLU 방식 교체, 워크플로우 링크 오류 수정, 코드 구조 정리라는 3대 결함을 이번에 해결하고, 여기에 (1) 화면 구성까지 명시한 UI 사양, (2) 완전 독립형 설치 프로그램(.exe) 패키징, (3) SmartScreen 대응까지 전부 확정해서 이 문서 하나로 처음부터 끝까지 재작업 없이 완결하는 것이 목표다.
