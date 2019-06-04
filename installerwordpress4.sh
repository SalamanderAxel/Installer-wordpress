#!/bin/bash

# Wordpress server installer for Debian , Ubuntu, CentOS, Fedora 
# Author Salamander

function isRoot () {
	if [ "$EUID" -ne 0 ]; then
		return 1
	fi
}

function checkOS () {
	if [[ -e /etc/debian_version ]]; then
		OS="debian"
		source /etc/os-release

		if [[ "$ID" == "debian" ]]; then
				if [[ ! $VERSION_ID =~ (9) ]]; then
				echo "Your version of Debian is not supported."
				echo "Hovewer, if you're using debian > 9 or unstable/testing then you can continue."
				echo ""
				until [[ $COUNTINUE =~ (y/n) ]]; do
					read -rp "Continue? [y|n]: " -e CONTINUE
				done
				if [[ "$CONTINUE" = "n" ]]; then
					exit  1
				fi
			fi
		elif [[ "$ID" == "ubuntu" ]]; then
			OS="ubuntu"
			if [[ ! $VERSION_ID =~ (16.04) ]]; then
				echo " Your version of Ubuntu is not supported."
				echo ""
				echo "However, if you're using Ubuntu > 16 or beta, then you can continue."
				echo "Keep in mind they are not supported, though."
				echo ""
				until [[ $CONTINUE =~ (y|n) ]]; do
					read -rp "Continue? [y/n]: " -e CONTINUE
				done
				if [[ "$CONTINUE" = "n" ]]; then
					exit 1
				fi
			fi
		fi
		elif [[ -e /etc/fedora-release ]]; then
		OS=fedora
		elif [[ -e /etc/centos-release ]]; then
			if ! grep -qs "^CentOS Linux release 7" /etc/centos-release; then
				echo "Your version of CentOS is not supported."
				echo "The script only support CentOS 7."
				echo ""
				unset CONTINUE
				until [[ $CONTINUE =~ (y|n) ]]; do
				read -rp "Continue anyway? [y/n]: " -e CONTINUE
				done
				if [[ "$CONTINUE" = "n" ]]; then
					echo "Ok, bye!"
					exit 1
				fi
			fi
		OS=centos
	else
		echo "I Thing you're not using a Debian, Ubuntu, CentOS. try to use 3 of them.?"
		exit 1
	fi
}

function initialCheck () {
	if ! isRoot; then
		echo "Sorry, you need to run this as root"
		exit 1
	fi
	checkOS
}

function installerWordpressD () {
	installQuestion

	if [[ "$OS" =~ (debian|ubuntu) ]]; then
		apt-get update
		if [[ "$VERSION_ID" = "9" ]]; then
		# Install LAMP
		echo "Preraring install LAMP (linux, Apache, Mysql, PHP) on debian..."
		ApacheInstalldeb
		MariaDBinstalldeb
		MariaDBadmindeb
		PHPinstalldeb

		# Install OpenSSL
		echo "Preraring install SSL Self Signed on debian..."
		OpenSSLdeb
		SSLparamsconfdeb
		SSLparamsdeb

		# Install Wordpress
		echo "preparing install Wordpress on debian"
		wordpressinstalldeb
		echo "Installing has been finised, please visit your IP public to configure yours wordpress" 
		fi

		if [[ "$VERSION_ID" = "16.04" ]]; then

		# Install LAMP
		echo "preparing install LAMP linux, Apache, Mysql, PHP on Ubuntu..."
		ApacheInstallubu
		Mysqlubu
		PHPinstallubu

		# Install SSL
		echo "preparing install SSL Self Signed on Ubuntu..."
		OpenSSLubu
		SSLparamsconfubu
		SSLparamsubu

		# Install Wordpress
		echo "preparing install Wordpress on Ubuntu"
		wordpressinstallubu
		echo "Installing has been finised, please visit your IP public to configure yours wordpress"
		fi
		
		elif [[ "$OS" = 'centos' ]]; then
		# Install LAMP 
		echo "Preparing install LAMP (linux, Apache, Mysql, PHP) on CentOS"
		ApacheInstallcen
		Mysqlcen
		PHPInstallcen
		
		# Install SSL
		echo "Preparing install SSL Self Signef on CentOS"
		OpenSSLcen
		Opensslparamcen
		Opensslnonssl
		aDBdatabasecen
		
		# Install Wordpress
		echo "Preparing install Wordpress on Ubuntu"
		installwordpresscen
		
		# Install firewall
		echo "Preparing enable firewall to http and https"
		firewallcen
		enableIptabcen
		echo "Installing has been finised, please visit your IP public to configure yours wordpress"
		fi
}


# function install LAMP CentOS

function ApacheInstallcen () {
	sudo yum install httpd -y
	sudo systemctl start httpd.service
	sudo systemctl enable httpd.service
}

function questionOpenSSL () {
	echo "I need ask some questions about our server information and embed the information correcly on the server"
	until [[ "$countryId" != "" ]]; do
		read -rp "Country Name (2 latter code) [ID] : " -e countryId
	done
	until [[ "$provinceName" != "" ]]; do
		read -rp "State or Province Name (full name) [Some-State] : " -e provinceName
	done
	until [[ "$cityLocal" != "" ]]; do
		read -rp "Locality Name (eg, city) [] : " -e cityLocal
	done
	until [[ "$companyName" != "" ]]; do
		read -rp "Organization Name (eg, company) [Internet Widgits Pty Ltd] : " -e companyName
	done
	until [[ "$unitName" != "" ]]; do
		read -rp "Organizational Unit Name (eg, section) [] : " -e unitName
	done
	until [[ "$commonName" != "" ]]; do
		read -rp "Common Name (e.g. server FQDN or YOUR name) [] : " -e commonName
	done
	until [[ "$youEmail" != "" ]]; do
		read -rp "Email Address []: " -e youEmail
	done
}

function Mysqlcen () {
	sudo yum install mariadb-server mariadb -y
	sudo systemctl start mariadb 
	sudo yum install expect -y

        Mysqlconfigure==$(expect -c "
        set timeout 10
        spawn mysql_secure_installation
        expect \"Enter current password for root:\"
        send \"\r\"
        expect \"Set root password?\"
        send \"y\r\"
        expect \"New password:\"
        send \"$MysqlSecure\r\"
        expect \"Re-enter new password :\"
        send \"$MysqlSecure\r\"
        expect \"Remove anonymous users?\"
        send \"y\r\"
        expect \"Disallow root login remotely?\"
        send \"y\r\"
        expect \"Remove test database and access to it?\"
        send \"y\r\"
        expect \"Reload privilege tables now?\"
        send \"y\r\"
        expect eof
        ")

        echo "$Mysqlconfigure"s
	sudo systemctl enable mariadb.service
}

function PHPInstallcen () {
	sudo yum install php php-mysql -y
	sudo systemctl restart httpd.service
	sudo yum install php-fpm -y
}

# function install SSL CentOS

function OpenSSLcen () {
	sudo yum install mod_ssl -y
	sudo mkdir /etc/ssl/private
	sudo chmod 700 /etc/ssl/private
	ssl==$(expect -c "
        set timeout 10
        spawn openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
        expect \"Country Name (2 letter code):\"
        send \"$countryId\r\"
        expect \"State or Province Name (full name):\"
        send \"$provinceName\r\"
        expect \"Locality Name (eg, city):\"
        send \"$cityLocal\r\"
        expect \"Organization Name (eg, company):\"
        send \"$companyName\r\"
        expect \"Organizational Unit Name (eg, section):\"
        send \"$unitName\r\"
        expect \"Common Name (e.g. server FQDN or YOUR name):\"
        send \"$commonName\r\"
        expect \"Email Address:\"
        send \"$youEmail\r\"
        expect eof
        ")

        echo "$ssl"
        sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
	cat /etc/ssl/certs/dhparam.pem | sudo tee -a /etc/ssl/certs/apache-selfsigned.crt
}

function Opensslparamcen () {
	sed -i '62iDocumentRoot "/var/www/html"' /etc/httpd/conf.d/ssl.conf
	sed -i '63iServerName $thisIP' /etc/httpd/conf.d/ssl.conf
	sed -i 's/SSLProtocol all -SSLv2 -SSLv3/\# SSLProtocol all -SSLv2 -SSLv3/g' /etc/httpd/conf.d/ssl.conf
	sed -i 's/SSLCipherSuite HIGH:3DES:!aNULL:!MD5:!SEED:!IDEA/\# SSLCipherSuite HIGH:3DES:!aNULL:!MD5:!SEED:!IDEA/g' /etc/httpd/conf.d/ssl.conf
	sed -i 's/SSLCertificateFile \/etc\/pki\/tls\/certs\/localhost.crt/SSLCertificateFile \/etc\/ssl\/certs\/apache-selfsigned.crt/g' /etc/httpd/conf.d/ssl.conf
	sed -i 's/SSLCertificateKeyFile \/etc\/pki\/tls\/private\/localhost.key/SSLCertificateKeyFile \/etc\/ssl\/private\/apache-selfsigned.key/g' /etc/httpd/conf.d/ssl.conf
	sed -i '219iSSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH' /etc/httpd/conf.d/ssl.conf
	sed -i '220iSSLProtocol All -SSLv2 -SSLv3' /etc/httpd/conf.d/ssl.conf
	sed -i '221iSSLHonorCipherOrder On' /etc/httpd/conf.d/ssl.conf
	sed -i '222iHeader always set Strict-Transport-Security "max-age=63072000; includeSubdomains"' /etc/httpd/conf.d/ssl.conf
	sed -i '223iHeader always set X-Frame-Options DENY' /etc/httpd/conf.d/ssl.conf
	sed -i '224iHeader always set X-Content-Type-Options nosniff' /etc/httpd/conf.d/ssl.conf
	sed -i '225iSSLCompression off' /etc/httpd/conf.d/ssl.conf
	sed -i '226iSSLUseStapling on' /etc/httpd/conf.d/ssl.conf
	sed -i '227iSSLStaplingCache "shmcb:logs/stapling-cache(150000)"' /etc/httpd/conf.d/ssl.conf
}

function Opensslnonssl () {
	cat <<-EOF > non-ssl.conf
	<VirtualHost *:80>
		ServerName $thisIP
		Redirect "/" "https://$thisIP/"
	</VirtualHost>
	EOF

	cp non-ssl.conf /etc/httpd/conf.d/
	sudo apachectl configtest
	sudo systemctl restart httpd.service
}

# function install Mysql

function aDBdatabasecen () {
        MariaDBdatabasecen=$(expect -c "
        set timeout 10
        spawn mysql -u root -p
        expect \"Enter password: \"
        send \"$MysqlSecure\r\"
        expect \"MariaDB>\"
        send \"CREATE DATABASE $MariaDBName;\r\"
        expect \"MariaDB>\"
	send \"CREATE USER $MariaDBUser@localhost IDENTIFIED BY '$MariaDBPassword';\r\"
	expect \"MariaDB>\"
        send \"GRANT ALL ON $MariaDBName.* TO '$MariaDBUser'@'localhost' IDENTIFIED BY '$MariaDBPassword';\r\"
	expect \"MariaDB>\"
        send \"FLUSH PRIVILEGES;\r\"
        expect \"MariaDB>\"
        send \"exit;\r\"
        expect eof
        ")

        echo "$MariaDBdatabasecen"
}

# function install wordpress centos

function installwordpresscen () {
	sudo yum install php-gd -y
	sudo service httpd restart
	cd ~ 
	wget http://wordpress.org/latest.tar.gz
	tar xzvf latest.tar.gz
	sudo rsync -avP ~/wordpress/ /var/www/html/
	mkdir /var/www/html/wp-content/uploads
	sudo chown -R apache:apache /var/www/html/*
	cd /var/www/html/
	cp wp-config-sample.php wp-config.php
	Wpsalts
} 

# function firewall centos

function firewallcen () {
	sudo firewall-cmd --add-service=http
	sudo firewall-cmd --add-service=https
	sudo firewall-cmd --runtime-to-permanent
}

function enableIptabcen () {
	sudo iptables -I INPUT -p tcp -m tcp --dport 80 -j ACCEPT
	sudo iptables -I INPUT -p tcp -m tcp --dport 443 -j ACCEPT
}
# function install LAMP ubuntu

function ApacheInstallubu () {
	sudo apt-get install apache2 -y
	sed -i '221iServerName '$thisIP'' /etc/apache2/apache2.conf
	sudo systemctl restart apache2
	sudo ufw app list
	sudo ufw app info "Apache Full"
	sudo ufw allow in "Apache Full"
	sudo ufw status
	apt-get install curl -y
}

function Mysqlubu () {
	apt-get install expect -y 
	echo "mysql-server-5.7 mysql-server/root_password password $MysqlSecure" | sudo debconf-set-selections
	echo "mysql-server-5.7 mysql-server/root_password_again password $MysqlSecure" | sudo debconf-set-selections
	apt-get install mysql-server -y

	Mysqlconfigure==$(expect -c "
	set timeout 10
	spawn mysql_secure_installation
	expect \"Enter password for user root:\"
	send \"$MysqlSecure\r\"
	expect \"Press y|Y for Yes, any other key for No:\"
	send \"y\r\"
	expect \"Please enter 0 = LOW, 1 = MEDIUM and 2 = STRONG:\"
	send \"0\r\"
	expect \"Change the password for root ? ((Press y|Y for Yes, any other key for No) :\"
	send \"n\r\"
	expect \"Remove anonymous users? (Press y|Y for Yes, any other key for No) :\"
	send \"y\r\"
	expect \"Disallow root login remotely? (Press y|Y for Yes, any other key for No) :\"
	send \"y\r\"
	expect \"Remove test database and access to it? (Press y|Y for Yes, any other key for No) :\"
	send \"y\r\"
	expect \"Reload privilege tables now? (Press y|Y for Yes, any other key for No) :\"
	send \"y\r\"
	expect eof
	")

	echo "$Mysqlconfigure"
}

function phpindex () {
        echo "<IfModule mod_dir.c>
                DirectoryIndex index.php index.cgi index.pl index.html index.xhtml index.htm
        </IfModule>
        #vim: syntax=apache ts=4 sw=4 sts=4 sr noet
        " > /etc/apache2/mods-enabled/dir.conf
}
function PHPinstallubu () {
        sudo apt install php libapache2-mod-php php-mcrypt  php-mysql -y
	phpindex
	sudo systemctl restart apache2
        sudo apt install php-cli
}

# function install openssl ubuntu

function OpenSSLubu () {
        ssl==$(expect -c "
        set timeout 10
        spawn openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
        expect \"Country Name (2 letter code): >\"
        send \"$countryId\r\"
        expect \"State or Province Name (full name): >\"
        send \"$provinceName\r\"
        expect \"Locality Name (eg, city): >\"
        send \"$cityLocal\r\"
        expect \"Organization Name (eg, company): >\"
        send \"$companyName\r\"
        expect \"Organizational Unit Name (eg, section): >\"
        send \"$unitName\r\"
        expect \"Common Name (e.g. server FQDN or YOUR name): >\"
        send \"$commonName\r\"
        expect \"Email Address: >\"
        send \"$youEmail\r\"
        expect eof
        ")

        echo "$ssl"
	sudo openssl dhparam -out /etc/ssl/certs/dhparam.pem 2048
}

function SSLparamsconfubu () {
        cat <<-EOF > ssl-params.conf
        SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
        SSLProtocol All -SSLv2 -SSLv3
        SSLHonorCipherOrder On
        # Disable preloading HSTS for now.  You can use the commented out header line that includes
        # the "preload" directive if you understand the implications.
        Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains"
        Header always set X-Frame-Options DENY
        Header always set X-Content-Type-Options nosniff
        # Requires Apache >= 2.4
        SSLCompression off
        SSLUseStapling on
        SSLStaplingCache "shmcb:logs/stapling-cache(150000)"
	SSLOpenSSLConfCmd DHParameters "/etc/ssl/certs/dhparam.pem"
	EOF
	cp ssl-params.conf /etc/apache2/conf-available/
}

function SSLparamsubu () {
	sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak
	sed -i 's/ServerAdmin webmaster@localhost/ServerAdmin thelinuxautomation@mail.com/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i '5iServerName '$thisIP'' /etc/apache2/sites-available/default-ssl.conf
	sed -i 's/SSLCertificateFile\t\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/SSLCertificateFile\t\/etc\/ssl\/certs\/apache-selfsigned.crt/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i 's/SSLCertificateKeyFile \/etc\/ssl\/private\/ssl-cert-snakeoil.key/SSLCertificateKeyFile \/etc\/ssl\/private\/apache-selfsigned.key/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i 's/\# BrowserMatch \"MSIE \[2\-6\]\" \\/BrowserMatch \"MSIE \[2\-6\]\" \\/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i 's/\#\t\tnokeepalive ssl-unclean-shutdown \\/\t\tnokeepalive ssl-unclean-shutdown \\/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i 's/\#\t\tdowngrade-1.0 force-response-1.0/\t\tdowngrade-1.0 force-response-1.0/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i '11iRedirect "/" "https://'$thisIP'/"' /etc/apache2/sites-available/000-default.conf
	sudo ufw enable
	sudo ufw allow "Apache Full"
	sudo ufw allow 22
	sudo ufw status
	sudo a2enmod ssl
	sudo a2enmod headers
	sudo a2ensite default-ssl
	sudo a2enconf ssl-params
	sudo apache2ctl configtest
	sudo systemctl restart apache2
}

function wordpressinstallubu () {
	mariaDBdatabaseubu
	htacessubu
	cd /tmp
	curl -O https://wordpress.org/latest.tar.gz
	tar xzvf latest.tar.gz
	touch /tmp/wordpress/.htaccess
	chmod 660 /tmp/wordpress/.htaccess
	cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
	mkdir /tmp/wordpress/wp-content/upgrade
	sudo cp -a /tmp/wordpress/. /var/www/html
	cd
	sudo chown -R thelinuxautomation:www-data /var/www/html
	sudo find /var/www/html -type d -exec chmod g+s {} \;
	sudo chmod g+w /var/www/html/wp-content
	sudo chmod -R g+w /var/www/html/wp-content/themes
	sudo chmod -R g+w /var/www/html/wp-content/plugins
	Wpsalts
}

function mariaDBdatabaseubu () {

        MariaDBdatabaseubu=$(expect -c "
        set timeout 10
        spawn mysql -u root -p
        expect \"Enter password: \"
	send \"$MysqlSecure\r\"
	expect \"mysql>\"
        send \"CREATE DATABASE $MariaDBName DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;\r\"
        expect \"mysql>\"
        send \"GRANT ALL ON $MariaDBName.* TO '$MariaDBUser'@'localhost' IDENTIFIED BY '$MariaDBPassword';\r\"
        expect \"mysql>\"
        send \"FLUSH PRIVILEGES;\r\"
        expect \"mysql>\"
        send \"exit;\r\"
        expect eof
        ")

        echo "$MariaDBdatabaseubu"
	sudo apt-get update
	sudo apt-get install php-curl php-gd php-mbstring php-mcrypt php-xml php-xmlrpc -y
	sudo systemctl restart apache2
}

function htacessubu () {
	sed -i '222i<Directory /var/www/html/>' /etc/apache2/apache2.conf
	sed -i '223i\\tAllowOverride All' /etc/apache2/apache2.conf
	sed -i '224i</Directory>' /etc/apache2/apache2.conf
	sudo a2enmod rewrite
	sudo systemctl restart apache2
}

# function install LAMP on debian

function ApacheInstalldeb () {
	# Install Apache and MariaDB 
        sudo apt-get install mariadb-server -y
        sudo apt-get install apache2 -y 
	# Install and enable ufw port WWW Full and OpenSSH
	apt-get install ufw
	sudo ufw enable
	sudo ufw app info "WWW Full"
	sudo ufw allow in "WWW Full"
	sudo ufw allow 22
	sudo ufw status
	apt-get install expect -y
}

function MariaDBadmindeb () {
	Mariaadmin==$(expect -c "
	set timeout 10
	spawn mariadb
	expect \"MariaDB >\"
	send \"GRANT ALL ON *.* TO '$MariaDBuseradmin'@'localhost' IDENTIFIED BY '$MariaDBpassadmin' WITH GRANT OPTION;\r\"
	expect \"MariaDB >\"
	send \"FLUSH PRIVILEGES;\r\" 
	expect \"MariaDB >\"
	send \"exit;\r\"
	expext eof
	")

	echo "$Mariaadmin"
}

function PHPinstalldeb () {
	sudo apt install php libapache2-mod-php php-mysql -y
	echo "<IfModule mod_dir.c>
		DirectoryIndex index.php index.cgi index.pl index.html index.xhtml index.htm
	</IfModule>
	#vim: syntax=apache ts=4 sw=4 sts=4 sr noet
	" > /etc/apache2/mods-enabled/dir.conf
	sudo systemctl restart apache2
	sudo apt install php-cli
}

function MariaDBinstalldeb () {
	Secure_Mysql=$(expect -c "
	set timeout 10
	spawn mysql_secure_installation
	expect \"Enter current password for root (enter for none):\"
	send \"$MysqlSecure\r\"
	expect \"Set root password?\"
	send \"n\r\"
	expect \"Remove anonymous users?\"
	send \"y\r\"
	expect \"Disallow root login remotely?\"
	send \"y\r\"
	expect \"Remove test database and access to it?\"
	send \"y\r\"
	expect \"Reload privilege tables now?\"
	send \"y\r\"
	expect eof
	")

	echo "$Secure_Mysql"
}

# function install OpenSSL debian

function OpenSSLdeb () {
	ssl==$(expect -c "
	set timeout 10
	spawn openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout /etc/ssl/private/apache-selfsigned.key -out /etc/ssl/certs/apache-selfsigned.crt
	expect \"Country Name (2 letter code): >\"
	send \"$countryId\r\"
	expect \"State or Province Name (full name): >\"
	send \"$provinceName\r\"
	expect \"Locality Name (eg, city): >\"
	send \"$cityLocal\r\"
	expect \"Organization Name (eg, company): >\"
	send \"$companyName\r\"
	expect \"Organizational Unit Name (eg, section): >\"
	send \"$unitName\r\"
	expect \"Common Name (e.g. server FQDN or YOUR name): >\"
	send \"$commonName\r\"
	expect \"Email Address: >\"
	send \"$youEmail\r\"
	expect eof
	")

	echo "$ssl"

}

function SSLparamsconfdeb () {
	cat <<-EOF > ssl-params.conf
	SSLCipherSuite EECDH+AESGCM:EDH+AESGCM:AES256+EECDH:AES256+EDH
	SSLProtocol All -SSLv2 -SSLv3 -TLSv1 -TLSv1.1
	SSLHonorCipherOrder On
	# Disable preloading HSTS for now.  You can use the commented out header line that includes
	# the "preload" directive if you understand the implications.
	# Header always set Strict-Transport-Security "max-age=63072000; includeSubDomains; preload"
	Header always set X-Frame-Options DENY
	Header always set X-Content-Type-Options nosniff
	# Requires Apache >= 2.4
	SSLCompression off
	SSLUseStapling on
	SSLStaplingCache "shmcb:logs/stapling-cache(150000)"
	# Requires Apache >= 2.4.11
	SSLSessionTickets Off
	EOF

	cp ssl-params.conf /etc/apache2/conf-available/
}

function SSLparamsdeb () {
	sudo cp /etc/apache2/sites-available/default-ssl.conf /etc/apache2/sites-available/default-ssl.conf.bak
	sed -i 's/ServerAdmin webmaster@localhost/ServerAdmin thelinuxautomation@mail.com/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i '5iServerName '$thisIP'' /etc/apache2/sites-available/default-ssl.conf
	sed -i 's/SSLCertificateFile\t\/etc\/ssl\/certs\/ssl-cert-snakeoil.pem/SSLCertificateFile\t\/etc\/ssl\/certs\/apache-selfsigned.crt/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i 's/SSLCertificateKeyFile \/etc\/ssl\/private\/ssl-cert-snakeoil.key/SSLCertificateKeyFile \/etc\/ssl\/private\/apache-selfsigned.key/g' /etc/apache2/sites-available/default-ssl.conf
	sed -i '11iRedirect "/" "https://'$thisIP'/"' /etc/apache2/sites-available/000-default.conf
	sudo a2enmod ssl
	sudo a2enmod headers
	sudo a2ensite default-ssl
	sudo a2enconf ssl-params
	sudo apache2ctl configtest
	sudo systemctl restart apache2
}

# function wordpressinstalldeb

function mariaDBdatabasecondeb () {
        sudo apt update
        sudo apt install php-curl php-gd php-mbstring php-xml php-xmlrpc php-soap php-intl php-zip -y
        sudo systemctl restart apache2

        MariaDBdatabase=$(expect -c "
        set timeout 10
        spawn mariadb
        expect \"MariaDB >\"
        send \"CREATE DATABASE $MariaDBName DEFAULT CHARACTER SET utf8 COLLATE utf8_unicode_ci;\r\"
        expect \"MariaDB >\"
        send \"\r\"
        expect \"MariaDB >\"
        send \"GRANT ALL ON $MariaDBName.* TO '$MariaDBUser'@'localhost' IDENTIFIED BY '$MariaDBPassword';\r\"
        expect \"MariaDB >\"
        send \"FLUSH PRIVILEGES;\r\"
        expect \"MariaDB >\"
        send \"exit;\r\"
        expect eof
        ")

        echo "$MariaDBdatabase"
}
function wordpressinstalldeb () {
	mariaDBdatabasecondeb
	wordpressconfdeb

	sudo apt install curl
	cd /tmp
	curl -O https://wordpress.org/latest.tar.gz
	tar xzvf latest.tar.gz
	touch /tmp/wordpress/.htaccess
	cp /tmp/wordpress/wp-config-sample.php /tmp/wordpress/wp-config.php
	mkdir /tmp/wordpress/wp-content/upgrade
	sudo cp -a /tmp/wordpress/. /var/www/html

	cd
	sudo chown -R www-data:www-data /var/www/html
	sudo find /var/www/html/ -type d -exec chmod 750 {} \;
	sudo find /var/www/html/ -type f -exec chmod 640 {} \;

	Wpsalts
}

function Wpsalts () {
	WPSalts=$(wget https://api.wordpress.org/secret-key/1.1/salt/ -q -O -)
	TablePrefx=$(cat /dev/urandom | tr -dc 'a-zA-Z0-9' | fold -w 9 | head -n 1)_
	cat <<-EOF > wp-config.php
	<?php
	define('DB_NAME', '$MariaDBName');
	define('DB_USER', '$MariaDBUser');
	define('DB_PASSWORD', '$MariaDBPassword');
	define('DB_HOST', 'localhost');
	define('DB_CHARSET', 'utf8');
	define('DB_COLLATE', '');
	define('FS_METHOD', 'direct');
	$WPSalts
	\$table_prefix = '$TablePrefx';
	define('WP_DEBUG', false);
	if ( !defined('ABSPATH') )
	define('ABSPATH', dirname(__FILE__) . '/');
	require_once(ABSPATH . 'wp-settings.php');
	EOF

	cp wp-config.php /var/www/html/
}

function wordpressconfdeb () {
	cat <<-EOF > wordpress.conf
	<Directory /var/www/wordpress/>
    		AllowOverride All
	</Directory>
	EOF
	cp wordpress.conf /etc/apache2/sites-available/
	sudo a2enmod rewrite
	sudo apache2ctl configtest
	sudo systemctl restart apache2
}

function installQuestion () {
	thisIP=$(wget -qO- ipv4.icanhazip.com);
	echo "Welcome to the Wordpress installer!"
	echo "The git respository is available at : https://github.com/salamanderaxel/installwordpress"
	echo "Author Salamander"
	echo ""
	echo "Your IP Public Address is $thisIP"
	echo "Secure your wordpress site using SSL this script will run automatic SSL to your IP public"
	echo "" 
	echo "I need to ask a few qustions before starting the setup."
	echo ""
	if [[ "$ID" == "debian" ]]; then
	until [[ "$MariaDBuseradmin" != "" ]]; do
		read -rp "We need enter a Name for MariaDB admin : " -e MariaDBuseradmin
	done
	until [[ "$MariaDBpassadmin" != "" ]]; do
		read -rp "We need enter a Password for MariaDB admin : " -e MariaDBpassadmin
	done
	fi
	
	until [[ "$MariaDBName" != "" ]]; do
		read -rp "We need enter a name for MariaDB database Wordpress : " -e MariaDBName
	done
	until [[ "$MariaDBUser" != "" ]]; do
		read -rp "We need enter a UserName for MariaDB database Wordpress : " -e MariaDBUser
	done
	until [[ "$MariaDBPassword" != "" ]]; do
		read -rp "We need enter a Password for MariaDB database Wordpress : " -e MariaDBPassword
	done
	until [[ "$MysqlSecure" != "" ]]; do
		read -rp "We need enter current password for MariaDB root : " -e MysqlSecure
	done
	echo ""

	questionOpenSSL

	echo""
	echo""
	echo "Okay, that was all I needed. We are ready to setup wordpress on your server now."
	read -n1 -r -p "Press any key to continue..."
}

function manageMenu () {
	clear
	echo "Welcome to Wordpress Installer !"
	echo "The git repository is available at: https://github.com/salamanderaxel/installerworpress"
	echo ""
	echo "It looks like Wordpress  is already installed."
	echo ""
	echo "What do you want to do?"
	echo "   1) Check Mysql User"
	echo "   2) Revoke existing Mysql user"
	echo "   3) Remove Wordpress"
	echo "   4) Exit"
	until [[ "$MENU_OPTION" =~ ^[1-4]$ ]]; do
		read -rp "Select an option [1-4]: " MENU_OPTION
	done

	case $MENU_OPTION in
	1)
	if [[ "$OS" =~ (debian|ubuntu) ]]; then
		MysqlUser
	fi
	if [[ "$OS" = 'centos' ]]; then
		MysqlUsercen
	fi
	;;
	2)
	if [[ "$OS" =~ (debian|ubuntu) ]]; then
		revokeClient
	fi
	if [[ "$OS" = 'centos' ]]; then
		revokeClientcen
	fi
	;;
	3)
	removewordpress
	;;
	4)
		exit 0
	;;
	esac
}

function MysqlUser () {
	echo "Mysql user checking...Please wait!"
	Mysqlusr==$(expect -c "
	set timeout 10
	spawn mariadb
	expect \"MariaDB >\"
	send \"SELECT host, user FROM mysql.user;\r\"
	expect \"MariaDB >\"
	send \"exit\r\"
	expect eof
	")

	echo "$Mysqlusr"
}

function revokeClient () {
	echo "Remove User Mysql"
	until [[ "$Mysqlrm" != "" ]]; do
		read -rp "Which username do you want to delete? : " -e Mysqlrm
	done
	echo "Preparing to delete user $Mysqlrm"
	Mysqlusrrm==$(expect -c "
        set timeout 10
        spawn mariadb
        expect \"MariaDB >\"
        send \"REVOKE SUPER ON *.* FROM '$Mysqlrm'@'localhost';\r\"
	expect \"MariaDB >\"
	send \"DROP USER '$Mysqlrm'@'localhost';\r\"
        expect \"MariaDB >\"
        send \"exit\r\"
        expect eof
        ")

        echo "$Mysqlusrrm"
}

function MysqlUsercen () {
	echo "Mysql user check"
	until [[ "$MysqlSecure" != "" ]]; do
		read -rp "Please insert Mysql root password please : " -e MysqlSecure
	done

	echo "Mysql user checking...Please Wait!"
	Mysqlusr==$(expect -c "
        set timeout 10
        spawn mysql -u root -p
	expect \"Enter Password:\"
	send \"$MysqlSecure\r\"
        expect \"MariaDB >\"
        send \"SELECT host, user FROM mysql.user;\r\"
        expect \"MariaDB >\"
        send \"exit\r\"
        expect eof
        ")

        echo "$Mysqlusr"

}

function revokeClientcen () {
	echo "Remove User Mysql"
	until [[ "$MysqlSecure" != "" ]]; do
		read -rp "Please insert Mysql root password please : " -e MysqlSecure
	done
	until [[ "$Mysqlrm" != "" ]]; do
		read -rp "Which username do you want to delete? : " -e Mysqlrm
	done
	echo "Preparing to delete user $Mysqlrm"
	Mysqlusrrm==$(expect -c "
	set timeout 10
	spawn mysql -u root -p
	expect \"MariaDB >\"
	send \"REVOKE SUPER ON *.* FROM '$Mysqlrm'@'localhost';\r\"
	expect \"MariaDB >\"
	send \"DROP USER '$Mysqlrm'@'localhost';\r\"
	expect \"MariaDB >\"
	send \"exit\r\"
	expect eof
	")

	echo "$Mysqlusrrm"
}


function removewordpress () {
	echo "Preparing remove wordpress"
	rm -r /var/www/html
}

# Initial check for root, OS!
initialCheck

# Initial if Wordpress is already installed!
if [[ -e /var/www/html/wp-config.php ]]; then
	manageMenu
else
	installerWordpressD
fi
