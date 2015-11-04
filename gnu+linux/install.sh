#!/bin/bash

path=$(pwd)
config_file="$path/install.config"
source "$config_file"
[[ $? -ne 0 ]] && echo "Error in configuration file \"$config_file\"" && exit 1

# http://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value
read -p "What is the full path for 'externalscripts' directory [$path/externalscripts] ? " dir_externalscripts
dir_externalscripts=${dir_externalscripts:-$path/externalscripts}
# o sed reclama caso haja caracteres a serem escapados na variavel, entao mudo o
# caractere delimitador para ,
# http://www.unix.com/shell-programming-and-scripting/71927-sed-how-escape-variable-number-slash.html
sed -i "s,$dir_external_scripts,$dir_externalscripts,g" "$path"/zabbix_agentd.conf.d/*.conf

read -p "What is the full path for 'alertscripts' directory [$path/alertscripts] ? " dir_alertscripts
dir_alertscripts=${dir_alertscripts:-$path/alertscripts}
sed -i "s,$dir_alert_scripts,$dir_alertscripts,g" "$path"/alertscripts/telegram.sh
sed -i "s,$dir_alert_scripts,$dir_alertscripts,g" "$path"/alertscripts/dist/telegram/telegram.config

read -p " What is the full path for the zabbix_agentd.conf file [/etc/zabbix/zabbix_agentd.conf] ? " zabbixagentconfig
zabbixagentconfig=${zabbixagentconfig:-/etc/zabbix/zabbix_agentd.conf}
sed -i "s,$zabbix_agent_config_file,$zabbixagentconfig,g" "$path"/zabbix_agentd.conf.d/apache.conf

echo "For MySQL monitoring. Use /tmp for none"
read -p "What is the directory for MySQL .my.cnf file [/etc/mysql/zabbix/] ? " mysql_config
mysql_config=${mysql_config:-/etc/mysql/zabbix/}
if [[ "$(dirname $mysql_config)" == "/tmp" ]]; then
	echo "Pass"
elif [[ "$mysql_config" == "/etc/mysql/zabbix/" ]]; then
	# no debian:
	# dara acesso automatico ao root
	# ln -s /etc/mysql/debian.cnf /etc/mysql/conf.d/credentials.cnf
	# ou
	# mkdir -p /etc/mysql/zabbix
	# ln -s /etc/mysql/debian.cnf /etc/mysql/zabbix/.my.cnf
	# ln vai dar erro de permissao depois pois o arquivo linkado pertence ao root
	mkdir -p /etc/mysql/zabbix/
	cp /etc/mysql/debian.cnf /etc/mysql/zabbix/.my.cnf 2>&1 >/dev/null
	chown -R zabbix: /etc/mysql/zabbix/
	echo "The file /etc/mysql/zabbix/.my.cnf must contains MySQL credentials"
	sed -i "s,$mysql_config_file,$mysql_config,g" "$path"/zabbix_agentd.conf.d/up_mysql.conf
fi

read -p "What user runs zabbix agent? [zabbix] ? " zabbix_agent_user
zabbix_agent_user=${zabbix_agent_user:-zabbix}

chmod +x "$path"/externalscripts/dist/zabbix-apache-stats/bin/check_apache
chmod +x "$path"/externalscripts/dist/speed_check/SpeedCheck.py
chmod +x "$path"/externalscripts/dist/speedtest-cli/speedtest_cli.py # nao é necessario


echo
echo "Writing new configurations"
echo "dir_external_scripts=$dir_externalscripts
dir_alert_scripts=$dir_alertscripts
zabbix_agent_config_file=$zabbixagentconfig
mysql_config_file=$mysql_config
" 2>&1 | tee $config_file

echo "Add into zabbix server configuration file:
AlertScriptsPath=$path/alertscripts"

echo
echo "Add into $zabbixagentconfig file:
Include=$path/zabbix_agentd.conf.d/"

echo
echo "If you wish measure download, add into cron:
*/30 * * * *	$zabbix_agent_user	$dir_externalscripts/sender_download_speed.sh --config=$zabbixagentconfig"

echo
echo "If you wish measure download (with speedtest), add into cron:
*/30 * * * *	$zabbix_agent_user	$dir_externalscripts/sender_speedtest.sh --config=$zabbixagentconfig"

echo
echo "Done"

# a saida de erro tem que ir para a saida do zabbix ou o debug para a saida de erro?

exit 0
#EOF