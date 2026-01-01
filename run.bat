@echo off
chcp 65001
title پلتفرم ترید فیوچرز

echo ========================================
echo     پلتفرم ترید فیوچرز - نسخه شبیهسازی
echo ========================================
echo.

if not exist "index.html" (
    echo ❌ خطا: فایل index.html پیدا نشد!
    pause
    exit /b 1
)

echo ✅ فایل index.html موجود است
echo.
echo 🔗 آدرس: http://localhost:8080
echo 💰 موجودی: 260.00 دلار
echo 📈 پوزیشن: BTC/USDT لانگ
echo ⏰ تایمر: 8 ساعت
echo.
echo ========================================
echo.

start http://localhost:8080

powershell -ExecutionPolicy Bypass -File "server.ps1"

pause
