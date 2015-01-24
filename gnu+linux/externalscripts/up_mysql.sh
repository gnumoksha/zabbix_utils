#!/bin/bash
# Copyright (C) 2013, 2014 Tobias <contato@eutobias.org>
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

# Script para realizar tarefas com MySQL e
# retornar valores compreensiveis para o Zabbix.
# Licença: GPL v3
#
# 22/11/2013 Tobias  v0.1
# 26/11/2013 Tobias  v0.2
# 05/01/2014 Tobias  v0.3 adicionado suporte as funcoes mysql.status,
#			  mysql.size, mysql.ping, mysql.version
#			  para casos onde o parametro definido no arquivo de
#			  configuracao nao funciona
#
# Nota: para formatar e validar json:
# http://jsonformatter.curiousconcept.com/


##############################
#
#        VARIÁVEIS
#
##############################

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
DEBUG=0
VERSAO=0.3
MYSQL=$(which mysql 2>/dev/null)
# os locais de configuracao sao exibidos quando se executa o mysql --help
# Nao expanda os valores aqui (use ').
# O arquivo eh procurado primeiro no home para o local de procura poder ser
# definido pelo parametro deste script
LOCAIS_CONF=('~/.my.cnf' '/etc/mysql/my.cnf' '/etc/my.cnf')


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
Script para executar tarefas com MySQL.
É necessário que exista um arquivo de configuração do MySQL \
em algum dos seguintes locais: ${LOCAIS_CONF[@]}; ou utilize \
--set-home para apontar para o diretório onde está o arquivo my.cnf.
No arquivo de configuração deverão estar contidos os dados para \
conexão com o banco de dados, inclusive a senha.

Uso: $0 [opção]
Versão: ${VERSAO}

Opção pode ser:
-d | --debug 			habilita o debug. Útil para averiguar erros
-h | --help 			exibe este texto de ajuda
[-o | --set-home]=valor 	define o diretorio home, onde o arquivo .my.cnf estah
[-s | --status]=valor 		Retorna o valor de uma variavel global.
[-z | --size]=Valor 		Retorna o tamanho em bytes. Valor = [<database>,<table>,<type>]
-p | --ping 			Retorna 1 se o mysql estiver ativo. 0 se contrario
-v | --version 			Retorna a versao do mysql
-b | --lld-databases 		retorna, em json, a relação das bases de dados encontradas
-t | --lld-tables 		retorna, em jsom, a relação das bases e tabelas encontradas
"
}


function mysql_status {
	echo "show global status where Variable_name='$1';" | HOME=$bkp_home mysql -N | awk '{print $2}'
}


function mysql_size {
	parametros=$@
	DATABASE=$(echo $parametros | cut -d ',' -f 1)
	TABLE=$(echo $parametros | cut -d ',' -f 2)
	TYPE=$(echo $parametros | cut -d ',' -f 3)
	# Flexible parameter to determine database or table size. On the frontend side, use keys like mysql.size[zabbix,history,data].
	# Key syntax is mysql.size[<database>,<table>,<type>].
	# Database may be a database name or "all". Default is "all".
	# Table may be a table name or "all". Default is "all".
	# Type may be "data", "index", "free" or "both". Both is a sum of data and index. Default is "both".
	# Database is mandatory if a table is specified. Type may be specified always.
	# Returns value in bytes.
	# 'sum' on data_length or index_length alone needed when we are getting this information for whole database instead of a single table
	echo "select sum($(case "$TYPE" in both|"") echo "data_length+index_length";; data|index) echo "$TYPE_length";; free) echo "data_free";; esac)) from information_schema.tables$([[ "$DATABASE" = "all" || ! "$DATABASE" ]] || echo " where table_schema='$DATABASE'")$([[ "$TABLE" = "all" || ! "$TABLE" ]] || echo "and table_name='$TABLE'");" | HOME=$bkp_home mysql -N
	# " corrige bug de destaque de sintaxe no kate
}


# Retorna uma relacao, em json, das bases de dados encontradas
# no MySQL
function lld_databases {
	jsonInicial="{\"data\":["
	bancos=$(echo "SHOW databases" | HOME=$bkp_home $MYSQL --column-names=FALSE)
	debugar "MySQL terminou com codigo \"$?\""
	if [[ $? -ne 0 ]]; then
		echo NAO_SUPORTADO
		debugar "Erro ao consultar os bancos de dados"
		exit 2
        fi
	numeroBancos=$(echo $bancos | wc -w)
	if (($numeroBancos < 1)); then
		debugar "Nao foram encontrados banco de dados"
		echo $NAO_SUPORTADO
		return
	fi
	indiceBanco=0
	for banco in $bancos; do
		indiceBanco=$((indiceBanco+1))
		jsonBanco="$jsonBanco\n {\"{#DBNAME}\":\"$banco\"}"
		if (( $indiceBanco < $numeroBancos )); then
			jsonBanco="$jsonBanco,"
		fi
	done
	jsonFinal="]}"
	jsonResultado="${jsonInicial}${jsonBanco}\n${jsonFinal}\n"
	# printf para imprimir as quebras de linha
	# http://stackoverflow.com/questions/18535902/concatnating-two-string-variables-in-bash-appending-newline
	printf "$jsonResultado"
}


# Retorna uma relação, em json, das bases de dados e tabelas econtradas
# no MySQL
function lld_tables {
	jsonInicial="{\"data\":["
	bancos=$(echo "SHOW databases" | HOME=$bkp_home $MYSQL --column-names=FALSE)
	debugar "MySQL terminou com codigo \"$?\""
	if [[ $? -ne 0 ]]; then
		echo NAO_SUPORTADO
		debugar "Erro ao consultar os bancos de dados"
		exit 2
	fi
	numeroBancos=$(echo $bancos | wc -w)
	if (($numeroBancos < 1)); then
		debugar "Nao foram encontrados banco de dados"
		echo $NAO_SUPORTADO
		return
	fi
	indiceBanco=0
	for banco in $bancos; do
		indiceBanco=$((indiceBanco+1))
		tabelas=$(echo "SHOW tables FROM $banco" | HOME=$bkp_home $MYSQL --column-names=FALSE)
		if [[ $? -ne 0 ]]; then
			echo NAO_SUPORTADO
			debugar "Erro ao consultar tabelas para o banco \"$banco\""
			exit 3
		fi
		numeroTabelas=$(echo $tabelas | wc -w)
		indiceTabela=0
		if (( $numeroTabelas < 1 )); then
			debugar "O banco \"$banco\" nao contem tabelas"
			continue
		fi
		for tabela in $tabelas; do
			indiceTabela=$((indiceTabela+1))
			jsonBancoTabela="$jsonBancoTabela\n {\"{#DBNAME}\":\"$banco\",\"{#TBNAME}\":\"$tabela\"}"
			if (($indiceTabela < $numeroTabelas)); then
				jsonBancoTabela="$jsonBancoTabela,"
			fi
		done
		if (( $indiceBanco < $numeroBancos )); then
			jsonBancoTabela="$jsonBancoTabela,"
		fi
	done
	jsonFinal="]}"
	jsonResultado="${jsonInicial}${jsonBancoTabela}\n${jsonFinal}\n"
	# printf para imprimir as quebras de linha
	# http://stackoverflow.com/questions/18535902/concatnating-two-string-variables-in-bash-appending-newline
	printf "$jsonResultado"
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
for argumento in "$@"; do
	case $argumento in
	-h=*|--set-home=*)
		p="${argumento#*=}"
		bkp_home=$p
		if [[ -z $p ]]; then
			debugar "O parametro \"$argumento\" foi passado mas seu valor nao foi definido"
		else
			HOME=${p}
			debugar "Definindo HOME para \"${HOME}\""
		fi;;
	esac
done

# Estas verificações são feitas aqui para o caso do
# debug estar ativado
if [[ -z $MYSQL || ! -x $MYSQL ]]; then
	debugar "Erro: executavel mysql nao encontrado ou nao eh executavel"
	echo $NAO_SUPORTADO
	exit 1
fi
configuracaoEncontrada=0
for localConf in ${LOCAIS_CONF[@]}; do
	# Uso eval para expandir o ~
	# http://stackoverflow.com/questions/3963716/how-to-manually-expand-a-special-variable-ex-tilde-in-bash
	eval localConf=$localConf
	debugar "Checando se \"$localConf\" existe"
	if [ -f $localConf ]; then
		debugar "Arquivo de configuracao encontrado em \"$localConf\""
		configuracaoEncontrada=1
		break
	fi
done
if [[ $configuracaoEncontrada == 0 ]]; then
	debugar "Erro: nao foi encontrado um arquivo de \
	configuracao nos seguintes locais ${LOCAIS_CONF[@]}"
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
		-h=*|--set-home=*)
			;;
		-s=*|--status=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "O parametro \"$argumento\" foi passado mas seu valor nao foi definido"
				echo $NAO_SUPORTADO
				exit 1
			else
				mysql_status $p
				exit 0
			fi;;
		-z=*|--size=*)
			p="${argumento#*=}"
			if [[ -z $p ]]; then
				debugar "O parametro \"$argumento\" foi passado mas seu valor nao foi definido"
				echo $NAO_SUPORTADO
				exit 1
			else
				mysql_size $p
				exit 0
			fi;;
		-p|--ping)
			HOME=$bkp_home mysqladmin ping | grep -c alive && exit 0;;
		-v|--version)
			mysql -V && exit 0;;
		-b|--lld-databases)
			debugar "Realizando LLD para os bancos de dados"
			lld_databases
			exit 0;;
		-t|--lld-tables)
			debugar "Relizando LLd para as tabelas"
			lld_tables
			exit 0;;
		*)
			debugar "Parametros nao reconhecidos"
			echo $NAO_SUPORTADO
			exit 1;;
	esac
done

exit 0

#EOF
