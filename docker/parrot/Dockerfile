FROM parrotsec/security:7.1

# environment variable for build
ARG DEBIAN_FRONTEND=noninteractive

COPY disable_init.sh /tmp/
COPY optimize_apt.sh /tmp/

RUN \
     chmod +x /tmp/disable_init.sh \
  && chmod +x /tmp/optimize_apt.sh \
  && /tmp/disable_init.sh \
  && /tmp/optimize_apt.sh \
  && rm -f /tmp/disable_init.sh \
  && rm -f /tmp/optimize_apt.sh

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

COPY fix_ssh_login.sh /tmp/

RUN \
     chmod +x /tmp/fix_ssh_login.sh \
  && /tmp/fix_ssh_login.sh \
  && rm -f /tmp/fix_ssh_login.sh

RUN mkdir /root/.ssh; chown root. /root/.ssh; chmod 700 /root/.ssh
ADD id_ed25519.pub /root/.ssh/authorized_keys

EXPOSE 22

# Configure SSSD.
ADD sssd.conf /etc/sssd/

COPY enable_sssd.sh /tmp/
RUN \
     chmod +x /tmp/enable_sssd.sh \
  && /tmp/enable_sssd.sh \
  && rm -f /tmp/enable_sssd.sh

RUN echo '%ldapwheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

COPY enable_japanese.sh /tmp/

RUN \
     sh /tmp/enable_japanese.sh \
  && rm -f /tmp/enable_japanese.sh


COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

