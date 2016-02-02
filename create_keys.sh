mkdir -p /u01/app/myCA/certs
mkdir /u01/app/myCA/csr
mkdir /u01/app/myCA/newcerts
mkdir /u01/app/myCA/private
cp /etc/pki/tls/openssl.cnf /u01/app/myCA/.
cd /u01/app/myCA
echo 00 > serial
echo 00 > crlnumber
touch index.txt
openssl genrsa -des3 -passout pass:qwerty -out  private/rootCA.key 2048
openssl rsa -passin pass:qwerty -in private/rootCA.key -out private/rootCA.key
openssl req -config openssl.cnf -new -x509 -subj '/C=DK/L=Aarhus/O=frogger CA/CN=theheat.dk' -days 999 -key private/rootCA.key -out certs/rootCA.crt
openssl genrsa -des3 -passout pass:qwerty -out private/winterfell.key 2048
openssl rsa -passin pass:qwerty -in private/winterfell.key -out private/winterfell.key
openssl req -config openssl.cnf -new -subj '/C=DK/L=Aarhus/O=frogger/CN=winterfell' -key private/winterfell.key -out csr/winterfell.csr
openssl ca -batch -config openssl.cnf -days 999 -in csr/winterfell.csr -out certs/winterfell.crt -keyfile private/rootCA.key -cert certs/rootCA.crt -policy policy_anything
openssl genrsa -des3 -passout pass:qwerty -out private/client.key 2048
openssl rsa -passin pass:qwerty -in private/client.key -out private/client.key
openssl req -config openssl.cnf -new -subj '/C=DK/L=Aarhus/O=frogger/CN=theClient' -key private/client.key -out csr/client.csr
openssl ca -batch -config openssl.cnf -days 999 -in csr/client.csr -out certs/client.crt -keyfile private/rootCA.key -cert certs/rootCA.crt -policy policy_anything
openssl pkcs12 -export -passout pass:qwerty -in certs/client.crt -inkey private/client.key -certfile certs/rootCA.crt -out certs/clientcert.p12
