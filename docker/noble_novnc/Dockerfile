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


COPY novnc_1.6.0_all.deb /tmp/

RUN apt-get -y remove novnc python3-novnc || true

RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      websockify \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get -y install /tmp/novnc_1.6.0_all.deb

RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      tigervnc-standalone-server tigervnc-common \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*

RUN apt-get -qq update \
    && apt-get -qq upgrade \
    && apt-get -qq install \
      tigervnc-tools \
    && apt-get -qq clean \
    && rm -rf /var/lib/apt/lists/*


RUN mkdir -p /root/.vnc
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT [ "/entrypoint.sh" ]
EXPOSE 8443

COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf
CMD ["/usr/bin/supervisord", "-n", "-c", "/etc/supervisor/supervisord.conf"]

