FROM php:7.4.13-fpm-alpine

COPY ./src /var/www/html
COPY ./source /var/www/html/source
COPY ./supervisor.d /etc/supervisor.d

RUN set -e; \
    sed -i 's!http://dl-cdn.alpinelinux.org!'https://mirrors.aliyun.com'!g' /etc/apk/repositories; \
    sed -i 's!https://dl-cdn.alpinelinux.org!'https://mirrors.aliyun.com'!g' /etc/apk/repositories; \
# Install build dependency packages
    apk update; \
    apk add --no-cache tzdata supervisor; \
    apk add --no-cache libstdc++ libx11 glib libxrender libxext libintl ttf-dejavu ttf-droid ttf-freefont ttf-liberation ttf-ubuntu-font-family; \
    apk add --virtual .phpize-deps-configure $PHPIZE_DEPS; \
# Setup timezone
    cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime; \
    echo "Asia/Shanghai" > /etc/timezone; \
# PECL Extensions
    pecl install swoole; \
    docker-php-ext-enable swoole; \
    docker-php-source delete; \
# Install run dependency packages
    # runDeps="$( \
    #     scanelf --needed --nobanner --format '%n#p' --recursive /usr/local/lib/php/extensions \
    #     | tr ',' '\n' \
    #     | sort -u \
    #     | awk 'system("[ -e /usr/local/lib/" $1 " ]") == 0 { next } { print "so:" $1 }' \
    # )"; \
    # apk add --virtual .php-rundeps $runDeps; \
# Cleanup
    rm -rf /tmp/pear; \
    rm -rf /var/cache/apk/*; \
# System configurations
    { \
        echo 'error_reporting = E_ALL'; \
        echo 'display_errors = Off'; \
        echo 'log_errors = On'; \
        echo 'always_populate_raw_post_data = -1'; \
        echo 'upload_max_filesize = 20M'; \
        echo 'post_max_size = 20M'; \
        echo 'date.timezone = Asia/Shanghai'; \
        echo 'memory_limit = 256M'; \
    } | tee /usr/local/etc/php/conf.d/docker.ini; \
    sed -i 's!pm.max_children = 5!pm.max_children = 500!g' /usr/local/etc/php-fpm.d/www.conf; \
    sed -i 's!pm.start_servers = 2!pm.start_servers = 20!g' /usr/local/etc/php-fpm.d/www.conf; \
    sed -i 's!pm.min_spare_servers = 1!pm.min_spare_servers = 10!g' /usr/local/etc/php-fpm.d/www.conf; \
    sed -i 's!pm.max_spare_servers = 3!pm.max_spare_servers = 30!g' /usr/local/etc/php-fpm.d/www.conf; \
    { \
        echo '[global]'; \
        echo 'error_log = /var/log/php-fpm/www-error.log'; \
        echo; \
        echo '[www]'; \
        echo 'php_admin_value[post_max_size] = 20M'; \
        echo 'php_admin_value[upload_max_filesize] = 20M'; \
    } | tee /usr/local/etc/php-fpm.d/docker.conf; \
    sed -i '$i mkdir -p /var/log/php-fpm/ ' /usr/local/bin/docker-php-entrypoint; \
    curl -sSL https://getcomposer.org/installer | php -- --install-dir=/usr/local/bin --filename=composer; \
    composer --version; \
    cd /var/www/html; \
    composer install --no-dev; \
    mv source/SourceHanSansCN-Normal.otf /usr/share/fonts/SourceHanSansCN-Normal.otf; \
    mv source/wkhtmltopdf /usr/bin/wkhtmltopdf; \
    chmod 655 /usr/bin/wkhtmltopdf; \
    # mv wkhtmltoimage /usr/bin/wkhtmltoimage; \
    mkdir /var/log/wkhtml2x; \
    sed -i '3a/usr/bin/supervisord -c /etc/supervisord.conf' /usr/local/bin/docker-php-entrypoint; \
    sed -i '4a' /usr/local/bin/docker-php-entrypoint;

WORKDIR /var/www/html
