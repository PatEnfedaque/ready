@echo off
setlocal

set SDK=C:\Users\xboxe\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b
set JAR=%SDK%\bin\monkeybrains.jar
set KEY=D:\GarminDevKey\developer_key
set DEVICE=vivoactive5

set TARGET=%~1
if "%TARGET%"=="" set TARGET=all

if /i "%TARGET%"=="prg" goto :prg
if /i "%TARGET%"=="iq"  goto :iq
if /i "%TARGET%"=="all" goto :all
echo Usage: build.bat [prg^|iq^|all]
exit /b 1

:all
echo Building release package (.iq)...
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "%JAR%" -o ready.iq -f monkey.jungle -y "%KEY%" -e -r -w -l 3
if %ERRORLEVEL% neq 0 ( echo Build failed. & exit /b 1 )

:prg
echo Building sideload binary (.prg)...
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "%JAR%" -o ready.prg -f monkey.jungle -y "%KEY%" -d "%DEVICE%" -r -w -l 3
if %ERRORLEVEL% neq 0 ( echo Build failed. & exit /b 1 )
goto :done

:iq
echo Building release package (.iq)...
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "%JAR%" -o ready.iq -f monkey.jungle -y "%KEY%" -e -r -w -l 3
if %ERRORLEVEL% neq 0 ( echo Build failed. & exit /b 1 )

:done
echo.
echo Build successful.
