#
# https://partner-images.canonical.com/core/bionic/current/ubuntu-bionic-core-cloudimg-amd64-root.tar.gz
#

FROM jammy

COPY elasticsearch/elasticsearch-8.10.2-amd64.deb /tmp/
COPY kibana/kibana-8.10.2-amd64.deb /tmp/
COPY logstash/logstash-8.10.2-amd64.deb /tmp/

RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/elasticsearch-8.10.2-amd64.deb \
    && DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/kibana-8.10.2-amd64.deb \
    && DEBIAN_FRONTEND=noninteractive dpkg -i /tmp/logstash-8.10.2-amd64.deb \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
         python3-psutil tcpdump tshark bc \
    && apt-get -qq clean \
    && rm -f  /tmp/*.deb \
    && rm -rf /var/lib/apt/lists/*

RUN groupmod -g 2000 elasticsearch && \
    usermod  -u 2000 elasticsearch && \
    chown -R root:elasticsearch \
         /etc/default/elasticsearch \
         /etc/elasticsearch && \
    mkdir -p /var/lib/elasticsearch /var/log/elasticsearch /var/run/elasticsearch && \
    chown -R elasticsearch:elasticsearch \
         /var/lib/elasticsearch \
         /var/log/elasticsearch \
         /var/run/elasticsearch && \
    groupmod -g 3000 kibana && \
    usermod  -u 3000 kibana && \
    chown -R root:kibana /etc/kibana && \
    mkdir -p /var/lib/kibana /var/log/kibana /var/run/kibana && \
    chown -R kibana:kibana \
         /var/lib/kibana \
         /var/log/kibana \
         /var/run/kibana && \
    groupmod -g 4000 logstash && \
    usermod  -u 4000 logstash && \
    chown -R root:logstash /etc/logstash && \
    mkdir -p /var/lib/logstash /var/log/logstash /var/run/logstash && \
    chown -R logstash:logstash \
         /var/lib/logstash \
         /var/log/logstash \
         /var/run/logstash


