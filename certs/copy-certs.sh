#!/bin/bash

cp ca/*.crt ../wordpress/certs/
cp ca/*.crt ../minio/certs/CA/
cp dt/dt.crt ../caddy/conf/certs/dt.crt
cp dt/dt.key ../caddy/conf/certs/dt.key
