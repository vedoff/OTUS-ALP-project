# odoo-project
## Развертывание инфраструктуры для обеспечения проекта odoo
# Схема проекта
![](https://github.com/vedoff/odoo-project/blob/main/pict/Screenshot%20from%202022-06-20%2013-35-04.png)
### Разворачиваем виртуалки
`vagrant up`
# 1. Устанавливаем базу данных

`ansible-playbook install-postgres.yml -t install`

### === Задаем пароль на пользователя postgres

`ansible-playbook install-postgres.yml -t addpass`

### ====== Создаем реплику базы на другом сервере

`ansible-playbook create-user-db-to-postgresql.yml -t replica`

`ansible-playbook install-postgres.yml -t slave -t pgpass`

`ansible-playbook install-postgres.yml -t slave -t config`

`ansible-playbook install-postgres.yml -t slave -t main`

`ansible-playbook add-ssh-key-to-postgresuser.yml -t key`

`ansible-playbook create-pg_replication_slot-slave.yml`

## Добавляем пользователей в кластер postgresql и создаем базы

`ansible-playbook create-user-db-to-postgresql.yml -t odoo`

`ansible-playbook create-user-db-to-postgresql.yml -t zabbix`

`ansible-playbook create-user-db-to-postgresql.yml -t barman`

# 2. Устанваливаем odoo

`ansible-playbook install-odoo.yml`

База для odoo создается после установки, в postgresql ее создавать руками не нужно.

В браузере: 

`192.168.56.50:8096`

Откроется мастер создания базы, заполняем, на выходе получим приглащение в приложение.

# 3. Устанавливаем backup

`ansible-playbook install-borg-server.yml`

`ansible-playbook install-borg-client.yml`

Связываем сервер и клиент ssh подключением по ключу

`borg pass = 123456`

`ssh vagrant@192.168.56.55`

на клиенте

`cd /root` \
`ssh-keygen` \
`cd .ssh/`

--------------------------------------------- Передать ключ без ввода пароля (нужно тестить)---------------------------
`- name: Register ssh key at serverB` \
  `command: ssh-copy-id -i /home/{{user}}/.ssh/id_rsa.pub -o StrictHostKeyChecking=no user@serverB`

-----------------------------------------------------------------------------------------------------------------------
 
`ssh-copy-id -i id_rsa.pub -o StrictHostKeyChecking=no borg@192.168.56.55`

### === Инициализируем репозиторий
`borg init --encryption=repokey borg@192.168.56.55:/var/Backuprepo/backup/`

вводим пароль для бекапов кторый также добавлен в сервис systemd borg-backu.service

`borg create --stats --list borg@192.168.56.55:/var/Backuprepo/backup/::"oddo-{now:%Y-%m-%d_%H:%M:%S}" /var/lib/odoo`

`borg list borg@192.168.56.55:/var/Backuprepo/backup/`

`systemctl list-timers --all`

### ============ Восстановление из бекапа 
Переходим в корень системы

`cd /`

запускаем скрипт который был скопирован ранее при развертывании \
После запуска скрипт выдаст список бекапов, копируем требуемое время, вставляем в поле, продолжаем, вводя пароли на бекап (123456)

`sh /root/backup_restore.sh`


# 4. Устанавливаем log server logrotate

Сконфигурируем сбор логов

`ansible-playbook configure-rsyslog.yml -t server`

`ansible-playbook configure-rsyslog.yml -t client`

# 5. Настраиваем мониторинг Zabbix 

------------------------------------------------------------------------------------------
1. `ansible-playbook install-zabbix-server.yml -t install`

2. `ansible-playbook add-ssh-key-to-postgresuser.yml -t key`

3. `ansible-playbook create-user-db-to-postgresql.yml -t zabbix`

### === На сервере zabbix  инициализируем базу

4. `ansible-playbook install-zabbix-server.yml -t pgpass`

5. `ansible-playbook install-zabbix-server.yml -t initbase`

6. `ansible-playbook install-zabbix-server.yml -t reconfig`

В браузере подключаемся к серверу мониторинга, проходим мастер инициализации.
`192.168.56.57/zabbix`

=== Инициализация базы в ручную если потребуется
`zcat /usr/share/doc/zabbix-server-pgsql/create.sql.gz | psql -h 192.168.56.51 zabbix zabbix`

### ====== Устанавливаем zabbix-agent

`ansible-playbook install-zabbix-agent.yml`

# 6. Разворачиваем Barman 

### === 1. Устанавливаем требуемые пакеты

`ansible-playbook install-barman.yml -t install`

### === Задаем пароль на пользователя barman

`ansible-playbook install-barman.yml -t addpass`

`password user postgres = 1qaz2wsx`

### === В зашифрованном виде 1qaz2wsx

Для шифрования пароля используется утилита `mkpasswd`

`$6$Mg9iAn8Ski/1h7ER$JA24vpr21UcriXFesc20ugr.tJyhxFRtK8TxtMKftvAYeFRO69mVucGxauP7i6VTialg.eN6jZoLDz9Kkc1QV/`

### === 2. Создаем пользователей и базы в postgresql

`ansible-playbook create-user-db-to-postgresql.yml -t barman`

### ===4. Применяем изменения в конфиге

`ansible-playbook reload-config-postgresql.yml -t reload`

### === Если потребуется 

`ansible-playbook restart-config-postgresql.yml -t restart`

### ===5. Добавление ключей для работы бекапа

### === Правим конфиг ssh на Barman

`ansible-playbook install-barman.yml -t sshd`


### === Создаем ключ ssh в barman

`su - barman`

`ssh-keygen -t rsa -N ''`

### === Копируем ключ на сервер postgresql

`ssh-copy-id -i id_rsa.pub postgres@192.168.56.51`

### === Добавляем pgpass в профиль barman

`ansible-playbook install-barman.yml -t pgpass`

### === Создаем ключ ssh в postgres

`su - postgres`

### === Создаем ключ
`ssh-keygen -t rsa -N ''`

### === Копируем ключ на сервер barman

`ssh-copy-id -i id_rsa.pub postgres@192.168.56.58`


### === Инициализируем соединение и проверяем

`su - barman`

`barman check pgnode-m`

`barman receive-wal pgnode-m`

`barman switch-wal --archive pgnode-m`

### ======= Вывод всей конфигурации 
`barman diagnose`


### ======= Создание бекапа

`barman backup pgnode-m`


## ====== Восстановление из беапа последней сделаной копии

1. Заходим на сервер postgresql
2. Останавливаем службу postgresql или тот инстанс который был испорчен если он сам не остановился.

### ======= Пример:

#### === Проверяем запущен не запущен
`pg_lsclusters`

Останавливаем кластер если потребуется \
`pg_ctlcluster 13 main stop`

## === Восстанавливаем из бекапа последний сделаный бекап
На сервере Barman

`barman recover \` \
`--remote-ssh-command "ssh postgres@192.168.56.51" \` \
`pgnode-m latest /var/lib/postgresql/13/main`

## === Переходим на сервер postgresql и запускаем инстанс

`su - postgres`

`pg_ctlcluster 13 main restart`

После этого кластер и бызы должы быть воссановлены.\
Проверяем приложение \
F5 в браузере на сранице приложения.



# 7. Настройка файервола 

`ansible-playbook configure-bastion.yml -t install`

`ansible-playbook configure-bastion.yml -t configure`


# 8. Настройка haproxy
`ansible-playbook configure-bastion.yml -t haproxy`

Настрока selinux для bastion haproxy включена в отдельную роль role/selinux

### === Заранее подготовливаем сертификаты
Создаем ключи \
`sudo openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/odoo-key.key -out /etc/ssl/certs/odoo-cert.crt`

Обьединяем ключи в pem \
`cat odoo-key.key odoo-cert.crt >> odoo.pem`

# После развертывания получим
### Zabbix допилин за кадром
   1. Добавлено оповещение в telegram
   2. Создана карта проекта в самом zabbix
 ## Odoo  
![](https://github.com/vedoff/odoo-project/blob/main/pict/Screenshot%20from%202022-06-20%2013-40-25.png)
## Zabbix
![](https://github.com/vedoff/odoo-project/blob/main/pict/Screenshot%20from%202022-06-20%2013-43-46.png)

