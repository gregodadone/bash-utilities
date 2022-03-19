#!/bin/bash
##################################
#          Linux Mint 13         #
#   Script de Post-Instalación   #
#           By Grego D.          #
##################################
#           V0.9.4 Beta.         #
##################################
# GMail: grego.dadone@gmail.com  #
##################################

#Configuraciones que no deben ejecutarse como root

if [ $UID -ne 0 ]; then
	gconftool-2 --type bool --set /desktop/gnome/interface/buttons_have_icons true
	gsettings set org.gnome.nautilus.preferences show-advanced-permissions true
	gsettings set org.gnome.desktop.interface menus-have-icons true
	gsettings set org.gnome.desktop.interface buttons-have-icons true
	gsettings set org.gnome.desktop.screensaver lock-enabled false
	gsettings set org.gnome.desktop.screensaver ubuntu-lock-on-suspend false
	gsettings set org.gnome.nautilus.desktop background-fade true
	gsettings set org.gnome.nautilus.desktop computer-icon-name 'Equipo'
	gsettings set org.gnome.nautilus.desktop trash-icon-visible true
	gsettings set org.gnome.nautilus.desktop trash-icon-name 'Papelera de reciclaje'
	gsettings set org.gnome.settings-daemon.plugins.power lid-close-ac-action nothing
	gsettings set org.gnome.settings-daemon.plugins.power lid-close-battery-action nothing
	gsettings set org.gnome.settings-daemon.plugins.power button-power shutdown
	gsettings set org.gnome.settings-daemon.plugins.power button-sleep suspend
	gsettings set org.gnome.settings-daemon.plugins.power critical-battery-action shutdown
	gsettings set org.gnome.power-manager lock-blank-screen false
	sudo $0 #Loguearse como root y ejecutar el resto
	exit
fi

#GUARDANDO NOMBRE DEL USUARIO
NOM=$(echo $HOME|cut -d'/' -f3)

#Automontar particiones NTFS al inicio

chmod +w /etc/fstab #Asignando permisos de escritura a fstab
echo "Agregando particiones NTFS a fstab"
i=1 #Guardando UUID
for line in $(blkid | grep ntfs | awk -F'UUID' '{ print$2 }' | awk -F'"' '{ print$2}'); do
        NTFS[$i]=$(echo $line)
        i=$(( i+1 ))
done
i=1 #Guardando numero de particion
for line in $(blkid | grep ntfs | awk -F':' '{ print$1 }'); do
        SDA[$i]=$(echo $line)
        i=$(( i+1 ))
done
i=1 #Guardando Labels de particiones
for line in $(blkid | grep ntfs | awk -F'LABEL=' '{print$2}' | awk -F'"' '{print$2}'); do
        LAB[$i]=$(echo $line)
        i=$(( i+1 ))
done
for i in ${!NTFS[*]}; do #Escribiendo particiones NTFS en fstab
        k=0
        for line in $(cat /etc/fstab); do
                if [[ $line = "${SDA[i]}" ]]; then #Si ya existe la particion no escribe
                        echo "Ya existe ${SDA[i]} en fstab"
                        k=1
                fi
        done
        if [ $k -eq 0 ]; then
                echo "#Entry for ${SDA[i]} :" >> /etc/fstab
                if [[ ${LAB[i]} = "" ]]; then #Si la particion no tiene label, se le genera uno
                        if ! [ -e /media/WIN$i ]; then
                                mkdir /media/WIN$i
                        fi
                        echo "UUID=${NTFS[i]}   /media/WIN$i    ntfs-3g defaults,locale=en_US.UTF-8     0       0" >> /etc/fstab
                else
                        if ! [ -e /media/${LAB[i]} ]; then #Si la particion tiene label se monta ahi
                                mkdir /media/${LAB[i]}
                        fi
                        echo "UUID=${NTFS[i]}   /media/${LAB[i]}        ntfs-3g defaults,locale=en_US.UTF-8     0       0" >> /etc/fstab
                fi
                echo "${SDA[i]} escrito correctamente en fstab"
        fi
done
echo ''
chmod -w /etc/fstab

#Agregar Repositorios

#Burg
add-apt-repository --yes ppa:ingalex/super-boot-manager
#Google Chrome
echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list
echo 'deb http://dl.google.com/linux/chrome/deb/ stable main' > /etc/apt/sources.list.d/google-chrome.list.save
wget -q -O - https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add -
#PlayDeb
wget http://archive.getdeb.net/install_deb/playdeb_0.3-1~getdeb1_all.deb
dpkg -i playdeb_0.3-1~getdeb1_all.deb
rm playdeb_0.3-1~getdeb1_all.deb
sed -i 's/maya/precise/g' /etc/apt/sources.list.d/playdeb.list
sed -i 's/maya/precise/g' /etc/apt/sources.list.d/playdeb.list.save
#GetDeb
wget http://archive.getdeb.net/install_deb/getdeb-repository_0.1-1~getdeb1_all.deb
dpkg -i getdeb-repository_0.1-1~getdeb1_all.deb
rm getdeb-repository_0.1-1~getdeb1_all.deb
sed -i 's/maya/precise/g' /etc/apt/sources.list.d/getdeb.list
sed -i 's/maya/precise/g' /etc/apt/sources.list.d/getdeb.list.save
#Cinnamon Extras
add-apt-repository --yes ppa:bimsebasse/cinnamonextras
#Ubuntu Tweaks
add-apt-repository --yes ppa:tualatrix/ppa

#Instalar software

apt-get update
#Burg Bootloader (REQUIERE INTERACCIÓN)
apt-get install --yes --force-yes burg burg-themes burg-theme-fortune
chmod -x /etc/grub.d/20_memtest86+ #Deshabilitando memtest
sed -i "s/#GRUB_DISABLE_LINUX_RECOVERY/GRUB_DISABLE_LINUX_RECOVERY/g" /etc/default/burg #Deshabilitando Modo de recuperación
burg-install "(hd0)"
update-burg
mv /usr/sbin/update-grub /usr/sbin/update-grub.bak
ln -s /usr/sbin/update-burg /usr/sbin/update-grub
#Fuentes de Microsoft (REQUIERE INTERACCIÓN)
apt-get --yes --force-yes install ttf-mscorefonts-installer
#Actualizaciones (A partir de acá es todo desatendido)
apt-get --yes --force-yes dist-upgrade
#Paquetes de idioma
apt-get --yes --force-yes install aspell-es libreoffice-help-es libreoffice-l10n-es myspell-es openoffice.org-hyphenation poppler-data thunderbird-locale-es thunderbird-locale-es-ar wspanish
#Aplicaciones varias
apt-get --yes --force-yes install bum cowsay deluge emesene exaile fortunes-es fortunes-es-off gimp google-chrome-stable gparted libnss3-1d libxss1 lm-sensors nautilus-wallpaper non-free-codecs openjdk-7-jre p7zip-full pinta rar skype songbird synapse ubuntu-restricted-addons ubuntu-restricted-extras ubuntu-tweak wajig wine
#Juegos
apt-get --yes --force-yes install gnome-games supertuxkart warmux

#Configuraciones Extra

#Instalar fuentes extra
if ! [ -e ~/.fonts ]; then
        mkdir ~/.fonts
fi
chown -R $NOM ~/.fonts
cd ~/.fonts
if ! [ -e fonts.tar.gz ]; then
        wget http://www.fileden.com/files/2007/3/18/900878/fonts.tar.gz
fi
tar xvzf fonts.tar.gz
rm fonts.tar.gz
fc-cache -f -v
#Cowsay en la consola
echo 'fortune|cowsay -f tux' >> ~/.bashrc
#Crear iconos en el escritorio
cd /usr/share/applications/
cp deluge.desktop emesene.desktop firefox.desktop gimp.desktop google-chrome.desktop libreoffice-calc.desktop libreoffice-writer.desktop pinta.desktop skype.desktop songbird.desktop vlc.desktop warmux.desktop supertuxkart.desktop ~/Escritorio
chmod 777 ~/Escritorio/*.desktop
#Iniciar Synapse con la sesión
mkdir -p ~/.config/autostart
cp synapse.desktop ~/.config/autostart/
chmod 777 ~/.config/autostart/synapse.desktop





