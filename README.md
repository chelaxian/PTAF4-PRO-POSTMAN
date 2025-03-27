# PTAF4-PRO-POSTMAN
ptaf 4 pro postman collection 

## Предварительная настройка POSTMAN
На вкладке `Settings` в разделе `General` отключить все что связано с проверкой `SSL` и везде выставить режим `Auto` \
<img width="617" alt="image" src="https://github.com/user-attachments/assets/fef1e7ef-a15a-4fd5-a064-9188474d2826" /> \
Отключить там же все Заголовки `Headers` вставляемые Postman по умолчанию \
<img width="606" alt="image" src="https://github.com/user-attachments/assets/7fe5a58b-f2f9-4456-86d8-11731c2cbbe8" /> 

Импортировать все коллекции в раздел `Collections` \
Импортировать все переменные в раздел `Environments` \
В правом верхнем углу выбрать `TOKENS` \
<img width="256" alt="image" src="https://github.com/user-attachments/assets/ef757ca0-b2dd-4990-8bca-e3bf139d1a7f" /> \
В настройках каждой коллекции отключить тумблеры всех опций и везде выставить `Auto` \
<img width="1280" alt="image" src="https://github.com/user-attachments/assets/97303bf8-7ebb-4bd8-9cc2-67a5b6554a1c" />

## Авторизация и запуск

В разделе `Environments` на вкладке `Globals` заполнить поля: 
- `{{base_url}}` # схема + IP без косой черты / на конце ( `https://10.10.10.10` )
- `{{username}}`
- `{{password}}`
  
Остальные разделы либо заполнятся автоматически, либо нужно будет заполнять по мере необходимости.

Раздел `TOKENS` заполнять не нужно, но из него для некоторых POST-запросов нужно будет выбирать необходимые `ID` из полей: 
- `{{tenant-X_id}}` # здесь появится список `ID` всех тенантов после выполнения запросов коллекции `Get IDs` - `Get tenant IDs`
- `{{all_policy_id}}` # здесь появится список `ID` всех политик после выполнения запросов коллекции `Get IDs` - `Get policy IDs`
- `{{all_rules_id}}` # здесь появится список `ID` всех правил после выполнения запросов коллекции `Get IDs` - `Get rules IDs`
- `{{all_action_id}}` # здесь появится список `ID` всех действий после выполнения запросов коллекции `Get IDs` - `Get action IDs`

Открыть в левом нижнем углу консоль `Console` для получения информации о результатах выполнения запросов. \
Выбрать запрос в коллекции и нажать кнопку `Send` (сначала нужно получить токены выполнив запрос `Get main token` в коллекции `Authorization`)

---

## Скриншоты результатов выполнения скриптов / запросов
<img width="1067" alt="image" src="https://github.com/user-attachments/assets/6bf60743-90ef-413f-98a4-de490b2fec71" /> \
<img width="1070" alt="image" src="https://github.com/user-attachments/assets/3f4adc3e-038a-4632-befd-74e5ed926361" /> \
<img width="1040" alt="image" src="https://github.com/user-attachments/assets/b26dd51d-528f-470d-ab82-75bea765799a" /> \
<img width="323" alt="image" src="https://github.com/user-attachments/assets/51230909-fe8c-4f9d-9da6-9ea55eeb2d92" /> \
<img width="531" alt="image" src="https://github.com/user-attachments/assets/12fec465-bf42-45e1-843e-db5dd6abac5c" /> \
<img width="478" alt="image" src="https://github.com/user-attachments/assets/5292cc2c-b41b-4709-89a6-4e972e814c99" /> \
<img width="436" alt="image" src="https://github.com/user-attachments/assets/f5c631a9-c8d2-47c6-9a8a-276542507a76" />

