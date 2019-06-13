FROM debian:9

 

RUN apt-get update && \
    apt-get install -y  opensaml2-schemas xmltooling-schemas libshibsp7 \
        libshibsp-plugins shibboleth-sp2-common shibboleth-sp2-utils supervisor procps curl git && \
    apt-get install -y build-essential libpcre3 libpcre3-dev libpcrecpp0v5 libssl-dev zlib1g-dev nano php-fpm wget gnupg

RUN echo '#nginx repository ' >> /etc/apt/sources.list
RUN echo 'deb http://nginx.org/packages/debian/ stretch nginx ' >> /etc/apt/sources.list
RUN echo 'deb-src http://nginx.org/packages/debian/ stretch nginx' >> /etc/apt/sources.list

RUN wget http://nginx.org/keys/nginx_signing.key -P /tmp
RUN apt-key add /tmp/nginx_signing.key
RUn apt-get update
WORKDIR /opt
RUN git clone https://github.com/openresty/headers-more-nginx-module.git 
RUN git clone https://github.com/nginx-shib/nginx-http-shibboleth.git 
RUN mkdir /opt/buildnginx
RUN ls -laF
WORKDIR /opt/buildnginx
RUN apt-get source nginx
RUN apt-get build-dep -y nginx

COPY rules /opt/buildnginx/nginx-1.16.0/debian/

WORKDIR /opt/buildnginx/nginx-1.16.0/
RUN dpkg-buildpackage -b

RUN cd ../ && dpkg -i nginx_1.16.0-1~stretch_amd64.deb

COPY shibboleth.conf /etc/supervisor/conf.d/shibboleth.conf

COPY default.conf /etc/nginx/conf.d/default.conf
WORKDIR /
RUN mkdir /var/www
RUN mkdir /var/www/secure
RUN mkdir /etc/nginx/ssl

COPY bundle.crt /etc/nginx/ssl/
WORKDIR /etc/nginx/ssl
RUN openssl dhparam -out /etc/nginx/ssl/dhparam.pem 2048

COPY www.conf /etc/php/7.0/fpm/pool.d/
COPY php.ini /etc/php/7.0/fpm/

RUN /etc/init.d/php7.0-fpm restart

RUN shib-keygen -f
COPY attribute-map.xml /etc/shibboleth/
COPY shibboleth2.xml /etc/shibboleth/
RUN wget https://md.idem.garr.it/certs/idem-signer-20220121.pem -O /etc/shibboleth/federation-cert.pem
RUN chmod 444 /etc/shibboleth/federation-cert.pem
RUN cp /opt/nginx-http-shibboleth/includes/* /etc/nginx
COPY sp_example_com.key /etc/nginx/ssl
WORKDIR /
COPY run_script.sh /root
RUN chmod +x /root/run_script.sh
RUN /root/run_script.sh
