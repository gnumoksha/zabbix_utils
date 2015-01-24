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
# Script para obter dados do software sensors
# #TODO obter valor de voltagens
#
# 26/11/13 Tobias v0.2
# 02/12/13 Tobias v0.3 incluido obtemValorPorFan
# removido -q dos grep


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.3
SENSORS=$(which sensors 2>/dev/null)


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
Script para extrair dados do programa sensors.
É necessário executar o sensors-detect e seguir as instruções.

Uso: $0 [opção]
Versão: ${VERSAO}

Opção pode ser:
-d | --debug 		habilita o debug. Útil para averiguar erros
-h | --help 		exibe este texto de ajuda
[-c | --core]=numero 	retorna a temperatura filtrando por core
[-t | --temp]=numero 	retorna a temperatura filtrando por temp
[-f | --fan]=numero 	retorna a rotação do fan
"
}


function obtemValorPorTemp {
	# Exemplo de saida
	# w83627dhg-isa-0290
	#Adapter: ISA adapter
	#Vcore:        +1.27 V  (min =  +0.00 V, max =  +2.04 V)
	#in1:          +0.94 V  (min =  +0.00 V, max =  +2.04 V)
	#A#VCC:         +3.18 V  (min =  +2.98 V, max =  +3.63 V)
	#+3.3V:        +3.17 V  (min =  +2.98 V, max =  +3.63 V)
	#in4:          +1.65 V  (min =  +0.00 V, max =  +2.04 V)
	#in5:          +1.54 V  (min =  +0.07 V, max =  +0.35 V)  ALARM
	#in6:          +1.85 V  (min =  +0.30 V, max =  +0.29 V)  ALARM
	#3VSB:         +3.18 V  (min =  +2.98 V, max =  +3.63 V)
	#Vbat:         +3.18 V  (min =  +2.70 V, max =  +3.63 V)
	#fan1:           0 RPM  (min =    0 RPM, div = 128)
	#fan2:        1562 RPM  (min =    0 RPM, div = 16)
	#fan3:           0 RPM  (min =    0 RPM, div = 128)
	#fan4:           0 RPM  (min = 10546 RPM, div = 128)  ALARM
	#fan5:           0 RPM  (min = 10546 RPM, div = 128)  ALARM
	#temp1:        +39.0°C  (high = +127.0°C, hyst = +127.0°C)  sensor = thermistor
	#temp2:        +30.5°C  (high = +127.0°C, hyst = +127.0°C)  sensor = CPU diode
	#temp3:         +7.5°C  (high = +127.0°C, hyst = +127.0°C)  sensor = thermistor
	#cpu0_vid:    +1.088 V
	#intrusion0:  ALARM
	retorno=$($SENSORS | grep -i "temp${1}" | awk '{print $2}'|  sed -e 's/[^0-9\.]//g')
	debugar "SENSORS terminou com codigo \"$?\""
	if [[ -z $retorno ]]; then
		echo $NAO_SUPORTADO
	else
		echo $retorno
	fi
}


function obtemValorPorFan {
	# Exemplo de saida
	# w83627dhg-isa-0290
	#Adapter: ISA adapter
	#Vcore:        +1.27 V  (min =  +0.00 V, max =  +2.04 V)
	#in1:          +0.94 V  (min =  +0.00 V, max =  +2.04 V)
	#A#VCC:         +3.18 V  (min =  +2.98 V, max =  +3.63 V)
	#+3.3V:        +3.17 V  (min =  +2.98 V, max =  +3.63 V)
	#in4:          +1.65 V  (min =  +0.00 V, max =  +2.04 V)
	#in5:          +1.54 V  (min =  +0.07 V, max =  +0.35 V)  ALARM
	#in6:          +1.85 V  (min =  +0.30 V, max =  +0.29 V)  ALARM
	#3VSB:         +3.18 V  (min =  +2.98 V, max =  +3.63 V)
	#Vbat:         +3.18 V  (min =  +2.70 V, max =  +3.63 V)
	#fan1:           0 RPM  (min =    0 RPM, div = 128)
	#fan2:        1562 RPM  (min =    0 RPM, div = 16)
	#fan3:           0 RPM  (min =    0 RPM, div = 128)
	#fan4:           0 RPM  (min = 10546 RPM, div = 128)  ALARM
	#fan5:           0 RPM  (min = 10546 RPM, div = 128)  ALARM
	#temp1:        +39.0°C  (high = +127.0°C, hyst = +127.0°C)  sensor = thermistor
	#temp2:        +30.5°C  (high = +127.0°C, hyst = +127.0°C)  sensor = CPU diode
	#temp3:         +7.5°C  (high = +127.0°C, hyst = +127.0°C)  sensor = thermistor
	#cpu0_vid:    +1.088 V
	#intrusion0:  ALARM
	retorno=$($SENSORS | grep -i "fan${1}" | awk '{print $2}')
	debugar "SENSORS terminou com codigo \"$?\""
	if [[ -z $retorno ]]; then
		echo $NAO_SUPORTADO
	else
		echo $retorno
	fi
}


function obtemValorPorCore {
	# Exemplo de saida
	# coretemp-isa-0000
	# Adapter: ISA adapter
	# Core 0:      +30.0°C  (high = +83.0°C, crit = +99.0°C)
	# Core 1:      +28.0°C  (high = +83.0°C, crit = +99.0°C)
	# Core 2:      +30.0°C  (high = +83.0°C, crit = +99.0°C)
	# Core 3:      +28.0°C  (high = +83.0°C, crit = +99.0°C)
	retorno=$($SENSORS | grep -i "Core ${1}" | awk '{printf $3}' | sed -e 's/[^0-9\.]//g')
	debugar "SENSORS terminou com codigo \"$?\""
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
if [[ -z $SENSORS || ! -x $SENSORS ]]; then
	debugar "Erro: software sensors nao encontrado ou nao eh executavel"
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
                -c=*|--core=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "Valor para $argumento nao foi especificado"
				echo $NAO_SUPORTADO
				exit 1
			fi
                        debugar "Filtrando por core com a string \"${p}\""
                        obtemValorPorCore "${p}"
                        exit 0;;
		-t=*|--temp=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado"
                                echo $NAO_SUPORTADO
                                exit 1
                        fi
                        debugar "Filtrando por temp com a string \"${p}\""
                        obtemValorPorTemp "${p}"
                        exit 0;;
		-f=*|--fan=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
                                debugar "Valor para $argumento nao foi especificado"
                                echo $NAO_SUPORTADO
                                exit 1
                        fi
                        debugar "Filtrando por fan com a string \"${p}\""
                        obtemValorPorFan "${p}"
                        exit 0;;


                *)
                        debugar "Parametros nao reconhecidos"
                        echo $NAO_SUPORTADO
                        exit 1;;
        esac
done

exit 0

#EOF
