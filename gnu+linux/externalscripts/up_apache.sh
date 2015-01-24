#!/bin/bash
# Copyright KovoKs http://www.kovoks.nl/ under GNU GPL version 2
 
find /tmp/zabbix_apache -cmin +1 -delete > /dev/null 2>&1
if [ ! -e /tmp/zabbix_apache ]
then
    wget -q -O /tmp/zabbix_apache http://localhost/server-status?auto
fi
if [ "$1" == "TA" ]
then
    awk '/Total Accesses/ {print $3}' < /tmp/zabbix_apache
fi
if [ "$1" == "TB" ]
then
    awk '/Total kBytes/ {print $3}' < /tmp/zabbix_apache
fi
if [ "$1" == "CPU" ]
then
    awk '/CPULoad/ {print $2}' < /tmp/zabbix_apache
fi
if [ "$1" == "UT" ]
then
    awk '/Uptime/ {print $2}' < /tmp/zabbix_apache
fi
if [ "$1" == "RPS" ]
then
    awk '/ReqPerSec/ {print $2}' < /tmp/zabbix_apache
fi
if [ "$1" == "BPS" ]
then
    awk '/BytesPerSec/ {print $2}' < /tmp/zabbix_apache
fi
if [ "$1" == "BPR" ]
then
    awk '/BytesPerReq/ {print $2}' < /tmp/zabbix_apache
fi
if [ "$1" == "BW" ]
then
    awk '/BusyWorkers/ {print $2}' < /tmp/zabbix_apache
fi
if [ "$1" == "IW" ]
then
    awk '/IdleWorkers/ {print $2}' < /tmp/zabbix_apache
fi
if [ "$1" == "" ]
then
    echo 1
fi
