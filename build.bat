@echo off
setlocal

set SDK=C:\Users\xboxe\AppData\Roaming\Garmin\ConnectIQ\Sdks\connectiq-sdk-win-9.1.0-2026-03-09-6a872a80b
set JAR=%SDK%\bin\monkeybrains.jar
set KEY=D:\GarminDevKey\developer_key
set DEVICE=vivoactive5

echo Building release package (.iq)...
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "%JAR%" -o ready.iq -f monkey.jungle -y "%KEY%" -e -r -w -l 3
if %ERRORLEVEL% neq 0 ( echo Build failed. & exit /b 1 )

echo Building sideload binary (.prg)...
java -Xms1g -Dfile.encoding=UTF-8 -Dapple.awt.UIElement=true -jar "%JAR%" -o ready.prg -f monkey.jungle -y "%KEY%" -d "%DEVICE%" -r -w -l 3
if %ERRORLEVEL% neq 0 ( echo Build failed. & exit /b 1 )

echo.
echo Build successful:
echo   ready.iq   (all devices)
echo   ready.prg  (vivoactive5 sideload)
