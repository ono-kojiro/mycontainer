FROM mediawiki:lts

# enable SSL
COPY ./certs/myserver.crt /etc/ssl/certs/
COPY ./certs/myserver.key /etc/ssl/private/

RUN sed -i -r 's|(SSLCertificateFile)\s+(.+)|\1 /etc/ssl/certs/myserver.crt|' \ 
  /etc/apache2/sites-available/default-ssl.conf
RUN sed -i -r 's|(SSLCertificateKeyFile)\s+(.+)|\1 /etc/ssl/private/myserver.key|' \ 
  /etc/apache2/sites-available/default-ssl.conf

# Allowing VisualEditor on page titles containing slashes
# (insert AllowEncodedSlashes NoDecode)
RUN sed -i -r 's|(\s+)(DocumentRoot)(\s+)(.+)|\1\2\3\4\n\1AllowEncodedSlashes NoDecode|' \
  /etc/apache2/sites-available/default-ssl.conf


RUN a2enmod ssl
RUN a2ensite default-ssl

# install extensions
COPY ./extensions/LDAPProvider-REL1_35-a801161.tar.gz        /tmp/
COPY ./extensions/PluggableAuth-REL1_35-efff551.tar.gz       /tmp/
COPY ./extensions/LDAPGroups-REL1_35-0afa75e.tar.gz          /tmp/
COPY ./extensions/LDAPAuthorization-REL1_35-149b7c0.tar.gz   /tmp/
COPY ./extensions/LDAPAuthentication2-REL1_35-dabdf22.tar.gz /tmp/
COPY ./extensions/LDAPUserInfo-REL1_35-d04327e.tar.gz        /tmp

RUN cd /var/www/html/extensions && \
  tar xzvf /tmp/LDAPAuthentication2-REL1_35-dabdf22.tar.gz; \
  tar xzvf /tmp/LDAPAuthorization-REL1_35-149b7c0.tar.gz; \
  tar xzvf /tmp/LDAPGroups-REL1_35-0afa75e.tar.gz; \
  tar xzvf /tmp/LDAPProvider-REL1_35-a801161.tar.gz; \
  tar xzvf /tmp/LDAPUserInfo-REL1_35-d04327e.tar.gz; \
  tar xzvf /tmp/PluggableAuth-REL1_35-efff551.tar.gz

RUN cp -f /usr/local/etc/php/php.ini-production /usr/local/etc/php/php.ini
RUN sed -ie 's|;extension=ldap|extension=ldap|' /usr/local/etc/php/php.ini

RUN apt -y -qq update  && \
  apt -y -qq install libldap2-dev && \
  apt -y -qq install vim less


RUN docker-php-ext-configure ldap && \
  docker-php-ext-install ldap

COPY ./extensions/ldap.json /var/www/

# logfile
RUN mkdir -p /var/log/mediawiki && chown www-data:www-data /var/log/mediawiki


