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


##############################
#
#		VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.1
FPING=$(which fping 2>/dev/null)
destino="google.com"
interface=

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
Script para testar conectivade de internet.
Verifique se o timeout no agent e servidor estao em, pelo menos, 10 segundos.

Versão: ${VERSAO}

Uso: $0 [opção]

Opção pode ser:
-d | --debug					habilita o debug. Útil para averiguar erros
-h | --help						exibe este texto de ajuda
[-d | --destination]=valor		define o site que vai ser consultado
[-i | --interface]=valor		define a interface a ser utilizada
"
}


function executaPing {
	if [[ -z $interface ]]; then
		retorno=$($FPING -c 4 -r 3 -q $destino 2>/dev/null)
	else
		retorno=$($FPING -c 4 -r 3 -q -I ${interface} $destino 2>/dev/null)
	fi
	codigoRetorno=$?
	debugar "FPING retornou o codigo \"$codigoRetorno\""
	if [[ $codigoRetorno -ne 0 ]]; then
		echo 0
	else
		echo 1
	fi
}


##############################
#
#		CHECAGENS
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
								debugar "Definindo site a resolver o ip externo para \"${destino}\""
						fi;;
				-i=*|--interface=*)
						p="${argumento#*=}"
						if [[ -z $p ]]; then
								debugar "Valor para $argumento nao foi especificado. Utilizando vazio."
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

debugar "Pingando site \"${destino}\" usando a interface \"${interface}\"."
executaPing

exit 0

#EOF
