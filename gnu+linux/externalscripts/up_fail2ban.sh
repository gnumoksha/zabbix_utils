#!/bin/bash
# Copyright (C) 2014 Dron <jiri.slezka@slu.cz>
# Copyright (C) 2014 Tobias <contato@eutobias.org>

# https://www.zabbix.com/forum/showthread.php?t=46974

##############################
#
#         VARIABLES
#
##############################

NOT_SUPPORTED="ZBX_NOTSUPPORTED"
DEBUG=0
VERSION=0.2
F2BANCLIENT=$(which fail2ban-client 2>/dev/null) # /usr/bin/fail2ban-client


##############################
#
#         FUNCTIONS
#
##############################

# If the DEBUG global variable is 1,
# this function prints on the screen all
# arguments that receive
function debug {
        if [[ $DEBUG == 1 ]]; then
                echo $@
        fi
}


# Show help text for this script
function show_help {
        echo "
Script to return fail2ban information for zabbix
Version ${VERSION}

Usage: $0 [-d | --debug] [options]

Opção pode ser:
-d | --debug 			enable debug
-h | --help 			Show this text
-l | --lld-jails 		Discovering jails
[-b | --banned]=jail		Get number of banned hosts
"
}


function get_banned_number {
	ret=$($F2BANCLIENT status $1 | grep "Currently banned:" | /bin/grep -o -E "[0-9]*")
	debug "fail2ban_client has terminated with code \"$?\""
        if [[ -z $ret ]]; then
		debug "fail2ban_client don't returned a valid value"
                echo $NOT_SUPPORTED
        else
                echo $ret
        fi
}

function discover_jails {
	# get list of all jails
	JAILS=$($F2BANCLIENT status | grep "Jail list" |grep -E -o "([-[:alnum:]]*, )*[-[:alnum:]]*$")
	debug "Jails list: $JAILS"

	echo -e "{"
	echo -e "\t\"data\":["

	# cycle through all jails
	IFS=","
	LAST="x"
	for JAIL in $JAILS ; do
	  # trim whitespaces
	  JAIL=$(echo $JAIL | sed -e 's/^ *//' -e 's/ *$//')
	  if [ $LAST != "x" ] ; then
	    echo -e "\t{\"{#F2BJAIL}\":\"$LAST\"},"
	  fi
	  LAST=$JAIL
	done

	# last item has no comma
	echo -e "\t{\"{#F2BJAIL}\":\"$LAST\"}"

	echo -e "\t]"
	echo -e "}"
}


##############################
#
#           CHECKS
#
##############################

# None parameter specified
if [[ $# < 1 ]]; then
        echo $NOT_SUPPORTED
        exit 1
fi

# The parameter to enable the debug can
# be specified in any order in the parameters
for argument in "$@"; do
        case $argument in
                -d|--debug)
		debug "Enabling debug"
		#set -x
                DEBUG=1;;
        esac
done

# These checks are made here to the case of
# debug be enabled
if [[ -z $F2BANCLIENT || ! -x $F2BANCLIENT ]]; then
        debug "Error: fail2ban_client software not found or is not executable"
        echo $NOT_SUPPORTED
        exit 1
fi


# Verifica os argumentos passados para este script.
# Nota: dentre várias opções de verificação de parâmetros,
# optei por esta por poder verificar parâmetros curtos e longos
# de uma maneira razoavelmente legível.
# Exemplos:
# http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-argument-in-bash
for argument in "$@"; do
        case $argument in
                -h|--help)
                debug "Displaying help text"
                show_help
                exit 0;;
                -d|--debug)
                        # Just so that this case does not return error
                        DEBUG=1;;
		-l|--lld-jails)
			debug "Discovering jails"
			discover_jails;;
                -b=*|--banned=*)
                        p="${argument#*=}"
                        if [[ -z $p ]]; then
                                debug "Value for $argument was not specified"
                                echo $NOT_SUPPORTED
                                exit 1
                        fi
			debug "Getting number of banned hosts for jail \"${p}\""
                        get_banned_number "${p}"
                        exit 0;;
                *)
                        debug "Not recognized parameters"
                        echo $NOT_SUPPORTED
                        exit 1;;
        esac
done

exit 0

#EOF
