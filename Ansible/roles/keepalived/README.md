keepalived
=========

Установка keepalived и настройка vrrp ip

Requirements
------------

Хосты должны быть зарегистрированы на satellite.

Role Variables
--------------

`vip_ip=172.17.35.96/20 - vrrp ip для настройки. префикс обязателен.`
`keepalived_check_process - имя процесса для проверки в track_script`
`defaults/main.yml - параметры по умолчанию`

Dependencies
------------

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
- hosts: esb
  become: yes

  roles:
    - role: keepalived
      keepalived_check_process: nginx
      tags: keepalived
```
License
-------

BSD

Author Information
------------------

evgeny.zemlyachenko@stoloto.ru
