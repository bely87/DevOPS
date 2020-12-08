galera
=========

Установка и инициализация кластера Galera для rhel7.

Пример
------
bash
запуск без дополнительных тегов и переменных установит и настроит галера кластер (на самом деле, нет, после этой роли необходимо дернуть роль zabbix, keepalived)
ansible-playbook -i inventories/<path to inventory> playbooks/<your playbook>.yml -b -v

для деинсталляции:
-t uninstall -e galera_uninstall=1

для старта кластера:
-t init -e galera_new_cluster=1


Документация non-ansible
------------------------
Условные обозначения
хххх в названии шага:
1000: нода галеры
0100: нода арбитра
0010: нода асинхронного мастера
0001: нода асинхронной реплики

Например, 1100 будет означать, что шаг предназначен для ноды галеры и арбитра и не касается асинхронных мастера и слейва.


### 1. 1111 Определиться с ресурсами:
        RAM: количество оперативной памяти зависит от количества коннектов и загруженности сервера
        CPU: количество оперативной памяти зависит от загруженности сервера. Обычно на каждое ядро не менее 2 GB RAM
        HDD: если размер /var/lib/mysql=100%, то размер БД не должен превышать 60%, размер /var/log/mysql не меньше 50%, /backup/ на бекап ноде не меньше 120%
        Для арбитра создаем vm из шаблона medium (4 GB RAM, 4 CPU)

### 2. 1111 Выделить ip адреса и завести завписи в прямой и обратной зоне dns:
        для работы в VLAN vmnet. паттерн именования хостов: проект-назначение (db/garb/backup).(домены 1-3 уровня)
        для работы в VLAN galeranet если нода участвует в галера кластере. паттерн именования хостов: проект-gc-назначение (db/garb/backup).(домены 1-3 уровня)

### 3.  1111 Установка:
#### 3.1 1111 прописать репозитории mariadb
#### 3.2 1100 прописать репозитории percona
#### 3.3 1111 yum-complete-transaction -y
#### 3.4 1011 установить следующие пакеты из репозиториев mariadb:
        - MariaDB-client-{{ galera_mysql_version }}
        - MariaDB-server-{{ galera_mysql_version }}
        - MariaDB-shared-{{ galera_mysql_version }}
        - MariaDB-common-{{ galera_mysql_version }}
        - MySQL-python
        - policycoreutils-python
        - gzip
#### 3.5 1111 установить следующие пакеты из репозиториев percona:
        - percona-xtrabackup-24{{ percona_xtrabackup_version }}
        - perl-Digest-MD5
#### 3.6 1100 установить следующие пакеты из репозиториев mariadb:
        - socat
        - galera

### 4.  1011 SELinux (включаем)
#### 4.1 1011 restorecon -Rv /var/lib/mysql && restorecon -Rv /var/log/mysql
#### 4.2 1011 semanage permissive -a mysqld_t
#### 4.3 1011 правка контекстов
```semanage fcontext --add -s unconfined_u -t mysqld_db_t '/var/lib/mysql/*'```

### 5.  1011 Конфигурация пользователей
#### 5.1 1011 systemctl start mariadb
#### 5.2 1011 замена рутовых паролей
```mysql -e "set password for 'root'@'localhost' = PASSWORD('Supersecurepa$$here');"
         mysql -e "set password for 'root'@''::1' = PASSWORD('Supersecurepa$$here');"
         mysql -e "set password for 'root'@`127.0.0.1' = PASSWORD('Supersecurepa$$here');"```
#### 5.3 1011 создание .my.cnf файла
```
          cat > /root/.my.cnf <<EOF
          [client]
          user=root
          password='Supersecurepa$$here'
          host=localhost
          EOF

          chmod 0600 /root/.my.cnf
          chown root:root /root/.my.cnf
```
#### 5.4 1000 при свежей установке следующий скрипт должен вернуть 0
```
          grep  -P  '^wsrep_sst_auth' /etc/my.cnf.d/*.cnf | wc -l
          #если вернет что-либо отличное от 0, то необходимо посмотреть, в каких файлах уже есть пользователь для репликации галера
          grep  -P  '^wsrep_sst_auth' /etc/my.cnf.d/*.cnf
```
#### 5.5 1000 создание пользователя для репликации
```
        mysql -e "CREATE USER '{{ galera_sst_user }}'@'localhost' IDENTIFIED BY '{{ galera_sst_pass }}';"         
        mysql -e "GRANT ALL PRIVILIGES on *.* to '{{ galera_sst_user }}'@'localhost';"  
```
#### 5.6 1011 удаление анонимных пользователей
```
        mysql -e "DROP USER ''@'localhost';"
        mysql -e "DROP USER ''@'ip_address_here';"
```
#### 5.7 1011 удаление root пользователей
```
        mysql -e "DROP USER 'root'@'::1';"
        mysql -e "DROP USER 'root'@'ip_address_here';"   
```
#### 5.8 1011 удаление test database
```
        mysql -e "DROP DATABASE test;"
```
#### 5.9 1011 создание пользователей clustercheck, logrotate
```
        mysql -e "CREATE USER 'clustercheck'@'localhost' IDENTIFIED BY 'clustercheckpass';"         
        mysql -e "GRANT PROCESS on *.* to 'clustercheck'@'localhost';"
        mysql -e "CREATE USER 'logrotate'@'localhost' IDENTIFIED BY 'logrotatepass';"         
        mysql -e "GRANT RELOAD on *.* to 'logrotate'@'localhost';"
```
### 6.0 1011 файлы конфигураций
#### 6.1 1011 mariadb.cnf
```
cat > /etc/my.cnf.d/mariadb.cnf <<EOF
[mysqld]
bind-address=0.0.0.0
character_set_server=utf8
collation_server=utf8_general_ci
datadir=/var/lib/mysql/
expire_logs_days={{ mysql_expire_logs_days }} #minimum 2 * интервал создания полного бекапа, обычно >7
general_log_file=/var/log/mysql/mariadb.log
gtid_domain_id=1
gtid_ignore_duplicates=1
gtid_strict_mode=1
init_connect='SET NAMES utf8'
key_buffer_size=20M
lc_messages=en_US
log_bin_index=/var/log/mysql/mariadb-bin.index
log_bin_trust_function_creators=1
log_bin=/var/log/mysql/mariadb-bin
log_slave_updates=1
log_slow_rate_limit=1
log_slow_verbosity=query_plan
log_warnings=2
long_query_time=0.5
max_allowed_packet=10M
max_binlog_size=100M
max_connections=1000 #определяется по формуле: округлить в меньшую сторону (общее количество RAM в MB/2)/(3 MB)
open_files_limit=65536
server-id={{ galera_server_id }}
skip-name-resolve
slow_query_log_file=/var/log/mysql/mariadb-slow.log
slow_query_log=1
sync_binlog=1
table-open-cache=10000


transaction-isolation=REPEATABLE-READ #Default value.
#tag6.8   or redmine#4863
table_open_cache=16384
table_definition_cache=16384

#From OETS
slave-net-timeout=21600

relay-log={{ mysql_directories.1 }}/mysql-relay-bin.log
bulk_insert_buffer_size=256M  # early was 8388608
innodb_log_buffer_size=8M     # early was 1048576
innodb_log_file_size=128M     # early was 5242880
innodb_thread_concurrency=0  # early was 8
thread_cache_size=32          # early was 16
thread_stack=256K             # early was 196608

[mariadb]
binlog_format=row
default_storage_engine=InnoDB
innodb_autoinc_lock_mode=2
innodb_buffer_pool_size={{ innodb_buffer_pool_size }}  #определяется по формуле: округлить в меньшую сторону, цифра должна делиться на 128 MB (общее количество RAM в MB/2)
innodb_file_per_table=1
innodb_flush_log_at_trx_commit=1
innodb_flush_method=O_DIRECT
max_prepared_stmt_count=65536
innodb_print_all_deadlocks=1
EOF
```
#### 6.2 1000 galera.cnf
```
cat > /etc/my.cnf.d/galera.cnf <<EOF
wsrep_cluster_address="gcomm:// здесь ip адреса всех= нод галера включая арбитр"
wsrep_cluster_name={{ galera_wsrep_cluster_name }}
wsrep_gtid_domain_id=5
wsrep_gtid_mode=1
wsrep_node_address={{ cluster_ip }}:{{ galera_wsrep_cluster_port }}
wsrep_node_name="{{ имя ноды }}"
wsrep_on=ON
wsrep_provider_options="gmcast.listen_addr=tcp://0.0.0.0:{{ galera_wsrep_cluster_port }};gcache.size=1G;gcache.recover=yes"
wsrep_provider=/usr/lib64/galera/libgalera_smm.so
wsrep_slave_threads=1
wsrep_sst_auth="{{ galera_sst_user }}:{{ galera_sst_pass }}"
wsrep_sst_method=xtrabackup-v2
wsrep_sst_donor="имена нод начиная с последней через запятую кроме первой"
EOF
```
### 7.  1111 Конфигурация системы
#### 7.1 1111 конфигурация firewalld
        - "firewall-cmd --new-service=galera --permanent"
        - "firewall-cmd --service=galera --add-port=3306/tcp --add-port={{galera_wsrep_cluster_port}}/udp --add-port={{galera_wsrep_cluster_port}}/tcp --add-port=4444/tcp --permanent"
        - "firewall-cmd --new-zone=galeranet --permanent"
        - "firewall-cmd --zone=galeranet --add-source=10.200.83.0/24 --permanent"
        - "firewall-cmd --zone=galeranet --add-service=mysql --add-service=galera --permanent"
        - "firewall-cmd --reload"
#### 7.2 1011 редактировние лимитов
```
cat > /etc/systemd/system/mariadb.service.d/limits.conf <<EOF
[Service]
LimitNOFILE=infinity
LimitMEMLOCK=infinity
EOF
```
#### 7.3 1011 конфигурация swappiness
        в /etc/sysctl.d/swappiness.conf пропишем
```
        vm.swappiness = 1
        sysctl vm.swappiness=1
```
#### 7.4 1011 отключение автозапуска mariadb
```
         chkconfig mysql off
         systemctl disable mariadb
```
#### 7.5 1000 Если установилась версия mariadb 10.2.13, рекомендуется ее переустановить с версии 10.2.14+

#### 7.6 0100 копируем бинарный файл garb
```
          cp /usr/bin/garb-systemd /usr/bin/garb-{{ galera_wsrep_cluster_name }}-systemd
```
#### 7.7 0100 создаем сервис арбитра
```
cat > /etc/systemd/system/garbd_{{ galera_wsrep_cluster_name }}.service <<EOF
#Systemd service file for garbd_{{ galera_wsrep_cluster_name }}

[Unit]
Description=Galera Arbitrator Daemon
After=network.target syslog.target

[Install]
WantedBy=multi-user.target
Alias=garbd_{{ galera_wsrep_cluster_name }}.service

[Service]
User=nobody
EnvironmentFile=/etc/sysconfig/garb_{{ galera_wsrep_cluster_name }}
ExecStart=/usr/bin/garb-{{ galera_wsrep_cluster_name }}-systemd start

#Use SIGINT because with the default SIGTERM
#garbd fails to reliably transition to 'destroyed' state
KillSignal=SIGINT

TimeoutSec=2m
PrivateTmp=false
EOF

#### 7.8 0100 создаем конфигурацию garb
cat > /etc/sysconfig/garb_{{ galera_wsrep_cluster_name }} <<EOF
#Copyright (C) 2012 Codership Oy
#This config file is to be sourced by garb service script.

#A comma-separated list of node addresses (address[:port]) in the cluster
GALERA_NODES="
{%- for host in ansible_play_hosts -%}
{{ hostvars[host].cluster_ip }}:{{ galera_wsrep_cluster_port }}
{%- if not loop.last -%} {{ ' ' }} {%- endif -%}
{%- endfor -%}"

#Galera cluster name, should be the same as on the rest of the nodes.
GALERA_GROUP="{{ galera_wsrep_cluster_name }}"

#Optional Galera internal options string (e.g. SSL settings)
#see http://galeracluster.com/documentation-webpages/galeraparameters.html
GALERA_OPTIONS="pc.recovery=FALSE"

#Log file for garbd. Optional, by default logs to syslog
#LOG_FILE="/var/log/garbd.log"
EOF
```
#### 7.9 0100 перезагрузка параметров демона арбитра
```
         systemctl daemon-reload garbd_{{ galera_wsrep_cluster_name }}
```
#### 7.10 0100 добавление сервиса в автозапуск
```
          systemctl enable garbd_{{ galera_wsrep_cluster_name }}
```
### 8. конфигурация logrotate

#### 8.1 1011 выведем файл slow_query_log_file
```
         mysql -e 'select @@slow_query_log_file' | grep -v slow_query_log_file
```
#### 8.2 1011 файл конфигурации logrotate
```
cat > /etc/logrotate.d/mysql-server <<EOF
#- I put everything in one block and added sharedscripts, so that mysql gets
#flush-logs'd only once.
#Else the binary logs would automatically increase by n times every day.
#- The error log is obsolete, messages go to syslog now.
{{ logrotate_mysql_slow_log_file }} {
	daily
	rotate 7
	missingok
	create 644 mysql mysql
	nocompress
        dateext
	sharedscripts
	postrotate

		if test -x /usr/bin/mysqladmin && \
		   /usr/bin/mysqladmin ping &>/dev/null
		then
		   /usr/bin/mysql --defaults-file={{ logrotate_mycnf }} -e "FLUSH NO_WRITE_TO_BINLOG SLOW LOGS;"
		fi

        endscript

        lastaction
		DAY=$(date +%Y%m%d)
		/bin/gzip {{ logrotate_mysql_slow_log_file }}-$DAY
{% if logrotate_send_to_bkp == 1 %}
		ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i {{ logrotate_ssh_key_path }} {{ logrotate_remote_user }}@{{ logrotate_server }} 'mkdir -p /home/{{ logrotate_remote_user }}/{{ env }}/{{ logrotate_project_name }}/{{ logrotate_hostname_short }}/'
                nice /usr/bin/rsync -rt --bwlimit=10000 -e "ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i {{ logrotate_ssh_key_path }}" {{ logrotate_mysql_slow_log_file }}-$DAY.gz {{ logrotate_remote_user }}@{{ logrotate_server }}:/home/{{ logrotate_remote_user }}/{{ env }}/{{ logrotate_project_name }}/{{ logrotate_hostname_short }}/ > /dev/null 2>&1
{% endif %}
        endscript

}
EOF
```
#### 8.3 1011 проверка, есть ли еще правило, ротирующее слоу логи, должно вернуть 0
```
         grep -o -P --exclude={mysql-server,mysqlog} '/var/log/mysql/' /etc/logrotate.d/* | wc -l
```
#### 8.4 1011 удалить старое правило, если оно есть
```
         rm -f /etc/logrotate.d/mysqlog
```
#### 8.5 1010 создадим директорию для ключа ssh logrotate_ssh_path
```
         mkdir -p /var/lib/logrotate/.ssh
```
#### 8.6 1010 поместим ключ для ssh в /var/lib/logrotate/.ssh/ права 0600

#### 8.7 1011 убедимся, что есть директория
```
         mkdir -p /var/lib/logrotate/
```
#### 8.8 1011 поместим туда .my.cnf файл, указав верный логин и пароль
```
cat > /var/lib/logrotate/.my.cnf <<EOF
[client]
user={{ logrotate_mysql_user }}
password={{ logrotate_mysql_pass }}
EOF
```
#### 8.9 1011 logrotate restorecon (SELinux)
          restorecon -Rv /etc/cron.daily/
          restorecon -Rv /usr/sbin/logrotate
          restorecon -Rv /var/lib/logrotate/

#### 8.10 1011 добавим в режим permissive
```
          semanage permissive -a logrotate_t
```
#########################################
### экспериментальные доработки
#########################################
ввести

1011 RAM RELATED SETTINGS. MySQL buffers and caches must fit in RAM
1011 innodb_buffer_pool_size = 50% RAM (должно делиться на 128 MB)
1010 max_connections = 45% RAM (45% RAM в MB/3 MB)
0001 max_connections = 500 (слейвы, которые не хот бекап)

1000 GALERA PERFORMANCE SETTINGS
1000 sync_binlog = 0
1000 innodb_flush_log_at_trx_commit = 2

1011 MYSQL VERBOSITY.
1011 innodb_print_all_deadlocks=1 #PRINT DEADLOCK IN ERROR LOG
1011 убрать log_error=/var/log/mysql/mysql_error.log из бетов. ошибки должны писаться в журнал systemd
1011 убрать thread_concurrency=0 из гейта

Requirements
------------

Хосты должны быть зарегистрированы на satellite.

При установке контура галера необходимо для всех ip адресов назначать прямые и обратные записи днс (в том числе и для ip внутри vlan galeranet)

При установке используются подписки
- `ORGLOT_OFFICE_MariaDB_10_MariaDB_10_1_release_for_RHEL7_-_x86_64`
- `ORGLOT_OFFICE_Percona_Percona_5_release_for_RHEL7`


Role Variables
--------------


`defaults/main.yml - параметры по умолчанию`

`galera_mysql_version: 10.2.14 - переменная которая контролирует версию mysql (всегда ставить только свежую)`

##### переменные, которые необходимо задать
variable|formula|explanation
---|---|---
galera_mariadb_repo||
galera_percona_repo||
mariadb_release|| версия mariadb для установки
mysql_only||если установка без галеры
galera_configs||
galera_server_id||
mysql_root_password||пароль рута на mysql
galera_sst_user||
galera_sst_pass||
mysql_users||


##### автоматически генерируемые переменные
variable|formula|explanation
---|---|---
play_hosts_whihtout_arb| {{ (ansible_play_hosts &#124; difference(groups['arbitrator'])) }}| хосты из плея кроме арбитра.
finnodb_buffer_pool_size| {{ ansible_memtotal_mb/100*mem_persent }}| промежуточная переменная, используется в innodb_buffer_pool_size
innodb_buffer_pool_size| {{ finnodb_buffer_pool_size.split('.')[0]+'M' }}| размер буфера innodb_buffer_pool_size
cluster_ip| {{ ansible_default_ipv4.address }}| если не определен явно, будет айпи адрес по умолчанию
cluster_size| {{ (( ansible_play_batch|length )/2) &#124; round(0, 'ceil') }}| минимальный размер галера кластера (нужен для скрипта кластерчек (deprecated))
galera_wsrep_cluster_name| {{ hostvars[ play_hosts_whihtout_arb.0 ].galera_wsrep_cluster_name &#124; default(galera_wsrep_cluster_name) }}| используетс/ в формировании имени сервиса арбитра и в конфигурационном файле galera.cnf
galera_wsrep_cluster_port| {{ hostvars[ play_hosts_whihtout_arb.0 ].galera_wsrep_cluster_port &#124; default(galera_wsrep_cluster_port) }}|
galera_nodes_pkgs||
galera_percona_pkgs||
galera_all_pkgs||
ansible_selinux||
galera_cnf||если есть файл /etc/my.cnf.d/galera.cnf
wsrep_sst_auth_existence||если опеределены креды для репликации галеры (на всякий случай, чтоб не поменять пароль галеры и не развалить ее)
ansible_fqdn||
mysql_directories||
galera_new_cluster||для инициализации галеры
grastate| есть ди файл grastate
bootstrap_value|| {{ safe_to_bootstrap.stdout.split(' ')[1] }}
safe_to_bootstrap||
bootstrap_node||
galera_restart_cluster||если задано, то рестартовать кластер
logrotate_slow_query_log_file| mysql -e 'select @@slow_query_log_file' | grep -v slow_query_log_file|
logrotate_mysql_slow_log_file| {{ logrotate_slow_query_log_file.stdout }}|
logrotate_file||
logrotate_matched||
logrotate_ssh_path||
logrotate_ssh_key_path||
logrotate_mycnf_dir||
logrotate_mycnf||
galera_max_connections||




Dependencies
------------

Example inventory
-----------------
text
[arbitrator]
board-adm.tsed.orglot.office ansible_host=10.200.81.11 cluster_ip=10.200.83.41

[esb]
board-esb1.tsed.orglot.office ansible_host=10.200.81.15 cluster_ip=10.200.83.42
board-esb2.tsed.orglot.office ansible_host=10.200.81.16 cluster_ip=10.200.83.43

[galera:children]
esb
arbitrator

[galera:vars]
galera_mysql_version: 10.1.24
...


`cluster_ip - ip vlan интерфейса, по умолчанию используется ansible_default_ipv4.address`

`arbitrator обязательно указывать последним`

TODOLIST
--------
Try to run arbitrator in enforced SELinux environment

Example Playbook
----------------
yaml
- hosts: galera
  become: yes
  gather_facts: yes
  vars:
    - hosts: galera
  roles:
    - role: galera
      tags: galera

    - role: galera
      new_cluster: 1
      tags:
        - galera_new

License
-------

BSD

Author Information
------------------

evgeny.zemlyachenko@stoloto.ru
