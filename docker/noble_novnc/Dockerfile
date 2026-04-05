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
      websockify \
      wget \
      dbus-x11 \
      xfce4-goodies \
      x11-xserver-utils \
      policykit-1 \
      tigervnc-standalone-server tigervnc-common \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Install nginx packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      nginx \
      libnginx-mod-http-auth-pam \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Install lightdm packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      lightdm \
      lightdm-gtk-greeter \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Install Xdummy packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      xserver-xorg-video-dummy \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*


# Install x11vnc packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      x11vnc \
      xserver-xorg \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

# Install dbus packages
RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      dbus \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*


EXPOSE 8080
EXPOSE 8443

COPY websockify /usr/local/bin/websockify-c
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

