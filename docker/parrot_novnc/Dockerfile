FROM parrot:latest

# environment variable for build
ARG DEBIAN_FRONTEND=noninteractive

# Install GUI packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install --no-install-recommends \
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

# Install GUI packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install --no-install-recommends \
      nginx-full \
      gettext-base \
      fonts-noto-cjk \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*


RUN  mkdir -p /etc/nginx/includes

COPY websockify /usr/local/bin/websockify-c
#COPY config/nginx/server.conf     /etc/nginx/conf.d/
COPY config/nginx/server.conf     /etc/nginx/sites-enabled/

COPY config/nginx/novnc.conf          /etc/nginx/includes/
COPY config/nginx/auth.conf           /etc/nginx/includes/
COPY config/nginx/websockify.conf     /etc/nginx/includes/
COPY config/nginx/ssl.conf.template   /etc/nginx/includes/

COPY config/nginx/pam-nginx /etc/pam.d/nginx

COPY config/lightdm/lightdm.conf /etc/lightdm/lightdm.conf.d/

COPY config/xorg/10-xdummy.conf /etc/X11/xorg.conf.d/10-xdummy.conf

# empty
COPY config/lightdm/50-xserver-command.conf /usr/share/lightdm/lightdm.conf.d/

COPY entrypoint.sh /entrypoint.sh
RUN  chmod +x /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

COPY lightdm-wrapper.sh /usr/local/bin/
RUN  chmod 755 /usr/local/bin/lightdm-wrapper.sh

COPY x11vnc-wrapper.sh /usr/local/bin/
RUN  chmod 755 /usr/local/bin/x11vnc-wrapper.sh

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

