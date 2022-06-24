#!/bin/sh
#download updates and packages
sudo apt update
sudo apt upgrade -y
sudo apt install build-essential libgd-dev openssl libssl-dev unzip apache2 php gcc libdbi-perl libdbd-mysql-perl -y

#Create a user account
sudo useradd nagios
sudo groupadd nagcmd
sudo usermod -a -G nagcmd nagios
sudo usermod -a -G nagcmd www-data

#download nagios from official site
mydir_tmp=/tmp/
cd /tmp && wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.4.tar.gz -O nagioscore.tar.gz
tar xvzf nagioscore.tar.gz
dir2=/tmp/nagios-4.4.4
cd /tmp/nagios-4.4.4/

sudo ./configure --with-https-conf=/etc/apache2/sites-enabled
sudo make all
sudo make install
sudo make install-init
sudo make install-config
sudo make install-commandmode

#creating a user e-mail addess
echo "Email Addr: "
read username
sudo sed -i "s/nagios\@localhost/$username/g" /usr/local/nagios/etc/objects/contacts.cfg

#Fire up the web interface installer
sudo make install-webconf

#need a user account to start using the Nagios web interface, so naturally, you must create a user account first.
sudo htpasswd -c /usr/local/nagios/etc/htpasswd.users nagios
sudo a2enmod cgi

#you can restart the Apache Servers.
sudo systemctl restart apache2