@echo off
setlocal
set "APP_HOME=%~dp0"
where bash >nul 2>nul
if errorlevel 1 (
  echo Bash is required to run this launcher.
  exit /b 1
)
bash "%APP_HOME%gradlew" %*
