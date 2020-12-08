nginx
=========

Установка nginx, деплой конфигурационных файлов и рестарт при необходимости

Requirements
------------

Хосты должны быть зарегистрированы на satellite.
При установке используются подписки
- `ORGLOT_OFFICE_NginX_NginX_Stable_for_RHEL7_-_x86_64`



Role Variables
--------------

`nginx_include_path: ../../inventories/boards - путь от корня роли к папке проекта содержащей все среды (test, stage, prod).`
`nginx_ssl_files - массив сертификатов в формате src(локальный путь от nginx_include_path к файлу), dest(путь на удаленном хосте)`
`nginx_templates - массив jinja2 темплейтов в формате src(локальный путь от nginx_include_path к j2 файлу), dest(путь на удаленном хосте)`
`defaults/main.yml - параметры по умолчанию`

`nginx_configs: - массив с полями dest и content, для создания конфигов`


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
  - role: nginx
    nginx_include_path: ../../inventories/boards
    nginx_ssl_files:
      - src: files/ssl/stage-board-esb.gate2.orglot.office.pem
        dest: /etc/pki/tls/certs
      - src: files/ssl/stage-board-esb.gate2.orglot.office-Key.pem
        dest: /etc/pki/tls/private
    nginx_templates:
      - src: templates/nginx/default.j2
        dest: /etc/nginx/conf.d/default.conf
      - src: templates/nginx/servicebus.j2
        dest: /etc/nginx/conf.d/servicebus.conf
      - src: templates/nginx/servicebus-ssl.j2
        dest: /etc/nginx/conf.d/servicebus-ssl.conf
```
License
-------

BSD

Author Information
------------------

evgeny.zemlyachenko@stoloto.ru
