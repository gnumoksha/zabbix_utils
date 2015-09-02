#!/bin/bash
# Copyright (C) 2015 Tobias <contato@tobias.ws>
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
# 24/08/15 Tobias v0.1
# 02/09/15 Tobias v0.2 - adicionado parâmetro -c -i -t do fping


##############################
#
#         VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.2
FPING=$(which fping 2>/dev/null)
destino="google.com"
interface=
numeroPings=4
interval=25
timeoutInicial=500
return="alive"

##############################
#
#		  FUNÇÕES
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
Script para testar conectivade.
Verifique se o timeout no agent e servidor estao em, pelo menos, 10 segundos.

Versão: ${VERSAO}

Uso: $0 [opção] [retorno]
Todas as opções são facultativas.

Opção pode ser:
-d | --debug				habilita o debug. Útil para averiguar erros
-h | --help				exibe este texto de ajuda
[-d | --destination]=valor		define o site que vai ser consultado ($destino)
[-I | --interface]=valor		define a interface a ser utilizada ($interface)
[-c | --count]=valor			numero de pings a enviar ($numeroPings)
[-i | --interval]=valor			intervalo, em milisegundos, entre os pings ($interval)
[-t | --timeout]=valor			timeout ate a primeira resposta ($timeoutInicial)
[-r | --return]=retorno			o que sera retornado ($return)

Retorno pode ser:
alive		ira retornar 0 se o host esta offline, 1 caso contrario
lost		ira retornar a porcentagem de perda de pacotes
ttlmin		retornara o menor TTL
ttlavg		retornara a media do TTL
ttlmax		retornara o maior TTL
"
}


function executaPing {
	parametroUm=$1
	debugar "Retorno eh $parametroUm"
	
	if [[ -z $interface ]]; then
		retorno=$($FPING -c $numeroPings -i $interval -t $timeoutInicial -r 3 -q $destino 2>&1)
	else
		retorno=$($FPING -c $numeroPings -i $interval -t $timeoutInicial- r 3 -q -I ${interface} $destino 2>&1)
	fi
	codigoRetorno=$?
	debugar "FPING retornou o codigo \"$codigoRetorno\" e a mensagem \"$retorno\"."
	if [[ $codigoRetorno -ne 0 ]]; then
		echo 0
	else
		# O fping foi executado com sucesso. O que retornar?
		# exemplo retorno fping:
		# 192.168.0.1 : xmt/rcv/%loss = 5/5/0%, min/avg/max = 2.67/5.61/10.5
		if [[ "$parametroUm" == "alive" ]]; then
			echo 1
		elif [[ "$parametroUm" == "lost" ]]; then
			echo $retorno | cut -d '=' -f 2 | cut -d '/' -f 3 | cut -d '%' -f 1;
		elif [[ "$parametroUm" == "ttlavg" ]]; then
			echo $retorno | cut -d '=' -f 3 | cut -d '/' -f 2
		elif [[ "$parametroUm" == "ttlmax" ]]; then
			echo $retorno | cut -d '=' -f 3 | cut -d '/' -f 3
		elif [[ "$parametroUm" == "ttlmin" ]]; then
			echo $retorno | cut -d '=' -f 3 | cut -d '/' -f 1 | sed 's/ //gi'
		fi
	fi
}


##############################
#
#          CHECAGENS
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
if [[ -z $FPING || ! -x $FPING ]]; then
	debugar "Erro: software fping nao encontrado ou nao eh executavel"
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
			-d=*|--destination=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado."
			else
				destino=${p}
				debugar "Definindo destino para \"${destino}\""
			fi;;
		-I=*|--interface=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado. Utilizando vazio."
			else
				interface=${p}
				debugar "Definindo interface para \"${interface}\""
			fi;;
		-c=*|--count=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado. Utilizando padrão."
			else
				numeroPings=${p}
				debugar "Definindo numero de pings para \"${numeroPings}\""
			fi;;
		-i=*|--interval=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado. Utilizando padrão."
			else
				interval=${p}
				debugar "Definindo intervalo para \"${interval}\""
			fi;;
		-t=*|--timeout=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado. Utilizando padrão."
			else
				timeoutInicial=${p}
				debugar "Definindo timeout inicial para \"${timeoutInicial}\""
			fi;;
		-r=*|--return=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado. Utilizando padrão."
			else
				return=${p}
				debugar "Definindo retorno para \"${return}\""
			fi;;
		*)
			debugar "Parametros nao reconhecidos"
			echo $NAO_SUPORTADO
			exit 1;;
	esac
done

debugar "Pingando host \"${destino}\" e retornando \"${return}\""
executaPing $return

exit 0

#EOF
