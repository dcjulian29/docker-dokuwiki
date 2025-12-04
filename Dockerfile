FROM alpine:3.23

LABEL org.opencontainers.image.source="https://github.com/dcjulian29/docker-dokuwiki"
LABEL org.opencontainers.image.description="A Docker Container that hosts a Dokuwiki website"

ARG VERSION

RUN apk update \
  && apk add php83 php83-fpm php83-opcache php83-zlib php83-xml php83-gd php83-session php83-json nginx curl supervisor \
  && rm -rf /var/cache/apk/*

RUN curl -fsSL "https://download.dokuwiki.org/src/dokuwiki/dokuwiki-$(echo ${VERSION} | sed 's/\./-/g').tgz" -o /dokuwiki.tgz \
  && tar xzf /dokuwiki.tgz -C /var/www \
  && rm /dokuwiki.tgz \
  && mv /var/www/dokuwiki* /var/www/html \
  && rm -Rf /var/www/html/lib/plugins/authad \
  && rm -Rf /var/www/html/lib/plugins/authldap \
  && rm -Rf /var/www/html/lib/plugins/authmysql \
  && rm -Rf /var/www/html/lib/plugins/authpgsql \
  && rm -Rf /var/www/html/lib/plugins/popularity \
  && rm -Rf /var/www/html/lib/plugins/plugin

RUN curl -fsSL 'https://github.com/selfthinker/dokuwiki_plugin_wrap/archive/master.zip' -o /tmp/wrap.zip \
  && unzip /tmp/wrap.zip -d /tmp \
  && mkdir -p /var/www/html/lib/plugins/wrap \
  && cp -R /tmp/dokuwiki_plugin_wrap-master/* /var/www/html/lib/plugins/wrap/ \
  && curl -fsSL 'https://github.com/gturri/nspages/tarball/master' -o /tmp/nspages.tgz \
  && tar zxvf /tmp/nspages.tgz -C /tmp \
  && mkdir /var/www/html/lib/plugins/nspages \
  && cp -R /tmp/gturri-nspages-*/* /var/www/html/lib/plugins/nspages/ \
  && curl -fsSL 'https://github.com/dwp-forge/columns/zipball/master' -o /tmp/columns.zip \
  && unzip /tmp/columns.zip -d /tmp \
  && mkdir -p /var/www/html/lib/plugins/columns \
  && cp -R /tmp/dwp-forge-columns-*/* /var/www/html/lib/plugins/columns/ \
  && curl -fsSL 'https://github.com/splitbrain/dokuwiki-plugin-gallery/zipball/master' -o /tmp/gallery.zip \
  && unzip /tmp/gallery.zip -d /tmp \
  && mkdir -p /var/www/html/lib/plugins/gallery \
  && cp -R /tmp/splitbrain-dokuwiki-plugin-gallery-*/* /var/www/html/lib/plugins/gallery/ \
  && rm -Rf /tmp/* \
  && chown -R nobody:nobody /var/www/html \
  && chown -R nobody:nobody /run \
  && chown -R nobody:nobody /var/lib/nginx \
  && chown -R nobody:nobody /var/log/nginx \
  && chown -R nobody:nobody /var/log/php83

COPY ./nginx.conf /etc/nginx/nginx.conf
COPY ./fpm.conf /etc/php83/php-fpm.conf
COPY ./supervisord.conf /etc/supervisor/conf.d/supervisord.conf

EXPOSE 80

VOLUME ["/var/www/html/data", "/var/www/html/lib/tpl/dokuwiki", "/var/www/html/conf"]

USER nobody

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

HEALTHCHECK --timeout=10s CMD curl --silent --fail http://127.0.0.1/fpm-ping
