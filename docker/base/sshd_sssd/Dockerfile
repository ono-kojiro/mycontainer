FROM jammy-ja:0.0.1
RUN  DEBIAN_FRONTEND=noninteractive \
     apt-get update && apt-get install -y \
       oddjob-mkhomedir \
       openssh-server \
       sssd-ldap \
       sudo \
       vim-nox \
     && apt-get -qq clean \
     && rm -rf /var/lib/apt/lists/*

# Configure SSHD.
# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd \
    && mkdir -p /var/run/sshd \
    && bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d' \
    && ex +'%s/^#\zeListenAddress/\1/g' -scwq /etc/ssh/sshd_config \
    && ex +'%s/^#\zeHostKey .*ssh_host_.*_key/\1/g' -scwq /etc/ssh/sshd_config \
    && RUNLEVEL=1 dpkg-reconfigure openssh-server \
    && ssh-keygen -A -v \
    && update-rc.d ssh defaults

# Configure SSSD.
COPY sssd.conf /etc/sssd/
RUN chmod 600 /etc/sssd/sssd.conf \
    && pam-auth-update --enable mkhomedir \
    && echo '%ldapwheel ALL=(ALL:ALL) ALL' >> /etc/sudoers \
    && sed -i -e 's|DAEMON_OPTS="-D -f"|DAEMON_OPTS="-D"|' /etc/default/sssd 

COPY startup.sh /
RUN chmod +x /startup.sh
CMD ["/startup.sh"]

