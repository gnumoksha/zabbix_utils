#!/bin/bash
# Copyright (C) 2014 Tobias <contato@eutobias.org>
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
# Script para enviar dados para o zabbix, via zabbix_sender
# Motivacao: 
# https://br.groups.yahoo.com/neo/groups/zabbix-brasil/conversations/messages/16789
#
# 07/04/14 Tobias v0.1


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.1
SENDER=$(which zabbix_sender 2>/dev/null)
IP="127.0.0.1"
PORTA=10051
HOST=
CHAVE=
SAIDA="cpu"
NUMERO_REGISTROS=5

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
Script para obter informacoes de processos e envia-los
ao zabbix via zabbix_sender.

Uso: $0 [opção]
Versão: ${VERSAO}

Opção pode ser:
-d | --debug 		habilita o debug. Útil para averiguar erros
-h | --help 		exibe este texto de ajuda
[-z | --ip]=IP 		define o ip do servidor. Padrao eh 127.0.0.1
[-p | --port]=PORTA 	define a porta do servidor. Padrao eh 10051
[-s | --host]=HOST 	deine qual o nome do host que ira receber os dados
[-k | --key]=CHAVE 	define qual a chave no host
[-o | --output]=TIPO 	define qual valor vai ser enviado. Valores possiveis sao: memoria, cpu
[-n | --number]=CHAVE 	numero de registros a retornar. Padrao eh 5

Exemplo:
$0 --ip=192.168.10.1 --host=servidor --key=chave.trapper --output=cpu
"
}

function obtemTopProcessos {
	# contribuicao de Janssen dos Reis Lima
	# e http://unix.stackexchange.com/questions/13968/show-top-five-cpu-consuming-processes-with-ps
	cabecalho=$(ps aux | head -1)
	if [[ "$SAIDA" == "cpu" ]]; then
		retorno=$(ps aux | sort -nk 3 -r | head -n $NUMERO_REGISTROS)
		debugar "PS e outros terminaram com codigo \"$?\""
	elif [[ "$SAIDA" == "memoria" ]]; then
		retorno=$(ps aux | sort -nk 4 -r | head -n $NUMERO_REGISTROS )
		debugar "PS e outros terminaram com codigo \"$?\""
	else
		retorno=
	fi

	if [[ -z $retorno ]]; then
		echo $NAO_SUPORTADO
	else
		echo -e "Exibindo os $NUMERO_REGISTROS processos com maior uso de ${SAIDA}: \n${cabecalho}\n${retorno}"
	fi
}

function enviar {
	valor="$@"
	retorno=$($SENDER -z "$IP" -p "$PORTA" -s "$HOST" -k "$CHAVE" -o "$valor")
	debugar "ZABBIX_SENDER terminou com codigo \"$?\""

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
if [[ -z $SENDER || ! -x $SENDER ]]; then
	debugar "Erro: zabbix_sender nao encontrado ou nao eh executavel"
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
                -z=*|--ip=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
			IP=$p
                        debugar "Definindo $argumento para \"${p}\"";;
                -p=*|--port=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
			PORTA=$p
                        debugar "Definindo $argumento para \"${p}\"";;
                -s=*|--host=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
			HOST=$p
                        debugar "Definindo $argumento para \"${p}\"";;
                -k=*|--key=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
			CHAVE=$p
                        debugar "Definindo $argumento para \"${p}\"";;
                -o=*|--output=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
			SAIDA=$p
                        debugar "Definindo $argumento para \"${p}\"";;
                -n=*|--number=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
			NUMERO_REGISTROS=$p
                        debugar "Definindo $argumento para \"${p}\"";;
                *)
                        debugar "Parametros nao reconhecidos"
                        echo $NAO_SUPORTADO
                        exit 1;;
        esac
done

if [[ ! -z $HOST && ! -z $CHAVE ]]; then
	debugar "Obtendo os valores"
	valor=$(obtemTopProcessos)
	debugar "Executando zabbix_sender"
	enviar "$valor"
else
	debugar "O host e a chave precisam ser informados"
	echo $NAO_SUPORTADO
fi

exit 0

#EOF
