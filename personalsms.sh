#!/bin/bash
#=================
#personalsms.sh ||
#=================
#Este script permite enviar mensajes a celulares Personal, y los datos pueden ser ingresados tanto 
#con un asistente como con parametros. Crea un alias en .bashrc y se descarga a si mismo a una carpeta
#oculta dentro de la home para asi poder ejecutarse siempre escribiendo el comando 'personalsms' sin 
#necesidad de correr el script.
#Proximamente UI con agenda de contactos.
#-------------------------------------------------------------------------------------------------------
#Autor: Grego D. - grego.dadone@gmail.com
#Basado en el script de wetsa@taringa.net.
#-------------------------------------------------------------------------------------------------------

#Instalando script en el sistema y creando alias
if ! [ -d $HOME/.personalsms ]; then
	mkdir -p $HOME/.personalsms
fi
if ! [ -e $HOME/.personalsms/personalsms.sh ]; then
	echo 'parece que es la primera vez que ejecuta personalsms. A partir de ahora podra usar personalsms sin necesidad de correr el script, simplemente escribiendo "personalsms" en su terminal'
	echo ''
	wget -q http://dl.dropbox.com/u/70317638/personalsms.sh -O $HOME/.personalsms/personalsms.sh
	echo 'alias personalsms="$HOME/.personalsms/./personalsms.sh"' >> $HOME/.bashrc
	chmod +x $HOME/.personalsms/personalsms.sh
fi
alias personalsms="$HOME/.personalsms/./personalsms.sh"

#Variables que voy a usar como constantes
URL="http://sms2.personal.com.ar/Mensajes/sms.php"
#URL="http://sms.personal.com.ar/Mensajes/sms.php"

#Mensaje de advertencia en caso de haber parametros de mas o de menos
if [ $# -eq 1 ] || [ $# -eq 2 ] || [ $# -ge 4 ]; then
  echo ''
  echo 'La forma de usar parametros es personalsms "NOMBRE" NUMERO-SIN-0-NI-15 "Mensaje entre comillas"'
  echo ''
  exit
else
  nombre=$1
  numero=$2
  mensaje=$3
fi

function verificar_parametros {
  if [[ $nombre = '' ]] || [[ $numero = '' ]] || [[ $mensaje = '' ]]; then
     obtener_nombre
     obtener_numero
     obtener_mensaje
  else
     echo ''
     if [ ${#nombre} -gt 30 ]; then
       echo 'El nombre no puede superar los 30 caracteres!'
       nombre=''
       obtener_nombre
     fi
     if [[ $(echo $numero|egrep '\b[0-9]{10}\b') = '' ]]; then
       echo 'El numero ingresado es incorrecto. Debe ingresar el numero sin 0 ni 15. Ejemplo 1145674321'
       numero=''
       obtener_numero
     else
       if [ ${numero:0:2} -eq 11 ]; then
		 codarea=11
		 cel=${numero:2}
	   else
		 codarea=${numero:0:4}
		 cel=${numero:4}
	   fi
	 fi
     if [ `expr ${#nombre} + ${#mensaje}` -gt 110 ]; then
       echo 'Entre el nombre y el mensaje superan los 110 caracteres!'
       echo ''
       mensaje=''
       obtener_mensaje
     fi
  fi
}
function obtener_nombre {
until [ ${#nombre} -gt 0 ] && [ ${#nombre} -le 30 ]; do
  echo 'Ingresá tu nombre:'
  read nombre
  if [ ${#nombre} -gt 30 ]; then
    echo ''
    echo 'El nombre no puede superar los 30 caracteres!!'
  fi
  echo ''
done
}
function obtener_numero {
until [ ${#numero} -eq 10 ]; do
  echo 'Ingresá número destino sin 0 ni 15: (Ejemplo 3624567351)'
  read numero
  numero=$(echo $numero|egrep '\b[0-9]{10}\b')
  if [ ${#numero} -eq 0 ]; then
    echo ''
    echo 'El número ingresado no es valido!'
  else
    if [ ${numero:0:2} -eq 11 ]; then
      codarea=11
      cel=${numero:2}
    else
      codarea=${numero:0:4}
      cel=${numero:4}
    fi
  fi
  echo ''
done
}
function obtener_mensaje {
while [ `expr ${#nombre} + ${#mensaje}` -gt 110 ] || [ ${#mensaje} -eq 0 ]; do
  echo 'Ingresá el mensaje a enviar:'
  read mensaje
  if [ `expr ${#nombre} + ${#mensaje}` -gt 110 ]; then
    echo ''
    echo 'Entre el mensaje y el nombre superan los 110 caracteres!!'
    echo "El mensaje a enviar es: $(echo $mensaje|cut -c 1-`expr 110 - ${#nombre}`)"
    op=0
    while [ $op -eq 0 ]; do
      echo ''
      echo 'Seleccione una opcion'
      echo '1) Enviar este mensaje'
      echo '2) Volver a escribir'
      echo '3) Salir'
      read op
      case $op in
		1) mensaje=$(echo $mensaje|cut -c 1-`expr 110 - ${#nombre}`);;
		2) mensaje='';;
		3) exit;;
		*) op=0;;
      esac
    done
    fi
done
}
function obtener_captcha {
  #esta variable contiene la direccion web del captcha
  imagen=$(cat /tmp/sms.php | grep /Mensajes/tmp | awk -F'"' '{print$2}')
  #Descargo el captcha
  wget -q --referer=$URL --cookies=on --load-cookies=/tmp/cookie.txt --keep-session-cookies --save-cookies=/tmp/cookie.txt --output-document=/tmp/captcha.png $imagen
  #Muestro el captcha en pantalla
  display -title "Captcha" -resize 300% "/tmp/captcha.png" > /dev/null 2>&1 &
  #Guarda el pid del ultimo proceso en segundo plano, en este caso el display del captcha
  while [ ${#captcha} -eq 0 ]; do
    echo ''
    echo "Ingrese el captcha:"
    read captcha
    captcha=$(echo $captcha|egrep '\b[0-9]{4}\b')
  done

  #Envio los datos a travez de personal
  POSTFIELDS='form_flag=&Snb='$numero'&subname='$numero'&sig='$nombre'&msgtext='$mensaje'&form=ht4&size=10&btn_send=SEND&historico=&Filename='$imagen'&FormValidar=validar&CODAREA='$codarea'&NRO='$cel'&DE_MESG_TXT='$nombre'&sizebox=''&MESG_TXT='$mensaje'&codigo='$captcha'&Enviar.x=13&Enviar.y=7&pantalla=';
  wget -q --post-data="$POSTFIELDS" --cookies=on --keep-session-cookies --load-cookies=/tmp/cookie.txt --save-cookies=/tmp/cookie.txt --output-document=/tmp/sms.php $URL
}
function verificar_captcha {
proceso=`ps aux | grep display | awk '{print $2}' | head -1`
kill -9 $proceso
while [[ $(cat /tmp/sms.php | grep "ingresado es incorrecto") != '' ]]; do
  echo 'El código es incorrecto! Volve a ingresarlo!'
  captcha=''
  rm /tmp/captcha.png
  obtener_captcha
done
echo ''
echo 'Mensaje enviado correctamente!'
}
function borrar_tmp {
rm /tmp/captcha.png
rm /tmp/sms.php
rm /tmp/cookie.txt
#for i in ${!PID[*]}; do
#  kill pid ${PID[i]} > /dev/null 2>&1 &
#  wait
#done
}
function menu_principal {
	pos=0
	mensaje=''
	captcha=''
	echo ''
	echo 'Que desea hacer? Seleccione una opcion'
	echo '1) Enviar otro mensaje al mismo numero'
	echo '2) Cambiar numero de destino'
	echo '3) Volver a cargar todos los datos'
	echo '4) Salir'
	read op
	case $op in
		1) echo "Tu nombre: $nombre";echo "Destino: $numero";
		mensaje='';obtener_mensaje;obtener_captcha;verificar_captcha;menu_principal;;
		2) numero='';obtener_numero;obtener_mensaje;obtener_captcha;verificar_captcha;menu_principal;;
		3) nombre='';numero='';verificar_parametros;obtener_captcha;verificar_captcha;menu_principal;;
		4) borrar_tmp;exit;;
		*) menu_principal;;
	esac
}	

pos=0
verificar_parametros
wget -q --post-data='' --tries=80 --cookies=on --keep-session-cookies --save-cookies=/tmp/cookie.txt --output-document=/tmp/sms.php $URL
obtener_captcha
verificar_captcha
menu_principal
