#!/bin/bash
# Copyright (C) 2013 Tobias <contato@eutobias.org>
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.If not, see <http://www.gnu.org/licenses/
#
# Obtem o nome netbios ou macaddress de um host especificado
# pelo seu ip
# Ver tambem: http://www.samba.org/samba/docs/man/manpages/nmblookup.1.html
#
# 29/10/13 Tobias v0.1
# 26/11/2013 Tobias v0.2


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.2
NBTSCAN=$(which nbtscan)
IP=
parametroObrigatorio=0

##############################
#
#          FUNÇÕES
#
##############################

# Caso a variavel global DEBUG seja 1,
# esta funcao imprime na tela todos os
# argumentos que receber
function debugar {
        if [[ $DEBUG == 1 ]]; then
                echo $@
        fi
}


# Exibe o texto de ajuda deste script
function ajuda {
        echo "
Script para retornar informações sobre um determinado ip.
Versão: ${VERSAO}

Uso: $0 [-i | --ip]=valor [opção]

Opção pode ser:
-d | --debug            habilita o debug. Útil para averiguar erros
-h | --help             exibe este texto de ajuda
-n | --name 		retorna nome netbios
-m | --mac 		retorna endereco MAC
"
}


function obtemNome {
	# IP address       NetBIOS Name     Server    User             MAC address
	# nbtscan -t 20 -v -h -q 192.168.5.25
	retornoNbtscan=$($NBTSCAN -t 20 -s ':' "$1" 2>/dev/null)
	debugar "NBTSCAN terminou com o codigo \"$?\""
	nomeNetbios=$(echo "$retornoNbtscan" | cut -d ':' -f 2)
	if [[ -z $nomeNetbios ]]; then
		echo $NAO_SUPORTADO
		exit 1
	else
		echo $nomeNetbios
	fi
}


function obtemMAC {
	# IP address       NetBIOS Name     Server    User             MAC address
	# nbtscan -t 20 -v -h -q 192.168.5.25
	retornoNbtscan=$($NBTSCAN -t 20 -s ':' "$1")
	debugar "NBTSCAN terminou com o codigo \"$?\""
	macAddress=$(echo "$retornoNbtscan" | cut -d ':' -f 5)
	if [[ -z $macAddress ]]; then
		echo $NAO_SUPORTADO
		exit 1
	else
		echo $macAddress
	fi
}


##############################
#
#        CHECAGENS
#
##############################

# Nenhum parametro especificado
if [[ $# < 1 ]]; then
        echo $NAO_SUPORTADO
        exit 1
fi

# O parametro para ativar o debug pode
# ser especificado em qualquer ordem nos parametros
for argumento in "$@"; do
        case $argumento in
                -d|--debug)
                DEBUG=1
                debugar "Debug ativado";;
        esac
done

# Estas verificações são feitas aqui para o caso do
# debug estar ativado
if [[ -z $NBTSCAN || ! -x $NBTSCAN ]]; then
        debugar "Erro: comando nbtscan nao encontrado ou nao eh executavel"
        echo $NAO_SUPORTADO
        exit 1
fi


# Verifica os argumentos passados para este script.
# Nota: dentre várias opções de verificação de parâmetros,
# optei por esta por poder verificar parâmetros curtos e longos
# de uma maneira razoavelmente legível.
# Exemplos:
# http://stackoverflow.com/questions/192249/how-do-i-parse-command-line-arguments-in-bash
for argumento in "$@"; do
        case $argumento in
                -h|--help)
                debugar "Exibindo texto de ajuda"
                ajuda
                exit 0;;
                -d|--debug)
                        # apenas para que este case nao retorne erro
                        DEBUG=1;;
                -i=*|--ip=*)
                        p="${argumento#*=}"
                        if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado. Utilizando valor padrao."
                        else
                                IP=${p}
                                debugar "Definindo site a resolver para \"${IP}\""
                        fi;;
		-m|--mac)
			debugar "Obtendo mac do ip \"${IP}\""
			parametroObrigatorio=1
			obtemMAC "${IP}";;
		-n|--name)
			debugar "Obtendo nome netbios do ip \"${IP}\""
			parametroObrigatorio=1
			obtemNome "${IP}";;
                *)
                        debugar "Parametros nao reconhecidos"
                        echo $NAO_SUPORTADO
                        exit 1;;
        esac
done

if [[ $parametroObrigatorio == 0 ]]; then
	debugar "Parametro obrigatorio nao definido"
	echo $NAO_SUPORTADO
	exit 1
else
	exit 0
fi

#EOF
