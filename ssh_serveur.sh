#!/bin/bash
# Meta données
	echo ""
	echo "************************************************"
	echo "Script : $0"
	#Autheur Gerard Fevill
	echo "Autheur : Gerard Fevill"
	echo "************************************************"

# Déclaration desvariable
USERNAME=""
SYSTEMNAME=""
SSHD_CONFIG_PATH="/etc/ssh/sshd_config"
SSHD_CONFIG_PATH_SAVE="/etc/ssh/sshd_config.save"
PARAM_1=$1
PARAM_2=$2
set -u

# help
ss_help(){
    echo "Ce script configuer la par-feu et"
    echo "autorise une connexion ssh avec le nom de l'utilisateur"
    echo "renter en parametre sur un systeme \`Linux\`"   
    echo "[OPTION]"
    echo "	-name : Enter l'option \`-name\` suivi du nom"
    echo "		de l'utilisateur du serveur ssh"
    echo "		exemple :" 
    echo "		\`./ssh_serveur -name lara\`"
    echo ""
    echo "	--help|-h : affiche l'aide"
}

# Configuration de sshd_config
ss_sshd_config(){
FIND_ALLOWUSERS=""
NEW_ALLOWUSERS=$(echo "AllowUsers	$USERNAME	")
	
	echo $FIND_ALLOWUSERS
	echo $NEW_ALLOWUSERS
	echo $SSHD_CONFIG_PATH
	# Retrai des drois de connexion de l'utilisateur root
	cat $SSHD_CONFIG_PATH > $SSHD_CONFIG_PATH_SAVE

	cat $SSHD_CONFIG_PATH | sed  "s.#PermitRoot.PermitRoot." > $SSHD_CONFIG_PATH
	
	cat $SSHD_CONFIG_PATH
	
	# Autorisation de la connetion ssh de l'utilisateur `username`
	#FIND_ALLOWDS_USERS=$(cat /etc/ssh/sshd_config_tmp | grep lar | wc -l)
	#echo $FIND_ALLOWUSERS
	#if [ $FIND_ALLOWUSERS = 0 ]; then
	#	$NEW_ALLOWUSERS >> $SSHD_CONFIG_PATH	
	#elif [ $FIND_ALLOWUSERS = 1 ]; then		
	#cat $SSHD_CONFIG_PATH | sed  ".AllowUsers.s.AllowUsers.$NEW_ALLOWUSERS." \
	#	>> $SSHD_CONFIG_PATH
	#fi
}

# verifaction de systeme
SYSTEMNAME=$(uname)
if [ -z $SYSTEMNAME ] || [ $SYSTEMNAME != 'Linux' ];  then
	echo "Votre systeme est $SYSTEMNAME"
	echo 'Ce script doit etre executer sur un systeme \`Linux\`'
	exit 1
fi

# Vérification de parametres
if [ -z $PARAM_1 ]; then
      echo "Aucune option n'est définit"
      ss_help
      exit 1
fi

# Option d'aide
if [ $PARAM_1 = '--help' ] || [ $PARAM_1 = '-h' ]; then
	# Afficher l'aide
	ss_help
	exit 0
fi

# Debut du script
if [ $PARAM_1 = '-name' ] && [[ $PARAM_2 != '' ]]; then

# Initialisation de la variable nom d'utilisateur
USERNAME=$PARAM_2

	# Création d'un nouveau utilisateur
	echo ""
	echo ""
	echo "*****************************"
	echo "Création d'un utilisatuer"
	adduser $USERNAME

	# Octroi de privilège administratifs
	usermod -aG sudo $USERNAME
	# Rendre utilisateur propritaire de répertoir /home/[username]/.ssh
	#chown -R $USERNAME:$USERNAME /home/$USERNAME/.ssh

	# Configuration du par-feu
	echo ""
	echo ""
	echo "*****************************"
	echo "Instalation du Firewall"
	apt install ufw
	ufw allow OpenSSH
	ufw enable
	ufw status

	# Configuration du fichier `/etc/ssh/sshd_config`
	echo ""
	echo ""
	echo "*****************************"
	echo "Configure de ssh"
	ss_sshd_config	
	exit 0
else
	echo "Nombre de parametre insuffisant"
	echo "Attendu \`2\` speficié 1 (-name)"
	exit 1
fi
