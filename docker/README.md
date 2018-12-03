# Docker-Image for Postal

This docker-image is based on [ruby:2.3-alpine](https://hub.docker.com/_/ruby/) and uses packages published by aTech Media.

Postal runs as user `postal` with uid `20000` and group id `20000`, exposed ports are `25` (SMTP) and `5000` (Postal web UI). Logs are printed to standard-out and saved as files in `/opt/postal/log` (log-rotation as per Postal's defaults).

## Configuration

This docker-image writes Postal's configuration to a YAML file by using some values from environment variables and others from a YAML file mounted at `USER_CONFIG_PATH` (optional):

- Read Postal's default configuration from `/opt/postal/app/config/postal.example.yml`
- Read our default configuration [default-config.yml](assets/default-config.yml)
- Read the configuration file mounted at `USER_CONFIG_PATH`. If you don't specify that
  environment variable, it will be ignored
- Read a set of environment variables and convert them into a YAML file

Those four configuration sources are deep-merged (in order) into the final `/opt/postal/config/postal.yml`.

Part of the `default-config.yaml` is an override of the machine's nameservers to the IPv4 addresses of Google's public DNS servers (see [Overriding nameservers](#overriding-nameservers)).

The following environment variables are required:

- `MARIADB_HOST`: Hostname of the MariaDB database to connect to.
- `MARIADB_USER`: Username for the MariaDB database.
- `MARIADB_PASSWORD`: Password for the MariaDB user.
- `RABBITMQ_HOST`: Hostname of the RabbitMQ to connect to.
- `RABBITMQ_USER`: Username for RabbitMQ.
- `RABBITMQ_PASSWORD`: Password for the RabbitMQ user.
- `RAILS_SECRET_KEY`: The secret key for rails. Generate a random alphanumeric key (e.g.
  with `openssl rand -hex 256`)
- `SIGNING_KEY`: Base64-encoded RSA private key in PEM format. Used for DKIM signing.
- `LETS_ENCRYPT_KEY`: Base64-encoded RSA private key in PEM format. Used by Postal to
  acquire and renew certificates for the click-tracking-server from Let's Encrypt.

The following environment variables are supported but not required:

- `USER_CONFIG_PATH`: Path to partial Postal YAML configuration that will be merged
  into the configuration after default values are applied. Use this YAML configuration
  for all your settings that aren't secrets, e.g. your DNS records.
- `SMTP_USER`: Username for the SMTP server.
- `SMTP_PASSWORD`: Password for the SMTP user.

You can generate and base64-encode the DKIM signing key and Let's Encrypt key like this:

```bash
# set to signing_key or lets_encrypt_key
KEYNAME=signing_key
# set to 1024 only if your DNS provider has trouble with long DKIM signatures
# set to 4096 for Let's Encrypt and if your DNS provider can handle such a long signature
KEYLENGTH=2048

openssl genpkey -algorithm RSA -out ${KEYNAME}.pem -pkeyopt rsa_keygen_bits:${KEYLENGTH}
echo -e "\n$(echo ${KEYNAME} | tr a-z A-Z)=$(openssl enc -base64 -A -in ${KEYNAME}.pem)\n"
```

## Additional Postal configuration

### Overriding nameservers

This docker-image adds support for specifying a list of DNS servers used by Postal when it verifies DNS records for one of your domains.

If you want to override the default resolver on the machine Postal is running on, you can add an array of IP addresses as a `nameservers` property in the `general` section of your configuration.

Example:

```yaml
general:
  nameservers:
    - "8.8.8.8"
    - "8.8.4.4"
```

## Behaviour

On startup, the following actions will be performed:

- Check if MariaDB is up. If it is not, exit with status code `1`
- Check if the `postal` schema exists in MariaDB. If it does not, create the `postal` database.
- Check if Postal's database is initialized. If it is not, run `postal initialize`.
- Run `postal start`

## Attribution

This docker-image is based on the docker-image from [CatDeployed](https://github.com/CatDeployed/docker-postal).
