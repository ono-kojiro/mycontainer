FROM ubuntu:24.04

RUN set -xe \
    \
    && echo '#!/bin/sh' > /usr/sbin/policy-rc.d \
    && echo 'exit 101' >> /usr/sbin/policy-rc.d \
    && chmod +x /usr/sbin/policy-rc.d \
    \
    && dpkg-divert --local --rename --add /sbin/initctl \
    && cp -a /usr/sbin/policy-rc.d /sbin/initctl \
    && sed -i 's/^exit.*/exit 0/' /sbin/initctl \
    \
    && echo 'force-unsafe-io' > /etc/dpkg/dpkg.cfg.d/docker-apt-speedup \
    \
    && echo 'DPkg::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' > /etc/apt/apt.conf.d/docker-clean \
    && echo 'APT::Update::Post-Invoke { "rm -f /var/cache/apt/archives/*.deb /var/cache/apt/archives/partial/*.deb /var/cache/apt/*.bin || true"; };' >> /etc/apt/apt.conf.d/docker-clean \
    && echo 'Dir::Cache::pkgcache ""; Dir::Cache::srcpkgcache "";' >> /etc/apt/apt.conf.d/docker-clean \
    \
    && echo 'Acquire::Languages "none";' > /etc/apt/apt.conf.d/docker-no-languages \
    \
    && echo 'Acquire::GzipIndexes "true"; Acquire::CompressionTypes::Order:: "gz";' > /etc/apt/apt.conf.d/docker-gzip-indexes \
    \
    && echo 'Apt::AutoRemove::SuggestsImportant "false";' > /etc/apt/apt.conf.d/docker-autoremove-suggests

RUN rm -rf /var/lib/apt/lists/*
RUN sed -i 's/^#\s*\(deb.*universe\)$/\1/g' /etc/apt/sources.list
RUN mkdir -p /run/systemd && echo 'docker' > /run/systemd/container

# 
# https://stackoverflow.com/questions/22886470/start-sshd-automatically-with-docker-container
#

# Install required tools.
RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
      tzdata \
      vim-nox \
      sudo \
      openssh-server \
      iproute2 \
      cron \
      sssd-ldap \
      oddjob-mkhomedir \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Configure SSHD.
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
 && mkdir /var/run/sshd \
 && bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d' \
 && ex +'%s/^#\zeListenAddress/\1/g' -scwq /etc/ssh/sshd_config \
 && ex +'%s/^#\zeHostKey .*ssh_host_.*_key/\1/g' -scwq /etc/ssh/sshd_config \
 && RUNLEVEL=1 dpkg-reconfigure openssh-server \
 && ssh-keygen -A -v \
 && sed -i -e 's|^\s\+GSSAPIAuthentication\s\+.\+|    GSSAPIAuthentication no|' /etc/ssh/ssh_config \
 && update-rc.d ssh defaults

# Configure SSSD.
ADD sssd.conf /etc/sssd/
RUN chmod 600 /etc/sssd/sssd.conf \
    && chown root:root /etc/sssd/sssd.conf \
    && pam-auth-update --enable mkhomedir \
    && sed 's|-D -f|-D|' -i /etc/default/sssd \
    && sed -i -e 's|^#\(AuthorizedKeysCommand\)\s\+.\+|\1 /usr/bin/sss_ssh_authorizedkeys|' /etc/ssh/sshd_config \
    && sed -i -e 's|^#\(AuthorizedKeysCommandUser\)\s\+\(.\+\)|\1 \2|' /etc/ssh/sshd_config

RUN echo '%ldapwheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

# change timezone and locale
ENV TZ Asia/Tokyo
RUN    DEBIAN_FRONTEND=noninteractive apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
      language-pack-ja \
    && update-locale LANG=ja_JP.UTF-8 \
    && ln -s -f /usr/share/zoneinfo/Asia/Tokyo /etc/localtime \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*
ENV LANG ja_JP.UTF-8
ENV LANGUAGE ja_JP:ja
ENV LC_ALL ja_JP.UTF-8

ADD startup.sh /
RUN chmod +x /startup.sh
CMD ["/startup.sh"]

