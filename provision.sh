#!/usr/bin/env bash
echo ">>> Starting provision for CentOS 7 <<<"

echo "- Remove old provision log file and create a new one."
sudo rm /vagrant/provision.log > /dev/null 2>&1
sudo touch /vagrant/provision.log > /dev/null 2>&1

echo ">>> Updating (that might take a while)"
sudo yum -y update >> /vagrant/provision.log 2>&1

echo ">>> Setting Permissive mode (required by Apache to access /vagrant folder)"
sudo setenforce Permissive
sudo sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/sysconfig/selinux
sudo sed -i -e 's/SELINUX=enforcing/SELINUX=permissive/g' /etc/selinux/config

echo ">>> Installing PHP 7.3"
sudo yum -y install epel-release >> /vagrant/provision.log 2>&1
sudo yum -y install http://rpms.remirepo.net/enterprise/remi-release-7.rpm >> /vagrant/provision.log 2>&1
sudo yum -y install yum-utils >> /vagrant/provision.log 2>&1
sudo yum-config-manager --enable remi-php73 >> /vagrant/provision.log 2>&1
sudo yum -y update >> /vagrant/provision.log 2>&1
sudo yum -y install php >> /vagrant/provision.log 2>&1
sudo yum -y install php-fpm php-gd php-json php-mbstring php-mysqlnd php-xml php-xmlrpc php-opcache php-devel php-intl php-posix >> /vagrant/provision.log 2>&1
sudo sed -i -e 's/upload_max_filesize = 2M/upload_max_filesize = 8M/g' /etc/php.ini
sudo systemctl enable php-fpm.service >> /vagrant/provision.log 2>&1
sudo systemctl start php-fpm.service >> /vagrant/provision.log 2>&1
php -v

echo ">>> Installing apache"
sudo yum -y install httpd >> /vagrant/provision.log 2>&1
sudo yum -y install mod_ssl >> /vagrant/provision.log 2>&1
sudo systemctl enable httpd.service  >> /vagrant/provision.log 2>&1
httpd -v

echo ">>> Configure apache user/group"
sudo sed -i -e 's/apache/vagrant/g' /etc/httpd/conf/httpd.conf

echo ">>> Configuring virtual host"
sudo rm /etc/httpd/conf.d/welcome.conf > /dev/null 2>&1
cat > /tmp/playground.conf <<'EOF'
<VirtualHost *:80>
    ServerName admin.webapp.lokal
    ServerAlias www.admin.webapp.lokal
    DocumentRoot /vagrant/web
    ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/vagrant/web/$1

    <Directory />
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

<VirtualHost *:443>
    ServerName admin.webapp.lokal
    ServerAlias www.admin.webapp.lokal
    DocumentRoot /vagrant/web
    ProxyPassMatch ^/(.*\.php(/.*)?)$ fcgi://127.0.0.1:9000/vagrant/web/$1

    SSLEngine on
    SSLProxyEngine on
    SSLProxyVerify none
    SSLProxyCheckPeerCN off
    SSLProxyCheckPeerName off
    SSLProxyCheckPeerExpire off
    SSLCertificateFile "/etc/pki/tls/certs/dev.crt"
    SSLCertificateKeyFile "/etc/pki/tls/private/dev.key"

    <Directory />
        Options Indexes FollowSymLinks
        AllowOverride All
        Require all granted
    </Directory>
</VirtualHost>

<Directory /vagrant>
    EnableSendfile Off
</Directory>
EOF
sudo cp /tmp/playground.conf /etc/httpd/conf.d/playground.conf >> /vagrant/provision.log 2>&1

cat > /tmp/30-xdebug.ini <<'EOF'
zend_extension = /usr/lib64/php/modules/xdebug.so
[xdebug]
xdebug.default_enabled=0
xdebug.cli_color=1
xdebug.screem=1
xdebug.idekey=xdebug
xdebug.remote_enable=1
xdebug.remote_connect_back=1
#xdebug.remote_host=192.168.101.10
xdebug.overload_var_dump=2
xdebug.var_display_max_children=-1
xdebug.var_display_max_data=-1
xdebug.var_display_max_depth=-1
EOF
sudo cp /tmp/30-xdebug.ini /etc/php.d/30-xdebug.ini >>  /vagrant/provision.log 2>&1

echo ">>> Configuring SSL"
sudo cp /vagrant/tools/ssl/dev.crt /etc/pki/tls/certs/ >> /vagrant/provision.log 2>&1
sudo cp /vagrant/tools/ssl/dev.key /etc/pki/tls/private/ >> /vagrant/provision.log 2>&1

echo ">>> Installing MySql 8.0. User: root, Password: root"
sudo rpm -Uvh https://repo.mysql.com/mysql80-community-release-el7-1.noarch.rpm  >> /vagrant/provision.log 2>&1
sudo yum -y install mysql-server  >> /vagrant/provision.log 2>&1
sudo sed -i -e 's/# default-authentication-plugin=mysql_native_password/default-authentication-plugin=mysql_native_password/g' /etc/my.cnf
sudo systemctl start mysqld  >> /vagrant/provision.log 2>&1
RootPassword="$(sed -n -e 's/^.*A temporary password is generated for root@localhost: //p' /var/log/mysqld.log)"
# echo "MYSQL temporary password: ${RootPassword}"
mysql --connect-expired-password -u root -p"${RootPassword}" -e "SET GLOBAL validate_password.policy=0; SET GLOBAL validate_password.number_count=0; SET GLOBAL validate_password.check_user_name=OFF; SET GLOBAL validate_password.length=0; SET GLOBAL validate_password.mixed_case_count=0; SET GLOBAL validate_password.special_char_count=0; ALTER USER 'root'@'localhost' IDENTIFIED BY 'root';" >> /vagrant/provision.log 2>&1
mysql -u root -proot -e ' SELECT VERSION(); '

echo ">>> Creating database for Drupal: playground (User: playground, Password: playground)"
mysql -uroot -proot -e "create database playground" >> /vagrant/provision.log 2>&1
mysql -uroot -proot -e "CREATE USER 'playground'@'localhost' IDENTIFIED BY 'playground'" >> /vagrant/provision.log 2>&1
mysql -uroot -proot -e "GRANT ALL PRIVILEGES ON playground.* TO 'playground'@'localhost'" >> /vagrant/provision.log 2>&1
mysql -uroot -proot -e "FLUSH PRIVILEGES" >> /vagrant/provision.log 2>&1

echo ">>> Restarting services"
sudo systemctl restart httpd.service >> /vagrant/provision.log 2>&1

echo ">>> Installing tools..."
sudo curl -sS https://getcomposer.org/installer | php >> /vagrant/provision.log 2>&1
sudo mv composer.phar /usr/local/bin/composer >> /vagrant/provision.log 2>&1
sudo yum -y install git >> /vagrant/provision.log 2>&1
sudo yum -y install unzip >> /vagrant/provision.log 2>&1
sudo yum -y install nodejs >> /vagrant/provision.log 2>&1

echo ">>> Setting box locale"
sudo touch /etc/environment
sudo echo "LANG=en_US.UTF-8" >> /etc/environment
sudo echo "LC_ALL=en_US.UTF-8" >> /etc/environment

echo ">>> Installing composer packages"
cd /vagrant >> /vagrant/provision.log 2>&1
composer install >> /vagrant/provision.log 2>&1

echo ">>> Done <<<"

echo "Perform the following manual steps:"
echo "1. Go to http://admin.webapp.lokal/ and install Drupal"
echo "2. Inside the box (vagrant ssh), cd into /vagrant and then enable modules: ./vendor/bin/drush en admin_toolbar admin_toolbar_tools search_api search_api_db dropzonejs dropzonejs_eb_widget entity_browser embed entity_embed file_browser basic_auth rest serialization webapp"
