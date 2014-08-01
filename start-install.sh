#!/bin/bash
NORMAL="\\033[0;32m"
#normal = vert
JAUNE="\\033[1;33m"
ROUGE="\\033[1;31m"
execPath=$(readlink -f $(dirname $0))
source "$(pwd)/spinner"
install-minimal(){
	apt-get update
	apt-get upgrade -y
	apt-get install -y wget #wget  is not installed on a minimal debootstrap
}
install-prerequi(){
	start_spinner 'instalation des prerequis et mise à jours'
	install-minimal &> $execPath/log/prerequi.log
	stop_spinner $?
install-n() {
	bash $execPath/script/install-nginx &> $execPath/log/install-nginx.log 
}
install-p() {
	bash $execPath/script/install-php &> $execPath/log/install-php.log 
}
install-m() {
	bash $execPath/script/install-mariadb &> $execPath/log/install-mariadb.log 
}
install-swift() {
	php -r "readfile('https://getcomposer.org/installer');" | php -- --install-dir=/usr/local/bin/
	mv /usr/local/bin/composer.phar /usr/local/bin/composer
	echo -e "$ROUGE""renomage de composer.phar en composer de maniere à le rendre utilisable comme une commande classique""$NORMAL"
	cd /usr/local/nginx/html
	mkdir lib
	cd lib
	composer require swiftmailer/swiftmailer @stable
}
aborted(){
	echo -e "$ROUGE""Instalation annulée""$NORMAL"
}
conf-a(){
	echo -e "$ROUGE""Configutation de MariaDB annulée"
	echo -e "$ROUGE""executez /usr/local/mysql/bin/mysql_secure_installation "
	echo -e "$ROUGE""pour configurer MariaDB""$NORMAL"
}
install-sw() {
	start_spinner 'instalation de swiftmailer en cours'
	install-swift &>> $execPath/log/install-php.log
	stop_spinner $?
}
install-1() {
	start_spinner 'instalation de nginx en cours'
	install-n
	stop_spinner $?
}
install-2() {
	start_spinner 'instalation de php en cours'
	install-p
	stop_spinner $?
}
install-ph-ext(){
	start_spinner 'instalation des prérequis imagick pour en cours'
	bash $execPath/script/imagemagick &>> $execPath/log/install-php.log
	stop_spinner $?
}
install-3(){
	echo -e "$JAUNE""instalation des extention php : imagick / intl / xdebug ""$NORMAL"
	install-ph-ext
	pear channel-update pear.php.net
	pecl channel-update pecl.php.net
	echo -e "$JAUNE""instalation de imagick""$NORMAL"
	pecl install imagick 
	cp $execPath/config/php/extention/imagik.ini /usr/local/etc/php/mods-available/imagik.ini
	echo -e "$JAUNE""copie de imagik.ini dans /usr/local/etc/php/mods-available""$NORMAL"
	echo -e "$JAUNE"" instalation de intl""$NORMAL"
	pecl install intl
	echo -e "$JAUNE""copie de intl.ini dans /usr/local/etc/php/mods-available""$NORMAL"
	cp $execPath/config/php/extention/intl.ini /usr/local/etc/php/mods-available/intl.ini
	start_spinner 'instalation de xdebug cours'
	pecl install xdebug &>> $execPath/log/install-php.log
	stop_spinner $?
	echo -e "$JAUNE""copie de xdebug.ini dans /usr/local/etc/php/mods-available""$NORMAL"
	cp $execPath/config/php/extention/xdebug.ini /usr/local/etc/php/mods-available/xdebug.ini
	/etc/init.d/php-fpm start
}
install-4() { 
	while true; do
		read -p "Voulez vous installez swiftmailer ?  [y/N]" yn
			case $yn in
			[Yy]* ) install-sw; break ;;
			[Nn]* ) aborted; break ;;
			* ) echo "Il faut taper Y ou N!";;
		esac
	done
}
install-5() {
	start_spinner 'instalation de MariaDB en cours'
	install-m
	stop_spinner $?
}
secu-m () {
	while true; do
		read -p "Voulez vous configuer MariaDB ?  [y/N]" yn
			case $yn in
			[Yy]* ) /usr/local/mysql/bin/mysql_secure_installation;  break ;;
			[Nn]* ) conf-a; break ;;
			* ) echo "Il faut taper Y ou N!";;
		esac
	done
}
if [ ! $UID == 0 ]
then
	echo -e "$ROUGE""ERREUR : Ce script nécessite les droits superutilisateur""$NORMAL"
	exit 1
fi
echo -e "$ROUGE""##############################################################"
echo -e "$ROUGE""#         Ce script installe les programmes suivants :       #"
echo -e "$ROUGE""#              version de php : 5.5.14                       #"
echo -e "$ROUGE""#              version de MariaDB : 5.5                      #"
echo -e "$ROUGE""#              version de nginx : 1.6.0                      #"
echo -e "$ROUGE""#   En cas de soucis les logs d installation sont dans le    #" 
echo -e "$ROUGE""#  dossier /full-install/log il y en a un par programme      #"
echo -e "$ROUGE""##############################################################"
echo -e "$JAUNE""ATTENTION L INSTALLATION PEUT PRENDRE PLUSIEURS HEURES""$NORMAL"
while true; do
	read -p "Confirmer l'installation [O/N]: " -n 2 confirme
		case $confirme in
		[Oo]* ) break;;
		[Nn]* ) echo -e "\nAbandon Installation\n"; exit;;
		* ) echo -e "\nRepondez par Oui ou Non.\n";;
	esac
done
while true; do
	read -p "Voulez vous installer tout les programmes  ?  [y/N]" yn
		case $yn in
		[Yy]* )  install-prerequi; install-1; install-2; install-3; install-sw;install-5; sleep 5; secu-m; insserv  php-fpm; insserv  mysqld; insserv  nginx; exit ;;
		[Nn]* )  break ;;
		* ) echo "Il faut taper Y ou N!";;
	esac
done
install-prerequi
while true; do
	read -p "Voulez vous installez nginx ?  [y/N]" yn
		case $yn in
		[Yy]* ) install-1; insserv  nginx; break ;;
		[Nn]* ) aborted; break ;;
		* ) echo "Il faut taper Y ou N!";;
	esac
done
while true; do
	read -p "Voulez vous installez php ?  [y/N]" yn
		case $yn in
		[Yy]* ) install-2; install-3;install-4; insserv  php-fpm; break ;;
		[Nn]* ) aborted; break ;;
		* ) echo "Il faut taper Y ou N!";;
	esac
done
while true; do
	read -p "Voulez vous installez MariaDB ?  [y/N]" yn
		case $yn in
		[Yy]* ) install-5; insserv  mysqld; secu-m; break ;;
		[Nn]* ) aborted; break ;;
		* ) echo "Il faut taper Y ou N!";;
	esac
done
exit 0



