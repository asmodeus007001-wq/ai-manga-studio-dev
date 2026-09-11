# AI Manga Studio — 1단계 결과 보고서

작성자: **Manus AI**  
기준 요청서: `AI_Manga_Studio_Manus_최종통합요청서_v6.md`  
작성일: 2026-09-11

## 결론

현재 실행 환경에는 기존 AI Manga Studio 프로젝트, 기존 ComfyUI 폴더, 워크플로우 JSON 4개, `patch_*.py`, `fix_workflow_links.py`, `validate_stage2.py`가 존재하지 않습니다. 따라서 기존 산출물 인벤토리와 기존 환경 무손상 검증 결과는 **완료(대상 없음)**으로 기록합니다.

지정된 `patientx-cfz/comfyui-rocm` 저장소는 외부 접근이 가능하고 `master` 브랜치가 확인되었습니다. 그러나 현재 실행 환경은 **Ubuntu 24.04 Linux**이며 Windows 11, AMD Radeon RX 6600, ROCm 런타임, `rocminfo`, Inno Setup이 없습니다. 그러므로 Windows용 독립 설치, AMD GPU 실제 생성, ComfyUI `/prompt` 실행, Inno Setup 설치·삭제 테스트는 이 세션에서 실측할 수 없습니다. 이는 요청서 §1-3의 **실측 불가 예외**에 해당합니다.

## 1. 실측 인벤토리

| 검사 대상 | 결과 | 상태 |
|---|---|---|
| 기존 AI Manga Studio 프로젝트 | 발견되지 않음 | 완료: 대상 없음 |
| 기존 ComfyUI 폴더 | 발견되지 않음 | 완료: 대상 없음 |
| 요청서에 명시된 워크플로우 JSON | 발견되지 않음 | 미실행: 입력 파일 없음 |
| `patch_*.py` | 발견되지 않음 | 완료: 대상 없음 |
| `fix_workflow_links.py` | 발견되지 않음 | 미실행: 입력 파일 없음 |
| `validate_stage2.py` | 발견되지 않음 | 미실행: 입력 파일 없음 |
| 기존 설치 프로그램 | 발견되지 않음 | 미실행: 입력 파일 없음 |
| 첨부 요청서 | `/home/ubuntu/upload/AI_Manga_Studio_Manus_최종통합요청서_v6.md` | 확인 |

인벤토리 검색 범위는 `/home/ubuntu` 하위 최대 깊이 4이며, 프로젝트명·ComfyUI명·패치 파일명·검증 스크립트명·JSON 확장자를 기준으로 수행했습니다.

## 2. 실행 환경 검증

| 항목 | 실측값 | 요청서 기준 | 판정 |
|---|---|---|---|
| OS | Ubuntu 24.04.4 LTS | Windows 11 Home 64-bit | 불일치 |
| Python | 3.12.3 | Python 3.12 | 일치 |
| Git | 2.43.0 | Git 설치 | 일치 |
| GPU | AMD GPU 미탐지 | Radeon RX 6600, 8GB | 검증 불가 |
| ROCm 도구 | `rocminfo` 미설치 | ROCm 실행 경로 | 검증 불가 |
| Inno Setup | `ISCC` 미설치 | Inno Setup | 검증 불가 |
| Windows 실행 호환 계층 | Wine 미설치 | Windows 실행 | 검증 불가 |

## 3. 지정 저장소 접근 확인

`https://github.com/patientx-cfz/comfyui-rocm.git`에 대한 Git 원격 조회가 성공했습니다.

| 브랜치 | 확인된 커밋 |
|---|---|
| `master` | `544b432061e5d3f43d5a9c123ca3e8d0e01be4d6` |
| `test` | `82896af8d333c81e3d4cb5d6c6dddffb1b3823d7` |

저장소 접근 가능성은 확인했지만, 이는 gfx1032에서의 실제 안정성이나 ROCm nightly wheel 설치 성공을 의미하지 않습니다. 실제 안정성은 RX 6600이 장착된 Windows 대상 PC에서 별도로 검증해야 합니다.

## 4. 독립 설치 구조 설계

대상 Windows PC에서 기존 ComfyUI와 충돌하지 않도록 다음 경로를 기본 구조로 사용합니다.

```text
AI-Manga-Studio/
├── app/
│   ├── frontend/
│   ├── backend/
│   └── assets/
├── comfyui-rocm/
│   ├── ComfyUI/
│   ├── python_embeded/
│   ├── models/
│   ├── custom_nodes/
│   └── user/
├── projects/
├── downloads/
├── logs/
├── backups/
├── tools/
└── uninstall-data/
```

기존 ComfyUI의 파일은 삭제·이동·덮어쓰기하지 않습니다. 기존 보조 체크포인트를 재사용할 때는 우선 **복사 방식**을 적용하여 원본 변경 가능성을 차단합니다. 심볼릭 링크는 Windows 권한과 배포 환경 차이 때문에 기본값으로 사용하지 않습니다.

모델 저장 위치는 독립 ComfyUI 아래에 둡니다.

```text
comfyui-rocm/ComfyUI/models/
├── checkpoints/
├── vae/
├── ipadapter/
├── loras/
├── clip_vision/
├── controlnet/
├── dwpose/
├── bbox/
└── upscale_models/
```

## 5. 단계별 진행 판정

| 요청서 DoD 항목 | 상태 | 사유 |
|---|---|---|
| 기존 산출물 인벤토리 | 부분완료 | 현재 샌드박스에서 대상 없음 확인. 사용자 Windows PC 산출물은 미제공 |
| 독립 설치 구조 확정 | 완료 | 본 보고서의 경로 구조로 확정 |
| 지정 ROCm 저장소 접근 | 완료 | Git 원격 브랜치 조회 성공 |
| Qwen3 로컬 파싱 | 미착수 | 2단계 대상이며 프로젝트 코드가 없음 |
| 워크플로우 그래프 검증 | 미착수 | 워크플로우 입력 JSON이 없음 |
| `/prompt` 실제 큐 테스트 | 미착수 | ComfyUI와 AMD GPU가 없음 |
| Windows/Inno Setup 패키징 | 미착수 | Linux 환경이며 Inno Setup 미설치 |
| 기존 ComfyUI 무손상 검증 | 완료: 대상 없음 | 현재 샌드박스에 기존 ComfyUI가 없음 |

## 6. 예외 및 다음 단계 진입 조건

다음 항목은 요청서에 따라 예외로 보고합니다.

1. **기존 산출물 부재:** 요청서가 전제한 기존 ComfyUI, 워크플로우, 패치 파일이 첨부되지 않았습니다. 따라서 패치 통폐합과 4개 워크플로우 대조 검증을 수행할 원본이 없습니다.
2. **실행 환경 불일치:** 현재 환경은 Windows 11/RX 6600이 아니므로 ROCm·gfx1032 안정성·검은 이미지/NaN 여부·실제 생성 결과를 검증할 수 없습니다.
3. **Windows 패키징 불가:** Inno Setup 설치 파일과 Windows 앱 제거 테스트는 Windows 대상 환경이 필요합니다.

2단계로 진행하려면 다음 중 최소 입력이 필요합니다.

| 필요 입력 | 용도 |
|---|---|
| 기존 AI Manga Studio 또는 ComfyUI 폴더 압축본 | 기존 산출물 인벤토리·보존 검증 |
| 요청서에 언급된 워크플로우 JSON 4개 | 그래프 재구성·링크 검증 |
| `patch_*.py`, 기존 검증 스크립트 | 패치 목적 인벤토리 및 통폐합 |
| RX 6600이 장착된 Windows 11 대상 PC 또는 해당 실측 로그 | ROCm·ComfyUI·생성·큐 검증 |
| 모델 파일 또는 합법적 다운로드 경로와 사용 권한 | 모델 설치·헤더 검증 |

현재 세션에서 안전하게 확정할 수 있는 것은 **독립 설치 구조와 환경 예외 보고**까지입니다. 입력 파일 없이 워크플로우를 새로 추정하거나, Linux에서 Windows/ROCm 성공을 주장하는 것은 요청서의 검증 기준을 위반하므로 진행하지 않았습니다.

## References

[1]: https://github.com/patientx-cfz/comfyui-rocm "patientx-cfz/comfyui-rocm GitHub repository"
[2]: https://docs.comfy.org/ "ComfyUI documentation"
