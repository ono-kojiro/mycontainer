#
# https://partner-images.canonical.com/core/bionic/current/ubuntu-bionic-core-cloudimg-amd64-root.tar.gz
#

FROM jammy

COPY filebeat-8.10.2-amd64.deb /tmp/

RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/filebeat-8.10.2-amd64.deb \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
         python3-psutil tcpdump tshark bc \
    && apt-get -qq clean \
    && rm -f  /tmp/*.deb \
    && rm -rf /var/lib/apt/lists/*

RUN groupadd --system -g 5000 filebeat && \
    groupmod -g 5000 filebeat && \
    useradd  --system -u 5000 -g filebeat --home-dir /var/lib/filebeat filebeat && \
    chown -R root:filebeat \
         /etc/filebeat && \
    mkdir -p /var/lib/filebeat /var/log/filebeat /var/run/filebeat && \
    chown -R filebeat:filebeat \
         /var/lib/filebeat \
         /var/log/filebeat \
         /var/run/filebeat

