@echo off
set ASPNETCORE_ENVIRONMENT=Production
set ASPNETCORE_URLS=http://localhost:5135
set Jwt__Key=BrightCleanLocalDevelopmentJwtKey_ChangeMe_AtLeast32Chars
set Logging__EventLog__LogLevel__Default=None
set LOCALAPPDATA=%~dp0.localappdata
set APPDATA=%~dp0.appdata
set USERPROFILE=%~dp0.profile
if not exist "%LOCALAPPDATA%" mkdir "%LOCALAPPDATA%"
if not exist "%APPDATA%" mkdir "%APPDATA%"
if not exist "%USERPROFILE%" mkdir "%USERPROFILE%"
cd /d "%~dp0BrightClean.API\bin\Debug\net8.0"
dotnet BrightClean.API.dll > "%~dp0api-run.log" 2>&1
