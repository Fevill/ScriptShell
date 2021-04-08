#!/bin/sh

### MODE SECURE
set -u # en cas de variable non définit, arreter le script
set -e # en cas d'erreur (code de retour non-zero) arreter le script

### UTILITER ###
# fonctions, variables, etc.
# afin d'eviter les collisions, je vais préfixer mes fonction par gl_
# gl = GilLab
DOMAINE_NAME=""

# Afficher de l'aide
gl_help(){
	1>&2 echo "Usage: ./script.sh DOMAIN"
	1>&2 echo ""
}

# Vérifier que le script est lancé en tant que root
gl_assert_root(){
	REAL_ID="$(id -u)"
	if [ "$REAL_ID" -ne 0 ]; then
		1>&2 echo "ERREUR: Le script doit etre exécuté en tant que root"
		exit 1
	fi
}


### POINT D'ENTRER DU SCRIPT ###

## Vérifier que le script est lancé en tant que root
gl_assert_root

## Instalation des dépendences
DOMAIN_NAME="${1:-}"
if [ -z "$DOMAIN_NAME" ]; then
	gl_help
	1>&2 echo "ERREUR: Définisser un paramètre DOMAIN"
	exit 1
fi

apt-get update
apt-get install -y curl openssh-server ca-certificates perl
apt-get install -y postfix

## Récuperer le package GitLab et l'installer
curl https://packages.gitlab.com/install/repositories/gitlab/gitlab-ee/script.deb.sh | bash
EXTERNAL_URL="http://$DOMAIN_NAME" apt-get install gitlab-ee

## Configuration /etc/gitlab/gitlab.rb
cp /etc/gitlab/gitlab.rb 	/etc/gitlab/gitlab.rb.s
sed \
	-e "s/# letsencrypt['enable'] = nil/letsencrypt['enable'] = true/" \
	-e "s/external_url 'http/external_url 'https/" \
	< /etc/gitlab/gitlab.rb \
	> /etc/gitlab/gitlab.rb_
mv /etc/gitlab/gitlab.rb_ /etc/gitlab/gitlab.rb
gitlab-ctl reconfigure


echo ""
echo "SUCCESS"
