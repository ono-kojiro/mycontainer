FROM noble

# environment variable for build
ARG DEBIAN_FRONTEND=noninteractive

# Install GUI packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      xfce4 \
      xfce4-terminal \
      novnc \
      dbus-x11 \
      x11-xserver-utils \
      nginx \
      libnginx-mod-http-auth-pam \
      lightdm \
      lightdm-gtk-greeter \
      xserver-xorg-video-dummy \
      x11vnc \
      xserver-xorg \
      dbus \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

EXPOSE 8080
EXPOSE 8443

COPY websockify /usr/local/bin/websockify-c

COPY config/nginx/pam-nginx /etc/pam.d/nginx
COPY config/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/
  
COPY config/xorg/10-xdummy.conf /etc/X11/xorg.conf.d/10-xdummy.conf

# empty
COPY config/lightdm/50-xserver-command.conf /usr/share/lightdm/lightdm.conf.d/

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

