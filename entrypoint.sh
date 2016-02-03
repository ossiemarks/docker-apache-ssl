#!/bin/bash

cat <<EOF
Welcome to the marvambass/apache2-ssl-secure container
If you want to add your own VirtualHosts Configuration, you can copy the following SSL Configuration Stuff
	SSLEngine On

	SSLProtocol all -SSLv2 -SSLv3
	# disable ssl compression
	SSLCompression Off
	# set HSTS Header
	#Header add Strict-Transport-Security "max-age=31536000" # just this domain
	#Header add Strict-Transport-Security "max-age=31536000; includeSubdomains" # with subdomains
	# Ciphers
	SSLCipherSuite ECDHE-RSA-AES256-GCM-SHA384:ECDHE-RSA-AES128-GCM-SHA256:DHE-RSA-AES256-GCM-SHA384:DHE-RSA-AES128-GCM-SHA256:ECDHE-RSA-AES256-SHA384:ECDHE-RSA-AES128-SHA256:ECDHE-RSA-AES256-SHA:ECDHE-RSA-AES128-SHA:DHE-RSA-AES256-SHA256:DHE-RSA-AES128-SHA256:DHE-RSA-AES256-SHA:DHE-RSA-AES128-SHA:ECDHE-RSA-DES-CBC3-SHA:EDH-RSA-DES-CBC3-SHA:AES256-GCM-SHA384:AES128-GCM-SHA256:AES256-SHA256:AES128-SHA256:AES256-SHA:AES128-SHA:DES-CBC3-SHA:HIGH:!aNULL:!eNULL:!EXPORT:!CAMELLIA:!DES:!MD5:!PSK:!RC4
	SSLHonorCipherOrder on

	<Directory "/var/www/html/secure/">
	SSLCertificateFile /u01/app/myCA/certs/winterfell.crt
	SSLCertificateKeyFile /u01/app/myCA/private/winterfell.key
	SSLCertificateChainFile /u01/app/myCA/certs/rootCA.crt
	SSLCACertificateFile /u01/app/myCA/certs/rootCA.crt
	SSLVerifyClient require
	SSLVerifyDepth  10
	</Directory>
	<IfModule mod_ssl.c>
	    ErrorLog /var/log/apache2/ssl_engine.log
	    LogLevel debug
	  </IfModule>

#############
EOF

if [ ! -z ${HSTS_HEADERS_ENABLE+x} ]
then
  echo ">> HSTS Headers enabled"
  sed -i 's/#Header add Strict-Transport-Security/Header add Strict-Transport-Security/g' /etc/apache2/sites-enabled/001-default-ssl

  if [ ! -z ${HSTS_HEADERS_ENABLE_NO_SUBDOMAINS+x} ]
  then
    echo ">> HSTS Headers configured without includeSubdomains"
    sed -i 's/; includeSubdomains//g' /etc/apache2/sites-enabled/001-default-ssl
  fi
else
  echo ">> HSTS Headers disabled"
fi


echo ">> copy /etc/apache2/external/*.conf files to /etc/apache2/sites-enabled/"
cp /etc/apache2/external/*.conf /etc/apache2/sites-enabled/ 2> /dev/null > /dev/null
#sed "s|./demoCA|/u01/app/myCA/|g" /etc/ssl/openssl.cnf
# exec CMD
echo ">> exec docker CMD"
echo "$@"
exec "$@"
