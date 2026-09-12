# AI Manga Studio — Session Handoff

이 문서는 세션이 바뀌어도 프로젝트를 동일한 기준으로 재개하기 위한 인수인계 문서다.

## Canonical sources of truth

| 영역 | 기준 위치 | 현재 상태 |
|---|---|---|
| 원본 요구사항·ComfyUI 자료 | `/home/ubuntu/ai-manga-studio-dev` 및 GitHub `asmodeus007001-wq/ai-manga-studio-dev` | v8 지시서 확인 완료, 부록 A 워크플로우 4개 정적 검증 PASS |
| Web 앱 소스·DB·UI | WebDev 프로젝트 `ai-manga-studio` (`/home/ubuntu/ai-manga-studio`) | Stage 14 완료, latest checkpoint `7ae7f652` |
| Web 앱 복구 지점 | WebDev checkpoint | `manus-webdev://7ae7f652` |
| 사용자 데이터 | WebDev managed database | migration 0005 적용 완료 |
| 실제 생성 런타임 | 사용자 Windows 11 + RX6600 ComfyUI | 아직 연결·Gate 1 실증 필요 |

## Completed stages

1. Repository clone, v8 instruction review, appendix-A inventory
2. Korean scene parser and prompt preview
3. Workflow catalog and queue payload preparation
4. Character and Story State foundation
5. Review checklist and partial repair MVP
6. Navigation, editor, history views
7. Panel persistence
8. Image storage upload and panel preview
9. Current-page longstrip PNG/PDF export
10. Multi-page project and page persistence
11. Project-wide navigator and export
12. Drag reorder and persisted panel order
13. Panel duplicate/delete and order undo/redo
14. Dialogue/SFX overlay position and font-size editing; migration `0005_exotic_doctor_doom.sql`

## Verification status

- TypeScript: passed
- Vitest: 7/7 passed
- Production build: passed
- Browser verification: passed
- Latest WebDev checkpoint: `7ae7f652`

## Important repository status

The source repository and WebDev application are separate repositories/projects. Do not assume that a commit in one updates the other.

At the time of writing, source repo `main` is ahead of `origin/main` by three commits. Push only after reviewing the commits and confirming that the user wants the remote updated.

## Do not commit

- `.env` files or secrets
- Manus/OAuth/API keys
- database credentials
- model binaries (`.safetensors`, `.bin`, `.onnx`)
- generated user images, private references, or personal project data
- local `node_modules`, `dist`, caches, and logs

## Required next work

1. Decide whether the four source workflow JSON files should be copied/versioned into the WebDev app's readiness layer. The source repository contains them; an earlier readiness implementation in another WebDev checkpoint reported them missing because it inspected a different project path.
2. Connect the user's Windows 11 + RX6600 ComfyUI endpoint.
3. Verify checkpoint/VAE/custom-node/model availability on that machine.
4. Execute Gate 1 through `/prompt` with the four workflows.
5. Preserve Gate 1 evidence: workflow name, commit/version, endpoint, model filenames, prompt response, output image, logs, and failure details.
6. After real-PC verification, save a new WebDev checkpoint and update this handoff document.

## Resume protocol

1. Read this file and `PROGRESS.md` first.
2. Open WebDev project `ai-manga-studio` or restore checkpoint `7ae7f652`.
3. Check the WebDev project status before editing; do not recreate the project.
4. Inspect the source repository workflow files and run `validate_workflow_links.py` before changing them.
5. Never claim ComfyUI/Gate 1 is verified from the Linux sandbox; it requires the user's Windows/RX6600 machine.
6. End each substantial stage with: tests, build, browser verification, a WebDev checkpoint, and an updated handoff record.
