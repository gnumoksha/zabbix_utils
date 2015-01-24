#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
Copyright (C) 2013 Tobias <contato@eutobias.org>

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License, or
any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.If not, see <http://www.gnu.org/licenses/>.
"""

import sys, getopt, platform, os, subprocess, re, ast, json

NAO_SUPORTADO="ZBX_NOTSUPPORTED"
debugAtivo = False

def uso():
	print os.linesep + sys.argv[0] + ":" + os.linesep + os.linesep + "\
	-h | --help 			exibe este menu de ajuda" + os.linesep + "\
	-d | --debug 			exibe mensagens de debug (util para averiguar erros)" + os.linesep + "\
	-a | --all 			exibe todas os resultados" + os.linesep + "\
	-f | --filter chave=valor	exibe somente os resultados onde 'chave' for igual a 'valor'. Deixe 'valor' em \
branco para retornar apenas registros onde 'valor' nao for nulo " + os.linesep + "\
	-l | --lld 			retorna uma lista, em json, de todas as informacoes" + os.linesep + "\
	     --lld-hd 			retorna uma lista, em json, de todos os HDs encontrados (util para usar em LLD)" + os.linesep + "\
	"


def debug(mensagem, forcarDebug = False):
	#global debugAtivo
	if (debugAtivo == True or forcarDebug == True):
		print mensagem


def checaValor(valor):
	if not valor:
		print NAO_SUPORTADO
	else:
		return valor


def lsblk(adicional = ""):
	# http://unix.stackexchange.com/questions/49786/finding-all-storage-devices-attached-to-a-linux-machine
	comandoInfoDisco="lsblk --fs --ascii --output NAME,KNAME,LABEL,UUID,MODEL,SIZE,STATE,OWNER,MODE,TYPE --pairs "+adicional+" 2> /dev/null"
	"""Exemplo de saida:
	NAME="sda" KNAME="sda" LABEL="" UUID="" MODEL="SAMSUNG HD080HJ " SIZE="74,4G" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="disk"
	NAME="sda1" KNAME="sda1" LABEL="" UUID="672q38a9-46e4-3q42-98b5-6q297cc9da43" MODEL="" SIZE="476M" STATE="" OWNER="root" MODE="brw-rw---T" TYPE="part"
	NAME="sda2" KNAME="sda2" LABEL="" UUID="" MODEL="" SIZE="1K" STATE="" OWNER="root" MODE="brw-rw---T" TYPE="part"
	NAME="sda5" KNAME="sda5" LABEL="" UUID="672q38a9-46e4-3q42-98b5-6q297c6q3a43" MODEL="" SIZE="74G" STATE="" OWNER="root" MODE="brw-rw---T" TYPE="part"
	NAME="host-barra (dm-0)" KNAME="dm-0" LABEL="" UUID="672q38a9-46e4-3q42-98b5-6q297cc9da69" MODEL="" SIZE="4,7G" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="lvm"
	NAME="host-swap (dm-1)" KNAME="dm-1" LABEL="" UUID="672q38a9-46e4-3q42-98b5-6q297cc9ds36" MODEL="" SIZE="1,9G" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="lvm"
	NAME="host-temp (dm-2)" KNAME="dm-2" LABEL="" UUID="672q38a9-46e4-3q42-98b5-6q297cq63a43" MODEL="" SIZE="952M" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="lvm"
	NAME="host-var (dm-3)" KNAME="dm-3" LABEL="" UUID="672q38a9-46e4-3q42-98b5-6q297cc9q633" MODEL="" SIZE="29,3G" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="lvm"
	NAME="host-home (dm-4)" KNAME="dm-4" LABEL="" UUID="672q38a9-46e4-3q42-98b5-6q297ccq3643" MODEL="" SIZE="1,9G" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="lvm"
	NAME="host-drbd0 (dm-5)" KNAME="dm-5" LABEL="" UUID="512fq12q3903q629" MODEL="" SIZE="5G" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="lvm"
	NAME="sr0" KNAME="sr0" LABEL="" UUID="" MODEL="DVDRAM GSA-H44N " SIZE="1024M" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="rom"
	NAME="sr1" KNAME="sr1" LABEL="VIVO INTERNET" UUID="" MODEL="Mass Storage    " SIZE="128M" STATE="running" OWNER="root" MODE="brw-rw---T" TYPE="rom"
	"""
	# http://docs.python.org/2/library/subprocess.html
	retornoInfoDisco = subprocess.Popen(comandoInfoDisco, shell=True, stdout=subprocess.PIPE)
	saidaInfoDisco, saidaErroInfoDisco = retornoInfoDisco.communicate()
	if ( retornoInfoDisco.returncode != 0 ):
		debug("Comando terminou com status " + str(retornoInfoDisco.returncode) + ". Comando: " + comandoInfoDisco)
		print NAO_SUPORTADO
		sys.exit(4)
	return saidaInfoDisco


# Transforma string em dicionario
def lsblkParaDicionario(string):
	saidaInfoDisco = string
	resultadoInfoDisco={}
	indiceResultado=0
	# para cada linha
	for t0 in saidaInfoDisco.split('\n'):
		# NAME="sda" KNAME="sda" ... para NAME="sda", KNAME="sda" ...
		t1 = t0.replace('" ','", ')
		# NAME="sda" KNAME="sda" ... para NAME:"sda", KNAME:"sda" ...
		t2 = t1.replace('=',':')
		# NAME="sda" KNAME="sda" ... para "NAME":"sda", "KNAME":"sda" ...
		t3 = re.sub(r'([a-zA-Z]*):', r'"\1":',t2)
		# NAME="sda" KNAME="sda" ... para {"NAME":"sda", "KNAME":"sda" ...}
		t4 = re.sub(r'(.*)', r'{\1}', t3)
		# string para dicionario
		# http://stackoverflow.com/questions/988228/converting-a-string-to-dictionary
		t5 = ast.literal_eval(t4)
		resultadoInfoDisco[indiceResultado] = t5
		indiceResultado = indiceResultado + 1
	return resultadoInfoDisco


# Transforma dicionario em json para o Zabbix
# http://docs.python.org/2/library/json.html
def dicionarioParaJsonZabbix(dicionario):
	# Exemplo retornado pelo item vfs.fs.discovery do zabbix
	"""
	{
		"data":[
			 {
				"{#FSNAME}":"\/",
				"{#FSTYPE}":"rootfs"},
			 {
				"{#FSNAME}":"\/dev",
				"{#FSTYPE}":"devtmpfs"},
			 {
				"{#FSNAME}":"\/sys\/fs\/fuse\/connections",
				"{#FSTYPE}":"fusectl"}]}
	"""
	resultado = []
	for chave, valor in dicionario.items():
		# ignora chaves vazias
		if not valor:
			continue
		novoValor = {}
		for chave2, valor2 in valor.items():
			# a chave ficara no formato {#CHAVE}
			chave2 = re.sub(r'(.*)',r'{#\1}',chave2)
			novoValor[chave2] = valor2
		resultado.append(novoValor)
	# acrescento o "modelo" de como o json deve iniciar
	resultado = { 'data' : resultado }
	return json.dumps(resultado, sort_keys=True, indent=4, separators=(',', ': '))


def main():
	if len(sys.argv) < 2:
		uso()
		sys.exit(2)
	
	# http://docs.python.org/release/2.4.1/lib/module-getopt.html
	try:
		listaOpcoes, argumentosAdicionais = getopt.getopt(sys.argv[1:],"hdafl",["help","debug","all","filter","lld","lld-hd"])
	except getopt.GetoptError:
		uso()
		#debug("Erro nos argumentos")
		sys.exit(2)
	
	if platform.system() != "Linux":
		debug("Sistema operacional nao suportado")
		print NAO_SUPORTADO
		sys.exit(3)

	for opcoesNome, opcoesValor in listaOpcoes:
		if opcoesNome in ("-h", "--help"):
			uso()
			sys.exit(2)
		if opcoesNome in ("-d", "--debug"):
			global debugAtivo
			debugAtivo = True
			debug("Debug ativado")
		if opcoesNome in ("-a", "--all"):
			#FIXME nao funciona
			debug("Listando tudo")
			print lsblk()
			sys.exit(0)
		if opcoesNome in ("-l", "--lld"):
			debug("Listando todas as informacoes em json")
			print checaValor(dicionarioParaJsonZabbix(lsblkParaDicionario(lsblk())))
			sys.exit(0)
		if opcoesNome == "--lld-hd":
			debug("Listando informacoes dos HDs em json")
			print checaValor(dicionarioParaJsonZabbix(lsblkParaDicionario(lsblk('| grep \'TYPE="disk"\''))))
			sys.exit(0)


if __name__ == "__main__":
	main()

#EOF
