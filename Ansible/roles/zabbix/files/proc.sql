SET NAMES 'utf8' COLLATE 'utf8_unicode_ci'\p;

DELIMITER //
DROP DATABASE IF EXISTS `zabbix_procs` \p//
CREATE DATABASE `zabbix_procs` \p//
USE `zabbix_procs` \p//

DROP PROCEDURE IF EXISTS `zabbix_db_size` \p//
DROP PROCEDURE IF EXISTS `zabbix_db_table_data_size` \p//
DROP PROCEDURE IF EXISTS `zabbix_db_table_index_size` \p//
DROP PROCEDURE IF EXISTS `zabbix_process_list` \p//

CREATE PROCEDURE `zabbix_db_size`(IN a_dbname VARCHAR (50))
BEGIN
        SELECT ifnull ( sum( data_length + index_length ) , 0 )
        FROM information_schema.TABLES
        WHERE table_schema = a_dbname COLLATE 'utf8_general_ci';
END
\p//

CREATE PROCEDURE `zabbix_db_table_data_size`(IN a_dbname VARCHAR (50), IN a_tablename VARCHAR (50))
BEGIN
        SELECT ifnull ( sum( data_length ) , 0 )
        FROM information_schema.TABLES
        WHERE table_schema = a_dbname COLLATE 'utf8_general_ci'
	AND table_name = a_tablename COLLATE 'utf8_general_ci';
END
\p//

CREATE PROCEDURE `zabbix_db_table_index_size`(IN a_dbname VARCHAR (50), IN a_tablename VARCHAR (50))
BEGIN
        SELECT ifnull ( sum( index_length ) , 0 )
        FROM information_schema.TABLES
        WHERE table_schema = a_dbname COLLATE 'utf8_general_ci'
	AND table_name = a_tablename COLLATE 'utf8_general_ci';
END
\p//

CREATE PROCEDURE `zabbix_process_list`()
BEGIN
        show processlist;
END
\p//

DELIMITER ;

GRANT EXECUTE ON PROCEDURE zabbix_procs.zabbix_db_size to zabbix@localhost;
GRANT EXECUTE ON PROCEDURE zabbix_procs.zabbix_db_table_data_size to zabbix@localhost;
GRANT EXECUTE ON PROCEDURE zabbix_procs.zabbix_db_table_index_size to zabbix@localhost;
GRANT EXECUTE ON PROCEDURE zabbix_procs.zabbix_process_list to zabbix@localhost;
