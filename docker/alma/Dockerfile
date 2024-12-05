FROM almalinux:9

# Install required tools.
RUN /usr/bin/dnf -y update \
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

ADD sssd.conf /etc/sssd/
RUN chmod 600 /etc/sssd/sssd.conf \
    && chown root:root /etc/sssd/sssd.conf \
    && sed -i -e 's|^#\(AuthorizedKeysCommand\)\s\+.\+|\1 /usr/bin/sss_ssh_authorizedkeys|' /etc/ssh/sshd_config \                                                
    && sed -i -e 's|^#\(AuthorizedKeysCommandUser\)\s\+\(.\+\)|\1 \2|' /etc/ssh/sshd_config \
    && authselect select sssd --force with-mkhomedir \
    && echo '%ldapwheel ALL=(ALL:ALL) ALL' >> /etc/sudoers

ADD startup.sh /
RUN chmod +x /startup.sh
CMD ["/startup.sh"]

