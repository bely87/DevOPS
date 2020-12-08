zabbix
=========

Регистрация хостов в zabbix


Requirements
------------

Хосты должны быть зарегистрированы на satellite.

`на хосте выполняющем плей требуется python модуль zabbix-api`


Role Variables
--------------
`zabbix_group - имя группы в которую нужно поместить хост. группа будет создана при отсутствии`
`ex: zabbix_group=['GA-FISCAL', 'GA-FISCAL-DB']`
`zabbix_templates - массив темплейтов zabbix, которые нужно применить для хоста (tmplt_orglot_linux_base по умолчанию)`
`defaults/main.yml - параметры по умолчанию`
`zabbix_macros - переменная отвечающая за работу с макросами хоста, пример использования ниже`
`zabbix_home_dir - по умолчанию прод, для га надо задать /home/zabbix`

Variables required for GA:
`zabbix_home_dir = '/home/zabbix'
zabbix_scripts_dir = '/home/zabbix/bin'
zabbix_tmp_dir = '/home/zabbix/tmp'`

Variables required for Galera:

`zabbix_macros:
- { name: "CLUSTER_SIZE", value: 5 }`

Dependencies
------------
В inventory  для mysql серверов должна существовать переменная first_db_instance напротив каждой мастер ноды
Это либо мастер сервер в цепочке мастер-слейв любого размера,
либо первая нода галеры

Правило выбора zabbix-прокси
----------------------------
zabbix-proxy1.tsed.orglot.office: DC1, сервера из лототронной кроме проекта лототроны
zabbix-proxy2.tsed.orglot.office: DC2, сервера GA (они, как правило, в Курчатнике)
zabbix-proxy3.oets.orglot.office: GATE1, GATE2
zabbix-proxy-vmware.tsed.orglot.office: сервера проекта лототроны

Как назначить zabbix-прокси
---------------------------
1. Прокси сервер выбирается автоматически на базе индекса в названии хоста, т.е. узлу с индексом 1 будет назначен прокси
zabbix-proxy1.tsed.orglot.office.
2. Если необходимо переопределить прокси, то для группы хостов создается массив вида

```yaml
zabbix_proxy_list:
- name: 'zabbix-proxy1.tsed.orglot.office'
  dc: 1
- name: 'zabbix-proxy2.tsed.orglot.office'
  dc: 2
- name: 'zabbix-proxy3.tsed.orglot.office'
  dc: 3
- name: 'zabbix-dev-proxy1.tsed.orglot.office'
  dc: 1
- name: 'zabbix-dev-proxy2.tsed.orglot.office'
  dc: 0
```
где переопределяются прокси и DC.

Пояснение:
параметр dc в массиве zabbix_proxy_list означает, где находится данный прокси по отношению к данному хосту.
1 - DC1
2 - DC2
3 - DC3
0 - данный прокси будет включен в список независимо в каком DC находится сервер

Example inventory
-----------------
```text
[esb]
board-esb1.tsed.orglot.office ansible_host=10.200.81.15 cluster_ip=10.200.83.42
board-esb2.tsed.orglot.office ansible_host=10.200.81.16 cluster_ip=10.200.83.43
```

Example Playbook
----------------
```yaml
- hosts: all
  become: yes

  roles:
  - role: zabbix
    tags: zabbix
```

```yaml

  zabbix_macros:
  - { name: "MAX_PROC", value: 210 }

```
inventory/host-env-example
```text
zabbix_macros = {{ 'name': "MAX_PROC", 'value': 210 }, { 'name': "TIMEOUT", 'value': 31104000 }}
```

Пример реализации роли заббикс в проекте с MySQL
----------------------------------------
1. Редактируем inventory file. Добавляем переменную ```yaml first_db_instance=1 ```, напротив всех первых нод галеры и мастер сервера
2. Добавляем переменные zabbix_group в секции с БД, например:
```yaml
[db-backup:vars]
zabbix_group=['PROD-PROJ', 'PROD-PROJ-DB']
```
3. В inventory/group_vars создаем директории с названиями секций из inventory. В этих директориях создаем файл zabbix.yml, в котором прописываем переменные zabbix_proxy_list, zabbix_templates. Для инстансов галеры zabbix_macros.
```yaml
zabbix_macros:
- { name: "CLUSTER_SIZE", value: 5 }
```
```
zabbix_templates: ['Template_linux_base','Template_Iostat-All-Disk-Utilization', 'Template App MySQL', '0rglot-linux-mysql']
```
темплейты, которые должны присутствовать на всех db хостах:
- Template_linux_base
- Template_Iostat-All-Disk-Utilization
- Template App MySQL
- 0rglot-linux-mysql

темплейты, которые должны присутствовать на хостах галеры:
- Template_Galera_MySQL

темплейты, которые должны присутствовать на асинхронных слейвах:
- Template_MySQL_Slave
4. В проекте создаем файл playbooks/90-postinstall.yml со следующим содержимым:

```yaml
---
- hosts: all
  name: postinstall playbook for all hosts
  become: yes
  gather_facts: yes

  roles:
  - role: zabbix
    tags: zabbix
```
5. Запуск.
 ```bash
 ansible-playbook -i <path_to_inventory> playbooks/90-postinstall.yml -l <секция с хостами> -b -v
 ```


Not implemented features yet
----------------------------

Task Mysql:
1. Separate monitoring for Galera,
                           standalone,
                           slave,
                           backup,
                           arbitrator
                           haproxy
Task main:                           
2. Automatic default zabbix proxy based on location

License
-------

BSD

Author Information
------------------

evgeny.zemlyachenko@stoloto.ru
