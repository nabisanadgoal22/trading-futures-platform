# سرور ساده HTTP با PowerShell
param([int]$Port = 8080)

Write-Host "========================================" -ForegroundColor Cyan
Write-Host "     پلتفرم ترید فیوچرز - نسخه شبیهسازی     " -ForegroundColor Yellow
Write-Host "========================================" -ForegroundColor Cyan
Write-Host ""

# تنظیمات
$rootPath = $PWD.Path
$indexFile = Join-Path $rootPath "index.html"

if (-not (Test-Path $indexFile)) {
    Write-Host "❌ خطا: فایل index.html پیدا نشد!" -ForegroundColor Red
    exit 1
}

# آدرسهای IP
$ipAddresses = @("127.0.0.1", "localhost")
try {
    $localIP = (Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.InterfaceAlias -notlike "*Loopback*"}).IPAddress | Select-Object -First 1
    if ($localIP) { $ipAddresses += $localIP }
} catch { }

# ساخت لیستنر HTTP
$listener = New-Object System.Net.HttpListener

foreach ($ip in $ipAddresses) {
    $listener.Prefixes.Add("http://$ip`:$Port/")
}

# باز کردن فایروال (اگر Administrator هستی)
try {
    New-NetFirewallRule -DisplayName "TradingPlatform-$Port" -Direction Inbound -Protocol TCP -LocalPort $Port -Action Allow -ErrorAction SilentlyContinue
    Write-Host "✓ فایروال تنظیم شد" -ForegroundColor Green
} catch {
    Write-Host "⚠ اجرا به عنوان Administrator برای دسترسی شبکه نیاز است" -ForegroundColor Yellow
}

# شروع سرور
$listener.Start()
Write-Host "✅ سرور فعال شد" -ForegroundColor Green
Write-Host ""

Write-Host "🔗 آدرسهای دسترسی:" -ForegroundColor Cyan
foreach ($prefix in $listener.Prefixes) {
    Write-Host "    $prefix" -ForegroundColor White
}
Write-Host ""

Write-Host "📊 مشخصات حساب:" -ForegroundColor Green
Write-Host "   موجودی اولیه: 260.00 دلار" -ForegroundColor White
Write-Host "   پوزیشن فعلی: BTC/USDT لانگ" -ForegroundColor White
Write-Host "   سود/ضرر لحظهای: فعال" -ForegroundColor White
Write-Host "   تایمر: 8 ساعت" -ForegroundColor White
Write-Host ""

Write-Host "🚀 در حال باز کردن مرورگر..." -ForegroundColor Yellow
Start-Process "http://localhost:$Port"

Write-Host "⏰ برای توقف سرور: Ctrl+C" -ForegroundColor Gray
Write-Host "========================================" -ForegroundColor Cyan

try {
    # حلقه اصلی سرور
    while ($listener.IsListening) {
        $context = $listener.GetContext()
        $request = $context.Request
        $response = $context.Response
        
        # مسیر فایل درخواستی
        $requestPath = $request.Url.LocalPath
        if ($requestPath -eq "/") { $requestPath = "/index.html" }
        
        $filePath = Join-Path $rootPath $requestPath.TrimStart('/')
        
        if (Test-Path $filePath -PathType Leaf) {
            # خواندن فایل
            $content = [System.IO.File]::ReadAllBytes($filePath)
            
            # تعیین Content-Type
            $ext = [System.IO.Path]::GetExtension($filePath).ToLower()
            $contentType = @{
                '.html' = 'text/html; charset=utf-8'
                '.css'  = 'text/css; charset=utf-8'
                '.js'   = 'application/javascript; charset=utf-8'
                '.json' = 'application/json; charset=utf-8'
                '.ico'  = 'image/x-icon'
                '.png'  = 'image/png'
                '.jpg'  = 'image/jpeg'
                '.jpeg' = 'image/jpeg'
                '.svg'  = 'image/svg+xml'
            }
            
            $response.ContentType = $contentType[$ext] ?? 'application/octet-stream'
            $response.ContentLength64 = $content.Length
            $response.OutputStream.Write($content, 0, $content.Length)
        } else {
            # 404 - فایل پیدا نشد
            $notFoundHtml = [System.Text.Encoding]::UTF8.GetBytes(@"
<!DOCTYPE html>
<html>
<head><title>404</title><style>body{font-family:Tahoma;text-align:center;padding:50px;}</style></head>
<body><h1>404 - صفحه پیدا نشد</h1><a href="/">بازگشت به صفحه اصلی</a></body>
</html>
"@)
            
            $response.StatusCode = 404
            $response.ContentType = 'text/html; charset=utf-8'
            $response.ContentLength64 = $notFoundHtml.Length
            $response.OutputStream.Write($notFoundHtml, 0, $notFoundHtml.Length)
        }
        
        $response.Close()
        
        # لاگ درخواست
        $logTime = Get-Date -Format "HH:mm:ss"
        Write-Host "[$logTime] $($request.RemoteEndPoint.Address) - $($request.HttpMethod) $requestPath" -ForegroundColor DarkGray
    }
} finally {
    $listener.Stop()
    Write-Host "`nسرور متوقف شد." -ForegroundColor Yellow
}
