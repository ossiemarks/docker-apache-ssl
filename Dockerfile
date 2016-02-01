#Will setup apache with SSL and a secure mutual Auth Dir

##########Snippet for SSL Debug logging ###########

<Directory "/var/www/html/">
Require ssl 
Require ssl-verify-client 
SSLRequireSSL 
SSLOptions +FakeBasicAuth +StrictRequire 
SSLRequire %{SSL_CIPHER_USEKEYSIZE} >= 256 
SSLRequire %{SSL_CLIENT_S_DN_O} eq "frogger" 
SSLRenegBufferSize 131072 
SSLOptions +StdEnvVars
</Directory>
<IfModule mod_ssl.c>
    ErrorLog /var/log/apache2/ssl_engine.log
    LogLevel debug
  </IfModule>

##########Snippet for SSL Debug logging ###########

