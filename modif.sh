#! /bin/bash
#
# modif-fichier.sh


PATH_FILE="/etc/"
NAME_FILE="crontab"
NOM_FICHIER="/etc/crontab"
MAIL_ADMIN="joan@outlook.fr"
BOOL_MODIF=$(find $PATH_FILE -name $NAME_FILE -mtime -1 -print)


if [ "${BOOL_MODIF}" != NULL ]; then
	CORPS_MESSAGE="Alerte, le fichier ${NOM_FICHIER} a été modifié";
	echo "$CORPS_MESSAGE" | mail -s "Alerte surveillance modification de fichier" "${MAIL_ADMIN}";
	echo "mdr lol\n"
fi
