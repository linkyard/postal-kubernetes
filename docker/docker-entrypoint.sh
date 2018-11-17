#!/bin/sh
set -eo pipefail

if [ -z "${MARIADB_HOST}" ]; then echo "error: MARIADB_HOST is unset"; exit 1; fi
if [ -z "${MARIADB_USER}" ]; then echo "error: MARIADB_USER is unset"; exit 1; fi
if [ -z "${MARIADB_PASSWORD}" ]; then echo "error: MARIADB_PASSWORD is unset"; exit 1; fi

if [ "$1" = "wait-for-mariadb" ]; then
  set +e
  while (true); do
    if ! mysqladmin -s ping -h "${MARIADB_HOST}" --user="${MARIADB_USER}" --password="${MARIADB_PASSWORD}"
    then
      echo "maridb ${MARIADB_HOST} is not ready"
      sleep 1
    else
      exit 0
    fi
  done
fi

if [ -z "${RABBITMQ_HOST}" ]; then echo "error: RABBITMQ_HOST is unset"; exit 1; fi
if [ -z "${RABBITMQ_USER}" ]; then echo "error: RABBITMQ_USER is unset"; exit 1; fi
if [ -z "${RABBITMQ_PASSWORD}" ]; then echo "error: RABBITMQ_PASSWORD is unset"; exit 1; fi

if [ -z "${RAILS_SECRET_KEY}" ]; then echo "error: RAILS_SECRET_KEY is unset"; exit 1; fi
if [ -z "${USER_CONFIG_PATH}" ]; then 
  echo "userConfig: false" > /tmp/user.yml
else
  cp "${USER_CONFIG_PATH}" /tmp/user.yml
fi

if [ -z "${SIGNING_KEY}" ]; then echo "error: SIGNING_KEY is unset"; exit 1; fi
if [ -z "${LETS_ENCRYPT_KEY}" ]; then echo "error: LETS_ENCRYPT_KEY is unset"; exit 1; fi

set -u

echo "${SIGNING_KEY}" | base64 -d > /opt/postal/config/signing.key
echo "${LETS_ENCRYPT_KEY}" | base64 -d > /opt/postal/config/lets_encrypt.pem

# collect secrets
SECRET_YAML="/tmp/secrets.yml"
{
  echo "main_db:"
  echo "  host: ${MARIADB_HOST}"
  echo "  username: ${MARIADB_USER}"
  echo "  password: ${MARIADB_PASSWORD}"
  echo "message_db:"
  echo "  host: ${MARIADB_HOST}"
  echo "  username: ${MARIADB_USER}"
  echo "  password: ${MARIADB_PASSWORD}"
  echo "rabbitmq:"
  echo "  host: ${RABBITMQ_HOST}"
  echo "  username: ${RABBITMQ_USER}"
  echo "  password: ${RABBITMQ_PASSWORD}"
  echo "rails:"
  echo "  secret_key: ${RAILS_SECRET_KEY}"
} > ${SECRET_YAML}

set +u
if [ ! -z "${SMTP_USER}" ] || [ ! -z "${SMTP_PASSWORD}" ]; then
  echo "smtp:" >> ${SECRET_YAML}
  if [ ! -z "${SMTP_USER}" ]; then echo "  username: ${SMTP_USER}" >> ${SECRET_YAML}; fi
  if [ ! -z "${SMTP_PASSWORD}" ]; then echo "  password: ${SMTP_PASSWORD}" >> ${SECRET_YAML}; fi
fi
set -u

GEM_HOME=/opt/postal/vendor/bundle/ruby/2.3.0/ ruby /opt/linkyard/write_config.rb
rm ${SECRET_YAML} /tmp/user.yml

onSigTerm() {
  postal stop
  touch /tmp/.stop-sleeping
  # shellcheck disable=SC2009
  ps xuaf | grep sleep | grep -v grep | xargs -r kill  
}

# shellcheck disable=SC2039
trap onSigTerm SIGHUP SIGINT SIGQUIT SIGTERM

for f in cron.log message_requeuer.log puma.log rails.log smtp_server.log worker.log; do
  touch /opt/postal/log/$f
done

if [ "$(echo "SELECT SCHEMA_NAME FROM INFORMATION_SCHEMA.SCHEMATA WHERE SCHEMA_NAME = 'postal'" | mysql -B -h "${MARIADB_HOST}" --user="${MARIADB_USER}" --password="${MARIADB_PASSWORD}" | grep -c -v SCHEMA_NAME)" -ne 1 ]; then
  set -e
  echo "Creating database"
  echo "CREATE DATABASE postal CHARSET utf8mb4 COLLATE utf8mb4_unicode_ci;" | mysql -B -h "${MARIADB_HOST}" --user="${MARIADB_USER}" --password="${MARIADB_PASSWORD}"
  set +e
fi

echo "select count(*) from additional_route_endpoints;" | mysql -B -h "${MARIADB_HOST}" --user="${MARIADB_USER}" --password="${MARIADB_PASSWORD}" --database=postal
if [ $? -eq 1 ]; then
  set -e
  postal initialize
  set +e
fi

if [ "$1" = "-" ]; then
  postal start
else
  postal "$@"
fi

tail -qF /opt/postal/log/*.log &

while (true); do
  if [ -e /tmp/.stop-sleeping ]; then
    break
  fi
  sleep 5
done
