FROM debian:bookworm-20260316

# environment variable for build
ARG DEBIAN_FRONTEND=noninteractive

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

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]

