#
# https://partner-images.canonical.com/core/bionic/current/ubuntu-bionic-core-cloudimg-amd64-root.tar.gz
#

FROM jammy

COPY packetbeat-8.10.4-amd64.deb /tmp/

RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/packetbeat-8.10.4-amd64.deb \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
         python3-psutil tcpdump tshark bc \
    && apt-get -qq clean \
    && rm -f  /tmp/*.deb \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system -g 6000 packetbeat && \
    groupmod -g 6000 packetbeat && \
    useradd  --system -u 6000 -g packetbeat --home-dir /var/lib/packetbeat packetbeat && \
    chown -R root:packetbeat \
         /etc/packetbeat && \
    mkdir -p /var/lib/packetbeat /var/log/packetbeat /var/run/packetbeat && \
    chown -R packetbeat:packetbeat \
         /var/lib/packetbeat \
         /var/log/packetbeat \
         /var/run/packetbeat

RUN sed -i -e 's|^#Port 22|Port 2222|' /etc/ssh/sshd_config

USER root:root

