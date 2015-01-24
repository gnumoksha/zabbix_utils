#!/bin/bash

# http://zabbixbrasil.org/wiki/tiki-index.php?page=Envio+de+alertas+por+e-mail+utilizando+SMTP+autenticado

comando=$(which mail) # /bin/mail
emailRemetente='tobias@certalogistica.com.br'
emailDestinatario=${1}
assuntoEmail=${2}
corpoEmail=${3}

echo "$corpoEmail" | $comando -r "$emailRemetente" -s "$assuntoEmail" "$emailDestinatario"

