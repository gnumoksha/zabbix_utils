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
# Script para obter o ip externo, na internet
#
# 29/04/2014 Tobias v0.1


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.1
CURL=$(which curl 2>/dev/null)
siteObtemIP='ip.appspot.com'
#siteObtemIP='myip.opendns.com'
interface=

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
Script para retornar o ip público na internet usando CURL.
Versão: ${VERSAO}

Uso: $0 [opção]

Opção pode ser:
-d | --debug                    habilita o debug. Útil para averiguar erros
-h | --help                     exibe este texto de ajuda
[-o | --origin]=valor           define o site que vai retornar o ip
[-i | --interface]=valor        define a interface utilizada para consulta
"
}


function obtemIP {
	opcaoInterface=
	if [[ ! -z $interface ]]; then
		opcaoInterface="--interface $interface"
	fi
	retorno=$($CURL $opcaoInterface ${siteObtemIP} 2>/dev/null)
	debugar "CURL retornou o codigo \"$?\""
	# sed com regex para filtrar ip
	# http://www.commandlinefu.com/commands/view/5669/extract-ip-addresses-with-sed
	retornoFiltrado=$(echo "${retorno}" | sed -n  's/\([0-9]\{1,3\}\.\)\{3\}[0-9]\{1,3\}/\nip&\n/gp' | grep ip | sed 's/ip//')
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
if [[ -z $CURL || ! -x $CURL ]]; then
        debugar "Erro: software CURL nao encontrado ou nao eh executavel"
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
                -o=*|--origin=*)
                        p="${argumento#*=}"
                        if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado. Utilizando valor padrao."
                        else
                                siteObtemIP=${p}
                                debugar "Definindo site a resolver o ip externo para \"${siteObtemIP}\""
                        fi;;
		-i=*|--interface=*)
                        p="${argumento#*=}"
                        if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado. Utilizando valor padrao."
                        else
                                interface=${p}
                                debugar "Definindo interface para \"${interface}\""
                        fi;;
		*)
			debugar "Parametros nao reconhecidos"
			echo $NAO_SUPORTADO
			exit 1;;

        esac
done

debugar "Obtendo ip externo atraves do site \"${siteObtemIP}\"."
obtemIP

exit 0

#EOF
