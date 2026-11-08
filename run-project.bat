@echo off
REM ============================================================================
REM  CHAY TOAN BO PROJECT: SQL Server + Backend + App Web
REM  Cach dung: chay dung (khong can Admin - SQL Server da duoc cai dat)
REM ============================================================================
title LTDD - Run Project
setlocal EnableDelayedExpansion

echo.
echo === [1/3] Kiem tra SQL Server (MSSQL$MSSQLSERVER01) ===
sc query "MSSQL$MSSQLSERVER01" | findstr "STATE" | findstr "RUNNING" >nul
if errorlevel 1 (
    echo     [!] Service SQL Server khong chay. Tuong duoc Windows tu dong start.
) else (
    echo     OK.
)

echo.
echo === [2/3] Kiem tra dong TCP port cua SQL (port dong duoc thay doi sau reboot) ===
powershell -NoProfile -Command ^
    "$p = (Get-NetTCPConnection -OwningProcess (Get-CimInstance Win32_Service -Filter "Name='MSSQL`$MSSQLSERVER01'").ProcessId -State Listen -ErrorAction SilentlyContinue).LocalPort ^| Select-Object -First 1; if ($p) { Set-Content 'C:\LTDD\backend\.env' @('DB_HOST=127.0.0.1', 'DB_PORT=' + $p, 'DB_USER=restaurant_user', 'DB_PASSWORD=your_password', 'DB_NAME=QLNH'); Write-Host ('     Port dong SQL = ' + $p + ' -> da cap nhat .env') } else { Write-Host '     Can thuc hien: bat Mixed Mode (enable-mixed-mode.bat)' }"

echo.
echo === [3/3] Kiem tra va phat backend + app web ===
REM Dong backend cu (neu van chay)
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":8080" ^| findstr "LISTENING"') do (
    echo     Dong backend cu PID %%p
    taskkill /F /PID %%p >nul 2>&1
)
for /f "tokens=5" %%p in ('netstat -ano ^| findstr ":5000" ^| findstr "LISTENING"') do (
    echo     Dong web app cu PID %%p
    taskkill /F /PID %%p >nul 2>&1
)
REM Khong can dong flutter chi chinh - web app bi phat lai
timeout /t 2 /nobreak >nul

REM Mo 2 terminal rieng: backend + flutter web
echo.
echo  Mo terminal moi de chay backend...
start "LTDD-Backend" cmd /k "cd /d C:\LTDD\backend ^&^& dart run lib/main.dart"
echo  Mo terminal moi de chay app web...
start "LTDD-Web" cmd /k "cd /d C:\LTDD ^&^& flutter run -d chrome --web-port=5000 --web-hostname=127.0.0.1"

echo.
echo ============================================================================
echo  HOAN TAT!  Chờ ~30 giay cho backend compile xong.
echo
echo  Backend   : http://127.0.0.1:8080
echo  App Web   : http://127.0.0.1:5000
echo  Admin     : admin / admin123
echo
echo  Khi backend bi mat (dong terminal, restart may...):
echo    - Chay lai file nay, hoac
echo    - Trong terminal backend: gan  Ctrl+C - roi chay "dart run lib/main.dart"
echo ============================================================================
echo.
pause
