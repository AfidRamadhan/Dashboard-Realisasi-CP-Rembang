@echo off
setlocal
cd /d "%~dp0"
title SIG Intransit - Realtime Conveyor Rembang Launcher

powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0server-realtime.ps1"

if %ERRORLEVEL% NEQ 0 (
    echo.
    echo Terjadi kendala saat menjalankan server otomatis.
    echo Membuka dashboard secara manual di browser...
    if exist "%~dp0index.html" (
        start "" "%~dp0index.html"
    ) else (
        start "" "%~dp0Realisasi Pengiriman CP-Rembang.html"
    )
    pause
)
