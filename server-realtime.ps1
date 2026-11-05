# ==============================================================================
# SIG Intransit - Realtime Conveyor & Realisasi Server Proxy
# PT Semen Gresik - Pabrik Rembang
# ==============================================================================

[System.Net.ServicePointManager]::SecurityProtocol = [System.Net.ServicePointManager]::SecurityProtocol -bor [System.Net.SecurityProtocolType]::Tls12
[System.Net.ServicePointManager]::ServerCertificateValidationCallback = {$true}

$port = 8088
$prefix = "http://127.0.0.1:$port/"
$currentDir = Split-Path -Parent $MyInvocation.MyCommand.Path
if (-not $currentDir) { $currentDir = (Get-Location).Path }

$htmlPath = Join-Path $currentDir "index.html"
if (-not (Test-Path $htmlPath)) {
    $htmlPath = Join-Path $currentDir "Realisasi Pengiriman CP-Rembang.html"
}
$htmlName = Split-Path $htmlPath -Leaf

Clear-Host
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host "   DASHBOARD REALISASI PENGIRIMAN & DISPLAY CONVEYOR REALTIME" -ForegroundColor Yellow
Write-Host "              PT SEMEN GRESIK - PABRIK REMBANG" -ForegroundColor White
Write-Host "=======================================================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "[1/2] Menyiapkan server proxy lokal bebas CORS..." -ForegroundColor Green

$listener = New-Object System.Net.HttpListener
try {
    $listener.Prefixes.Add($prefix)
    $listener.Start()
} catch {
    Write-Host "[PERINGATAN] Port $port sedang digunakan aplikasi lain." -ForegroundColor Yellow
    Write-Host "Membuka file dashboard secara langsung di browser..." -ForegroundColor Yellow
    Start-Process "file:///$($htmlPath.Replace('\', '/'))"
    Write-Host "Tekan sembarang tombol untuk keluar..."
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
    exit
}

Write-Host "[2/2] Server aktif di: $prefix" -ForegroundColor Green
Write-Host "Membuka browser otomatis..." -ForegroundColor Green
Start-Process $prefix

Write-Host ""
Write-Host "-----------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host " STATUS REALTIME: " -ForegroundColor White -NoNewline
Write-Host "TERHUBUNG KE https://app.sig.id" -ForegroundColor Green
Write-Host " Conveyor Terpantau: 01, 02, 03, 04, 05 (Zak) & 90, 91, 92 (Curah)" -ForegroundColor Gray
Write-Host " Auto-refresh: Aktif (Diperbarui berkala setiap 15-30 detik)" -ForegroundColor Gray
Write-Host " Deteksi Otomatis: Truk keluar plant langsung masuk ke Realisasi" -ForegroundColor Magenta
Write-Host "-----------------------------------------------------------------------" -ForegroundColor DarkGray
Write-Host ""
Write-Host "Petunjuk:" -ForegroundColor Cyan
Write-Host " - Biarkan jendela ini TETAP TERBUKA selama Anda memantau dashboard." -ForegroundColor White
Write-Host " - Untuk menghentikan server: Tutup jendela ini atau tekan Ctrl+C." -ForegroundColor Gray
Write-Host ""

$global:prevInLoad = @{}

while ($listener.IsListening) {
    try {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response

        # Header CORS universal
        $response.Headers.Add("Access-Control-Allow-Origin", "*")
        $response.Headers.Add("Access-Control-Allow-Methods", "GET, POST, OPTIONS")
        $response.Headers.Add("Access-Control-Allow-Headers", "*")

        if ($request.HttpMethod -eq "OPTIONS") {
            $response.StatusCode = 200
            $response.Close()
            continue
        }

        $path = $request.Url.AbsolutePath

        if ($path -eq "/api/sig" -or $path -eq "/api/sig/") {
            try {
                $sr = New-Object System.IO.StreamReader($request.InputStream, [System.Text.Encoding]::UTF8)
                $body = $sr.ReadToEnd()
                if ([string]::IsNullOrWhiteSpace($body)) {
                    $body = "comp=5000&plant=5401"
                }

                $wc = New-Object System.Net.WebClient
                $wc.Headers.Add("Content-Type", "application/x-www-form-urlencoded; charset=UTF-8")
                $wc.Headers.Add("X-Requested-With", "XMLHttpRequest")
                $targetUrl = "https://app.sig.id/sgg/sd/intransit/index.php/dashboard/get_data_all"
                $sigBytes = $wc.UploadData($targetUrl, "POST", [System.Text.Encoding]::UTF8.GetBytes($body))

                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 200
                $response.ContentLength64 = $sigBytes.Length
                $response.OutputStream.Write($sigBytes, 0, $sigBytes.Length)
                
                $timeNow = (Get-Date).ToString("HH:mm:ss")
                Write-Host "[$timeNow] Sinkronisasi SIG Realtime berhasil ($($sigBytes.Length) bytes)" -ForegroundColor Green

                # Deteksi truk keluar untuk log konsol
                try {
                    $jsonStr = [System.Text.Encoding]::UTF8.GetString($sigBytes)
                    $dataObj = ConvertFrom-Json $jsonStr
                    $currentInLoad = @{}
                    if ($dataObj.in_load) {
                        foreach ($t in $dataObj.in_load) {
                            $pl = "$($t.NO_POLISI)".Trim().ToUpper()
                            if ($pl) { $currentInLoad[$pl] = $t }
                        }
                    }
                    if ($global:prevInLoad -and $global:prevInLoad.Count -gt 0) {
                        foreach ($oldPl in $global:prevInLoad.Keys) {
                            if (-not $currentInLoad.ContainsKey($oldPl)) {
                                $oldT = $global:prevInLoad[$oldPl]
                                Write-Host "[$timeNow] [TRUK KELUAR] Plat $oldPl ($($oldT.NAMA_SOPIR) - $($oldT.KWANTUMX) ton ke $($oldT.KOTA)) -> Masuk ke Realisasi!" -ForegroundColor Magenta
                            }
                        }
                    }
                    $global:prevInLoad = $currentInLoad
                } catch {}
            } catch {
                $errMsg = $_.Exception.Message
                $errJson = "{`"error`": `"$($errMsg.Replace('"', '`"'))`"}"
                $errBytes = [System.Text.Encoding]::UTF8.GetBytes($errJson)
                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 502
                $response.OutputStream.Write($errBytes, 0, $errBytes.Length)
                
                $timeNow = (Get-Date).ToString("HH:mm:ss")
                Write-Host "[$timeNow] Gagal mengambil data dari SIG: $errMsg" -ForegroundColor Red
            }
        } elseif ($path -eq "/data/realtime.json") {
            # Layani snapshot realtime.json jika diminta
            $dataPath = Join-Path $currentDir "data\realtime.json"
            if (Test-Path $dataPath) {
                $bytes = [System.IO.File]::ReadAllBytes($dataPath)
                $response.ContentType = "application/json; charset=utf-8"
                $response.StatusCode = 200
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $response.StatusCode = 404
                $msg = [System.Text.Encoding]::UTF8.GetBytes('{"error": "data not found"}')
                $response.OutputStream.Write($msg, 0, $msg.Length)
            }
        } else {
            # Layani file HTML dashboard
            if (Test-Path $htmlPath) {
                $bytes = [System.IO.File]::ReadAllBytes($htmlPath)
                $response.ContentType = "text/html; charset=utf-8"
                $response.StatusCode = 200
                $response.ContentLength64 = $bytes.Length
                $response.OutputStream.Write($bytes, 0, $bytes.Length)
            } else {
                $msg = [System.Text.Encoding]::UTF8.GetBytes("File $htmlName tidak ditemukan di folder yang sama.")
                $response.StatusCode = 404
                $response.OutputStream.Write($msg, 0, $msg.Length)
            }
        }

        $response.Close()
    } catch {
        if (-not $listener.IsListening) { break }
    }
}
