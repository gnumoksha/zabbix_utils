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
# Script para obter temperatura de um HD
#
# 26/11/13 Tobias v0.2
#
# Usar hddtemp com sudo ou rodando como um serviço
# https://bbs.archlinux.org/viewtopic.php?id=74927


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.2
#HDDTEMP=$(which hddtemp 2>/dev/null)
HDDTEMP="/usr/sbin/hddtemp"


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
Script para retornar a temperatura de um HD.
Versão ${VERSAO}

Uso: $0 [opção]

Opção pode ser:
-d | --debug 			habilita o debug. Útil para averiguar erros
-h | --help 			exibe este texto de ajuda
-s | --sudo 			executa o hddtemp com sudo
[-h | --hd]=valor 		retorna a temperatura filtrando por HD
[-f | --file-system]=valor 	retorna a temperatura filtrando por sistema de arquivos
"
}


function obtemValorPorFS {
	# A ideia de utilizar o mount veio do zadiskio.sh v1 criado por Adail Horst
	# O hddtemp pode receber um dispositivo LVM tambem
	dispositivoOrigem=$(mount | grep -i "$1" | cut -d ' ' -f 1);
	retorno=$($HDDTEMP $dispositivoOrigem | cut -f 3 -d ':' | sed -e 's/[^0-9]*//gi')
	debugar "HDDTEMP terminou com codigo \"$?\""
	if [[ -z $retorno ]]; then
		echo $NAO_SUPORTADO
	else
		echo $retorno
	fi
}


function obtemValorPorHD {
	retorno=$($HDDTEMP $1 | cut -f 3 -d ':' | sed -e 's/[^0-9]*//gi')
	debugar "HDDTEMP terminou com codigo \"$?\""
        if [[ -z $retorno ]]; then
                echo $NAO_SUPORTADO
        else
                echo $retorno
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
if [[ -z $HDDTEMP || ! -x $HDDTEMP ]]; then
        debugar "Erro: software hddtemp nao encontrado ou nao eh executavel"
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
		-s|--sudo)
			debugar "Uso do sudo foi ativado"
			HDDTEMP="sudo ${HDDTEMP}";;
                -h=*|--hd=*)
                        p="${argumento#*=}"
                        if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado"
                                echo $NAO_SUPORTADO
                                exit 1
                        fi
			debugar "Obtendo valor atraves do hd \"${p}\""
                        obtemValorPorHD "${p}"
                        exit 0;;
		-f=*|--file-system=*)
                        p="${argumento#*=}"
                        if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado"
                                echo $NAO_SUPORTADO
                                exit 1
                        fi
			debugar "Obtendo valor atraves do file system \"${p}\""
                        obtemValorPorFS "${p}"
                        exit 0;;

                *)
                        debugar "Parametros nao reconhecidos"
                        echo $NAO_SUPORTADO
                        exit 1;;
        esac
done

exit 0

#EOF
