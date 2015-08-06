###
#
# Docker image for Drupal
#
###

FROM ubuntu:14.04

MAINTAINER Matthew R Hanlon <mrhanlon@tacc.utexas.edu>

EXPOSE 80 443

CMD ["supervisord", "-n"]

# install php and other system deps
RUN \
  apt-get update && \
  apt-get install -y \
    curl \
    mysql-client \
    git \
    php5 \
    php5-cli \
    php5-curl \
    php5-mysqlnd \
    php5-mcrypt \
    php5-fpm \
    php5-apcu \
    php5-json \
    php5-imagick \
    php5-gd \
    php-pear \
    nginx \
    supervisor \
    postfix

# install node, bower
RUN \
  mkdir /usr/local/node && cd /usr/local/node && \
  curl -O https://nodejs.org/dist/v0.12.7/node-v0.12.7-linux-x64.tar.gz && \
  tar -xzf node-v0.12.7-linux-x64.tar.gz && \
  ln -s /usr/local/node/node-v0.12.7-linux-x64/bin/node /usr/local/bin/node && \
  ln -s /usr/local/node/node-v0.12.7-linux-x64/bin/npm /usr/local/bin/npm && \
  npm install -g bower

# install composer
RUN \
  curl -sS https://getcomposer.org/installer | php && \
  mv composer.phar /usr/local/bin/composer

ENV PATH=/root/.composer/vendor/bin:$PATH

# supervisor conf
COPY conf/supervisor-araport.conf /etc/supervisor/conf.d/araport.conf

# nginx conf
COPY conf/nginx-araport.conf /etc/nginx/sites-enabled/default

# php conf
COPY conf/php.ini /etc/php5/fpm/php.ini
COPY conf/php-fpm.conf /etc/php5/fpm/php-fpm.conf

# install drush; log dirs; nginx tuning; php tuning
RUN \
  composer global require drush/drush:dev-master && \
  mkdir -p /var/log/drupal/nginx && \
  echo "daemon off;" >> /etc/nginx/nginx.conf && \
  printf "[Date]\ndate.timezone=America/Chicago" > /etc/php5/fpm/conf.d/20-date_timezone.ini

# configure drupal
COPY drupal /araport

# permissions
# RUN \
#   chown -R www-data:www-data /araport/sites/default/files && \
#   chown -R www-data:www-data /usr/local/drupal/files

WORKDIR /araport