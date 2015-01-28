#!/bin/bash

path=$(pwd)
config_file="$path/install.config"
source "$config_file"
[[ $? -ne 0 ]] && echo "Erro no arquivo de configuracao \"$config_file\"" && exit 1

# http://stackoverflow.com/questions/2642585/read-a-variable-in-bash-with-a-default-value
read -p "Qual o caminho completo para o diretorio 'externalscripts' [$path/externalscripts] ? " dir_externalscripts
dir_externalscripts=${dir_externalscripts:-$path/externalscripts}
# o sed reclama caso haja caracteres a serem escapados na variavel, entao mudo o
# caractere delimitador para ,
# http://www.unix.com/shell-programming-and-scripting/71927-sed-how-escape-variable-number-slash.html
sed -i "s,$dir_external_scripts,$dir_externalscripts,g" "$path"/zabbix_agentd.conf.d/*.conf

read -p "Qual o caminho completo para o diretorio 'alertscripts' [$path/alertscripts] ? " dir_alertscripts
dir_alertscripts=${dir_alertscripts:-$path/alertscripts}
sed -i "s,$dir_alert_scripts,$dir_alertscripts,g" "$path"/alertscripts/telegram.sh
sed -i "s,$dir_alert_scripts,$dir_alertscripts,g" "$path"/alertscripts/dist/telegram/telegram.config

read -p "Qual path completo para o zabbix_agentd.conf? [/etc/zabbix/zabbix_agentd.conf] ? " zabbixagentconfig
zabbixagentconfig=${zabbixagentconfig:-/etc/zabbix/zabbix_agentd.conf}
sed -i "s,$zabbix_agent_config_file,$zabbixagentconfig,g" "$path"/zabbix_agentd.conf.d/apache.conf

read -p "Qual o diretorio para o arquivo .my.cnf do MySQL? [/etc/mysql/zabbix/] ? " mysql_config
mysql_config=${mysql_config:-/etc/mysql/zabbix/}
if [[ "$mysql_config" == "/etc/mysql/zabbix/" ]]; then
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
	echo "O arquivo /etc/mysql/zabbix/.my.cnf deve conter credenciais de acesso ao MySQL"
fi
sed -i "s,$mysql_config_file,$mysql_config,g" "$path"/zabbix_agentd.conf.d/up_mysql.conf

read -p "Qual o usuario que roda o agent zabbix [zabbix] ? " zabbix_agent_user
zabbix_agent_user=${zabbix_agent_user:-zabbix}

chmod +x "$path"/externalscripts/dist/zabbix-apache-stats/bin/check_apache
chmod +x "$path"/externalscripts/dist/speed_check/SpeedCheck.py
chmod +x "$path"/externalscripts/dist/speedtest-cli/speedtest_cli.py # nao é necessario


echo
echo "Escrevendo novas configuracoes"
echo "dir_external_scripts=$dir_externalscripts
dir_alert_scripts=$dir_alertscripts
zabbix_agent_config_file=$zabbixagentconfig
mysql_config_file=$mysql_config
" 2>&1 | tee $config_file

echo "Adicone ao arquivo de configuracao do servidor zabbix:
AlertScriptsPath=$path/alertscripts"

echo
echo "Adicione no arquivo $zabbixagentconfig:
Include=$path/zabbix_agentd.conf.d/"

echo
echo "Se quiser medir o download, adicione no cron:
*/30 * * * *	$zabbix_agent_user	$dir_externalscripts/sender_download_speed.sh --config=$zabbixagentconfig"

echo
echo "Se quiser medir o download e upload com o speedtest, adicione no cron:
*/30 * * * *	$zabbix_agent_user	$dir_externalscripts/sender_speedtest.sh --config=$zabbixagentconfig"

echo
echo "Terminado"

# a saida de erro tem que ir para a saida do zabbix ou o debug para a saida de erro?

exit 0
#EOF