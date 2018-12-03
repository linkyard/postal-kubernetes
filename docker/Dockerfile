FROM ruby:2.3-alpine

COPY patches /tmp/patches/

RUN set -ex \
  && apk --no-cache add nodejs mariadb-client bash libcap build-base mariadb-dev tzdata vim tini \
  && apk --no-cache --repository http://dl-3.alpinelinux.org/alpine/edge/testing/ add gosu \
  && gem install bundler procodile tzinfo-data \
  && mkdir -p /opt/postal/app /opt/postal/config /opt/postal/log \
  && addgroup -g 20000 -S postal \
  && adduser -u 20000 -S -G postal -h /opt/postal -s /bin/bash postal \
  && wget https://postal.atech.media/packages/stable/postal-1.0.0-67d0f6514d.tgz -O - | tar zxpv -C /opt/postal/app \
  && chown -R postal:postal /opt/postal \
  && ln -s /opt/postal/app/bin/postal /usr/bin/postal \
  && for patch in $(ls /tmp/patches); do cat /tmp/patches/${patch} | patch -p1; done \
  && rm -rf /tmp/patches \
  && su postal -c "postal bundle /opt/postal/vendor/bundle" \
  && rm -rf /var/cache/apk/* \
  && setcap 'cap_net_bind_service=+ep' /usr/local/bin/ruby

COPY docker-entrypoint.sh /usr/local/bin/
COPY assets/* /opt/linkyard/

EXPOSE 25 5000
USER postal

ENTRYPOINT [ "tini", "--", "docker-entrypoint.sh" ]
CMD [ "-" ]
