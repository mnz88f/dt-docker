# Disciple Tools Docker compose file

## env file

The following variables should be defined in your docker .env file:
```
MYSQL_ROOT_PASSWORD=MySQLRootPassword

MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=MinioPassword
MINIO_BUCKET_NAME=dt-bucket
MINIO_PUBLIC_DOMAIN=dt-domain.org
MINIO_REGION=default

WORDPRESS_DB_HOST=db
WORDPRESS_DB_USER=dtuser
WORDPRESS_DB_PASSWORD='WPDBPassword'
WORDPRESS_DB_NAME=production
WORDPRESS_DEBUG=false
```

## Setting up Caddy DT using a public domain

If your DT host server is accessible using a public domain (ie `dt-domain.org`) then Caddy will create a certificate for you using Let's Encrypt.

```
https://dt-domain.org {
        reverse_proxy wordpress:80
}

https://dt-domain.org:9000 {
        reverse_proxy minio:9000
}
```

In this case, the connections between minio and Wordpress should just work.

## Running on a LAN with https

If you are running DT on a LAN only using the server IP address, but still want https, then it is necessary to generate site certificates yourself and configure caddy, wordpress and minio to recognize those certificates.

In this case, the Caddyfile should look like:
```
:443 {
    tls /etc/caddy/certs/dt.crt /etc/caddy/certs/dt.key
    reverse_proxy wordpress:80
}

:9000 {
    tls /etc/caddy/certs/dt.crt /etc/caddy/certs/dt.key
    reverse_proxy minio:9000
}

:9001 {
    tls /etc/caddy/certs/dt.crt /etc/caddy/certs/dt.key
    reverse_proxy minio:9001
}
```

The caddy certificates are mounted from `caddy/conf/certs`

### Creating a certificate authority and DT certificates

I follow the following steps to set up the certificates. First create the site certificate request configuration file (`dt.cnf`):

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
commonName_default          = dt.local

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = <your-LAN-dns if relavent>
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

### Copy the certificates into caddy, wordpress and minio

Place `dt-root-ca.crt` in `certs/ca/`, and `dt.crt` and `dt.key` in `certs/dt/`. Then run the script to copy the keys to the necessary folders:
```
cd certs
./copy-certs.sh
```

## Install DT theme

TODO Create script to install dt theme from a local zip file

## Set up minio on first-time use

TODO, run script, open storage settings, enter storage details
