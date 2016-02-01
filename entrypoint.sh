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

	<Directory "/var/www/html/">
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

  echo ">> generating self signed cert"
	mkdir -p /u01/app/myCA/certs
	mkdir /u01/app/myCA/csr
	mkdir /u01/app/myCA/newcerts
	mkdir /u01/app/myCA/private
	cd /u01/app/myCA
	echo 00 > serial
	echo 00 > crlnumber
	touch index.txt
	# Create CA private key
	openssl genrsa -des3 -passout pass:qwerty -out  private/rootCA.key 2048
	# Remove passphrase
	openssl rsa -passin pass:qwerty -in private/rootCA.key -out private/rootCA.key
	# Create CA self-signed certificate
	openssl req -config openssl.cnf -new -x509 -subj '/C=DK/L=Aarhus/O=frogger CA/CN=theheat.dk' -days 999 -key private/rootCA.key -out certs/rootCA.crt
	# Create private key for the winterfell server
	openssl genrsa -des3 -passout pass:qwerty -out private/winterfell.key 2048
	# Remove passphrase
	openssl rsa -passin pass:qwerty -in private/winterfell.key -out private/winterfell.key
	# Create CSR for the winterfell server
	openssl req -config openssl.cnf -new -subj '/C=DK/L=Aarhus/O=frogger/CN=winterfell' -key private/winterfell.key -out csr/winterfell.csr
	# Create certificate for the winterfell server
	openssl ca -batch -config openssl.cnf -days 999 -in csr/winterfell.csr -out certs/winterfell.crt -keyfile private/rootCA.key -cert certs/rootCA.crt -policy policy_anything
	# Create private key for a client
	openssl genrsa -des3 -passout pass:qwerty -out private/client.key 2048
	# Remove passphrase
	openssl rsa -passin pass:qwerty -in private/client.key -out private/client.key
	# Create CSR for the client.
	openssl req -config openssl.cnf -new -subj '/C=DK/L=Aarhus/O=frogger/CN=theClient' -key private/client.key -out csr/client.csr
	# Create client certificate.
	openssl ca -batch -config openssl.cnf -days 999 -in csr/client.csr -out certs/client.crt -keyfile private/rootCA.key -cert certs/rootCA.crt -policy policy_anything
	# Export the client certificate to pkcs12 for import in the browser
	openssl pkcs12 -export -passout pass:qwerty -in certs/client.crt -inkey private/client.key -certfile certs/rootCA.crt -out certs/clientcert.p12
 echo ">> Copying client certs to /tmp"
cp 	certs/rootCA.crt certs/clientcert.p12 /tmp/


echo ">> copy /etc/apache2/external/*.conf files to /etc/apache2/sites-enabled/"
cp /etc/apache2/external/*.conf /etc/apache2/sites-enabled/ 2> /dev/null > /dev/null

# exec CMD
echo ">> exec docker CMD"
echo "$@"
exec "$@"
