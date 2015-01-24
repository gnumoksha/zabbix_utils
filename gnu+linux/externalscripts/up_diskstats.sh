#! /bin/bash
#
# Name: zadiskio
#
# Checks IO Disk activity.
#
# Authors:
# Adail Horst
# Tobias Sette <contato@eutobias.org>
#
# Version: 2.0
#

zaver="2.0"
rval=0

function usage()
{
    echo "zadiskio version: $zaver $#"
    echo "usage:"
    echo "    $0 <HardDisk> ReadOps   -- Check Read Ops."
    echo "    $0 <HardDisk> ReadMs    -- Check Read Latency."
    echo "    $0 <HardDisk> WriteOps  -- Check Write Ops."
    echo "    $0 <HardDisk> WriteMs   -- Check Write Latency."
    echo "    $0 <HardDisk> IoProgress-- Current IO Requests."
    echo "    $0 <HardDisk> IoMs      -- Check IO Latency."
    echo "    $0 <HardDisk> ReadSectors       -- Check Read Sectors."
    echo "    $0 <HardDisk> WriteSectors      -- Check Write Sectors."

}

########
# Main #
########
#set -x

if [[ $# ==  3 ]];then
    #Agent Mode
    VAR=$(cat /proc/diskstats | grep $1 | head -1)
    CASE_VALUE=$2
elif [[ $# == 2 ]];then
    #External Script Mode
    VAR=$(cat /proc/diskstats | grep $1 | head -1)
    CASE_VALUE=$2
else
    #No Parameter
    usage
    exit 0
fi

if [[ -z $VAR ]]; then
    echo "ZBX_NOTSUPPORTED"
    exit 1
fi

case $CASE_VALUE in
'ReadOps')
    echo "$VAR"|awk '{print $4}'
    rval=$?;;
'ReadMs')
    echo "$VAR"|awk '{print $7}'
    rval=$?;;
'ReadSectors')
    echo "$VAR"|awk '{print $6}'
    rval=$?;;

'WriteOps')
    echo "$VAR"|awk '{print $8}'
    rval=$?;;
'WriteMs')
    echo "$VAR"|awk '{print $11}'
    rval=$?;;
'WriteSectors')
    echo "$VAR"|awk '{print $10}'
    rval=$?;;
'IoProgress')
    echo "$VAR"|awk '{print $12}'
    rval=$?;;
'IoMs')
    echo "$VAR"|awk '{print $13}'
    rval=$?;;
*)
    usage
    exit $rval;;
esac

if [ "$rval" -ne 0 ]; then
      echo "ZBX_NOTSUPPORTED"
fi

exit $rval

#
# end

