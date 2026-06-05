@echo off
set ASPNETCORE_ENVIRONMENT=Development
set ASPNETCORE_URLS=http://localhost:5135
set Logging__EventLog__LogLevel__Default=None
set LOCALAPPDATA=%~dp0.localappdata
set APPDATA=%~dp0.appdata
set USERPROFILE=%~dp0.profile

REM Check that Jwt__Key is set externally
if "%Jwt__Key%"=="" (
    echo ERROR: Jwt__Key environment variable must be set before running this script.
    echo Please set it with: set Jwt__Key=YourSecretKeyHere
    exit /b 1
)

if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%USERPROFILE%" mkdir "%USERPROFILE%"
cd /d "%~dp0BrightClean.API\bin\Debug\net8.0"
dotnet BrightClean.API.dll > "%~dp0api-run.log" 2>&1
