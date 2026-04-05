FROM noble

# environment variable for build
ARG DEBIAN_FRONTEND=noninteractive

# Install GUI packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      xfce4 \
      xfce4-terminal \
      tightvncserver \
      novnc \
      wget \
      dbus-x11 \
      xfce4-goodies \
      x11-xserver-utils \
      policykit-1 \
      tigervnc-standalone-server tigervnc-common \
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
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

