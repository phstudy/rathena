#!/bin/bash
#set -e

if [ -z "$MYSQL_PORT_3306_TCP" ]; then
	echo >&2 'error: missing MYSQL_PORT_3306_TCP environment variable'
	echo >&2 ' Did you forget to --link some_mysql_container:mysql ?'
	exit 1
fi

# Setup a MySQL
mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -p"$MYSQL_ENV_MYSQL_ROOT_PASSWORD" <<'EOF'
CREATE DATABASE IF NOT EXISTS ragnarok;
GRANT SELECT,INSERT,UPDATE,DELETE ON `ragnarok`.* TO 'ragnarok'@'%' identified BY 'ragnarok';
EOF

# Insert SQL files
if ! [ -e .sql_inited ]; then
	sql=( main.sql logs.sql item_db.sql item_db2.sql item_db_re.sql item_db2_re.sql item_cash_db.sql item_cash_db2.sql mob_db.sql mob_db2.sql mob_db_re.sql mob_skill_db.sql mob_skill_db2.sql mob_skill_db_re.sql )
	for i in "${sql[@]}"
	do
		echo "Insert $i"
	    mysql -h"$MYSQL_PORT_3306_TCP_ADDR" -P"$MYSQL_PORT_3306_TCP_PORT" -uroot -p"$MYSQL_ENV_MYSQL_ROOT_PASSWORD" ragnarok < /rAthena/sql-files/$i
	done
	touch .sql_inited
fi

sed -i "s/sql.db_hostname:.*/sql.db_hostname: ${MYSQL_PORT_3306_TCP_ADDR}/g" /rAthena/conf/inter_athena.conf 
sed -i "s/char_server_ip:.*/char_server_ip: ${MYSQL_PORT_3306_TCP_ADDR}/g" /rAthena/conf/inter_athena.conf 
sed -i "s/map_server_ip:.*/map_server_ip: ${MYSQL_PORT_3306_TCP_ADDR}/g" /rAthena/conf/inter_athena.conf 
sed -i "s/log_db_ip:.*/log_db_ip: ${MYSQL_PORT_3306_TCP_ADDR}/g" /rAthena/conf/inter_athena.conf 


if [ ! -z "$AWS" ]; then
	AWS_PUBLIC_IP=$(curl -s http://169.254.169.254/latest/meta-data/public-ipv4)
	sed -i "s/char_ip:.*/char_ip: $AWS_PUBLIC_IP/g" /rAthena/conf/char_athena.conf
	sed -i "s/map_ip:.*/map_ip: $AWS_PUBLIC_IP/g" /rAthena/conf/map_athena.conf
        echo "Set IP to $AWS_PUBLIC_IP (AWS)"
fi

if [ ! -z "$PUBLIC_IP" ]; then
        sed -i "s/char_ip:.*/char_ip: $PUBLIC_IP/g" /rAthena/conf/char_athena.conf
        sed -i "s/map_ip:.*/map_ip: $PUBLIC_IP/g" /rAthena/conf/map_athena.conf
        echo "Set IP to $AWS_PUBLIC_IP"
fi  

exec "$@"

