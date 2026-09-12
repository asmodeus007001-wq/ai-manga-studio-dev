# AI Manga Studio — 진행 상황

## 2026-09-12 — 최종 점검 및 설치 패키징 준비

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
