inoc/pdns-superslave
===========
A Docker container for a PowerDNS superslave.

Usage
-----
This container runs PowerDNS in superslave mode with the sqlite backend. It exposes port 53 by default and takes the `PDNS_SUPERMASTERS` environment variable for configuration on container start. `PDNS_SUPERMASTERS` holds a space-separated list of DNS master servers, where each is in the format `<IP Address>:<Server name>`.

This also supports `TSIG_SUPERMASTER` and `TSIG_NOTIFY` environment variable to support PowerDNS's allow-unsigned-supermaster and allow-unsigned-notify=no flags.
```bash
sudo docker run \
-e ALLOW_NOTIFY_FROM=208.70.84.203,208.70.84.173 \
-e PDNS_SUPERMASTERS="208.70.84.203:ns.internetnoc.com 208.70.84.173:ns.internetnoc.com" \
-e DEBUG=true \
-p 8083:8083 -p 53:53/udp \
inoc/pdns-slave
```
All configuration options available as environment variables:
```bash
SQLITE_DBPATH=${SQLITE_DBPATH:-/data/pdns.sqlite}
API_KEY=${API_KEY:-genericapikey}
MASTER=${MASTER:-no}
SLAVE=${SLAVE:-yes}
SLAVE_CYCLE_INTERVAL=${SLAVE_CYCLE_INTERVAL:-60}
DEFAULT_TTL=${DEFAULT_TTL:-3600}
DEFAULT_SOA_NAME=${DEFAULT_SOA_NAME:-$(hostname -f)}
DEFAULT_SOA_MAIL=${DEFAULT_SOA_MAIL}
ALLOW_AXFR_IPS=${ALLOW_AXFR_IPS:-127.0.0.0/8}
ALSO_NOTIFY=${ALSO_NOTIFY}
ALLOW_NOTIFY_FROM=${ALLOW_NOTIFY_FROM}
GSQLITE3_PRAGMA_SYNCHRONOUS=${GSQLITE3_PRAGMA_SYNCHRONOUS:-0}
DNSSEC=${DNSSEC:-no}
TSIG_SUPERMASTER=
TSIG_NOTIFY=
DEBUG=
```

See https://doc.powerdns.com/md/authoritative/settings/ for descriptions.
