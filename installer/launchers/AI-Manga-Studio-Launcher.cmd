@echo off
setlocal
set "ROOT=%~dp0"
set "APP_DATA=%ROOT%data"
if not exist "%APP_DATA%" mkdir "%APP_DATA%"
set "NODE_ENV=production"
start "AI Manga Studio Server" /D "%ROOT%app" "%ROOT%runtime\node.exe" "%ROOT%app\dist\index.js"
timeout /t 2 /nobreak >nul
start "AI Manga Studio" "http://127.0.0.1:3000"
endlocal
