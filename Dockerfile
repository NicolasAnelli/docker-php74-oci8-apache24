#######################################
#  Contendo PHP 7.4.8, Apache 2.4.38, e
# oracle instant-client (oci)
#######################################
FROM php:7.4.8-apache
MAINTAINER nicolasanelli

ENV APACHE_DOCUMENT_ROOT /hadrion/qualis/home
ENV DEBIAN_FRONTEND noninteractive
ENV LANG C.UTF-8
#ENV TZ=America/Sao_Paulo
ENV LD_LIBRARY_PATH=/opt/oracle/instantclient_18_5

## Configurando o timezone
#RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && \
#    apt-get install -y tzdata && \
#    dpkg-reconfigure -f noninteractive tzdata

## Habilitando reescrita de URL do apache
#RUN a2enmod rewrite

# Instalando ferramentas necessárias
RUN apt-get update && apt-get install --no-install-recommends -y \
        libaio-dev unzip

# Adicionando conteúdo do oci-18.5
ADD oci/x64-18.5.0.0.0/ /opt/oracle/
RUN unzip /opt/oracle/instantclient-basiclite-linux.zip -d /opt/oracle \
    && unzip /opt/oracle/instantclient-sdk-linux.zip -d /opt/oracle \
    && ln -sfn /opt/oracle/instantclient_18_5/libclntsh.so.18.1 /opt/oracle/instantclient_18_5/libclntsh.so \
    && ln -sfn /opt/oracle/instantclient_18_5/libclntshcore.so.18.1 /opt/oracle/instantclient_18_5/libclntshcore.so \
    && ln -sfn /opt/oracle/instantclient_18_5/libocci.so.18.1 /opt/oracle/instantclient_18_5/libocci.so \
    && rm -rf /opt/oracle/*.zip

# Instalando oci pdo_oci para o PHP
RUN echo 'instantclient,/opt/oracle/instantclient_18_5' | pecl install oci8-2.2.0 \
    && docker-php-ext-configure pdo_oci --with-pdo-oci=instantclient,/opt/oracle/instantclient_18_5 \
    && docker-php-ext-install \
            pdo_oci \
    && docker-php-ext-enable \
            oci8

# Alterando ROOT do apache
RUN sed -ri -e 's!/var/www/html!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/sites-available/*.conf
RUN sed -ri -e 's!/var/www/!${APACHE_DOCUMENT_ROOT}!g' /etc/apache2/apache2.conf /etc/apache2/conf-available/*.conf

# Criando e definindo
RUN mkdir -p ${APACHE_DOCUMENT_ROOT}
WORKDIR /hadrion
RUN echo "<?= phpinfo(); ?>" > ${APACHE_DOCUMENT_ROOT}/index.php

# Limpando repositório
RUN apt-get clean \
    && rm -rf /var/lib/apt/lists/*