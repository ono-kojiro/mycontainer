FROM mybaseimage

RUN apt -y update && apt install -y openssh-server
RUN apt -y update && apt install -y sssd
RUN apt -y update && apt install -y gawk

RUN apt -y update && apt install -y apache2
RUN echo "Hello Docker World" > /var/www/html/index.html

RUN mkdir /var/run/sshd
RUN echo 'root:secret' | chpasswd
RUN sed -i -e 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
   sed -i -e 's/#PasswordAuthentication/PasswordAuthentication/' /etc/ssh/sshd_config && \
   sed -i -e 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' /etc/pam.d/sshd

ADD sssd.conf /etc/sssd/
RUN chmod 600 /etc/sssd/sssd.conf

RUN echo '%ldapwheel ALL=(ALL) ALL' >> /etc/sudoers

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

EXPOSE 22 80
CMD ["/sbin/init"]

