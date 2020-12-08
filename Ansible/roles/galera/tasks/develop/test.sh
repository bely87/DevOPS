ansible-playbook -u agolovin -i inventories/gate/buf/hosts-buf-ga.ini playbooks/50-keepalived.yml -t keepalived -e galera-db -b -vvv
