#!/bin/sh

### MODE SECURE
set -u # en cas de variable non définit, arreter le script
set -e # en cas d'erreur (code de retour non-zero) arreter le script

### UTILITER ###
# fonctions, variables, etc.
# afin d'eviter les collisions, je vais préfixer mes fonction par sw_
DOMAINE_NAME=""

# Afficher de l'aide
sw_help(){
	1>&2 echo "Usage: ./script.sh DOMAIN"
	1>&2 echo ""
}

# Vérifier que le script est lancé en tant que root
sw_assert_root(){
	REAL_ID="$(id -u)"
	if [ "$REAL_ID" -ne 0 ]; then
		1>&2 echo "ERREUR: Le script doit etre exécuté en tant que root"
		exit 1
	fi
}

# Une fonction qui vérifie si un package est installé
# et qui sinon l'installe
sw_install_package(){
	PACKAGE_NAME="$1"
	if ! dpkg -l |grep --quiet "^ii.*PACKAGE_NAME "; then
		apt-get install -y "$PACKAGE_NAME"
	fi
}

sw_apache2_vhost_create(){
	DOMAIN="$1"
	DIRECTORY="/var/www/$1"
	CONFIG_FILE=$(echo "$DOMAIN" |tr '.' '-')
	sed \
		-e "s/#ServerName www.example.com/ServerName $DOMAIN/" \
		-e "s|DocumentRoot /var/www/html|DocumentRoot $DIRECTORY|" \
		< /etc/apache2/sites-available/000-default.conf \
		> "/etc/apache2/sites-available/$CONFIG_FILE.conf"
	a2ensite "$CONFIG_FILE" > /dev/null
}

sw_host_entry_add(){
	DOMAIN="$1"
	if ! grep -q "127.0.0.1.*$DOMAIN" /etc/hosts ; then
		echo "127.0.0.1 $DOMAIN" >> /etc/hosts
	fi
}

sw_apache2_reload(){
	systemctl stop apache2
	systemctl start apache2
}

sw_apache2_datadir_setup(){
	TARGET_DIRECTORY="$1"
	DOMAIN="$2"
	if [ ! -d "$TARGET_DIRECTORY" ];then
		mkdir -p "$TARGET_DIRECTORY"
	fi
	echo "Serveur web $DOMAIN Opérationnel" > "$TARGET_DIRECTORY/index.html"
	chown -R www-data:www-data "$TARGET_DIRECTORY"
}

sw_create_virtualhost(){
DOMAIN="$1"
DIRECTORY="/var/www/$1"

## Créer le conteneur
sw_apache2_datadir_setup "$DIRECTORY" "$DOMAIN"

## Créer la configuration du site demandé
sw_apache2_vhost_create "$DOMAIN"

## Créer l'entrée hosts du site demandé
sw_host_entry_add "$DOMAIN"

## Recharger  la configuration de apache
sw_apache2_reload

}

### POINT D'ENTRER DU SCRIPT ###

## Vérifier que le script est lancé en tant que root
sw_assert_root

## Vérifier que le script possède les bons parametres
DOMAIN_NAME="${1:-}"
if [ -z "$DOMAIN_NAME" ]; then
	sw_help
	1>&2 echo "ERREUR: Définisser un paramètre DOMAIN"
	exit 1
fi

## Installer les prérequis si nécessaire (apache, php, etc.)
sw_install_package "apache2"
sw_install_package "php7.3"
sw_install_package "libapache2-mod-php7.3"
sw_install_package "w3m"

## Créer le dossier du site demandé
sw_create_virtualhost "$DOMAIN_NAME"

echo "SUCCESS"
