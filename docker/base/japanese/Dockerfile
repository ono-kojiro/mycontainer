FROM jammy:0.0.1
RUN  DEBIAN_FRONTEND=noninteractive \
     apt-get -qq update \
     && apt-get -qq install locales \
     && apt-get -qq install tzdata \
     && locale-gen ja_JP.UTF-8 \
     && ln -fs /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
     && dpkg-reconfigure -f noninteractive tzdata \
     && apt-get -qq clean \
     && rm -rf /var/lib/apt/lists/*

CMD ["/usr/bin/bash"]

