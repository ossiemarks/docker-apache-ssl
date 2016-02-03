#Will setup apache with SSL and a secure mutual Auth Dir

FROM ubuntu:14.04
MAINTAINER ossiemarks

ENV LANG C.UTF-8
VOLUME /home/osman/ssl_server

RUN apt-get update; apt-get install -y \
    apache2 \
    bash \
    openssl

RUN rm -rf /var/www/html/*; rm -rf /etc/apache2/sites-enabled/*; \
    mkdir -p /etc/apache2/external; \
    mkdir -p /u01/app/myCA/ ; \
    mkdir -p /var/www/html/secure/

ENV APACHE_RUN_USER www-data
ENV APACHE_RUN_GROUP www-data
ENV APACHE_LOG_DIR /var/log/apache2

RUN sed -i 's/^ServerSignature/#ServerSignature/g' /etc/apache2/conf-enabled/security.conf; \
    sed -i 's/^ServerTokens/#ServerTokens/g' /etc/apache2/conf-enabled/security.conf; \
    echo "ServerSignature Off" >> /etc/apache2/conf-enabled/security.conf; \
    echo "ServerTokens Prod" >> /etc/apache2/conf-enabled/security.conf; \ 
    sed -i "s|./demoCA|/u01/app/myCA/|g" /etc/ssl/openssl.cnf; \
    echo " modified openssl.cnf"; \
    a2enmod ssl; \
    a2enmod headers; \
    echo "SSLProtocol ALL -SSLv2 -SSLv3" >> /etc/apache2/apache2.conf

ADD 000-default.conf /etc/apache2/sites-enabled/000-default.conf
ADD 001-default-ssl.conf /etc/apache2/sites-enabled/001-default-ssl.conf
ADD openssl.cnf /etc/openssl/openssl.cnf
ADD index.html /var/www/html/secure/index.html

EXPOSE 80
EXPOSE 443

ADD entrypoint.sh /opt/entrypoint.sh
ADD openssl.cnf /u01/app/myCA/
ADD create_keys.sh /opt/create_keys.sh

RUN mkdir -p /u01/app/myCA/certs; \
mkdir /u01/app/myCA/csr; \
mkdir /u01/app/myCA/newcerts; \
mkdir /u01/app/myCA/private; \
mkdir -p /var/www/html/secure; \
cp /etc/openssl/openssl.cnf /u01/app/myCA/.

WORKDIR /u01/app/myCA 

RUN echo 00 > serial ;\
echo 00 > crlnumber ;\
touch index.txt


RUN openssl genrsa -des3 -passout pass:qwerty -out  private/rootCA.key 2048; \
openssl rsa -passin pass:qwerty -in private/rootCA.key -out private/rootCA.key; \
openssl req -config openssl.cnf -new -x509 -subj '/C=DK/L=Aarhus/O=mariocart CA/CN=apache-ssl' -days 999 -key private/rootCA.key -out certs/rootCA.crt; \
openssl genrsa -des3 -passout pass:qwerty -out private/winterfell.key 2048; \
openssl rsa -passin pass:qwerty -in private/winterfell.key -out private/winterfell.key; \
openssl req -config openssl.cnf -new -subj '/C=DK/L=Aarhus/O=mariocart/CN=winterfell' -key private/winterfell.key -out csr/winterfell.csr; \
openssl ca -batch -config openssl.cnf -days 999 -in csr/winterfell.csr -out certs/winterfell.crt -keyfile private/rootCA.key -cert certs/rootCA.crt -policy policy_anything; \
openssl genrsa -des3 -passout pass:qwerty -out private/client.key 2048; \
openssl rsa -passin pass:qwerty -in private/client.key -out private/client.key; \
openssl req -config openssl.cnf -new -subj '/C=DK/L=Aarhus/O=mariocart/CN=theClient' -key private/client.key -out csr/client.csr; \
openssl ca -batch -config openssl.cnf -days 999 -in csr/client.csr -out certs/client.crt -keyfile private/rootCA.key -cert certs/rootCA.crt -policy policy_anything; \
openssl pkcs12 -export -passout pass:qwerty -in certs/client.crt -inkey private/client.key -certfile certs/rootCA.crt -out certs/clientcert.p12 

RUN  echo ">> Copying client certs to /var/"; \
cp /u01/app/myCA/certs/rootCA.crt /u01/app/myCA/certs/clientcert.p12 /var/

RUN chmod a+x /opt/entrypoint.sh

ENTRYPOINT ["/opt/entrypoint.sh"]
CMD ["/usr/sbin/apache2ctl", "-D", "FOREGROUND"]
