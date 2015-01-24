#!/bin/bash
# Copyright (C) 2015 Tobias <contato@eutobias.org>
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
#
# 23/01/2015 Tobias v0.1


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.1
SENDER=$(which zabbix_sender 2>/dev/null) # /usr/bin/zabbix_sender
IP="127.0.0.1"
PORTA=10051
HOST=$(hostname)
PYTHON=$(which python 2>/dev/null) # /usr/bin/python
SPEEDTEST="$(dirname $0)/dist/speedtest-cli/speedtest_cli.py"
ARQUIVO_CONFIG=

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
                printf "$@\n"
                CONTEUDO_DEBUG="${CONTEUDO_DEBUG}$@\n"
        fi
}


# Exibe o texto de ajuda deste script
function ajuda {
        echo "
Script para obter a velocidade de download e envia-la
ao zabbix via zabbix_sender.

Uso: $0 [opção]
Versão: ${VERSAO}

Opção pode ser:
-d | --debug 		habilita o debug. Útil para averiguar erros
-h | --help 		exibe este texto de ajuda
[-z | --ip]=IP 		define o ip do servidor. Padrao eh 127.0.0.1
[-p | --port]=PORTA 	define a porta do servidor. Padrao eh 10051
[-s | --host]=HOST 	deine qual o nome do host que ira enviar os dados.
			Padrao eh $(hostname)
[-c | --config=ARQUIVO	define o caminho completo para o arquivo de configuracao.
			Certifique-se de preencher corretamente os valores de
			ServerActive e Hostname

Exemplo:
$0 --config=/etc/zabbix/zabbix_agentd.conf
$0 --ip=192.168.10.1 --host=$(hostname)
"
}

function obtemValores {
	debugar "Obtendo os valores"
	
	retorno=$($PYTHON $SPEEDTEST --simple 2>&1)
	debugar "Speedtest-cli terminou com o codigo \"$?\" e a saida \"$retorno\""
	
	valorPing=$(echo $retorno | sed -rn 's/.*Ping: ([0-9.]*).*/\1/p')
	valorDownload=$(echo $retorno | sed -rn 's/.*Download: ([0-9.]*).*/\1/p')
	valorUpload=$(echo $retorno | sed -rn 's/.*Upload: ([0-9.]*).*/\1/p')
	debugar "Os valores obtidos são: \"$valorPing\", \"$valorDownload\", \"$valorUpload\""
	
	if [[ -z $valorPing || -z $valorDownload || -z $valorUpload ]]; then
		debugar "Um ou mais valores estao vazios"
		echo $NAO_SUPORTADO
		exit 1
	else
		if [[ ! -z $HOST || ! -z $ARQUIVO_CONFIG ]]; then
			h="-"
		else
			# improvavel que isso aconteça
			# o usuário teria que setar nada em host
			h=$(hostname)
		fi
		valorEnviar="$h up.speedtest.ping $valorPing
		$h up.speedtest.download $valorDownload
		$h up.speedtest.upload $valorUpload"
		debugar "Valor a ser enviado eh \"${valorEnviar}\""
	fi
	
	# faz o envio das informacoes
	if [[ ! -z $ARQUIVO_CONFIG ]]; then
		cmd_sender="$SENDER -vv -c $ARQUIVO_CONFIG -i -"
	else
		cmd_sender="$SENDER -vv -z $IP -p $PORTA -s $HOST -i -"
	fi
	debugar "Executando zabbix_sender: \"$cmd_sender\""
	retorno=$(echo "$valorEnviar" | $cmd_sender 2>&1)
	debugar "ZABBIX_SENDER terminou com codigo \"$?\" e a saida \"$retorno\""
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

if [[ -z $PYTHON || ! -x $PYTHON ]]; then
        debugar "Erro: comando python nao encontrado ou nao eh executavel"
        echo $NAO_SUPORTADO
        exit 1
fi

if [[ -z $SPEEDTEST || ! -f $SPEEDTEST ]]; then
        debugar "Erro: comando speedtest-cli nao encontrado"
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
                        debugar "Definindo IP para \"${p}\"";;
                -p=*|--port=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
			PORTA=$p
			debugar "Definindo Port para \"${p}\"";;
                -s=*|--host=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
			HOST=$p
			debugar "Definindo Host para \"${p}\"";;
		-c=*|--config=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado."
			else
				ARQUIVO_CONFIG=${p}
				debugar "Definindo arquivo de configuracao para \"${ARQUIVO_CONFIG}\""
			fi;;
                *)
                        debugar "Parametros nao reconhecidos"
                        echo $NAO_SUPORTADO
                        exit 1;;
        esac
done

obtemValores

exit 0

#EOF