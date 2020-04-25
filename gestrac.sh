#!/bin/bash
# Date: 09-07-2016
# Author: "lapipaplena" <lapipaplena@gmail.com>
# Version: 6.0 (09-07-2016)
# Licence: GPL v3.0
# Description: Consulta del tractatus alojado en GitHub via consola.
# Require: cowsay ccze git
## comprobar privilegios
DIR=$HOME/TRAC
if [ "$(id -u)" = "0" ]
then
    echo
    echo "<< Ejecutar el script como usuario sin privilegios... abortando.... >>"
    echo
    exit 1
fi
#
function fcolor ()
{
    echo $1 | ccze -A
}
#
function fdir ()
{
    if [ -d $DIR ]
    then
        echo
    else
        mkdir $DIR
    fi
}
#
function fdesglosetractatus ()
{
    mkdir files
    cd files
    ESTAT=1 # 1 - Linia en blanc, 2- comanda,
    COMANDA=""
    while read linia
    do
	    if [ $ESTAT -eq 1 ] && [ -z "${linia}" ];
	    then
		    ESTAT=1
	    else
		    if [ $ESTAT -eq 1 ] && [ ! -z "${linia}" ];
		    then
			    ESTAT=2
			    read -ra COMANDA <<< "$linia"
			    echo "$linia" >> "$COMANDA"
		    elif [ $ESTAT -eq 2 ] && [ -z "${linia}" ];
		    then
			    ESTAT=1
		    else
			    echo "$linia" >> "$COMANDA"
		    fi
	    fi
    done < ../0-file1.txt
    echo
    fcolor "... proceso terminado...."
    cd ..
    ls files > 0-lista.txt
    if [ ! -s 0-lista.txt ]
    then
        fcolor "Se han detectado errores al procesar la descarga del Tractatus"
        exit
    else
        echo
        fcolor  "<< Creado el directorio "files" correctamente ... >>"
    fi
}
#
function fpagina_man ()
{
    MAN=$(man $COMANDO | wc -l 2>/dev/null)
    if [ $MAN -gt 2 ]
    then
        echo
        read -n 1 -p "No existe la entrada $COMANDO en el tractatus... ¿Visualizar su página man?  (s/n) " CON
        echo
        if [ $CON = s ]
        then
            echo
            man $COMANDO
            echo
            echo "Pulsar "intro" para volver al menú"
            echo
        else
            echo
        fi
    else
        echo
        cowsay -f tux "Concepto inexistente en el tractatus y en las páginas man. Pulsar "intro" para volver al menú"
        echo
    fi
    read
}
#
function fshowhelp ()
{
  	echo
	echo "  gestrac [--update] [-u] (Descargar la última versión) "
        echo
        echo "  gestrac [--version] [-v] (Consultar versión)"
	echo
	echo "  gestrac (Consulta local. Más rápido) "
	echo
	echo "  gestrac [--help] [-h] (Mostrar esta ayuda y salir) "
	echo
}
#
function factualizar ()
{
    if [ -d $DIR ]
	then
  		echo
        fcolor "Encontrado directorio de trabajo "${HOME}/TRAC"..."
        echo
        fcolor " <<Actualizando la versión del tractatus... >> "
		cd $DIR
  		rm 0-*.txt
  		rm -R files
  		echo
                # git pull
  		echo
		cp ~/webtrac2pip/tractatus/tractatus.txt .
  		cat tractatus.txt | sed '1d' > 0-file1.txt
  		fdesglosetractatus
  		echo
	else
  		fdir
  		cd $DIR
  		git clone https://github.com/templix/tractatus.git .
  		git init
  		echo
  		fcolor " << Creando directorio TRAC y repositorio git... >> "
  		echo
  		cat tractatus.txt | sed '1d' > 0-file1.txt
  		fdesglosetractatus
  		echo
	fi
}
#
#
### Argumentos opcionales
while [ $1 ]; do
	case $1 in
		'-h' | '--help' | '?' )
			fshowhelp
			exit
			;;
		'--update' | '-u' )
            factualizar
            break
			;;
        '--version' | '-v' )
            sed -n 4p ~/gestrac/gestrac.sh
            exit
            ;;
		* )
			fshowhelp
			exit
			;;
	esac
done
#
#
###
cd $DIR/files
NUM2=$(cat ../0-file1.txt | awk 'BEGIN { FS="\n"; RS="" } {print $1 }' | awk -F " " '{print$1 }' | wc -l)
while [ "$OPC1" != 3 ]
do
    echo
	fcolor "[1] Entrar una busqueda"
	fcolor "[2] Realizar busqueda avanzada"
	fcolor "[3] Salir"
	echo
	read -n 1 -p "<< Ingresar opción (NO distingue mayúsculas y minúsculas): >> " OPC1
	echo
	case $OPC1 in
	    1)
    	    # Buscar los comandos deseados.
            clear
    	    echo
    	    read -p "<< Introducir dato a consultar: >> " COMAND_
     	    echo
		    COMANDO=$(echo "$COMAND_" | tr 'A-Z' 'a-z')
 		    clear
      	    if [ -e "$COMANDO" ]
      	    then
        	    pr -f -d -h $COMANDO $COMANDO | ccze -A
          	    echo
                echo "Pulsar INTRO para volver al menú"
          	    read
     	    else
          	    fpagina_man
          	    echo
     	    fi
     	    clear;;
 	    2)
      	    ### Busqueda recursiva
      	    clear
      	    echo
        	read -p "<< Introducir dato a consultar: >> " COMAND_
          	echo
          	COMANDO=$(echo "$COMAND_" | tr 'A-Z' 'a-z')
          	clear
          	grep -l $COMANDO * | cut -d/ -f2 > ../0-file3.txt
          	if [ -s ../0-file3.txt ]
          	then
            	OP=s
              	while [ $OP = s ]
              	do
                	echo
                  	fcolor "El dato entrado sale en los siguientes ficheros: "
                  	echo
                  	numero=0
                  	for linia in `cat ../0-file3.txt`; do
                    	let numero+=1
                      	echo "[$numero] $linia"
                  	done
                  	echo
                  	echo "[0] Cancelar"
                  	echo
                  	read -p "<< Comando a mostrar... >> " COM
                  	if [ $COM -ne 0 ] && [ $COM -le $numero ];
                  	then
                    	comando=`sed -n ${COM}p ../0-file3.txt`
                      	if [ "$?" -eq "0" ]
                      	then
                        	echo
                          	clear
                          	pr -f -d -h $comando $comando | ccze -A
                            echo
                	        echo "Pulsar INTRO para volver al menú"
          	    	        #read
                      	else
                        	echo
                     	fi
                    	read
                    	echo
                    	read -n 1 -p "<< Consultar otro comando del listado? [s/n] >> " OP
                    	clear
                  	elif [ $COM -gt $numero ] ;
                  	then
                    	echo
                      	clear
                      	cowsay -f tux "No existe en el listado"
                        echo
                        echo "Pulsar INTRO para volver al menú"
                      	read
                 	else
                    	OP="n"
                      	clear
                  	fi
              	done
          	else
            	fpagina_man
              	echo
         	fi
     	    echo;;
	    3);;
    esac
done
clear
echo
echo  "============================================================="
fcolor "<< La base de datos del tractatus cuenta con $NUM2 entradas >>"
echo "============================================================="
cd $HOME
echo
exit
