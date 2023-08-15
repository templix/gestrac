#!/usr/bin/env bash
#!/bin/bash
# Date: 09-07-2016 (6.0)
# Author: "lapipaplena" <lapipaplena@gmail.com>
# Version: 6.5 (19-07-2023)
# Licence: GPL v3.0
# Description: Consulta y actualiza el tractatus alojado en GitHub via consola.
# Require: cowsay ccze git
## comprobar privilegios
#
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
## Desglosar el tractatus.md en entradas independientes
function _desglose () {
	cat /home/pep/TRAC/tractatus.md | awk 'BEGIN {ESTADO=1} \
		{ \
			if (ESTADO == 1 && NF == 0) \
					{ESTADO=1} \
			else    {       if (ESTADO==1 && NF != 0) {NOMBRE=$1; ESTADO=2; print $0 >> NOMBRE} \
							else    {       if (ESTADO==2 && NF == 0) {ESTADO=1} \
											else { print $0 >> NOMBRE } \
									} \
					} \
		}'
	echo
    echo "... Desglose acabat..."
}
#
function _post () {

    for i in *
    do
        cat ../plantilla0.txt > ../tmp2/$i
        cat $i | sed -e '1 s/^/# /' -e 'G' >> ../tmp2/$i
	# -f gfm desactiva el suport de TEX a l'hora de llegir. O sigui, no interpreta codi TeX
 	pandoc -f gfm -o ../tmp3/$i.html ../tmp2/$i
        cat ../tmp3/$i.html > ../HTMLS/$i.html
        #cp -u ../tmp3/$i.html ../HTMLS/
        sed -i '1i\<a href="http://localhost/tractatus/">Volver al listado</a><br><br>' ../HTMLS/$i.html
	echo "<br><a href="http://localhost/tractatus/">Volver al listado</a>" >> ../HTMLS/$i.html
        echo -e "<li><a id='$i' href="http://localhost/tractatus/${i}.html">$i</a></li> " >> ../HTMLS/index.html
        i=i+1
    done
    echo -e "</div>" >> ../HTMLS/index.html
    echo
    echo "... convertits els arxius a html..."
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
            clear
            exit
        else
            clear
            exit
        fi
    else
        echo
        cowsay -f tux "Concepto inexistente en el tractatus y en las páginas man. Pulsar "intro" para volver al prompt"
        read
        clear
        exit
    fi
}
#
function fshowhelp ()
{
    echo "  gestrac [--command] [-w] (Buscar un comando concreto) "
    echo
    echo "  gestrac [--recursivo] [-r] (Comandos en los que sale un concepto) "
    echo
    echo "  gestrac [--commit] [-c] (Realizar commit y push del tractatus) "
    echo
    echo "  gestrac [--update] [-u] (Descargar la última versión) "
    echo
    echo "  gestrac [--markdown] [-m] (Pasar el tractatus a markdown necesario antes que -t) "
    echo
    echo "  gestrac [--tractatus] [-t] (Actualizar la web del tractatus) "
    echo
    echo "  gestrac [--entradas] [-e] (Número de entradas en el tractatus) "
    echo
    echo "  gestrac [--version] [-v] (Consultar versión) "
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
        cd /home/pep/webtrac2pip/tractatus
        git pull
        cd $DIR
        rm 0-*.txt
        rm -R files
        rm tractatus.txt
        cp /home/pep/webtrac2pip/tractatus/tractatus.txt /home/pep/TRAC
        echo
        cat tractatus.txt | sed '1d' > 0-file1.txt
        cat 0-file1.txt | tr -d '\r' > 0-file3.txt
        mv 0-file3.txt 0-file1.txt
        fdesglosetractatus
        exit 0
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
        cat 0-file1.txt | tr -d '\r' > 0-file3.txt
        mv 0-file3.txt 0-file1.txt
        fdesglosetractatus
        exit 0
        echo
    fi
}
################## Inici ################################
#########################################################
DIR=$HOME/TRAC
if [ "$(id -u)" = "0" ]
then
    echo
    echo "<< Ejecutar el script como usuario sin privilegios... abortando.... >>"
    echo
    exit 1
fi
echo
if [ -z "$1" ]
then
    clear
    echo
    fcolor "--------->  Falta el argumento <-----------"
    echo
    fshowhelp
    exit 1
fi
### Argumentos
while [ $1 ]; do
    case $1 in
        '--command' | '-w' )
            # Buscar comando deseado.
            clear
            cd $DIR/files
            echo
            read -p "<< Introducir dato a consultar: >> " COMAND_
            echo
            COMANDO=$(echo "$COMAND_" | tr 'A-Z' 'a-z')
            clear
            if [ -f ${COMANDO} ]
            then
                cat ${COMANDO} | ccze -A
                echo
                echo "Pulsar INTRO para volver al prompt"
                read
                clear
                exit
            else
                fpagina_man
                echo
            fi
            clear
            ;;
        '--recursiva' | '-r' )
            clear
            cd $DIR/files
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
                        exit
                    fi
                done
            else
                fpagina_man
                echo
                exit
            fi
            echo
            exit
            ;;
        '--commit' | '-c' )
            cd /home/pep/webtrac2pip/tractatus
            git pull
            rm /home/pep/Dropbox/tractatus.txt
            rm /home/pep/tractatus/tractatus.txt
            echo "fet git pull i eliminats els txt dels directoris Dropbox i tractatus."
            echo
            read -n 1 -p "pulsa tecla per fer el commit"
            echo
            echo "templix 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"
            echo
            git commit -a
            git push
            cp tractatus.txt /home/pep/tractatus/
            cp tractatus.txt /home/pep/Dropbox/
            cd ..
            echo "Recordatori: Per actualitzar la web -u, -m i -t"
            exit
            ;;
        '--update' | '-u' )
            factualizar
            read
            ;;
        '--markdown' | '-m' )
            # function fdir ()
            # {
            #     if [ -d $DIR2 ]
            #     then
            #         echo
            #     else
            #         mkdir $DIR2
            #     fi
            # }
            ## Desglosar el tractatus.md en entradas independientes
            function _desglose () {
                cat $HOME/TRAC/tractatus.md | awk 'BEGIN {ESTADO=1} \
		{ \
			if (ESTADO == 1 && NF == 0) \
					{ESTADO=1} \
			else    {       if (ESTADO==1 && NF != 0) {NOMBRE=$1; ESTADO=2; print $0 >> NOMBRE} \
							else    {       if (ESTADO==2 && NF == 0) {ESTADO=1} \
											else { print $0 >> NOMBRE } \
									} \
					} \
		}'
                echo
                fcolor  " Separació del tractatus per comandes amb markdown acabat. "
                echo
            }
            #
            DIR2=/home/pep/TRAC/1-tractatux
            if [ -d "$DIR2" ]
            then
                cd $DIR2/FILES
                #rm *
            else
                mkdir /home/pep/TRAC/1-tractatux
                mkdir /home/pep/TRAC/1-tractatux/FILES
                cd /home/pep/TRAC/1-tractatux/FILES
            fi
            # convertir txt a markdown:
            cat $HOME/TRAC/tractatus.txt | sed -e '1,2d' | sed -e 's/^[#]/>\\#/' -e 's/^[$]/>$/' -e 's/^[<]/\t\</' > $HOME/TRAC/tractatus.md
            cat $HOME/TRAC/tractatus.md | tr -d '\r' > $HOME/TRAC/file1.md
            mv $HOME/TRAC/file1.md $HOME/TRAC/tractatus.md
            fcolor "creat tractatus.md..."
            cd /home/pep/TRAC/1-tractatux/FILES
            #
            _desglose
            ls | wc -l
            echo
            echo "Fet"
            exit 0
            ;;
        '--tractatus' | '-t' )
            ## Crear directorios de trabajo.
            DIR=/home/pep/TRAC/webtrac
            if [ -d $DIR ]
            then
                rm -R $DIR/HTMLS/* $DIR/FILES/* $DIR/tmp/* $DIR/tmp2/* $DIR/tmp3/* 2>/dev/null
                #rm -R $DIR/FILES/* $DIR/tmp/* $DIR/tmp2/* $DIR/tmp3/* 2>/dev/null
                echo "Esborrades totes les comandes..."
                echo
            else
                mkdir -p $DIR/{HTMLS,FILES,tmp,tmp2,tmp3}
                echo "creat directori de treball i temporals"
                echo
            fi
            #
            ## comprobar si hi ha modificacions
            cd /home/pep/webtrac2pip/tractatus
            git pull
            echo
            read -n 1 -p "Comprobat amb git pull si el tractatus ha estat actualitzat"
            echo
            cd $DIR
            ## Descargar el tractatus.txt
            cp $HOME/webtrac2pip/tractatus/tractatus.txt .
            #
            cd $HOME/TRAC/webtrac/FILES/
            _desglose
            ENTRADAS=$(ls -F /home/pep/TRAC/webtrac/FILES | grep -v '/$' | grep -v index.html | wc -l)
            echo
            sed "s/ENTRADAS/$ENTRADAS/" ../plantilla1.txt > ../plantilla.txt
            cat ../plantilla.txt >> ../HTMLS/index.html
            echo
            _post
            cd ..
            cat plantilla2.txt >> HTMLS/index.html
            echo
            ###########################
            # ## eliminar directorios y ficheros temporales:
            #rm -R FILES/* tmp* file1.*
            echo
            if [ -d /var/www/html/tractatus ]
            then
                fcolor "Directori web correcta: /var/www/html/tractatus"
                #rm /var/www/html/tractatus/*.html 2>/dev/null
            else
                mkdir /var/www/html/tractatus
            fi
            pwd
            cp -u HTMLS/* /var/www/html/tractatus/
            echo
            echo "$ENTRADAS entrades en el tractatus"
            echo
            echo "done"
            exit 0
            ;;
        '--entradas' | '-e' )
            echo
            cd $DIR
            NUM=$(ls FILES/ | wc -l)
            clear
            echo
            echo  "============================================================="
            fcolor "<< La base de datos del tractatus cuenta con $NUM  entradas >>"
            echo "============================================================="
            echo
            echo "pulsar "intro" para volver al prompt"
            read
            clear
            exit
            ;;
        '--version' | '-v' )
            echo
            sed -n 4p /usr/local/bin/gestrac.sh | tr -d '#'
            echo
            exit
            ;;

        '--help' | '-h' | '?' )
            echo
            fshowhelp
            exit
            ;;
        * )
            fshowhelp
            exit
            ;;
    esac
done
clear
exit 0
