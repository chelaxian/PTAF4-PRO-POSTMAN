# PTAF4-PRO-POSTMAN
Postman коллекция для проверки модулей защиты PTAF по основным атакам из OWASP Top 10, а так же для получения токенов, различных идентификаторов тенантов, политик, правил и действий через API PT AF Pro.

Приветствуются предложения по улучшению/расширению коллекции через `pull request` или в `issues`.

## Предварительная настройка [скриптов с тестовыми атаками](https://github.com/chelaxian/PTAF4-PRO-POSTMAN/tree/main/Test_attacks)
Перед выполнением тестовых атак, откройте в текстовом редакторе скрипты (или [коллекцию](https://github.com/chelaxian/PTAF4-PRO-POSTMAN/blob/main/Test_attacks/waf_attacks_postman_collection.json) в Postman) и замените в них значение строки `BASE_URL` в начале файла
```
# Конфигурация - укажите здесь целевой сайт
BASE_URL="https://msproject.site.net/console"
```
вместо `https://msproject.site.net/console` укажите реальное DNS-имя веб-приложения, находящегося за PTAF, для его проверки тестовыми атаками 

## Запуск скриптов

- [`waf_attacks_curl_linux.sh`](https://github.com/chelaxian/PTAF4-PRO-POSTMAN/blob/main/Test_attacks/waf_attacks_curl_linux.sh) - запускается в bash терминале linux
- [`waf_attacks_curl_windows.bat`](https://github.com/chelaxian/PTAF4-PRO-POSTMAN/blob/main/Test_attacks/waf_attacks_curl_windows.bat) - запускается в CMD консоли windows
- [`waf_attacks_powershell.ps1`](https://github.com/chelaxian/PTAF4-PRO-POSTMAN/blob/main/Test_attacks/waf_attacks_powershell.ps1) - запускается в Powershell уонсоли windows

- [`waf_attacks_postman_collection.json`](https://github.com/chelaxian/PTAF4-PRO-POSTMAN/blob/main/Test_attacks/waf_attacks_postman_collection.json) - запускается в Postman (инструкции по настройке ниже)

## Предварительная настройка POSTMAN
На вкладке `Settings` в разделе `General` отключить все что связано с проверкой `SSL` и везде выставить режим `Auto` \
<img width="617" alt="image" src="https://github.com/user-attachments/assets/fef1e7ef-a15a-4fd5-a064-9188474d2826" /> \
Отключить там же все Заголовки `Headers` вставляемые Postman по умолчанию \
<img width="606" alt="image" src="https://github.com/user-attachments/assets/7fe5a58b-f2f9-4456-86d8-11731c2cbbe8" /> 

Импортировать [все коллекции](https://github.com/chelaxian/PTAF4-PRO-POSTMAN/tree/main/Collections) в раздел `Collections` \
Импортировать [все переменные](https://github.com/chelaxian/PTAF4-PRO-POSTMAN/tree/main/Environments) в раздел `Environments` \
В правом верхнем углу выбрать `TOKENS` \
<img width="256" alt="image" src="https://github.com/user-attachments/assets/ef757ca0-b2dd-4990-8bca-e3bf139d1a7f" /> \
В настройках каждой коллекции отключить тумблеры всех опций и везде выставить `Auto` \
![image](https://github.com/user-attachments/assets/4d6f822a-8f17-47ec-9ba5-126e24ce00f7)


---

## Авторизация и запуск

В разделе `Environments` на вкладке `Globals` заполнить поля: 
- `{{base_url}}` # схема + MGMT IP PTAF без косой черты / на конце ( `https://10.10.10.10` )
- `{{username}}` # по-умолчанию `admin`
- `{{password}}` # пароль от веб-интерфейса управления
  
Остальные разделы либо заполнятся автоматически, либо нужно будет заполнять по мере необходимости.

<img width="1175" alt="image" src="https://github.com/user-attachments/assets/ec04c67a-7fcb-44a2-ab04-fd8ef167b791" />

Раздел `TOKENS` заполнять не нужно, но из него для некоторых POST-запросов нужно будет выбирать необходимые `ID` из полей: 
- `{{tenant-X_id}}` # здесь появится список `ID` всех тенантов после выполнения запросов коллекции `Get IDs` - `Get tenant IDs`
- `{{all_policy_id}}` # здесь появится список `ID` всех политик после выполнения запросов коллекции `Get IDs` - `Get policy IDs`
- `{{all_rules_id}}` # здесь появится список `ID` всех правил после выполнения запросов коллекции `Get IDs` - `Get rules IDs`
- `{{all_action_id}}` # здесь появится список `ID` всех действий после выполнения запросов коллекции `Get IDs` - `Get action IDs`
  
<img width="884" alt="image" src="https://github.com/user-attachments/assets/768bfcc1-a37c-43ff-bd78-66b60db21985" />

Открыть в левом нижнем углу консоль `Console` для получения информации о результатах выполнения запросов. \
Выбрать запрос в коллекции и нажать кнопку `Send` (сначала нужно получить токены выполнив запрос `Get main token` в коллекции `Authorization`)

---

## Скриншоты результатов выполнения запросов
![Без имени](https://github.com/user-attachments/assets/5bfcb74c-1cf7-4e5a-aa4b-92fc7d72ecfd) \
![image](https://github.com/user-attachments/assets/d30f47e8-4acc-494d-bd7b-6b6f44ff36cc) \
<img width="1040" alt="image" src="https://github.com/user-attachments/assets/b26dd51d-528f-470d-ab82-75bea765799a" /> \
<img width="323" alt="image" src="https://github.com/user-attachments/assets/51230909-fe8c-4f9d-9da6-9ea55eeb2d92" />

## Скриншоты результатов выполнения скриптов 
<img width="531" alt="image" src="https://github.com/user-attachments/assets/12fec465-bf42-45e1-843e-db5dd6abac5c" /> \
<img width="478" alt="image" src="https://github.com/user-attachments/assets/5292cc2c-b41b-4709-89a6-4e972e814c99" /> \
<img width="436" alt="image" src="https://github.com/user-attachments/assets/f5c631a9-c8d2-47c6-9a8a-276542507a76" />

