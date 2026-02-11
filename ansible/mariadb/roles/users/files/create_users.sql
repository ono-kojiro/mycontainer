DROP   USER IF EXISTS 'maria';
CREATE USER 'maria' identified by 'maria123';
GRANT ALL PRIVILEGES ON *.* TO 'maria'@'%' WITH GRANT OPTION;

