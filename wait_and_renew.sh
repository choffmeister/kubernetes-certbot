#!/bin/bash

set -eux

while true; do
    # Sleep 5 minutes so a crash looping pod doesn't punch let's encrypt.
    echo "Renewing cert in 5 minutes"
    sleep 300
    ./renew_certs.sh
    echo "Certs renewed; see you tomorrow"
    sleep 86100
done
