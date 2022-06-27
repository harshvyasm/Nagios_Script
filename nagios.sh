#!/bin/sh
#download updates and packages
sleep 10s
echo "download updates and packages"
sudo apt update
sudo apt upgrade -y
sudo apt install build-essential libgd-dev openssl libssl-dev unzip apache2 php gcc libdbi-perl libdbd-mysql-perl -y

#Create a user account
sleep 10s
echo "Create a user account"
sudo useradd nagios
sudo groupadd nagcmd
sudo usermod -a -G nagcmd nagios
sudo usermod -a -G nagcmd www-data

#download nagios from official site
sleep 10s
echo "download nagios from official site"
mydir_tmp=/tmp/
cd /tmp && wget https://assets.nagios.com/downloads/nagioscore/releases/nagios-4.4.4.tar.gz -O nagioscore.tar.gz
tar xvzf nagioscore.tar.gz
dir2=/tmp/nagios-4.4.4
cd /tmp/nagios-4.4.4/

sleep 5s
echo "configure apache and https"
sudo ./configure --with-https-conf=/etc/apache2/sites-enabled
sleep 5s
echo "Make all"
sudo make all
sleep 5s
echo "Make Install"
sudo make install
sleep 5s
echo "Make Install-init"
sudo make install-init
sleep 5s
echo "Make Install-config"
sudo make install-config
sleep 5s
echo "Make Install-commandmode"
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
sleep 10s
echo "Restart Apache Service"
sudo systemctl restart apache2

#Install Nagios Plugins
sleep 10s
echo "Install Nagios Plugins"
mydirPluginsTmp=/tmp/
cd /tmp && wget https://nagios-plugins.org/download/nagios-plugins-2.3.3.tar.gz
tar -zxvf /tmp/nagios-plugins-2.3.3.tar.gz
dirPlugins=/tmp/nagios-plugins-2.3.3/
cd /tmp/nagios-plugins-2.3.3/
sudo ./configure --with-nagios-user=nagios --with-nagios-group=nagios
sudo make
sudo make install


#Create Nagios service file
sleep 10s
echo "Create Nagios service file"
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
sleep 5s
echo " Nagios Service"
sudo systemctl enable nagios.service 
sleep 5s
echo "Start Nagios Service"
sudo systemctl start nagios.service
sleep 5s
echo "Restart Nagios Service"
sudo systemctl restart nagios.service

#Allowed the permission to the new user
sed -i 's/authorized_for_all_hosts=nagiosadmin/authorized_for_all_hosts=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_all_services=nagiosadmin/authorized_for_all_services=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_all_host_commands=nagiosadmin/authorized_for_all_host_commands=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_all_service_commands=nagiosadmin/authorized_for_all_service_commands=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_system_commands=nagiosadmin/authorized_for_system_commands=nagios/g' /usr/local/nagios/etc/cgi.cfg
sed -i 's/authorized_for_configuration_information=nagiosadmin/authorized_for_configuration_information=nagios/g' /usr/local/nagios/etc/cgi.cfg

#windows configuration settings

echo "###############################################################################
# WINDOWS.CFG - SAMPLE CONFIG FILE FOR MONITORING A WINDOWS MACHINE
#
#
# NOTES: This config file assumes that you are using the sample configuration
#    files that get installed with the Nagios quickstart guide.
#
###############################################################################



###############################################################################
#
# HOST DEFINITIONS
#
###############################################################################

# Define a host for the Windows machine we'll be monitoring
# Change the host_name, alias, and address to fit your situation

define host {

    use                     windows-server          ; Inherit default values from a template
    host_name               Application-test         ; The name we're giving to this host
    alias                   Application Server      ; A longer name associated with the host
    address                 10.0.101.44             ; IP address of the host
    notifications_enabled   1
    notification_period     24x7
    notification_options    d,u,r,f,s
    notification_interval   5
    contact_groups          admins
    contacts                nagios
}

define host {

    use                     windows-server          ; Inherit default values from a template
    host_name               screening-test           ; The name we're giving to this host
    alias                   Screening Server        ; A longer name associated with the host
    address                 10.0.103.220             ; IP address of the host
    notifications_enabled   1
    notification_period     24x7
    notification_options    d,u,r,f,s
    notification_interval   5
    contact_groups          admins
    contacts                nagios
}

define host {

    use                     windows-server          ; Inherit default values from a template
    host_name               database-test            ; The name we're giving to this host
    alias                   Database Server         ; A longer name associated with the host
    address                 10.0.101.59             ; IP address of the host
    notifications_enabled   1
    notification_period     24x7
    notification_options    d,u,r,f,s
    notification_interval   5
    contact_groups          admins
    contacts                nagios
}

###############################################################################
#
# HOST GROUP DEFINITIONS
#
###############################################################################

# Define a hostgroup for Windows machines
# All hosts that use the windows-server template will automatically be a member of this group

define hostgroup {

    hostgroup_name          windows-servers         ; The name of the hostgroup
    alias                   Windows Servers         ; Long name of the group
}



###############################################################################
#
# SERVICE DEFINITIONS
#
###############################################################################

# Create a service for monitoring the version of NSCLient++ that is installed
# Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               Application-test
    service_description     NSClientversion
    check_command           check_nt!CLIENTVERSION
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}



#  Create a service for monitoring the uptime of the server
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               Application-test
    service_description     Uptime
    check_command           check_nt!UPTIME
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}



#  Create a service for monitoring CPU load
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               Application-test
    service_description     CPU Load
    check_command           check_nt!CPULOAD!-l 5,80,90
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}



#  Create a service for monitoring memory usage
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               Application-test
    service_description     Memory Usage
    check_command           check_nt!MEMUSE!-w 80 -c 90
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}



#  Create a service for monitoring C:\ disk usage
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               Application-test
    service_description     C Drive Space
    check_command           check_nt!USEDDISKSPACE!-l c -w 80 -c 90
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}



#  Create a service for monitoring the W3SVC service
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               Application-test
    service_description     W3SVC
    check_command           check_nt!SERVICESTATE!-d SHOWALL -l W3SVC
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Define a service to check HTTP on the local machine.
#  Disable notifications for this service by default, as not all users may have HTTP enabled.

define service {

    use                     generic-service           ; Name of service template to use
    host_name               Application-test
    service_description     HTTPS
    check_command           check_http! -S -u /RegTechone
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Define a service to check RegTechOne service is running on the local machine.

define service {

    use                     generic-service           ; Name of service template to use
    host_name               Application-test
    service_description     RegTechOne
    check_command           check_nt!SERVICESTATE!-d SHOWALL -l RegTechOneServiceHost
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   2
}

#  Create a service for monitoring the version of NSCLient++ that is installed
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               screening-test
    service_description     NSClientversion
    check_command           check_nt!CLIENTVERSION
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}



#  Create a service for monitoring the uptime of the server
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               screening-test
    service_description     Uptime
    check_command           check_nt!UPTIME
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Create a service for monitoring CPU load
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               screening-test
    service_description     CPU Load
    check_command           check_nt!CPULOAD!-l 5,80,90
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}



#  Create a service for monitoring memory usage
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               screening-test
    service_description     Memory Usage
    check_command           check_nt!MEMUSE!-w 80 -c 90
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Create a service for monitoring C:\ disk usage
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               screening-test
    service_description     C Drive Space
    check_command           check_nt!USEDDISKSPACE!-l c -w 80 -c 90
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Define a service to check HTTP on the local machine.
#  Disable notifications for this service by default, as not all users may have HTTP enabled.

define service {

    use                     generic-service           ; Name of service template to use
    host_name               screening-test
    service_description     HTTPS
    check_command           check_http! -S -u /api/diag/nodes -p 8090
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Create a service for monitoring the version of NSCLient++ that is installed
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               database-test
    service_description     NSClientversion
    check_command           check_nt!CLIENTVERSION
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Create a service for monitoring the uptime of the server
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               database-test
    service_description     Uptime
    check_command           check_nt!UPTIME
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}


#  Create a service for monitoring CPU load
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               database-test
    service_description     CPU Load
    check_command           check_nt!CPULOAD!-l 5,80,90
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}


#  Create a service for monitoring memory usage
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               database-test
    service_description     Memory Usage
    check_command           check_nt!MEMUSE!-w 90 -c 95
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Create a service for monitoring C:\ disk usage
#  Change the host_name to match the name of the host you defined above

define service {

    use                     generic-service
    host_name               database-test
    service_description     C Drive Space
    check_command           check_nt!USEDDISKSPACE!-l c -w 80 -c 90
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Define a service to check HTTP on the local machine.
#  Disable notifications for this service by default, as not all users may have HTTP enabled.

define service {

    use                     generic-service
    host_name               database-test
    service_description     MSSQLserver
    check_command           check_nt!PROCSTATE!-d SHOWALL -l sqlservr.exe
    notifications_enabled   1
    notification_period     24x7
    notification_options    w,u,c,r,f,s
    check_interval          2
    notification_interval   5
}

#  Create a service for monitoring the Explorer.exe process
#  Change the host_name to match the name of the host you defined above

#define service {

#    use                     generic-service
#    host_name               winserver
#    service_description     Explorer
#    check_command           check_nt!PROCSTATE!-d SHOWALL -l Explorer.exe" > /usr/local/nagios/etc/objects/windows.cfg

echo "Enter IP Application-test: "
read ip1
sudo sed -i "s/10\.0\.101\.44/$ip1/g" /usr/local/nagios/etc/objects/windows.cfg

echo "Enter IP screening-test: "
read ip2
sudo sed -i "s/10\.0\.103\.220/$ip2/g" /usr/local/nagios/etc/objects/windows.cfg

echo "Enter IP database-test: "
read ip3
sudo sed -i "s/10\.0\.101\.59/$ip3/g" /usr/local/nagios/etc/objects/windows.cfg