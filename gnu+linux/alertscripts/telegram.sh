#!/bin/bash
# 27/01/15 Tobias v0.1

MAIN_DIRECTORY="$dir_alertscripts/dist/telegram"
# Is better use: user#user_id. For example: user#141213
USER=$1
SUBJECT=$2
TEXT=$3

cd $MAIN_DIRECTORY
if [[ $? -ne 0 ]]; then
	echo "Error to enter the main directory"
	exit 1
fi

# o comando broadcast envia mensagem para varios usuarios
#
# funciona sem o -WR, mas acredito que deva-se ao fato de estar utilizando o
# ID do usuario. Não funcionou usando nome
# https://github.com/vysheng/tg/issues/48
./telegram-cli -k tg-server.pub -c telegram.config -WR -e "msg $USER $SUBJECT"
#
# Não funcionou usando nome
#echo "dialog_list
#"msg user#USERID testando${RANDOM}"
#safe_quit" | ./bin/telegram-cli -k server.pub
#
# https://github.com/vysheng/tg/issues/46
# http://coldbeer.blogspot.com.br/2014/02/enviar-telegram-linea-comandos.html
# Usando metodos com -W retorna o erro:
# [warn] Epoll ADD(1) on fd 0 failed.  Old events were 0; read change was 1 (add); write change was 0 (none): Operation not permitted
#
# echo "msg user#12345 testando${RANDOM}" | ./bin/telegram-cli

#EOF