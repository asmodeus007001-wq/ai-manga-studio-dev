# AI Manga Studio 개발 요청서

## 0. 최우선 지시사항

이 프로젝트의 목표는 단순한 AI 이미지 생성 프로그램이나 ComfyUI의 새로운 GUI를 만드는 것이 아니다.

**한국어 자연어로 장면을 설명하면, 캐릭터·의상·포즈·표정·배경·구도·카메라·참조 이미지 등을 구조적으로 분석하고, 적절한 AI 이미지 생성 Workflow를 자동으로 구성하여 만화 패널을 제작할 수 있는 통합 로컬 AI Manga Studio를 개발한다.**

가장 중요한 원칙은 다음과 같다.

> **기능을 한꺼번에 구현하지 말고, 먼저 실제 사용자 PC에서 ComfyUI와 후보 모델 및 AMD Backend가 실제로 작동하는지 검증한 뒤, 검증된 구성만을 기반으로 단계적으로 개발한다.**

사용자 PC는 다음과 같다.

- Windows 11 Home 64-bit
- AMD Ryzen 5 5600X
- RAM 32GB
- AMD Radeon RX 6600
- VRAM 8GB

**NVIDIA CUDA를 기본 전제로 개발하지 않는다.**

AMD 환경에서 실제 작동하는 Backend를 테스트하여 결정한다.

가능한 후보:

- DirectML
- Vulkan
- ROCm 계열
- ZLUDA 계열
- 기타 실제 RX 6600에서 사용할 수 있는 방식

단순히 인터넷에서 "AMD 지원"이라고 되어 있다는 이유만으로 채택하지 말고, **실제 RX 6600 8GB 환경에서 생성 테스트를 수행한다.**

---

# 1. 기존 ComfyUI 환경 보호

사용자 PC에는 이미 ComfyUI가 설치되어 있으며 기존 Workflow가 3개 존재한다.

### 절대 하지 말 것

- 기존 Workflow 삭제
- 기존 Workflow 덮어쓰기
- 기존 Checkpoint 삭제
- 기존 LoRA 삭제
- 기존 Custom Node 삭제
- 기존 ComfyUI 환경 초기화
- 기존 설정을 임의로 덮어쓰기

### 먼저 수행할 것

1. 현재 ComfyUI 설치 위치 확인
2. Python/runtime 확인
3. Custom Node 목록 확인
4. 모델 목록 확인
5. 기존 Workflow 3개 확인
6. 각각 실제로 작동하는지 확인
7. 기존 환경 백업

새 AI Manga Studio용 Workflow와 파일은 기존 환경과 충돌하지 않는 별도의 구조로 추가한다.

기존 Workflow 중 재사용 가능한 부분이 있다면 분석하여 활용한다.

---

# 2. 개발 방식

처음부터 모든 기능을 구현하지 않는다.

다음 순서로 개발한다.

1. 환경 조사
2. AMD/ComfyUI 테스트
3. 모델 테스트
4. 기본 Workflow 구축
5. 설치/모델 관리
6. 기본 생성
7. Reference/Control
8. Inpainting
9. 자연어 Scene Parser
10. Multi-character
11. Character Consistency
12. 자동 검수
13. Manga Editor

각 단계에서 실제 작동 여부를 테스트한 후 다음 단계로 진행한다.

---

# 3. VRAM 8GB 제약

이 프로젝트에서 **8GB VRAM은 절대적인 제약 조건**이다.

기본 설계가 12GB/16GB/24GB VRAM을 요구해서는 안 된다.

필요할 경우:

- Low VRAM
- CPU Offload
- Sequential Loading
- Model Unload
- Tiled VAE
- Tiled Upscale
- Batch Size 최소화
- 보조 모델 필요 시에만 로딩

등을 사용한다.

여러 대형 모델을 동시에 GPU에 올리는 구조를 피한다.

각 Workflow에 예상 VRAM 사용량을 표시한다.

예:

- Recommended
- Possible
- Slow
- Not Recommended
- Unsupported

---

# 4. 모델 선정

특정 모델을 처음부터 최종 모델로 확정하지 않는다.

실제 RX 6600 8GB에서 다음 후보들을 테스트한다.

- SDXL
- SDXL Turbo
- Z-Image
- Z-Image-Turbo
- Anime/Illustration 계열 SDXL 모델
- 필요 시 SD1.5 계열
- 기타 현재 시점에서 적합한 모델

특히 SDXL Turbo는 빠른 Draft/Preview 용도로 테스트한다.

Z-Image 및 Z-Image-Turbo도 테스트한다.

단, 어떤 모델이 인터넷에서 좋다고 평가된다는 이유만으로 채택하지 않는다.

각 모델에 대해 실제로 측정한다.

- VRAM 사용량
- 생성 시간
- 이미지 품질
- 캐릭터 표현
- 포즈 제어
- Reference 대응
- Inpainting
- AMD 호환성
- 안정성

사용자가 제공하는 모델명이 오타일 가능성이 있는 경우 임의로 추측하지 말고 정확한 공식 모델명을 확인한다.

---

# 5. 설치 자동화

Manus는 프로그램 자체뿐 아니라 **초기 AI 생성 환경 구축까지 최대한 자동화**한다.

필요한 구성요소:

- Python/runtime
- Git
- ComfyUI
- Custom Nodes
- Checkpoint
- VAE
- CLIP/Text Encoder
- ControlNet
- IP-Adapter
- LoRA
- Upscaler
- Inpainting 모델
- Face 관련 모델
- Hand 관련 모델
- Pose/OpenPose 관련 모델
- 필요한 기타 모델
- Workflow JSON
- AMD Backend 설정

이미 설치되어 있는 것은 다시 설치하지 않는다.

---

# 6. Model Manager

프로그램 안에 Model Manager를 만든다.

각 모델에 대해 다음 정보를 표시한다.

| 항목 | 내용 |
|---|---|
| Model Name | 실제 모델명 |
| File Name | 실제 파일명 |
| Type | Checkpoint / LoRA / VAE / ControlNet 등 |
| Purpose | 생성 / 포즈 / 얼굴 / 손 / 업스케일 등 |
| Status | Installed / Missing |
| Compatibility | Backend 및 모델 호환성 |
| VRAM | 예상 요구량 |
| Path | 실제 설치 위치 |
| Recommendation | Recommended / Possible / Slow / Not Recommended / Unsupported |

---

# 7. Drag & Drop 모델 설치

사용자가 모델 파일을 프로그램으로 Drag & Drop할 수 있도록 한다.

프로그램이 파일 종류를 판단하고 적절한 ComfyUI 모델 폴더로 이동할 수 있도록 한다.

예:

Checkpoint → checkpoints

LoRA → loras

VAE → vae

ControlNet → controlnet

Upscaler → upscale_models

등.

자동 판별이 불가능한 경우 사용자에게 선택하도록 한다.

---

# 8. 자동 설치가 불가능한 모델

라이선스 또는 기술적인 이유로 자동 다운로드가 불가능한 경우:

- 정확한 모델명
- 정확한 파일명
- 용도
- 공식 다운로드 위치
- 저장해야 할 정확한 폴더
- 설치 후 확인 방법

을 프로그램에서 알려준다.

가능하면 사용자가 모델 파일을 Drag & Drop하여 설치할 수 있게 한다.

---

# 9. 라이선스

모델과 Custom Node를 무작정 자동 다운로드하지 않는다.

각 구성요소의 라이선스를 확인한다.

특히:

- 상업적 이용 가능 여부
- 재배포 가능 여부
- 자동 다운로드 가능 여부

를 확인한다.

라이선스가 불명확하거나 자동 다운로드가 부적절한 경우 수동 설치로 전환한다.

가능한 경우 공식 GitHub/Hugging Face/공식 배포처를 우선한다.

---

# 10. 기본 Workflow

최소한 다음 Workflow를 만든다.

1. Basic Text-to-Image
2. Fast Draft
3. High Quality
4. Character Reference
5. Face Reference
6. Style Reference
7. Clothing Reference
8. Background Reference
9. Pose Reference
10. OpenPose
11. ControlNet
12. IP-Adapter
13. Multi-Reference
14. Character + Style + Pose
15. Hand Inpainting
16. Face Inpainting
17. Foot/Shoe Inpainting
18. Clothing Inpainting
19. Accessory Inpainting
20. Background Inpainting
21. Targeted Partial Repair
22. Upscale
23. Manga Panel

각 Workflow는 JSON 형태로 저장한다.

사용자가 원하면 ComfyUI에 직접 Drag & Drop하여 열 수 있어야 한다.

---

# 11. 프로그램과 ComfyUI의 관계

ComfyUI는 생성 Backend로 활용한다.

하지만 AI Manga Studio가 단순한 "ComfyUI 스킨"이나 "ComfyUI를 예쁘게 만든 GUI"가 되어서는 안 된다.

사용자는 기본적으로 다음을 직접 조작할 필요가 없어야 한다.

- Nodes
- Conditioning
- Sampler
- VAE
- CLIP
- ControlNet
- IP-Adapter

프로그램이 Scene Data를 기반으로 적절한 Workflow를 선택하고 실행한다.

고급 사용자를 위해서는:

**Open in ComfyUI**

기능을 제공한다.

---

# 12. 한국어 자연어 입력

사용자는 복잡한 Prompt나 Tag를 직접 작성하지 않아도 되어야 한다.

예:

"교실 창가에 아린이 서 있고 오른손으로 창문을 잡고 있다. 흰색 셔츠와 검은색 치마를 입고 있고 약간 아래를 바라보고 있다. 카메라는 정면보다 조금 낮은 위치에서 바라본다."

이런 식으로 입력할 수 있어야 한다.

중요:

**단순히 한국어를 영어로 번역하는 시스템을 만들지 않는다.**

자연어를 의미 단위로 분석한다.

---

# 13. Semantic Scene Parser

입력 문장을 다음과 같은 구조로 변환한다.

```text
Scene
├── Characters
│   ├── Identity
│   ├── Gender/Sex
│   ├── Face
│   ├── Body Type
│   ├── Physical Traits
│   ├── Hair
│   ├── Eyes
│   ├── Clothing
│   ├── Accessories
│   ├── Pose
│   ├── Expression
│   ├── Gaze
│   └── Position
│
├── Environment
│   ├── Location
│   ├── Background
│   ├── Props
│   └── Lighting
│
├── Camera
│   ├── Position
│   ├── Angle
│   ├── Shot Type
│   ├── Perspective
│   └── Composition
│
├── Style
│
├── References
│
└── Generation Settings
```

그 후 해당 모델에 맞게 Prompt/Tag/Conditioning으로 변환한다.

---

# 14. Common Scene Data

모델마다 Prompt 방식이 다르더라도 내부 Scene Data는 공통으로 유지한다.

구조:

```text
User Korean Input
        ↓
Semantic Parser
        ↓
Common Scene Data
        ↓
Model Adapter
        ↓
Model-specific Prompt / Tags
        ↓
ComfyUI Workflow
        ↓
Generation
```

이를 통해 나중에 모델을 변경해도 프로그램 UI와 프로젝트 데이터가 최대한 유지되도록 한다.

---

# 15. 캐릭터 시스템

캐릭터를 프로젝트에 저장한다.

예:

```text
Character
├── Name
├── Face
├── Hair
├── Eyes
├── Body
├── Physical Traits
├── Default Clothing
├── Accessories
├── Reference Images
├── Style Association
└── Story State
```

패널마다 현재 상태를 별도로 관리할 수 있어야 한다.

예:

```text
Panel 1
→ 교복

Panel 10
→ 사복

Panel 20
→ 전투복
```

의상이 바뀌어도 캐릭터의 핵심 외형은 유지한다.

---

# 16. 캐릭터 속성 분리

매우 중요하다.

다음 속성을 서로 독립적으로 관리한다.

- Biological Sex
- Gender Expression
- Face
- Body Type
- Physical Traits
- Clothing
- Pose
- Expression

예를 들어:

```text
Male
+
Feminine Face
+
Feminine Body
+
Large Chest
+
Feminine Clothing
```

같은 복합적인 설정도 그대로 유지해야 한다.

모델이 임의로 하나의 특징을 다른 특징으로 대체하지 않도록 Scene Data 단계부터 속성을 분리한다.

---

# 17. Multi-Character

여러 캐릭터가 등장하는 장면에서 속성이 섞이지 않도록 한다.

예:

```text
Character A
- Black Hair
- White Shirt
- Left
- Sitting

Character B
- White Hair
- Black Coat
- Right
- Standing
```

A의 의상이나 얼굴이 B에게 적용되는 문제를 최대한 방지한다.

검사해야 할 오류:

- Character Missing
- Character Duplicate
- Character Attribute Swap
- Clothing Swap
- Face Swap
- Pose Swap
- Position Swap

가능하면 캐릭터별 Reference/Conditioning을 독립적으로 처리한다.

---

# 18. Reference Image 시스템

Reference 이미지는 하나의 카테고리로 취급하지 않는다.

다음 역할을 독립적으로 제공한다.

- Character Appearance Reference
- Face Reference
- Pose Reference
- Clothing Reference
- Background Reference
- Style Reference
- Composition/Camera Reference
- Prop/Accessory Reference

예:

```text
Character Appearance → Image A
Pose → Image B
Clothing → Image C
Background → Image D
Style → Image E
```

이들을 동시에 조합할 수 있어야 한다.

---

# 19. Pose 시스템

사용자가 자연어로 포즈를 입력할 수 있어야 한다.

예:

"한쪽 무릎을 꿇고 오른손으로 검을 들고 왼쪽을 바라본다."

가능하면 다음 기능을 제공한다.

- Pose Reference
- OpenPose
- ControlNet
- 기타 호환 가능한 Pose Conditioning
- 시각적 Pose 조정

---

# 20. Scene Layout

캐릭터의 위치와 크기를 간단한 2D Editor에서 조정할 수 있도록 한다.

예:

```text
┌──────────────────────────────┐
│                              │
│       A              B       │
│                              │
│               C              │
│                              │
└──────────────────────────────┘
```

Drag & Drop으로:

- 위치
- 크기
- 앞/뒤
- 좌/우
- 상/하

등을 조정할 수 있도록 한다.

---

# 21. 의상 구조화

의상을 하나의 문자열로 저장하지 않는다.

```text
Clothing
├── Top
├── Bottom
├── Outer
├── Underwear
├── Socks
├── Shoes
├── Gloves
├── Hat
└── Accessories
```

사용자가:

"상의만 변경"

이라고 하면 다른 요소는 최대한 유지하면서 상의만 변경할 수 있어야 한다.

---

# 22. 이미지 오류 검사

생성된 이미지에서 다음 요소를 검사한다.

- Hands
- Fingers
- Feet
- Shoes
- Face
- Eyes
- Ears
- Hair
- Accessories
- Clothing
- Small Props

문제가 발견되면 전체 이미지를 무조건 재생성하지 않는다.

---

# 23. Targeted Inpainting

핵심 원칙:

> **수정이 필요한 부분만 수정한다.**

예:

```text
Full Image
     ↓
Hand Error Detected
     ↓
Select Hand Region
     ↓
Hand Inpainting
     ↓
Keep Everything Else
```

사용자가 직접 영역을 선택할 수도 있어야 한다.

수정 영역 밖의 이미지가 최대한 보존되도록 한다.

---

# 24. Automatic Visual Verification

생성 후 Vision AI/VLM을 사용하여 결과를 검사한다.

검사 항목:

- Character Count
- Character Presence
- Character Position
- Face
- Hair
- Clothing
- Accessories
- Pose
- Expression
- Gaze
- Background
- Props
- Hands
- Feet
- Shoes
- 기타 사용자가 명시한 요소

예:

```text
Generation Check

✓ Character A
✓ White Shirt
✓ Black Skirt
✓ Classroom
✓ Right Hand on Window

✗ Gaze Direction
✗ Left Hand
```

사용자가 선택한다.

- Full Regenerate
- Partial Repair
- Accept

---

# 25. Automatic Repair Loop

가능하면:

```text
Generate
 ↓
Vision Check
 ↓
No Error
 ↓
Done
```

또는:

```text
Generate
 ↓
Vision Check
 ↓
Error
 ↓
Classify Error
 ↓
Targeted Inpainting
 ↓
Vision Check
 ↓
Pass
```

자동 수정 횟수에는 제한을 둔다.

예:

**최대 1~3회**

RX 6600 8GB에서 무한 생성 Loop가 발생하지 않도록 한다.

---

# 26. Character Consistency

동일 캐릭터가 여러 패널에 등장할 경우 일관성을 최대한 유지한다.

가능한 방법:

- Character Reference
- Face Reference
- Style Reference
- IP-Adapter
- LoRA
- Seed
- Generation Metadata
- Previous Panel Reference
- Character State

등을 적절하게 조합한다.

단순히 매번 같은 Prompt를 반복하는 것으로 끝내지 않는다.

---

# 27. Story State

만화에서는 캐릭터 상태가 장면마다 변화할 수 있다.

따라서 프로젝트에:

- 현재 의상
- 현재 액세서리
- 현재 위치
- 현재 소품
- 현재 상태
- 스토리 진행 상태

등을 저장할 수 있도록 설계한다.

이를 통해 이전 패널의 상황이 다음 패널에 자연스럽게 이어지도록 한다.

---

# 28. Generation Metadata

생성 결과마다 다음 정보를 저장한다.

- Model
- VAE
- LoRA
- ControlNet
- IP-Adapter
- Prompt
- Negative Prompt
- Seed
- Steps
- CFG
- Sampler
- Resolution
- Reference Images
- Workflow
- Timestamp

나중에 동일하거나 유사한 결과를 재현할 수 있어야 한다.

---

# 29. Generation History

생성 결과를 자동으로 버전 관리한다.

예:

```text
Panel 12
├── Generation 001
├── Generation 002
├── Generation 003
└── Final
```

이전 결과를 다시 선택할 수 있어야 한다.

---

# 30. Undo / Version Control

특히 Inpainting에서는 수정 결과가 원본보다 나빠질 수 있다.

따라서:

```text
Original
 ↓
Repair 1
 ↓
Repair 2
 ↓
Repair 3
```

각 단계로 돌아갈 수 있어야 한다.

수정하기 전 원본을 보존한다.

---

# 31. 원본 이미지 보호

부분 수정 시 사용자가 지정하지 않은 영역은 최대한 변경하지 않는다.

특히 Inpainting에서:

> **수정 대상 영역 밖의 캐릭터 얼굴, 의상, 배경, 구도 등이 불필요하게 변하지 않도록 한다.**

---

# 32. Manga Editor

최종 목표는 이미지 생성기가 아니라 만화 제작 시스템이다.

구조:

```text
Story
 ↓
Storyboard
 ↓
Page
 ↓
Panel
 ↓
Image Generation
 ↓
Correction
 ↓
Speech Bubble
 ↓
Dialogue
 ↓
SFX
 ↓
Final Page
```

---

# 33. Page Editor

페이지를 편집할 수 있어야 한다.

필요 기능:

- Page Size
- Panel Creation
- Panel Resize
- Panel Move
- Panel Ordering
- Image Placement
- Speech Bubble
- Dialogue
- SFX
- Text
- Export

---

# 34. Dialogue는 이미지 생성과 분리

AI 이미지 생성 모델에게 한글/일본어 대사를 직접 생성시키지 않는다.

말풍선과 텍스트는 별도 편집 시스템에서 처리한다.

```text
Panel
├── Image
├── Speech Bubble
│   └── Text
└── SFX
```

사용자가 나중에 직접 대사를 입력하고 수정할 수 있어야 한다.

---

# 35. 프로젝트 구조

권장 구조:

```text
Project/
│
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

프로젝트 전체를 Export / Import할 수 있도록 한다.

다른 PC에서 프로젝트를 복구할 수 있는 구조를 고려한다.

---

# 36. UI

초보자가 사용할 수 있어야 한다.

기본 화면은 다음과 같은 방향을 권장한다.

```text
┌─────────────────────────────────────┐
│ Project                             │
├──────────────┬──────────────────────┤
│ Characters   │ Scene Description     │
│              │                      │
│ A            │ 한국어 자연어 입력   │
│ B            │                      │
│ C            │                      │
│              │                      │
│ References  │ Scene Layout          │
│              │                      │
│ Character    │                      │
│ Face         │                      │
│ Pose         │                      │
│ Clothing     │                      │
│ Style        │                      │
│ Background   │                      │
├──────────────┴──────────────────────┤
│ Generate                            │
├─────────────────────────────────────┤
│ Result / Verification               │
└─────────────────────────────────────┘
```

고급 옵션은 Advanced 메뉴로 분리한다.

---

# 37. 오류 메시지

단순히 "Generation Failed"라고 표시하지 않는다.

가능하면 원인을 분류한다.

예:

- VRAM 부족
- Model Missing
- Custom Node Missing
- Backend Error
- ControlNet Error
- Workflow Error
- Invalid Model
- Unsupported Configuration

그리고 가능한 해결 방법을 함께 표시한다.

---

# 38. 모델 추상화 구조

특정 모델 하나에 프로그램 전체가 종속되지 않도록 한다.

예:

```text
Common Scene Data
        ↓
Model Adapter
        ↓
Model-specific Prompt / Conditioning
        ↓
Workflow Adapter
        ↓
ComfyUI
```

새로운 모델이 등장했을 때 전체 프로그램을 다시 만드는 것이 아니라 Model Adapter/Workflow Adapter를 추가하는 방식으로 확장할 수 있어야 한다.

---

# 39. 기존 Workflow와 새 Workflow 분리

기존 ComfyUI Workflow와 AI Manga Studio Workflow를 분리한다.

예:

```text
Existing ComfyUI Workflows
        ↓
보존

AI Manga Studio Workflows
        ↓
별도 관리
```

기존 Workflow를 분석해서 재사용할 수 있는 요소만 가져온다.

---

# 40. 테스트

다음 테스트를 실제 사용자 PC에서 수행한다.

### Environment

- GPU Detection
- VRAM Detection
- AMD Backend
- ComfyUI Launch

### Model

- Checkpoint Load
- VAE
- Text Encoder
- LoRA

### Generation

- Text-to-Image
- Fast Draft
- High Quality

### Control

- Character Reference
- Style Reference
- Pose Reference
- ControlNet
- IP-Adapter

### Repair

- Face Inpainting
- Hand Inpainting
- Foot/Shoe Inpainting
- Clothing Inpainting
- Accessory Inpainting
- Background Inpainting

### Logic

- Korean Natural Language Parsing
- Character Separation
- Multi-character
- Clothing Separation
- Scene Layout

### Verification

- Character Detection
- Attribute Verification
- Pose Verification
- Background Verification
- Error Detection

### Manga

- Page
- Panel
- Speech Bubble
- Dialogue
- SFX
- Export

---

# 41. 성능 테스트

각 주요 Workflow에 대해:

- VRAM 사용량
- 생성 시간
- 실패 여부
- GPU 사용률
- CPU 사용률
- RAM 사용량

을 기록한다.

RX 6600 8GB에서 실제로 어느 정도의 설정이 안정적인지 확인한다.

---

# 42. 설치 실패 대응

자동 설치나 자동 설정이 실패했을 경우 프로그램이 중단된 상태로 끝나면 안 된다.

다음 정보를 표시한다.

```text
Problem
Cause
Required File
Required Version
Required Path
Solution
Retry
```

가능하면 자동 수정 후 재시도한다.

---

# 43. 보안 및 안정성

설치 프로그램이 기존 ComfyUI 환경을 임의로 파괴하지 않도록 한다.

중요한 파일을 변경하기 전에 백업한다.

모델 다운로드 및 Custom Node 설치 시 출처를 확인한다.

---

# 44. 개발 완료 기준

다음 조건을 만족해야 프로젝트가 기본적으로 완료된 것으로 본다.

### 환경

- [ ] Windows 11에서 실행
- [ ] Ryzen 5 5600X에서 실행
- [ ] RAM 32GB 환경에서 실행
- [ ] RX 6600 8GB에서 실제 생성
- [ ] AMD Backend 정상 작동

### 기존 환경

- [ ] 기존 ComfyUI 보존
- [ ] 기존 Workflow 3개 보존
- [ ] 기존 모델 보존
- [ ] 기존 Custom Node 보존
- [ ] 백업 가능

### AI Generation

- [ ] Text-to-Image
- [ ] Fast Draft
- [ ] High Quality
- [ ] Character Reference
- [ ] Style Reference
- [ ] Pose Reference
- [ ] Clothing Reference
- [ ] Background Reference
- [ ] ControlNet/OpenPose
- [ ] IP-Adapter

### Character

- [ ] Character Profile
- [ ] Character Consistency
- [ ] Multi-character
- [ ] Attribute Separation
- [ ] Clothing State
- [ ] Story State

### Repair

- [ ] Hand Repair
- [ ] Face Repair
- [ ] Foot/Shoe Repair
- [ ] Clothing Repair
- [ ] Accessory Repair
- [ ] Background Repair
- [ ] Targeted Inpainting
- [ ] Original Preservation
- [ ] Undo/Version

### AI Verification

- [ ] Character Verification
- [ ] Clothing Verification
- [ ] Pose Verification
- [ ] Expression Verification
- [ ] Background Verification
- [ ] Object Verification
- [ ] Hand/Foot/Face Verification
- [ ] Automatic Repair Loop

### Manga

- [ ] Story
- [ ] Storyboard
- [ ] Page
- [ ] Panel
- [ ] Speech Bubble
- [ ] Dialogue
- [ ] SFX
- [ ] Export

### Project

- [ ] Generation History
- [ ] Metadata
- [ ] Backup
- [ ] Import
- [ ] Export

---

# 45. 가장 중요한 최종 사용자 경험

최종 사용자는 AI 모델의 Prompt 문법을 몰라도 다음과 같은 작업을 할 수 있어야 한다.

```text
1. 캐릭터를 만든다.
        ↓
2. 캐릭터 Reference를 지정한다.
        ↓
3. 한국어로 장면을 설명한다.
        ↓
4. 필요한 Reference를 지정한다.
        ↓
5. Generate를 누른다.
        ↓
6. AI가 이미지를 생성한다.
        ↓
7. AI가 결과를 검사한다.
        ↓
8. 오류가 있으면 해당 부분만 수정한다.
        ↓
9. 캐릭터 일관성을 유지한다.
        ↓
10. 여러 패널을 만든다.
        ↓
11. 페이지에 배치한다.
        ↓
12. 대사와 효과음을 추가한다.
        ↓
13. 완성된 만화를 Export한다.
```

사용자가 직접 Prompt Tag, ComfyUI Node, ControlNet 설정 등을 관리하지 않아도 되는 것이 기본 UX다.

---

# 46. 최종 개발 철학

이 프로그램의 핵심은 **"AI가 이미지를 한 장 잘 만드는 것"이 아니다.**

핵심은:

> **사용자가 원하는 장면을 정확하게 해석하고, 그 장면을 반복적으로 수정하면서 캐릭터와 스타일의 일관성을 유지하고, 최종적으로 여러 패널의 만화로 완성할 수 있게 하는 것**

이다.

따라서 단일 이미지의 화질만을 기준으로 모델을 선정하지 않는다.

다음 전체 과정의 성능을 기준으로 판단한다.

```text
Natural Language
       ↓
Scene Understanding
       ↓
Character Control
       ↓
Reference Control
       ↓
Pose Control
       ↓
Generation
       ↓
Visual Verification
       ↓
Targeted Repair
       ↓
Consistency
       ↓
Manga Panel
       ↓
Manga Page
```

**이 전체 Pipeline이 사용자 PC에서 안정적으로 실행되는 것을 최종 목표로 한다.**