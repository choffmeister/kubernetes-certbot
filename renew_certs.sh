#!/bin/bash

set -eux

while IFS='=' read -r secret_name domains
do
    ./run.sh $secret_name $domains
done < /etc/letsencrypt-certs/ssl-certifcates.properties
