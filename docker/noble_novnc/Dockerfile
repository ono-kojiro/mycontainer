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
      x11vnc \
      xvfb \
      wget \
      dbus-x11 \
      xfce4-goodies \
      x11-xserver-utils \
      policykit-1 \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

RUN mkdir -p /root/.vnc
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
EXPOSE 8443

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

