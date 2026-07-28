FROM rockylinux/rockylinux:10.2-ubi

# Install required tools.
RUN dnf -y update \
    && dnf -y install \
      vim-enhanced \
      openssh-server \
      iproute \
      sssd-ldap \
      sssd-tools \
      sudo \
      initscripts \
      initscripts-service \
      openldap-clients \
      oddjob \
      oddjob-mkhomedir \
      authselect \
    && /usr/bin/ssh-keygen -A \
    && dnf clean all

# Install supervisor
RUN dnf -y update \
    && dnf -y install \
      python3-pip \
      gettext-envsubst \
    && pip3 install supervisor --force \
    && dnf clean all

ADD ldap.conf.template /etc/ldap/

# Configure SSSD.
ADD sssd.conf.template /etc/sssd/

COPY enable_sssd.sh /tmp/
RUN \
     chmod +x /tmp/enable_sssd.sh \
  && /tmp/enable_sssd.sh \
  && rm -f /tmp/enable_sssd.sh

RUN echo '%ldapwheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

RUN mkdir /root/.ssh; chown root. /root/.ssh; chmod 700 /root/.ssh
ADD id_ed25519.pub /root/.ssh/authorized_keys

RUN  mkdir -p /etc/supervisor/conf.d/
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/local/bin/supervisord", "-n", "-c", "/etc/supervisor/conf.d/supervisord.conf"]


