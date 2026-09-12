@echo off
setlocal
set "ROOT=%~dp0"
cd /D "%ROOT%comfyui"
if not exist "main.py" (
  echo Independent ComfyUI runtime is missing from %ROOT%comfyui
  exit /b 1
)
if exist "venv\Scripts\python.exe" (
  "venv\Scripts\python.exe" main.py --listen 127.0.0.1 --port 8188
) else (
  py -3.12 main.py --listen 127.0.0.1 --port 8188
)
endlocal
