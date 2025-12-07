#FROM ubuntu:24.04
FROM scratch
ADD noble-server-cloudimg-amd64-root.tar.xz /

# environment variable for build
ARG DEBIAN_FRONTEND=noninteractive

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

# Install base packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      tzdata \
      vim-nox \
      sudo \
      supervisor \
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

RUN mkdir /root/.ssh; chown root. /root/.ssh; chmod 700 /root/.ssh
ADD id_ed25519.pub /root/.ssh/authorized_keys

EXPOSE 22

# Configure SSSD.
ADD sssd.conf /etc/sssd/
RUN chmod 600 /etc/sssd/sssd.conf \
    && chown root:root /etc/sssd/sssd.conf \
    && sed 's|-D -f|-D|' -i /etc/default/sssd \
    && pam-auth-update --enable mkhomedir \
    && sed -i -e 's|^#\(AuthorizedKeysCommand\)\s\+.\+|\1 /usr/bin/sss_ssh_authorizedkeys|' /etc/ssh/sshd_config \
    && sed -i -e 's|^#\(AuthorizedKeysCommandUser\)\s\+\(.\+\)|\1 \2|' /etc/ssh/sshd_config

RUN echo '%ldapwheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

# Install desktop
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      --no-install-recommends \
      xfce4 \
      dbus-x11 \
      x11vnc \
      xvfb \
      xauth \
      x11-utils \
      wget git python3 python3-pip python3-websockify \
      ca-certificates \
      net-tools \
      procps \
      git build-essential cmake qtbase5-dev \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Install noVNC + websockify
RUN git clone https://github.com/novnc/noVNC.git /opt/noVNC && \
    git clone https://github.com/novnc/websockify /opt/noVNC/utils/websockify || true && \
    chmod -R a+rx /opt/noVNC

RUN apt-get update && \
    apt-get -y install --no-install-recommends \
    xfce4-terminal libgdk-pixbuf-2.0-0 librsvg2-2 dbus-x11 libsdl2-2.0-0 \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

RUN apt-get update && apt-get install -y \
    adwaita-icon-theme \
    tango-icon-theme \
    hicolor-icon-theme \
    gnome-icon-theme \
    thunar-volman tumbler \
 && rm -rf /var/lib/apt/lists/*

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

