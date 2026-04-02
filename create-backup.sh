#!/bin/bash

mysqldump -h 127.0.0.1 -u root -p \
  --databases production \
  --default-character-set=utf8mb4 \
  --single-transaction
