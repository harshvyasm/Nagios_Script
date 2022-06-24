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

#Install Nagios Plugins
mydirPluginsTmp=/tmp/
cd /tmp && wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz
tar -zxvf /tmp/nagios-plugins-2.3.3.tar.gz
dirPlugins=/tmp/nagios-plugins-2.3.3/
cd /tmp/nagios-plugins-2.3.3/
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagios
sudo make
sudo make install


#Create Nagios service file
echo "[Unit]" > /etc/systemd/system/nagios.service
echo "Description=Nagios" >> /etc/systemd/system/nagios.service
echo "BindTo=network.target" >> /etc/systemd/system/nagios.service
echo "[Install]" >> /etc/systemd/system/nagios.service
echo "WantedBy=multi-user.target" >> /etc/systemd/system/nagios.service
echo "[Service]" >> /etc/systemd/system/nagios.service
echo "User=nagios" >> /etc/systemd/system/nagios.service
echo "Group=nagios" >> /etc/systemd/system/nagios.service
echo "Type=simple" >> /etc/systemd/system/nagios.service
echo "ExecStart=/usr/local/nagios/bin/nagios /usr/local/nagios/etc/nagios.cfg" >> /etc/systemd/system/nagios.service

#Enable, Start and Restart the service
sudo systemctl enable nagios.service 
sudo systemctl start nagios.service
sudo systemctl restart nagios.service

#Allowed the permission to the new user
sed -i 's/authorized_for_all_hosts=nagiosadmin/authorized_for_all_hosts=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_all_services=nagiosadmin/authorized_for_all_services=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_all_host_commands=nagiosadmin/authorized_for_all_host_commands=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_all_service_commands=nagiosadmin/authorized_for_all_service_commands=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_system_commands=nagiosadmin/authorized_for_system_commands=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_configuration_information=nagiosadmin/authorized_for_configuration_information=nagios/g' /usr/local/nagios/etc/cgi.cfg
