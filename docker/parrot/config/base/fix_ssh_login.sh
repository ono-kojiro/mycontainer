#!/bin/sh

# Configure SSHD.
# SSH login fix. Otherwise user is kicked off after login

sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

mkdir /var/run/sshd
bash -c 'install -m755 <(printf "#!/bin/sh\nexit 0") /usr/sbin/policy-rc.d'

ex +'%s/^#\zeListenAddress/\1/g' -scwq /etc/ssh/sshd_config
ex +'%s/^#\zeHostKey .*ssh_host_.*_key/\1/g' -scwq /etc/ssh/sshd_config

RUNLEVEL=1 dpkg-reconfigure openssh-server
ssh-keygen -A -v
sed -i -e 's|^\s\+GSSAPIAuthentication\s\+.\+|    GSSAPIAuthentication no|' /etc/ssh/ssh_config

update-rc.d ssh defaults

