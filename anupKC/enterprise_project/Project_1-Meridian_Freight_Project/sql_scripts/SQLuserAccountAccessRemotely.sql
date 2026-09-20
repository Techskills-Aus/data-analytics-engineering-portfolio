CREATE USER 'external_user'@'%' IDENTIFIED BY 'p44w0rD@2026DA';
GRANT ALL PRIVILEGES ON *.* TO 'external_user'@'%';
FLUSH PRIVILEGES;

CREATE USER 'external_user1'@'%' IDENTIFIED BY 'p44w0rD@2026DA';
GRANT ALL PRIVILEGES ON *.* TO 'external_user1'@'%';
FLUSH PRIVILEGES;

SELECT user, host FROM mysql.user WHERE user = 'external_user1';

DROP USER IF EXISTS 'external_user'@'%';
DROP USER IF EXISTS 'external_user1'@'%';

