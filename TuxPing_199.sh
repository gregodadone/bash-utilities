#!/bin/bash
#---------------------------------------------------------------------------
#TuxPing 1.99
#---------------------------------------------------------------------------
#Reescritura total del viejo GZDMPing optimizado, depurado, simplificado 
#y modularizado.
#---------------------------------------------------------------------------
#Autor: Grego D. - grego.dadone@gmail.com
#---------------------------------------------------------------------------
#Programa dedicado a todos los piratas WiFi. Lo que hace es controlar
#si una o varias IPs estan conectadas en un momento determinado, y en
#caso de estarlo, puede reproducir un sonido y mostrar una notificacion
#para advertir y tambien limitar la velocidad de descarga. 
#Cuando las IPs se desconectan reestablece la velocidad de descarga normal.
#---------------------------------------------------------------------------
#Indice de funciones:
#Linea 34: obtener_info
#Linea 63: crear_logs
#Linea 86: rellenar_info_logs
#Linea 117: control_conexion
#Linea 124: check_root
#Linea 133: check_dis
#Linea 153: control_software
#Linea 181: instalar_software
#Linea 198: control_addons
#Linea 225: asistente_config
#Linea 244: preguntar_alarmas
#Linea 272: preguntar_limites
#Linea 346: mandar_ping
#Linea 366: monitor_individual
#Linea 422: monitor_multiple
#Linea 538: PROGRAMA PRINCIPAL
#---------------------------------------------------------------------------
function obtener_info() {
	int=$(ifconfig | grep -a1 255.255 | grep 'Link' | awk '{print$1}')
	myip=$(ifconfig | grep 255.255 | cut -d: -f2 | awk '{print$1}')
	androidip=$(lynx --dump http://10.0.0.2/dhcpinfo.html --auth=admin:Macrosoft 2> /dev/null | grep android | awk '{print$3}')
	androidippos=$(( $(echo $androidip | awk -F'10.0.0.' '{print$2}')-2 ))
	i=1
	for linea in $(lynx --dump http://10.0.0.2/dhcpinfo.html --auth=admin:Macrosoft 2> /dev/null | grep hours | awk '{print$1}'); do
		if [[ $linea != $HOSTNAME ]]; then
			nombres[$i]=$(echo $linea | sed 's/_aca7c641567110a5//g')
			i=$(( i+1 ))
		fi
	done
	i=1
	for linea in $(lynx --dump http://10.0.0.2/dhcpinfo.html --auth=admin:Macrosoft 2> /dev/null | grep hours | awk '{print$3}'); do
		if [[ $linea != $myip ]]; then
			IP[$i]=$linea
			i=$(( i+1 ))
		fi
	done
	if [[ ${nombres[*]} = '' ]] || [[ ${IP[*]} = '' ]]; then
		echo 'No se pudo conectar al modem, se volvera a intentar cada 30 segundos'
		sleep 30
		obtener_info
	fi
}
function crear_logs() {
	case $DIS in
		Mint|Ubuntu|Debian) NOM=$(echo ~ | awk -F'/home/' '{print$2}');;
		*) NOM=$USER;;
	esac
	yn='nose'
	while [[ $yn = 'nose' ]]; do
		echo 'Desea guardar en un archivo de texto los movimientos de la red? (s/n)'
		read yn
		case $yn in
			s|si|S|SI|Si)	gzdmlog="$(date --rfc-3339=date)_$(date|awk '{print$4}')"
					touch /home/$NOM/TuxPing_log_$gzdmlog.txt
					chown $NOM /home/$NOM/TuxPing_log_$gzdmlog.txt
					log="-a /home/$NOM/TuxPing_log_$gzdmlog.txt"
					echo "Se guardara el log TuxPing_log_$gzdmlog.txt en su carpeta personal"
					rellenar_info_log
					;;
			n|no|N|NO|No)	log='';;
			*) yn='nose';;
		esac
	done
		
}
function rellenar_info_log() {
	echo 'TuxPing 1.99' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo '=============' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo '' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo '-------------------------------' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo 'Información de la configuración' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo '-------------------------------' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo "Interfaz de red: $int" >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo "Mi IP: $myip" >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo "Cantidad de IPs analizadas: ${#IP[*]}" >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo -n "Alarmas activadas: " >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	case $alarma in
		0) echo 'NO' >> /home/$NOM/TuxPing_log_$gzdmlog.txt;;
		1) echo 'SI' >> /home/$NOM/TuxPing_log_$gzdmlog.txt;;
	esac
	echo -n "Limites de velocidad activados: "  >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	case $limit in
		0) echo 'NO' >> /home/$NOM/TuxPing_log_$gzdmlog.txt;;
		1) echo 'SI' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
		   echo "Velocidad maxima de descarga cuando hay PCs conectadas: $(( vdescarga/8 )) KB/s" >> /home/$NOM/TuxPing_log_$gzdmlog.txt
		   echo "Velocidad maxima de subida cuando hay PCs conectadas: $(( vsubida/8 )) KB/s" >> /home/$NOM/TuxPing_log_$gzdmlog.txt
		   echo "Velocidad maxima de descarga cuando hay SmartPhones conectados: $(( vdandroid/8 )) KB/s" >> /home/$NOM/TuxPing_log_$gzdmlog.txt
		   echo "Velocidad maxima de subida cuando hay SmartPhones conectados: $(( vsandroid/8 )) KB/s" >> /home/$NOM/TuxPing_log_$gzdmlog.txt
		   ;;
	esac
	echo '' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo 'Comienzo del logueo de las actividades' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo '------------------------------------------------------------------' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
	echo '' >> /home/$NOM/TuxPing_log_$gzdmlog.txt
}
function control_conexion() {
	if [[ $(ifconfig|grep 255.255) = '' ]]; then
		echo 'Necesita estar conectado a una red para usar TuxPing'
		echo ''
		exit
	fi
}
function check_root() {
	if [ $UID -ne 0 ]; then
		case $DIS in
			Ubuntu|Debian|Mint) sudo $0;;
			*) echo 'Ingrese contraseña de Administrador';su -c "$0";echo '';;
		esac
		exit
	fi
}
function check_dis() {
	DIS=''
	for line in $(cat /etc/issue); do
		if [[ $line = 'Ubuntu' ]]; then
			DIS='Ubuntu'
		fi
		if [[ $line = 'Arch' ]]; then
			DIS='Arch'
		fi
		if [[ $line = 'Debian' ]]; then
			DIS='Debian'
		fi
		if [[ $line = 'Fedora' ]]; then
			DIS='Fedora'
		fi
		if [[ $line = 'Mint' ]] || [[ $line = 'LinuxMint' ]]; then
			DIS='Mint'
		fi
	done
}
function control_software() {
	software=''
	if ! [ -e /usr/bin/mplayer ]; then
		software="$software mplayer"
	fi
	if ! [ -e /usr/bin/notify-send ]; then
		software="$software libnotify-bin"
	fi
	if ! [ -e /usr/sbin/wondershaper ] && ! [ -e /usr/bin/wondershaper ] && ! [ -e /usr/sbin/wshaper ]; then
		software="$software wondershaper"
	fi
	if ! [ -e /usr/bin/wget ]; then
		software="$software wget"
	fi
	if [[ $software != '' ]]; then
		yn='nose'
		while [[ $yn = 'nose' ]]; do
			echo "Usted necesita instalar el siguiente software:$software"
			echo "Desea instalarlo? (s/n)"
			read yn
			case $yn in
				s|si|S|SI|Si) instalar_software;;
				n|no|N|NO|No) echo "No se puede continuar sin esos programas";exit;;
				*) yn='nose';;
			esac
		done
	fi
}
function instalar_software() {
	case $DIS in
		Ubuntu|Mint) apt-get update;apt-get --yes --force-yes install $software;;
		Debian) aptitude update;aptitude --yes --force-yes install $software;;
		Fedora) for line in $software; do
				if [[ $line = 'wondershaper' ]]; then
					wget -q http://mmahut.fedorapeople.org/reviews/wondershaper/wondershaper-1.1a-2.fc8.i386.rpm
					yum -y --nogpgcheck install wondershaper-1.1a-2.fc8.i386.rpm
				fi
			done
			software=$(echo $software|sed "s/libnotify-bin/libnotify/g"|sed "s/wondershaper//g")
			yum -y install $software
			;;
		Arch) echo 'Por ahora TuxPing no puede instalar software en Arch Linux :)';exit;;
	esac
	control_software
}
function control_addons() {
	if ! [ -e ~/.TuxPing ]; then
		echo 'Parece que es la primera vez que ejecuta TuxPing'
		echo 'TuxPing descargara automaticamente las alarmas e iconos, presione Enter'
		read i
		mkdir ~/.TuxPing
	fi
	cd ~/.TuxPing
	if ! [ -e ~/.TuxPing/online.png ]; then
		wget -q http://www.fileden.com/files/2007/3/18/900878/online.png
	fi
	if ! [ -e ~/.TuxPing/offline.png ]; then
		wget -q http://www.fileden.com/files/2007/3/18/900878/offline.png
	fi
	if ! [ -e ~/.TuxPing/status.png ]; then
		wget -q http://www.fileden.com/files/2007/3/18/900878/status.png
	fi
	if ! [ -e ~/.TuxPing/online.ogg ]; then
		wget -q http://www.fileden.com/files/2007/3/18/900878/online.ogg
	fi
	if ! [ -e ~/.TuxPing/offline.ogg ]; then
		wget -q http://www.fileden.com/files/2007/3/18/900878/offline.ogg
	fi
	if ! [ -e ~/.TuxPing/status.ogg ]; then
		wget -q http://www.fileden.com/files/2007/3/18/900878/status.ogg
	fi
}
function asistente_config() {
	opcion=0
	while [ $opcion -eq 0 ]; do
		echo 'Seleccione una opcion:'
		echo '1) Configuración manual'
		echo '2) Configuración automática:'
		echo '  - Alarmas desactivadas'
		echo '  - Limite de velocidad de descarga cuando hay PCs: 50 KB/s'
		echo '  - Limite de velocidad de descarga cuando hay SmartPhones: 80 KB/s'
		echo '  - Limite de velocidad de subida: 10 KB/s'
		echo '  - Logueo de actividades desactivado'
		read opcion
		case $opcion in
			1) preguntar_alarmas;preguntar_limites;crear_logs;;
			2) log='';alarma=0;limit=1;vdescarga=400;vsubida=80;vdandroid=640;vsandroid=80;;
			*) opcion=0;;
		esac
	done
}
function preguntar_alarmas() {
	if ! [ -e ~/.mplayer ]; then
		mkdir ~/.mplayer
	fi
	if ! [ -e ~/.mplayer/config ]; then
		echo 'nolirc=yes' >> ~/.mplayer/config
	else
		yn='n'
		for line in $(cat ~/.mplayer/config); do
			if [[ $line = nolirc=yes ]]; then
				yn='s'
			fi
		done
		if [[ $yn = 'n' ]]; then
			echo "nolirc=yes" >> ~/.mplayer/config
		fi
	fi
	yn='nose'
	while [[ $yn = 'nose' ]]; do
		echo 'Desea activar alarmas sonoras? (s/n)'
		read yn
		case $yn in
			s|si|S|SI|Si) alarma=1;;
			n|no|N|NO|No) alarma=0;;
			*) yn='nose';;
		esac
	done
}
function preguntar_limites() {
	yn='nose'
	while [[ $yn = 'nose' ]]; do
		echo 'Desea activar limites de velocidad cuando haya hosts conectados? (s/n)'
		read yn
		case $yn in
			s|si|S|SI|Si) limit=1;;
			n|no|N|NO|No) limit=0;;
			*) yn='nose';;
		esac
	done
	vdescarga=0
	vsubida=0
	vdandroid=0
	vsandroid=0
	if [ $limit -eq 1 ]; then
		while [ $vdescarga -eq 0 ]; do
			echo 'Ingrese la velocidad maxima de descarga cuando haya PCs conectadas'
			read vdescarga
			vdescarga=$(echo $vdescarga | egrep '[0-9]{1,4}')
			if [[ $vdescarga = '' ]]; then
				vdescarga=0
			fi
			if [ $vdescarga -le 0 ]; then
				echo 'La velocidad debe ser mayor a 0'
				echo ''
				vdescarga=0
			fi
		done
		while [ $vsubida -eq 0 ]; do
			echo 'Ingrese la velocidad maxima de subida cuando haya PCs conectadas'
			read vsubida
			vsubida=$(echo $vsubida | egrep '[0-9]{1,4}')
			if [[ $vsubida = '' ]]; then
				vsubida=0
			fi
			if [ $vsubida -le 0 ]; then
				echo 'La velocidad debe ser mayor a 0'
				echo ''
				vsubida=0
			fi
		done
		while [ $vdandroid -eq 0 ]; do
			echo 'Ingrese la velocidad maxima de descarga cuando haya SmartPhones conectados'
			read vdandroid
			vdandroid=$(echo $vdandroid | egrep '[0-9]{1,4}')
			if [[ $vdandroid = '' ]]; then
				vdandroid=0
			fi
			if [ $vdandroid -le 0 ]; then
				echo 'La velocidad debe ser mayor a 0'
				echo ''
				vdandroid=0
			fi
		done
		while [ $vsandroid -eq 0 ]; do
			echo 'Ingrese la velocidad maxima de subida cuando haya SmartPhones conectados'
			read vsandroid
			vsandroid=$(echo $vsandroid | egrep '[0-9]{1,4}')
			if [[ $vsandroid = '' ]]; then
				vsandroid=0
			fi
			if [ $vsandroid -le 0 ]; then
				echo 'La velocidad debe ser mayor a 0'
				echo ''
				vsandroid=0
			fi
		done
	fi
	vdescarga=$(( vdescarga*8 ))
	vsubida=$(( vsubida*8 ))
	vdandroid=$(( vdandroid*8 ))
	vsandroid=$(( vsandroid*8 ))
}
function mandar_ping(){
	pingcont=$(ping -s 0 -c 3 ${IP[pos]} 2> /dev/null | grep 'received' | awk '{print$4}')
	pingcont=$(echo $pingcont | egrep '[0-9]')
	if [[ $pingcont = '' ]]; then
		if [ $errores -eq 0 ]; then
			echo '' | tee $log
			echo "Hay un problema, compruebe su conexion a Internet. Hora: $(date|awk '{print$4}')" | tee $log
			notify-send -i ~/.TuxPing/online.png "TuxPing" \ "Hay problemas en la red"
		fi
		errores=$(( errores+1 ))
		pingcont=0
	else
		if [ $errores -gt 0 ]; then
			echo ''  | tee $log
			echo "Se ha reestablecido la conexion. Hora: $(date|awk '{print$4}')" | tee $log
			notify-send -i ~/.TuxPing/offline.png "TuxPing" \ "Se ha reestablecido la conexion"
		fi
		errores=0
	fi
}
function monitor_individual() {
	while [[ $cliente = 'offline' ]]; do
		mandar_ping
		if [ $pingcont -ge 1 ]; then
			if [ $alarma -eq 1 ] && [ $mensajes -eq 0 ]; then
				mplayer ~/.TuxPing/online.ogg >> /dev/null
			fi
			echo '' | tee $log
			if [ $mensajes -eq 0 ]; then
				echo "El host ${nombres[1]} esta conectada! Hora: $(date|awk '{print$4}')" | tee $log
			else
				echo "El host ${nombres[1]} se ha conectado! Hora: $(date|awk '{print$4}')" | tee $log
			fi
			notify-send -i ~/.TuxPing/online.png "TuxPing" \ "El host ${nombres[1]} esta conectada"
			if [ $limit -eq 1 ]; then
				if [ $androidippos -eq 1 ]; then
					$wshaper $int $vdandroid $vsandroid
					echo "Se limito la velocidad de descarga a $(( vdandroid/8 )) KB/s y subida a $(( vsandroid/8 )) Kb/s" | tee $log
				else
					$wshaper $int $vdescarga $vsubida
					echo "Se limito la velocidad de descarga a $(( vdescarga/8 )) Kb/s y la de subida a $(( vsubida/8 )) Kb/s" | tee $log
				fi
			fi
			cliente='online'
		else
			if [ $mensajes -eq 0 ] && [ $errores -eq 0 ]; then
				echo '' | tee $log
				echo "El host ${nombres[1]} esta desconectada. Hora: $(date|awk '{print$4}')" | tee $log
				echo "se le avisara cuando se conecte" | tee $log
			fi
			sleep 40
		fi
		mensajes=1
	done
	while [[ $cliente = 'online' ]]; do
		mandar_ping
		if [ $pingcont -ge 1 ]; then
			sleep 40
		else
			if [ $errores -eq 0 ]; then
				if [ $alarma -eq 1 ]; then
					mplayer ~/.TuxPing/offline.ogg >> /dev/null
				fi
				echo '' | tee $log
				echo "El host ${nombres[1]} se ha desconectado! Hora: $(date|awk '{print$4}')" | tee $log
				echo 'Se le avisara si se vuelve a conectar' | tee $log
				notify-send -i ~/.TuxPing/offline.png "TuxPing" \ "El host ${nombres[1]} se ha desconectado"
				if [ $limit -eq 1 ]; then
					$wshaper clear $int >> /dev/null
					echo 'Se ha reestablecido la velocidad de la red' | tee $log
				fi
				cliente='offline'
			fi
		fi
	done
}
function monitor_multiple() {
	if [ $mensajes -eq 0 ]; then
		echo ''
		echo "Recuperando estados actuales... Hora: $(date|awk '{print$4}')" | tee $log
		echo '======================================' | tee $log
		echo '=    IP    =    Estado    = Hostname ' | tee $log
		echo '======================================' | tee $log
	fi
	conectados=0
	while [ $conectados -eq 0 ]; do
		desconectados=0
		for pos in ${!IP[*]}; do
			mandar_ping
			if [ $pingcont -ge 1 ]; then
				status[$pos]='CONECTADO!!!'
				conectados=$(( conectados+1 ))
			else
				status[$pos]=Desconectado
				desconectados=$(( desconectados+1 ))
			fi
			if [ $mensajes -eq 0 ] && [ $errores -eq 0 ]; then
				echo "= ${IP[pos]} = ${status[pos]} = ${nombres[pos]} " | tee $log
			fi
		done
		if [ $mensajes -eq 0 ] && [ $errores -eq 0 ] && [ $conectados -eq 0 ]; then
				echo '======================================' | tee $log
			echo "No hay IPs conectadas! Hora: $(date|awk '{print$4}')" | tee $log
			echo 'Se le avisara si alguna se conecta' | tee $log
			echo '' | tee $log
		fi
		if [ $conectados -gt 0 ]; then
			notify-send -i ~/.TuxPing/online.png "TuxPing" \ "Hay IPs conectadas"
			if [ $mensajes -eq 1 ]; then
				echo "Algunas IPs se han conectado! Hora: $(date|awk '{print$4}')" | tee $log
				if [ $alarma -eq 1 ]; then
					mplayer ~/.TuxPing/status.ogg >> /dev/null
				fi
				echo '======================================' | tee $log
				echo '=    IP    =    Estado    = Hostname ' | tee $log
				echo '======================================' | tee $log
				for pos in ${!IP[*]}; do
					echo "= ${IP[pos]} = ${status[pos]} = ${nombres[pos]} " | tee $log
				done
			fi
				echo '======================================' | tee $log
			echo "$conectados IPs conectadas, $desconectados IPs desconectadas" | tee $log
			echo 'Se le avisara si hay cambios en los estados o si se desconectan' | tee $log
			if [ $limit -eq 1 ]; then
				if [[ ${status[androidippos]} = 'CONECTADO!!!' ]] && [ $conectados -eq 1 ]; then
					$wshaper $int $vdandroid $vsandroid
					echo 'Solo hay un SmartPhone conectado' | tee $log
					echo "Se limito la velocidad de descarga a $(( vdandroid/8 )) KB/s y subida a $(( vsandroid/8 )) KB/s" | tee $log
					echo '' | tee $log
				else
					$wshaper $int $vdescarga $vsubida
					echo "Se limito la velocidad de descarga a $(( vdescarga/8 )) KB/s y subida a $(( vsubida/8 )) KB/s" | tee $log
					echo '' | tee $log
				fi
			fi
		fi
		sleep 30
		mensajes=1
	done
	while [ $conectados -gt 0 ]; do
		BAK=${status[*]}
		conectados=0
		desconectados=0
		for pos in ${!IP[*]}; do
			mandar_ping
			if [ $pingcont -ge 1 ]; then
				status[$pos]='CONECTADO!!!'
				conectados=$(( conectados+1 ))
			else
				status[$pos]=Desconectado
				desconectados=$(( desconectados+1 ))
			fi
		done
		if [ $conectados -eq 0 ]; then
			if [ $errores -eq 0 ];then
				if [ $alarma -eq 1 ]; then
					mplayer ~/.TuxPing/offline.ogg >> /dev/null
				fi
				notify-send -i ~/.TuxPing/offline.png "TuxPing" \ "No quedan IPs conectadas"
				echo '' | tee $log
				echo "No quedan IPs conectadas! Hora: $(date|awk '{print$4}')" | tee $log
				if [ $limit -eq 1 ]; then
					$wshaper clear $int >> /dev/null
					echo 'Se ha restablecido la velocidad normal' | tee $log
				fi
				echo 'Se le avisara si alguna se vuelve a conectar' | tee $log
				echo '' | tee $log
			fi
		else
			if [ "${BAK[*]}" != "${status[*]}" ]; then
				if [ $alarma -eq 1 ]; then
					mplayer ~/.TuxPing/status.ogg >> /dev/null
				fi
				notify-send -i ~/.TuxPing/status.png "TuxPing" \ "Los estados de las IPs han cambiado"
				echo "Ha habido cambios en los estados!, $(date|awk '{print$4}')" | tee $log
				echo '======================================' | tee $log
				echo '=    IP    =    Estado    = Hostname ' | tee $log
				echo '======================================' | tee $log
				for pos in ${!IP[*]}; do
					echo "= ${IP[pos]} = ${status[pos]} = ${nombres[pos]} " | tee $log
				done
				echo '======================================' | tee $log
				echo "$conectados IPs conectadas - $desconectados IPs desconectadas" | tee $log
				echo "Se le avisara si hay cambios en los estados o si se desconectan" | tee $log
				if [ $conectados -ge 2 ]; then
					$wshaper $int $vdescarga $vsubida
					echo "Se limito la velocidad de descarga a $(( vdescarga/8 )) KB/s y subida a $(( vsubida/8 )) KB/s" | tee $log
					echo '' | tee $log
				else
					if [[ ${status[androidippos]} = 'CONECTADO!!!' ]]; then
						$wshaper $int $vdandroid $vsandroid
						echo 'Solo queda un SmartPhone conectado' | tee $log
						echo "Se limito la velocidad de descarga a $(( vdandroid/8 )) KB/s y subida a $(( vsandroid/8 )) KB/s" | tee $log
						echo '' | tee $log
					fi
				fi
			fi
		fi
		sleep 30
	done
}

#PROGRAMA PRINCIPAL
control_conexion
check_dis
check_root
control_software
control_addons
obtener_info
asistente_config
case $DIS in
	Fedora) wshaper='wshaper';;
	*) wshaper='wondershaper';;
esac
errores=0
mensajes=0
if [ ${#IP[*]} -eq 1 ]; then
	pos=1
	cliente='offline'
	while [ ${#IP[*]} -eq 1 ]; do
		monitor_individual
	done
else
	while [ ${#IP[*]} -gt 1 ]; do
		monitor_multiple
	done
fi