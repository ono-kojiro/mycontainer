#FROM ubuntu:24.04
FROM scratch
ADD noble-server-cloudimg-amd64-root.tar.xz /

ENV USERNAME=admin

# Install base packages
RUN apt-get -qq update \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq upgrade \
    && DEBIAN_FRONTEND=noninteractive apt-get -qq install \
      tzdata \
      vim-nox \
      sudo \
      supervisor \
      openssh-server \
      iproute2 \
      cron \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

RUN useradd -m -s /bin/bash -g users ${USERNAME} && \
    echo "${USERNAME}:password" | chpasswd && \
    usermod -a -G sudo ${USERNAME}

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

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

