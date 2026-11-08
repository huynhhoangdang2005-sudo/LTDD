@echo off
REM ============================================================================
REM  BATT MIXED MODE + TCP PORT 1433 CHO INSTANCE MSSQL$MSSQLSERVER01
REM  (De backend Dart ket noi QLNH bang login restaurant_user)
REM
REM  cach chay: Chuot phai file nay -> "Run as Administrator"
REM  (can quyen Admin vi phai ghi registry + restart service SQL)
REM ============================================================================
title Enable Mixed Mode + TCP 1433 - MSSQLSERVER01

set "BASE=HKLM\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL16.MSSQLSERVER01\MSSQLServer"
set "SVC=MSSQL$MSSQLSERVER01"

echo.
echo [1/4] Bật Mixed Mode Authentication (LoginMode=2)...
reg add "%BASE%" /v LoginMode /t REG_DWORD /d 2 /f
if errorlevel 1 (
  echo [LOI] Khong ghi duoc registry - phai chay "Run as Administrator".
  pause & exit /b 1
)

echo [2/4] Bật TCP protocol + gan port that 1433...
reg add "%BASE%\SuperSockets\Tcp" /v enabled /t REG_DWORD /d 1 /f
reg add "%BASE%\SuperSockets\Tcp" /v TcpDynamicPorts /t REG_SZ /d "" /f
reg add "%BASE%\SuperSockets\Tcp\IPAll" /v enabled /t REG_DWORD /d 1 /f
reg add "%BASE%\SuperSockets\Tcp\IPAll" /v Port /t REG_DWORD /d 1433 /f

echo [3/4] Restart service %SVC% (can ~10 giay)...
sc stop "%SVC%"
sc start "%SVC%"
if errorlevel 1 (
  echo [LOI] Khong restart duoc service - thieu quyen Admin?
  pause & exit /b 1
)

echo [4/4] Chờ server sẵn sàng (8 giay)...
timeout /t 8 /nobreak >nul

echo.
echo ===================== VERIFY (nhanh) =====================
netstat -ano -p TCP | findstr ":1433" | findstr LISTENING
powershell -NoProfile -Command "Add-Type -AssemblyName System.Data; try { $c = New-Object System.Data.SqlClient.SqlConnection 'Server=127.0.0.1,1433;User ID=restaurant_user;Password=your_password;Initial Catalog=QLNH;Encrypt=False;TrustServerCertificate=True;Connect Timeout=10'; $c.Open(); Write-Host 'OK: SQL password login restaurant_user co duoc!'; $c.Close() } catch { Write-Host ('VAN LOI: ' + $_.Exception.Message) }"
echo ==========================================================
echo.
echo HOAN TAT! Bay gio chay backend (moi cua cmd):
echo   cd C:\LTDD\backend
echo   set MSSQL_PORT=1433
echo   dart run lib/main.dart
echo.
echo LUU Y: .env hien dang DB_PORT=64517. Sau khi bat 1433 thanh cong,
echo          sua file .env: thay DB_PORT=64517 thanh DB_PORT=1433
echo          (hoac dong .env va set MSSQL_PORT=1433 khi chay).
echo.
pause
