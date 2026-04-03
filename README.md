# Disciple Tools Docker compose file

*What is this?* This is a docker compose file and set of scripts and tools to deploy Disciple Tools with local MinIO storage.

## How to use this

### Create a `.env` file

To begin, you need to create a `.env` file. Define the following variables, choosing new passwords instead of the placeholders:

``` ini
MYSQL_ROOT_PASSWORD=MySQLRootPassword

MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=MinioPassword
MINIO_BUCKET_NAME=dt-bucket
MINIO_PUBLIC_DOMAIN=your-dt-domain.org
MINIO_REGION=default

WORDPRESS_DB_HOST=db
WORDPRESS_DB_USER=dtuser
WORDPRESS_DB_PASSWORD='WPDBPassword'
WORDPRESS_DB_NAME=production
WORDPRESS_DEBUG=false
```

### Configure Caddy

Caddy is web-server which provides a reverse proxy for docker services. The file `caddy/conf/Caddyfile` defines what services will be exposed by this docker compose service.

If DT is going to be served on a public web domain (ie `dt-domain.org`), then rename the file `Caddyfile.public.domain` to `Caddyfile` and adjust for your domain. Caddy automates the generation of a valid ssl certificate for https, using Let's Encrypt. Once this certificate is generate, connections between minio and Wordpress should work.

If DT is going to be served on a LAN, you will need to generate your own certificate in order to still have encrypted connections using https. In this case, rename the file `Caddyfile.lan.ip` to `Caddyfile`, and use the process below to generate your own certificate.

### Creating a certificate authority and DT certificates

If you are serving DT on a public domain name, then your certificate is generated using Let's Encrypt, and you should skip this step.

Otherwise, the following are the steps used to generate a certificate authority and signed certificate for serving on a LAN. First create the site certificate request configuration file (`dt.cnf`), replaceing `<fiels>` with your own values:

``` ini dt.cnf
[ req ]
default_bits       = 2048
default_keyfile    = dt.key
distinguished_name = req_distinguished_name
req_extensions     = req_ext

[ req_distinguished_name ]
countryName                 = Country Name (2 letter code)
countryName_default         = <Your Country>
stateOrProvinceName         = State or Province Name (full name)
stateOrProvinceName_default = <Your State or Provice>
localityName                = Locality Name (eg, city)
localityName_default        = <Your City>
organizationName            = Organization Name (eg, company)
organizationName_default    = <Your Organization>
commonName                  = Common Name (e.g., server FQDN or YOUR name)
commonName_default          = <your-LAN-domain-name>

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = <your-LAN-domain-name>
IP.1  = <your-LAN-ip>
```

Then go through these steps:

``` bash
# Generate CA (dt-root-ca.key)
openssl genrsa -out dt-root-ca.key 2048

# Generate CA public key (dt-root-ca.crt)
openssl req -x509 -new -nodes -key dt-root-ca.key -sha256 -days 3650 -out dt-root-ca.crt

# Generate the dt site key to be signed (dt.key)
openssl genpkey -algorithm RSA -out dt.key -pkeyopt rsa_keygen_bits:2048

# Generate the signing request (dt.csr)
openssl req -new -key dt.key -out dt.csr -config dt.cnf -extensions req_ext

# Sign the key (creates dt.crt)
openssl x509 -req -in dt.csr -CA dt-root-ca.crt -CAkey dt-root-ca.key \
    -CAcreateserial -out dt.crt -days 3650 -sha256 \
    -extfile dt.cnf -extensions req_ext

# View and verify the site certificate
openssl x509 -in dt.crt -text -noout
```

Once these steps are done, place `dt-root-ca.crt` in `certs/ca/`, and `dt.crt` and `dt.key` in `certs/dt/`. Then go into the `certs` directory and run the script `./copy-certs.sh` in order to have the certificates copied into the locations needed by Caddy, Wordpress and MinIO.

In order to avoid a certificate warning in client's browsers, you can install the root certificate `dt-root-ca.crt` into the client OS and/or browser certificate store, configuring it for use for trusting websites. If you don't do this step, users will need to add a certificate exception the first time they connect to the site (and potentially also for `<your-dt-ip>:9000`).

### Install DT theme

To install Disciple Tools, the Disciple Tools wordpress theme needs to be downloaded and extracted within the 'wordpress' container. A script is provided to help with this.

First, make sure the docker services are running. Run `docker compose up -d` in the folder with the docker compose file (`compose.yml`).

Then go into the `wordpress` folder, and run `./install_dt_theme.sh`. This should download, extract and copy the DT theme into the wordpress container.

After this, DT can be updated either using the Wordpress interface, or otherwise you can remove the downloaded `wordpress/disciple-tools-theme.zip` file and run the `install_dt_theme.sh` script again.

### Set up minio on first-time use

As in the previous step, ensure that the docker services are running. In addition, you need to be able to access the Wordpress admin console, which will likely involve setting up Wordpress with an admin user, and then setting up Disciple Tools.

After these are complete, go into the `minio` folder and run `./first_time.sh deploy`. (This copies and runs the scirpt inside the running `MinIO` container).

The script should set up `MinIO` for use, using the MinIO variables defined in the `.env` file. Once it is complete, it will print out the settings for Provider, AccessKey, Secret, Region, Bucket, Endpoint and Path-style endpoint. Navigate to the storage settings in WordPress (`wp-admin/admin.php?page=dt_options&tab=storage`) and enter the provided settings, and test the connection. Hopefully it will work!

### Set up systemd service unit

The docker services can be configured to start automatically using docker compose restart policy. However, as an alternative a systemd service unit can be used. Modify the `systemd-startup/dt-docker.service` service unit to have the actual path to dt-docker. Then copy the service unit to `/etc/systemd/system/dt-docker.service`, and run:

``` bash
systemctl daemon-reload
systemctl enable dt-docker.service
systemctl start dt-docker.service
```

This will allow the dt-docker docker compose service to be started during the operating system startup.
