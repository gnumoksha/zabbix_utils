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
# Script para retornar temperatura do termometro USB comprado na DX
#
# 27/11/2013 Tobias v0.2


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.2
PCSENSOR=/usr/local/bin/pcsensor


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
Script para retornar a temperatura vinda de um termometro usb.
Versão: ${VERSAO}

Uso: $0 [opção]

Opção pode ser:
-d | --debug                    habilita o debug. Útil para averiguar erros
-h | --help                     exibe este texto de ajuda
"
}


function obtemTemperatura {
	retorno=$($PCSENSOR -c -m 2>/dev/null)
	debugar "PCSENSOR terminou com o codigo \"$?\""
	retornoFiltrado=$(echo "${retorno}" | head -1 | sed 's/[^0-9\.]//g')
	if [[ -z $retornoFiltrado ]]; then
		echo $NAO_SUPORTADO
		exit 1
	else
		echo $retornoFiltrado
	fi
}


##############################
#
#        CHECAGENS
#
##############################

# Nenhum parametro especificado
#if [[ $# < 1 ]]; then
#        echo $NAO_SUPORTADO
#        exit 1
#fi

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
if [[ -z $PCSENSOR || ! -x $PCSENSOR ]]; then
        debugar "Erro: comando pcsensor nao encontrado ou nao eh executavel"
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
		*)
                        debugar "Parametros nao reconhecidos"
                        echo $NAO_SUPORTADO
                        exit 1;;
        esac
done

debugar "Obtendo temperatura"
obtemTemperatura

exit 0

#EOF
