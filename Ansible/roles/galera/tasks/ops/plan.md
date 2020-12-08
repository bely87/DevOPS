## Description
```
1000 backup source server
0100 backup dst server
0010 arbitrator
0001 other galera nodes
```
### 1. 1000 create directory and copy root mycnf jn backup server
### 2. 1000 remove backup directory
### 3. 1000 create backup directory
### 4. 1000 create backup with innobackupex
### 5. 1000 create backup directory on bkp storage server
### 6. 0101 stop mariadb
### 7. 0101 remove mysql dirs
### 8. 0101 remove backup directory on backup dst server
### 9. 0101 create backup directory on backup dst server
### 10. 0101 fetch backup
### 11. 0101 fetch root mycnf
### 12. 0101 innobackupex apply log
### 13. 0101 innobackupex copy back
### 14. 0101 restorecon mysql directory
### 15. 0101 mysql permissive mode
### 16. 0101 semanage contexts
### 17. 0100 galera_new_cluster
### 17. 0010 stop arbitrators
### 18. 0001 remove mysql dirs
### 19. 0001 start nodes (not first_db_instance)
### 20. start arbitrators
