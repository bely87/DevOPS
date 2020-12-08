pause after each check, print out checks to stdout
1. print out mariadb.cnf variables.
1.1 print out system RAM, CPU count, HDD partitioning and available space
1.2 print out max_connections, innodb_buffer_pool_size
2. print out galera.cnf variables
3. print out ip addresses from hosts.ini and from the interfaces, check out dns. checkout keepalived vip ips and dns lookup from keepalived vip ips
4. check if galera cluster initialized, check cluster size, try to connect to galera cluster by using keepalived vip ips
5. check 'journalctl -xefu mariadb' for errors
6. try to connect to mariadb using .my.cnf files for configured services (zabbix after zabbix role, logrotate, root). try to connect to mariadb using galera credentials
7. try to run logrotate script with runcon if selinux is in enforcing mode.
8. check if rotated logs are sent to backup server
9. check firewalld zones, services, ports and networks, print them out
10. print mariadb version
11. check if mariadb in permissive
12. check if logrotate in permissive
13. ll -Z mysql and logrotate directories
14. check swappiness
15. check system limits
16. check keepalived scripts, print out vars for keepalived
