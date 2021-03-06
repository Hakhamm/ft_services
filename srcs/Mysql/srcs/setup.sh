#!/bin/bash

#prepare openrc run dir
if [ ! -d "/run/openrc/" ]; then
  mkdir -p /run/openrc/
  touch /run/openrc/softlevel
  openrc
fi

chown -R mysql: /app/data

if [ ! -d "/run/mysqld" ]; then
  mkdir -p /run/mysqld
fi

/etc/init.d/mariadb setup

if [ -d /app/mysql ]; then
	echo "MySQL directory already present, skipping creation"
else
	echo "MySQL data directory not found, creating initial DatabasesBs"

	mysql_install_db --user=root > /dev/null

	if	[ "$MYSQL_ROOT_PASSWORD" = "" ]; then
		MYSQL_ROOT_PASSWORD=toor
		echo "MySQL root Password: $MYSQL_ROOT_PASSWORD"
  fi

	MYSQL_DATABASE=${MYSQL_DATABASE:-""}
	MYSQL_USER=${MYSQL_USER:-""}
	MYSQL_PASSWORD=${MYSQL_PASSWORD:-""}

	tempfile=`mktemp` #create a temporary file
	if [ ! -f "$tempfile" ]; then
	  return 1
	fi

	#applying root new permissions
	cat << EOF > $tempfile
USE mysql;
FLUSH PRIVILEGES;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY "$MYSQL_ROOT_PASSWORD" WITH GRANT OPTION;
GRANT ALL PRIVILEGES ON *.* TO 'root'@'localhost' WITH GRANT OPTION;
ALTER USER 'root'@'localhost' IDENTIFIED BY '';
EOF

	# creating database
	if [ "$MYSQL_DATABASE" != "" ]; then
	echo "Creating database: $MYSQL_DATABASE"
	echo "CREATE DATABASE IF NOT EXISTS \`$MYSQL_DATABASE\` CHARACTER SET utf8 COLLATE utf8_general_ci;" >> $tempfile

	#creating user
	if [ "$MYSQL_USER" != "" ]; then
	  echo "Creating user: $MYSQL_USER with password $MYSQL_PASSWORD"
	  echo "GRANT ALL ON \`$MYSQL_DATABASE\`.* to '$MYSQL_USER'@'%' IDENTIFIED BY '$MYSQL_PASSWORD';" >> $tempfile
	fi
	fi
	mkdir -p /app/mysql
	# apply everything on the sql script file and delete it
	/usr/bin/mysqld --user=root --bootstrap --verbose=0 < $tempfile
	/usr/bin/mysqld --user=root --bootstrap --verbose=0 $MYSQL_DATABASE < wordpress.sql
	rm -f $tempfile
	rm -f /wordpress.sql
fi
rc-service mariadb restart
rc-service mariadb stop

(/usr/bin/mysqld --user=root --console &)

while true;	do
sleep 5
ret1="$(ps | grep mysqld | grep -vc grep)"
if [ $ret1 -eq 0 ]; then
    echo "pod is unhealthy"
    break ;
else
    echo "pod is healthy"
fi
done
