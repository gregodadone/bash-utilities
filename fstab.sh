#!/bin/bash
#Comprobando root
if [ "$UID" -ne 0 ]; then     #Checkeando si somos root
        sudo $0 #Si no somos root se llama a si mismo y pide pass
        exit
fi
#Asignando permisos de escritura a fstab
chmod +w /etc/fstab
#Agregando particiones NTFS a fstab
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
#Escribiendo en fstab
for i in ${!NTFS[*]}; do
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
#Quitando permisos de escritura a fstab
chmod -w /etc/fstab
