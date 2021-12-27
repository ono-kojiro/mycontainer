#
# https://partner-images.canonical.com/core/bionic/current/ubuntu-bionic-core-cloudimg-amd64-root.tar.gz
#

FROM scratch
#ADD ubuntu-bionic-core-cloudimg-amd64-root.tar.gz /
ADD ubuntu-focal-core-cloudimg-amd64-root.tar.gz /

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

RUN DEBIAN_FRONTEND=noninteractive

# Install required tools.
RUN apt-get -qq update \
    && apt-get -qq install tzdata \
    && apt-get -qq install vim-nox \
    && apt-get -qq install sudo \
    && apt-get -qq install python3-pip \
    && apt-get -qq install openssh-server \
    && apt-get -qq install iproute2 \
    && apt-get -qq install sssd-ldap \
    && apt-get -qq install oddjob-mkhomedir \
    && apt-get -qq install tzdata \
    && apt-get -qq clean    \
    && rm -rf /var/lib/apt/lists/*

# Configure SSHD.
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd
RUN mkdir /var/run/sshd
RUN bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d'
RUN ex +'%s/^#\zeListenAddress/\1/g' -scwq /etc/ssh/sshd_config
RUN ex +'%s/^#\zeHostKey .*ssh_host_.*_key/\1/g' -scwq /etc/ssh/sshd_config
RUN RUNLEVEL=1 dpkg-reconfigure openssh-server
RUN ssh-keygen -A -v
RUN update-rc.d ssh defaults

# Configure SSSD.
ADD sssd.conf /etc/sssd/
RUN chmod 600 /etc/sssd/sssd.conf

RUN pam-auth-update --enable mkhomedir

RUN echo '%ldapwheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

#CMD ["/bin/bash"]
ADD startup.sh /
RUN chmod +x /startup.sh
CMD ["/startup.sh"]

