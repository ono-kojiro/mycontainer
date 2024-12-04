FROM noble:latest

# Install gpg
RUN \
    DEBIAN_FRONTEND=noninteractive apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
      gpg \
      apt-transport-https \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Install elasticsearch
RUN \
    rm -f /usr/share/keyrings/elasticsearch-keyring.gpg \
    && wget -qO - https://artifacts.elastic.co/GPG-KEY-elasticsearch \
      | gpg --batch --yes --dearmor -o /usr/share/keyrings/elasticsearch-keyring.gpg \
    && echo "deb [signed-by=/usr/share/keyrings/elasticsearch-keyring.gpg] https://artifacts.elastic.co/packages/8.x/apt stable main" \
      | tee /etc/apt/sources.list.d/elastic-8.x.list

RUN \
    DEBIAN_FRONTEND=noninteractive apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
      elasticsearch \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

