FROM debian:8.1

RUN \
  apt-get update && \
  apt-get install ---yes git wget && \
  apt-get clean && \
  rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*

RUN \
  git clone https://github.com/certbot/certbot /opt/certbot && \
  ln -s /opt/certbot/letsencrypt-auto /usr/local/bin/letsencrypt-auto && \
  letsencrypt-auto; exit 0

RUN \
  wget https://storage.googleapis.com/kubernetes-release/release/v1.9.3/bin/linux/amd64/kubectl && \
  chmod +x kubectl && \
  mv kubectl /usr/local/bin

WORKDIR /opt/kubernetes-certbot
COPY run.sh ./run.sh

EXPOSE 80
CMD sleep 86400
