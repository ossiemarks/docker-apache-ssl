# docker-apache-ssl
Docker Apache SSL With Mutual Auth

This will create a apache server with mod ssl enabled and it will generate keys for the server and the client

client keys are copied to /var/www/html
The php page wants to connect to a DB called mysql-db and a user called mysqluser

Will use somthing like this docker run -it --add-host "mysqldb":localhost 
