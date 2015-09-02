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
# 18/08/14 Tobias v0.1


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.1
CURL=$(which curl 2>/dev/null)
siteAcessar='google.com.br'
versaoIP=4
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
Script para testar conectivade de internet.
Verifique se o timeout no agent e servidor estao em, pelo menos, 10 segundos.

Versão: ${VERSAO}

Uso: $0 [opção]

Opção pode ser:
-d | --debug                    habilita o debug. Útil para averiguar erros
-h | --help                     exibe este texto de ajuda
[-o | --origin]=valor           define o site que vai ser consultado
[-i | --interface]=valor        define a interface a ser utilizada
[-v | --ip-version]=valor 	define a versão do protocolo ip. 4 ou 6. 4 é padrão
"
}


function obtemIP {
	if [[ -z $interface ]]; then
		retorno=$($CURL --connect-timeout 5 --fail --insecure -${versaoIP} --location  $siteAcessar 2>/dev/null)
	else
		retorno=$($CURL --connect-timeout 5 --fail --insecure --interface ${interface} -${versaoIP} --location  $siteAcessar 2>/dev/null)
	fi
	debugar "CURL retornou o codigo \"$?\""
	retornoFiltrado=$(echo "${retorno}" | grep -i html )
	if [[ -z $retornoFiltrado ]]; then
		echo 0
	else
		echo 1
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
        debugar "Erro: software curl nao encontrado ou nao eh executavel"
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
                                siteAcessar=${p}
                                debugar "Definindo site a resolver o ip externo para \"${siteAcessar}\""
                        fi;;
                -i=*|--interface=*)
                        p="${argumento#*=}"
                        if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado. Utilizando valor padrao."
                        else
                                interface=${p}
                                debugar "Definindo interface para \"${interface}\""
                        fi;;
		-v=*|--ip-version=*)
			p="${argumento#*=}"
                        if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado. Utilizando valor padrao."
                        else
                                versaoIP=${p}
				debugar "Definindo versao do ip para \"${versaoIP}\""
                        fi;;
                        *)
                        debugar "Parametros nao reconhecidos"
                        echo $NAO_SUPORTADO
                        exit 1;;
        esac
done

debugar "Acessando site \"${siteAcessar}\" usando a interface \"${interface}\" e ip versao ${versaoIP}."
obtemIP

exit 0

#EOF
