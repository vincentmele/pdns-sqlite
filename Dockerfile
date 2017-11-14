FROM alpine:3.6

MAINTAINER Vince Mele <vmele@inoc.com>

RUN apk --no-cache add pdns pdns-backend-sqlite3 sqlite bash \
    && mkdir /data /pdns \
    && chown -Rv pdns: /data

COPY files/schema.sqlite3.sql /pdns/init.sql
COPY files/entrypoint.sh /entrypoint.sh
VOLUME ["/data"]
WORKDIR /data

EXPOSE 53 8083
ENTRYPOINT ["/entrypoint.sh"]
