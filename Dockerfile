FROM alpine:latest
MAINTAINER Kre
ENV UNREAL_VERSION="5.0.8" \
    TERM="vt100" \
    LC_ALL=C

# preparing for make keys
RUN addgroup -S ircd && adduser -S ircd -G ircd 
COPY --chown=ircd:ircd unrealircd-keys-make.expect /home/ircd/unrealircd-keys-make.expect

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
    ca-certificates \
    wget \
    file \
    expect \
    openssl-dev \
    openssl \
    gnupg \
    certbot \
    supervisor \
    sudo \
    # temporary apps
    && apk add --no-cache --virtual .build-deps \
    build-base \
    cmake \
    && sed -i '/\[supervisord\]/a nodaemon=true\nuser=root' /etc/supervisord.conf \
    && sed -i "s/\[unix_http_server\]/;\[unix_http_server\]/" /etc/supervisord.conf \
    && sed -i "s/file=\/run\/supervisord.sock/;file=\/run\/supervisord.sock/" /etc/supervisord.conf \
    && cd /home/ircd \
    # getting sources and verify it
    && sudo -u ircd wget https://www.unrealircd.org/downloads/unrealircd-$UNREAL_VERSION.tar.gz \
    && sudo -u ircd wget https://www.unrealircd.org/downloads/unrealircd-$UNREAL_VERSION.tar.gz.asc \
    && gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys 0xA7A21B0A108FF4A9 \
    && gpg --verify unrealircd-$UNREAL_VERSION.tar.gz.asc unrealircd-$UNREAL_VERSION.tar.gz \
    && sudo -u ircd tar zxvf unrealircd-$UNREAL_VERSION.tar.gz \
    # compiling the sources
    && cd unrealircd-$UNREAL_VERSION \
    && sudo -u ircd ./Config \
    && sudo -u ircd /home/ircd/unrealircd-keys-make.expect \
    && sudo -u ircd make \
    && sudo -u ircd make install \
    # delete temporary apps
    && apk del .build-deps


USER ircd
WORKDIR /home/ircd/
ENV HOME /home/ircd
# moving default conf to conf.orig
RUN mv /home/ircd/unrealircd/conf /home/ircd/unrealircd/conf.orig

EXPOSE 6667
EXPOSE 6900

USER root
COPY supervisor_services.conf /etc/supervisor.d/unrealircd.ini
COPY unrealircd-entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
CMD ["/usr/bin/supervisord","-c","/etc/supervisord.conf"]

