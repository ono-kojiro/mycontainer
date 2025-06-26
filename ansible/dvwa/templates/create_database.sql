CREATE DATABASE IF NOT EXISTS {{ database }};
CREATE USER IF NOT EXISTS '{{ sql_user }}'@'localhost' IDENTIFIED BY '{{ sql_pass }}';
GRANT ALL PRIVILEGES ON {{ database }}.* TO '{{ sql_user }}'@'localhost';
FLUSH PRIVILEGES;

