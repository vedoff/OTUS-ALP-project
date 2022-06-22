# odoo-project
## Развертывание инфраструктуры для обеспечения проекта odoo
### В проекте реализовано
  1. Первоначалное развертывание проекта [Odoo (бывшая Tiny ERP, OpenERP) — ERP- и CRM-система, разрабатываемая бельгийской компанией Odoo S. A. Распространяется по лицензии LGPL](https://ru.wikipedia.org/wiki/Odoo)
  2. База данных `Postgresql`. База имее реплику в виде отдельного сервера. Репликация `async` (можно изменить на `sync`)
  3. Установлен `Barman`. Отливка базы осуществляется с мастера. Можно доработать изменить. Быстрое восстановление.
  4. Реализован файловый бекап проекта odoo на отдельный сервер средствами `Borg backup`. 
  5. Реализован сервер мониторинга `Zabbix`
  6. Реализован лог коллектор
  7. Фронтом выступает "Bastion", на котором реализована защита средствами netfilter (iptebles). 
  8. На фронте развернут `haproxy` - устанавливает защищенное соединение`SSL` и редирект на `nginx`
  9. На фронте установлен `nginx`, который проксирует соединения на `odoo`. (Вообщето nginx нужно перенести на отдельный сервер, а лучше реализовать vrrp  keepalived - еще не успел)
# Схема проекта
![](https://github.com/vedoff/odoo-project/blob/main/pict/Screenshot%20from%202022-06-20%2013-35-04.png)
### Требуется для развертывания
Требуется создать ssh ключ на машине которая которая будет осуществлять развертывание, 
публичную часть ключа добавить в \
`provizion/vagrant-key.pub` \
А так же скопировать его в роль \
`create-user-db-to-postgresql/files/authorized_key` \
Это требуется для того, что осуществлять действия под пользователем `posrgres` 
### Разворачиваем виртуалки
`vagrant up`
## 1. Устанавливаем базу данных
ansible-playbook install-postgres.yml
ansible-playbook create-user-db-to-postgresql.yml -t replica
ansible-playbook create-pg_replication_slot-slave.yml
### Копируем ключи
Под пользователем postgres на нодах

`postgres pass = 1qaz2wsx`

`ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@192.168.56.52`

`ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@192.168.56.51`
### === Добавляем пользователей в базу
`ansible-playbook create-user-db-to-postgresql.yml`
## 2. Устанваливаем odoo

`ansible-playbook install-odoo.yml`

база для odoo создается после установки, в postgresql ее создавать руками не нужно.

В браузере: 

`192.168.56.50:8096`

Откроется мастер создания базы, заполняем, на выходе получим приглащение в приложение.
### Пример:
`мастер пароль: wjiv-z9ew-wzsf` \
`user: testuser@gmail.com` \
`pass : 123456` 
### 3. Устанавливаем backup
`ansible-playbook install-borg-server.yml && ansible-playbook install-borg-client.yml`

Связываем сервер и клиент ssh подключением по ключу

`borg pass = 123456` \
`ssh-copy-id -i id_rsa.pub borg@192.168.56.55`
## === Инициализируем репозиторий
`borg init --encryption=repokey borg@192.168.56.55:/var/Backuprepo/backup/` \
вводим пароль для бекапов кторый также добавлен в сервис systemd borg-backu.service
### === Создаем бекап
Стартуем сервис, тем самым проверяя что он работает

`systemctl start borg-backup`

Или создаем в ручную

`borg create --stats --list borg@192.168.56.55:/var/Backuprepo/backup/::"oddo-{now:%Y-%m-%d_%H:%M:%S}" /var/lib/odoo`

Проверяем

`borg list borg@192.168.56.55:/var/Backuprepo/backup/`

`systemctl list-timers --all`

============ Восстановление из бекапа
Переходим в корень системы

`cd /`

запускаем скрипт который был скопирован ранее при развертывании
После запуска скрипт выдаст список бекапов, копируем требуемое время, вставляем в поле, продолжаем, вводя пароли на бекап (123456)

`sh /root/backup_restore.sh`
## 4. Разворачиваем Barman 
`ansible-playbook install-barman.yml`
### === Копируем ключ на сервер postgresql
`su - barman` \
`postgres pass = 1qaz2wsx` \
`ssh-copy-id -i ~/.ssh/id_rsa.pub postgres@192.168.56.51`
### === Копируем ключ на сервер barman
`su - postgres` \
`barman pass = 1qaz2wsx` \
`ssh-copy-id -i ~/.ssh/id_rsa.pub barman@192.168.56.58`
### =============== Инициализируем соединение и проверяем
`su - barman` \
`barman check pgnode-m` \
`barman switch-wal --archive pgnode-m`
### === Не обязательно
`barman receive-wal pgnode-m`
### ================== Вывод всей конфигурации ===============
barman diagnose
### ================ Создание бекапа
`barman backup pgnode-m`
### =============== Восстановление из беапа последней сделаной копии

1. Заходим на сервер postgresql
2. Останавливаем службу postgresql или тот инстанс который был испорчен если он сам не остановился.

### ======= Пример:

### === Проверяем запущен не запущен
`pg_lsclusters`
### Останавливаем кластер если потребуется
`pg_ctlcluster 13 main stop`
### === Восстанавливаем из бекапа последний сделаный бекап
На сервере Barman \
`barman list-backup pgnode-m`

`barman recover --remote-ssh-command "ssh postgres@192.168.56.51" pgnode-m latest /var/lib/postgresql/13/main`

===!!! Пример: Восстановление на конкретную дату !!!===

barman recover \
  --target-time "2022-06-21 13:32:28.568809+00:00" \ \
  --remote-ssh-command "ssh postgres@192.168.56.51" \ \
  pgnode-m 20220621T133150 /var/lib/postgresql/13/main
### === Переходим на сервер postgresql и запускаем инстанс
`su - postgres` \
`pg_ctlcluster 13 main restart`

После этого кластер и бызы должы быть воссановлены.
Проверяем приложение
F5 в браузере на сранице приложения.
## 5. Настраиваем мониторинг Zabbix 
1. ansible-playbook install-zabbix-server.yml && ansible-playbook install-zabbix-agent.yml

`192.168.56.57/zabbix`

Если база не инициализируется то можно инициализировать отдельно

`zabbix pass = 1qaz2wsx`
### === Инициализация базы в ручную если потребуется
`zcat /usr/share/doc/zabbix-server-pgsql/create.sql.gz | psql -h 192.168.56.51 zabbix zabbix`

Пререзапускаем службы

`systemctl restart zabbix-server` \
`systemctl restart apache2`
## 6. Устанавливаем log server logrotate
Сконфигурируем сбор логов \
`ansible-playbook configure-rsyslog.yml`
## 7. Настройка bastion
`ansible-playbook configure-bastion.yml`

После конфигурации bastion проект odoo будет доступен по адресу 
`192.168.56.254`

## 8. Настройка haproxy
### === Заранее подготовливаем сертификаты
#### Ключи уже находятся в конфигурацилнных файлах роли. 
Создаем ключи \
`sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/odoo-key.key -out /etc/ssl/certs/odoo-cert.crt`

Обьединяем ключи в pem \
`cat odoo-key.key odoo-cert.crt >> odoo.pem` 

Настрока selinux для bastion haproxy включена в отдельную роль role/selinux

# После развертывания получим
### Zabbix допилин за кадром
   1. Добавлено оповещение в telegram
   2. Создана карта проекта в самом zabbix
 ## Odoo  
![](https://github.com/vedoff/odoo-project/blob/main/pict/Screenshot%20from%202022-06-20%2013-40-25.png)
## Zabbix
![](https://github.com/vedoff/odoo-project/blob/main/pict/Screenshot%20from%202022-06-20%2013-43-46.png)

