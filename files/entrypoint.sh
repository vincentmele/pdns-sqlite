#!/bin/bash

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
#TSIG_SUPERMASTER=
#TSIG_NOTIFY=
#DEBUG=

OPTIONS=()
OPTIONS+="--setuid=pdns "
OPTIONS+="--setgid=pdns "
OPTIONS+="--api=yes "
OPTIONS+="--api-key=${API_KEY} "
OPTIONS+="--webserver=yes "
OPTIONS+="--webserver-address=0.0.0.0 "
OPTIONS+="--launch=gsqlite3 "
OPTIONS+="--gsqlite3-database=${SQLITE_DBPATH} "
OPTIONS+="--gsqlite3-pragma-foreign-keys "
OPTIONS+="--gsqlite3-dnssec=${DNSSEC} "
OPTIONS+="--gsqlite3-pragma-synchronous=${GSQLITE3_PRAGMA_SYNCHRONOUS} "
OPTIONS+="--default-ttl=${DEFAULT_TTL} "
OPTIONS+="--default-soa-name=${DEFAULT_SOA_NAME} "
OPTIONS+="--allow-axfr-ips=${ALLOW_AXFR_IPS} "
OPTIONS+="--slave-cycle-interval=${SLAVE_CYCLE_INTERVAL} "
OPTIONS+="--webserver-port=8083 "
OPTIONS+="--daemon=no --no-config "

# Use TSIGs if provided
if [[ -n ${TSIG_SUPERMASTER} ]]; then
  OPTIONS+="--allow-unsigned-supermaster=no "
fi

if [[ -n ${TSIG_NOTIFY} ]]; then
  OPTIONS+="--allow-unsigned-notify=no "
fi 

# Enable showing of dns queries if debugging enabled
if [[ ${DEBUG} == "true" ]]; then
  OPTIONS+="--log-dns-queries=yes "
  OPTIONS+="--loglevel=5 "
fi

# Master/Slave management
if [[ ${SLAVE} == "yes" ]]
then
  OPTIONS+="--slave=${SLAVE} "

  # ALLOW_NOTIFY_FROM must be set
  if [[ -z ${ALLOW_NOTIFY_FROM} ]]; then
    echo "ALLOW_NOTIFY_FROM is not set, please configure this when to turn slave mode on."
    exit 1
  fi

  OPTIONS+="--allow-notify-from=${ALLOW_NOTIFY_FROM} "

elif [[ ${MASTER} == "yes" ]]
then
  OPTIONS+="--master=${MASTER} "
else
  echo "Error, PowerDNS must be configured in either master or slave mode"
  exit 1
fi

# also-notify
if [[ -n ${ALSO_NOTIFY} ]]
then
  OPTIONS+="--also-notify=$ALSO_NOTIFY "
fi

# default-soa-email
if [[ -n ${DEFAULT_SOA_MAIL} ]]; then
  OPTIONS+="--default-soa-mail=${DEFAULT_SOA_MAIL} "
fi

# Init the sqlite db if it does not exist
if [[ ! -e ${SQLITE_DBPATH} ]]
then
  cat /pdns/init.sql | sqlite3 ${SQLITE_DBPATH}
else
  echo "Database exist and some tables were found."
  echo "Assuming this is not the first launch"
fi

# Set correct permissions
chown -Rv pdns:pdns /data
chown -Rv pdns:pdns ${SQLITE_DBPATH}

# Recreate list of Supermasters.
if [[ -n $PDNS_SUPERMASTERS ]]; then
  echo "PDNS_SUPERMASTERS SET! TO: $PDNS_SUPERMASTERS"
  for i in $PDNS_SUPERMASTERS; do
    IFS=: read -r ipaddr ipname <<< "$i"
    echo "sqlite3 ${SQLITE_DBPATH} insert into supermasters values ('$ipaddr','$ipname', 'admin');"
    sqlite3 ${SQLITE_DBPATH} "insert into supermasters values ('$ipaddr','$ipname', 'admin');"
  done
fi

# Start PowerDNS
echo "/usr/sbin/pdns_server ${OPTIONS}"
/usr/sbin/pdns_server ${OPTIONS}
