FROM alpine:3.4
MAINTAINER Christian Hoffmeister <mail@choffmeister.de>

RUN apk add --no-cache --update wget bash certbot ca-certificates

RUN \
  wget https://storage.googleapis.com/kubernetes-release/release/v1.3.0/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl && \
  chmod +x /usr/local/bin/kubectl

WORKDIR /opt/certbot

COPY run.sh ./run.sh
COPY wait_and_renew.sh ./wait_and_renew.sh
COPY renew_certs.sh ./renew_certs.sh

EXPOSE 80
CMD ["./wait_and_renew.sh"]
