:: Name:     BuildUE5Project.bat
:: Purpose:  Build / generate / package the UE project without opening Visual Studio IDE.
:: Author:   EvenZHAng

:: This batch file is used to operate the UE5 project in current folder.
:: For this bat to work correctly:
::   1. This bat file must be placed in the same folder with the *.uproject file.
::   2. The engine version is read from the *.uproject file, then the matching install is resolved.
::   3. The target platform is hardcoded to Win64.

@echo off
setlocal enabledelayedexpansion

SET CurrentPath=%cd%
echo Current Path: %CurrentPath%
echo.

:: ---------------------------------------------------------------
:: Locate the *.uproject file
:: ---------------------------------------------------------------
set "FileName="
for %%a in (*.uproject) do (
    set "FileName=%%a"
)
if not defined FileName Goto :NOFILE

set "FileNameNoSuffix=%FileName:.uproject=%"
echo Find UProject file: %FileName%
echo UProject Name: %FileNameNoSuffix%
echo.

:: ---------------------------------------------------------------
:: Global variables used by all tasks
:: ---------------------------------------------------------------
set "TargetPlatform=Win64"
set "ProjectFile=%CurrentPath%\%FileName%"

:: Root folder containing source-built engines named UE_<version>.
:: Override with the UE_SOURCE_ROOT environment variable if needed.
if not defined UE_SOURCE_ROOT set "UE_SOURCE_ROOT=F:\UnrealEngine"

:: ---------------------------------------------------------------
:: Locate the engine installation matching the *.uproject
:: ---------------------------------------------------------------
call :FIND_UE_PATH
if not defined UEInstalledPath Goto :NOENGINE

echo Engine Version: %EngineVersion%
echo Engine Path: %UEInstalledPath%
echo.

set "UBTPath=%UEInstalledPath%\Engine\Build\BatchFiles"
set "UBTExe=%UEInstalledPath%\Engine\Binaries\DotNET\UnrealBuildTool\UnrealBuildTool.exe"
set "GenProjectFilesBat=%UBTPath%\GenerateProjectFiles.bat"
set "ArchiveRoot=%CurrentPath%\Packaged"

:: Optional argument: task name or number.
:: Usage: BuildUE5Project.bat <vs|vscode|build|rebuild|package-dev|package-shipping|1-6>
:: When an argument is given, the task runs directly (no menu, no pause).
set "TaskArg=%~1"
set "Interactive=1"
if not "%TaskArg%"=="" set "Interactive=0"

if "%Interactive%"=="0" Goto :DISPATCH_ARG


:MAINMENU
echo ==========================================================
echo   UE5 Project Toolbox - %FileNameNoSuffix%
echo ==========================================================
echo   [1] Generate Visual Studio solution
echo   [2] Generate VS Code workspace
echo   [3] Build project   (Editor / Win64 / Development)
echo   [4] Rebuild project (clean then build)
echo   [5] Package project - Development
echo   [6] Package project - Shipping
echo.
echo   [0] Exit
echo ==========================================================
echo   CLI: build / rebuild / package-dev / package-shipping / vs / vscode
echo ==========================================================
set "CHOICE="
set /p "CHOICE=Please enter your choice [0-6]: "

if "%CHOICE%"=="1" Goto :TASK_VS
if "%CHOICE%"=="2" Goto :TASK_VSCODE
if "%CHOICE%"=="3" Goto :TASK_BUILD
if "%CHOICE%"=="4" Goto :TASK_REBUILD
if "%CHOICE%"=="5" Goto :TASK_PACKAGE_DEV
if "%CHOICE%"=="6" Goto :TASK_PACKAGE_SHIPPING
if "%CHOICE%"=="0" Goto :FINISH

echo.
echo Invalid choice, please try again.
echo.
Goto :MAINMENU


:: ===============================================================
:: Non-interactive dispatch (task number passed on the command line)
:: ===============================================================
:DISPATCH_ARG
:: Named aliases (case-insensitive)
if /i "%TaskArg%"=="vs"               Goto :TASK_VS
if /i "%TaskArg%"=="vscode"           Goto :TASK_VSCODE
if /i "%TaskArg%"=="build"            Goto :TASK_BUILD
if /i "%TaskArg%"=="rebuild"          Goto :TASK_REBUILD
if /i "%TaskArg%"=="package-dev"      Goto :TASK_PACKAGE_DEV
if /i "%TaskArg%"=="package-shipping" Goto :TASK_PACKAGE_SHIPPING

:: Numeric tasks (kept for backward compatibility)
if "%TaskArg%"=="1" Goto :TASK_VS
if "%TaskArg%"=="2" Goto :TASK_VSCODE
if "%TaskArg%"=="3" Goto :TASK_BUILD
if "%TaskArg%"=="4" Goto :TASK_REBUILD
if "%TaskArg%"=="5" Goto :TASK_PACKAGE_DEV
if "%TaskArg%"=="6" Goto :TASK_PACKAGE_SHIPPING

echo [ERROR] Invalid task: "%TaskArg%"
echo         Expected: vs, vscode, build, rebuild, package-dev, package-shipping, or 1-6.
Goto :FINISH


:: ===============================================================
:: [1] Generate Visual Studio solution
:: ===============================================================
:TASK_VS
echo.
echo [1] Generating Visual Studio solution ...
echo.
call :GEN_PROJECT_FILES
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to generate the Visual Studio solution. Error code: !errorlevel!
) else (
    echo.
    echo [OK] Solution: "%CurrentPath%\%FileNameNoSuffix%.sln"
)
Goto :BACK_TO_MENU


:: ===============================================================
:: [2] Generate VS Code workspace
:: ===============================================================
:TASK_VSCODE
echo.
echo [2] Generating VS Code workspace ...
echo.
call :GEN_PROJECT_FILES -VSCode
if errorlevel 1 (
    echo.
    echo [ERROR] Failed to generate the VS Code workspace. Error code: !errorlevel!
) else (
    echo.
    echo [OK] Workspace: "%CurrentPath%\%FileNameNoSuffix%.code-workspace"
)
Goto :BACK_TO_MENU


:: ===============================================================
:: [3] Build project (Editor / Win64 / Development)
:: ===============================================================
:TASK_BUILD
echo.
echo [3] Building %FileNameNoSuffix%Editor %TargetPlatform% Development ...
echo.
call "%UBTPath%\Build.bat" %FileNameNoSuffix%Editor %TargetPlatform% Development -Project="%ProjectFile%" -WaitMutex
if errorlevel 1 (
    echo.
    echo [ERROR] Build failed. Error code: !errorlevel!
) else (
    echo.
    echo [OK] Build Done.
)
Goto :BACK_TO_MENU


:: ===============================================================
:: [4] Rebuild project (clean then build)
:: ===============================================================
:TASK_REBUILD
echo.
echo [4] Rebuilding %FileNameNoSuffix%Editor %TargetPlatform% Development ...
echo.
call "%UBTPath%\Rebuild.bat" %FileNameNoSuffix%Editor %TargetPlatform% Development -Project="%ProjectFile%" -WaitMutex
if errorlevel 1 (
    echo.
    echo [ERROR] Rebuild failed. Error code: !errorlevel!
) else (
    echo.
    echo [OK] Rebuild Done.
)
Goto :BACK_TO_MENU


:: ===============================================================
:: [5] Package project - Development
:: ===============================================================
:TASK_PACKAGE_DEV
set "PackConfig=Development"
Goto :DO_PACKAGE


:: ===============================================================
:: [6] Package project - Shipping
:: ===============================================================
:TASK_PACKAGE_SHIPPING
set "PackConfig=Shipping"
Goto :DO_PACKAGE


:: ===============================================================
:: Shared packaging routine (BuildCookRun)
:: ===============================================================
:DO_PACKAGE
set "ArchiveDir=%ArchiveRoot%\%PackConfig%"
echo.
echo Packaging [%PackConfig%] - output: "%ArchiveDir%"
echo This may take a long time, please wait ...
echo.
call "%UBTPath%\RunUAT.bat" BuildCookRun ^
 -project="%ProjectFile%" ^
 -noP4 ^
 -platform=%TargetPlatform% ^
 -clientconfig=%PackConfig% ^
 -serverconfig=%PackConfig% ^
 -build ^
 -cook ^
 -stage ^
 -pak ^
 -compressed ^
 -archive ^
 -archivedirectory="%ArchiveDir%" ^
 -nocompileeditor ^
 -utf8output
if errorlevel 1 (
    echo.
    echo [ERROR] Packaging [%PackConfig%] failed. Error code: !errorlevel!
) else (
    echo.
    echo [OK] Packaging [%PackConfig%] Done. Output: "%ArchiveDir%"
)
Goto :BACK_TO_MENU


:: ===============================================================
:: Subroutines
:: ===============================================================

:: Generate IDE project files.
:: Uses GenerateProjectFiles.bat when the engine provides it,
:: otherwise falls back to UnrealBuildTool -ProjectFiles.
:: Arguments are appended verbatim, e.g. "call :GEN_PROJECT_FILES -VSCode".
:GEN_PROJECT_FILES
set "GENARGS=%*"
if exist "%GenProjectFilesBat%" (
    call "%GenProjectFilesBat%" -project="%ProjectFile%" -game -engine !GENARGS!
    exit /b !errorlevel!
)
if not exist "%UBTExe%" (
    echo [ERROR] Cannot find UnrealBuildTool.exe:
    echo         "%UBTExe%"
    exit /b 1
)
call "%UBTExe%" -ProjectFiles -Project="%ProjectFile%" -Game -Engine -Progress !GENARGS!
exit /b !errorlevel!


:: Resolve the engine version from the *.uproject, then locate the matching install.
:: Lookup order:
::   1. EngineAssociation in the *.uproject
::   2. Custom engine registered in HKCU\Software\Epic Games\Unreal Engine\Builds
::   3. Launcher install registered in HKLM\SOFTWARE\EpicGames\Unreal Engine\<version>
::   4. Default Launcher install path
::   5. Source-built engine under UE_SOURCE_ROOT
:FIND_UE_PATH
set "UEInstalledPath="
set "EngineVersion="

:: 1) Engine version from the .uproject (e.g. "5.6")
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "try { (Get-Content -Raw -LiteralPath '%ProjectFile%' | ConvertFrom-Json).EngineAssociation } catch { }"`) do set "EngineVersion=%%a"

if not defined EngineVersion (
    echo [ERROR] Cannot determine EngineAssociation from "%ProjectFile%".
    exit /b 0
)

:: 2) Custom/source build registered in HKCU
for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "try { (Get-ItemProperty 'Registry::HKEY_CURRENT_USER\Software\Epic Games\Unreal Engine\Builds' -Name '%EngineVersion%' -ErrorAction Stop).'%EngineVersion%' } catch { }"`) do set "UEInstalledPath=%%a"

:: 3) Launcher install registered in HKLM
if not defined UEInstalledPath (
    for /f "usebackq delims=" %%a in (`powershell -NoProfile -Command "try { (Get-ItemProperty 'Registry::HKEY_LOCAL_MACHINE\SOFTWARE\EpicGames\Unreal Engine\%EngineVersion%' -Name 'InstalledDirectory' -ErrorAction Stop).'InstalledDirectory' } catch { }"`) do set "UEInstalledPath=%%a"
)

:: 4) Default Launcher install path
if not defined UEInstalledPath (
    if exist "%ProgramFiles%\Epic Games\UE_%EngineVersion%\Engine\Build\BatchFiles\Build.bat" set "UEInstalledPath=%ProgramFiles%\Epic Games\UE_%EngineVersion%"
)

:: 5) Source-built engine (UE_<version> under UE_SOURCE_ROOT)
if not defined UEInstalledPath if defined UE_SOURCE_ROOT (
    if exist "%UE_SOURCE_ROOT%\UE_%EngineVersion%\Engine\Build\BatchFiles\Build.bat" set "UEInstalledPath=%UE_SOURCE_ROOT%\UE_%EngineVersion%"
)

if not defined UEInstalledPath exit /b 0

:: Strip a trailing backslash
if "%UEInstalledPath:~-1%"=="\" set "UEInstalledPath=%UEInstalledPath:~0,-1%"

if not exist "%UEInstalledPath%\Engine\Build\BatchFiles\Build.bat" set "UEInstalledPath="
exit /b 0


:BACK_TO_MENU
if "%Interactive%"=="0" Goto :FINISH
echo.
echo ----------------------------------------------------------
echo Task finished. Press any key to return to the main menu ...
pause >nul
Goto :MAINMENU


:NOFILE
echo No *.uproject file in this folder.
Goto :FINISH


:NOENGINE
echo [ERROR] No Unreal Engine installation was found for version "%EngineVersion%".
echo         EngineAssociation was read from: "%ProjectFile%"
echo         Looked in:
echo           HKCU\Software\Epic Games\Unreal Engine\Builds
echo           HKLM\SOFTWARE\EpicGames\Unreal Engine\%EngineVersion%
echo           %ProgramFiles%\Epic Games\UE_%EngineVersion%
echo           %UE_SOURCE_ROOT%\UE_%EngineVersion%
Goto :FINISH


:FINISH
if "%Interactive%"=="0" exit /b 0
echo.
echo Bye.
pause