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
	apt-get install -y wget zlib1g make #wget  is not installed on a minimal debootstrap
	apt-get purge openssl -y
}
install-prerequi(){
	start_spinner 'Instaling dependancies and update '
	install-minimal &> $execPath/log/prerequi.log
	stop_spinner $?
}
install-ssl(){
	start_spinner 'Install openssl in progress'
	bash $execPath/script/install-openssl &> $execPath/log/install-openssl.log
	stop_spinner $?
}
aborted(){
	echo -e "$ROUGE""Install aborted""$NORMAL"
}
conf-a(){
	echo -e "$ROUGE""MariaDB configuration aborted"
	echo -e "$ROUGE""use /usr/local/mysql/bin/mysql_secure_installation "
	echo -e "$ROUGE""to configure""$NORMAL"
}
install-1() {
	start_spinner 'Install nginx in progress'
	bash $execPath/script/install-nginx &> $execPath/log/install-nginx.log
	stop_spinner $?
}
install-2() {
	start_spinner 'Install php in progress'
	bash $execPath/script/install-php &> $execPath/log/install-php.log
	stop_spinner $?
}
install-ph-ext(){
	start_spinner 'Install imagick dependancies in progress'
	bash $execPath/script/imagemagick &>> $execPath/log/install-php.log
	stop_spinner $?
}
install-3(){
	echo -e "$JAUNE""Install imagik / intl / xdebug (php add-on)""$NORMAL"
	install-ph-ext
	pear channel-update pear.php.net
	pecl channel-update pecl.php.net
	echo -e "$JAUNE""install imagick""$NORMAL"
	pecl install imagick 
	cp $execPath/config/php/extention/imagik.ini /usr/local/etc/php/mods-available/imagik.ini
	echo -e "$JAUNE""Making imagick alvaible to php""$NORMAL"
	echo -e "$JAUNE"" install intl""$NORMAL"
	pecl install intl
	echo -e "$JAUNE""Making intl alvaible to php""$NORMAL"
	cp $execPath/config/php/extention/intl.ini /usr/local/etc/php/mods-available/intl.ini
	start_spinner 'install xdebug in progress'
	pecl install xdebug &>> $execPath/log/install-php.log
	stop_spinner $?
	echo -e "$JAUNE""Making xdebug alvaible to php""$NORMAL"
	cp $execPath/config/php/extention/xdebug.ini /usr/local/etc/php/mods-available/xdebug.ini
	/etc/init.d/php-fpm start
}
install-5() {
	start_spinner 'install MariaDB in progress'
	bash $execPath/script/install-mariadb &> $execPath/log/install-mariadb.log
	stop_spinner $?
}
secu-m () {
	while true; do
		read -p "Want to configure MariaDB ?  [y/N]" yn
			case $yn in
			[Yy]* ) /usr/local/mysql/bin/mysql_secure_installation;  break ;;
			[Nn]* ) conf-a; break ;;
			* ) echo "Type Y or N!";;
		esac
	done
}
if [ ! $UID == 0 ]
then
	echo -e "$ROUGE""ERROR : This script need root access""$NORMAL"
	exit 1
fi
echo -e "$ROUGE""#########################################################"
echo -e "$ROUGE""# This script install:                                  #"
echo -e "$ROUGE""#            openssl : 1.0.1i                           #"
echo -e "$ROUGE""#                php : 5.5.16                           #"
echo -e "$ROUGE""#            MariaDB : 5.5.39                           #"
echo -e "$ROUGE""#              nginx : 1.6.1                            #"
echo -e "$ROUGE""#   Install logs can be found in ./full-install/log     #"
echo -e "$ROUGE""#########################################################"
echo -e "$JAUNE""Warning this install can run some time""$NORMAL"
while true; do
	read -p "Confirm install [Y/N]: " -n 2 confirme
		case $confirme in
			[Yy]* ) break;;
			[Nn]* ) aborted; exit;;
		* ) echo  "Type Y or N!";;
	esac
done
while true; do
	read -p "Want to  install all  ?  [y/N]" yn
		case $yn in
		[Yy]* )  install-prerequi; install-ssl; install-1; install-2; install-3;install-5; sleep 5; secu-m; insserv  php-fpm; insserv  mysqld; insserv  nginx; exit ;;
		[Nn]* )  break ;;
		* ) echo "Type Y or N!";;
	esac
done
install-prerequi
while true; do
	read -p "Want to  install openssl ?  [y/N]" yn
		case $yn in
		[Yy]* ) install-ssl; break ;;
		[Nn]* ) aborted; break ;;
		* ) echo "Type Y or N!";;
	esac
done
while true; do
	read -p "Want to  install nginx ?  [y/N]" yn
		case $yn in
		[Yy]* ) install-1; insserv  nginx; break ;;
		[Nn]* ) aborted; break ;;
		* ) echo "Type Y or N!";;
	esac
done
while true; do
	read -p "Want to  install php ?  [y/N]" yn
		case $yn in
		[Yy]* ) install-2; install-3; insserv  php-fpm; break ;;
		[Nn]* ) aborted; break ;;
		* ) echo "Type Y or N!";;
	esac
done
while true; do
	read -p "Want to  install MariaDB ?  [y/N]" yn
		case $yn in
		[Yy]* ) install-5; insserv  mysqld; secu-m; break ;;
		[Nn]* ) aborted; break ;;
		* ) echo "Type Y or N!";;
	esac
done
exit 0



