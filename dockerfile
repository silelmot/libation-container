FROM linuxcontainers/debian-slim

ENV DEBIAN_FRONTEND=noninteractive

# Install dependencies
RUN apt-get update && apt-get install -y \
    apt-utils \
    && apt-get install -y \
    wget \
    xvfb \
    x11vnc \
    openbox \
    pcmanfm \
    python3-numpy \
    novnc \
    xdg-utils \
    websockify \
    ca-certificates \
    && wget https://github.com/rmcrackan/Libation/releases/download/v11.3.13/Libation.11.3.13-linux-chardonnay-amd64.deb -O /tmp/libation.deb \
    && dpkg -i --force-all /tmp/libation.deb || apt-get install -f -y \
    && rm /tmp/libation.deb \
    && apt-get remove -y wget \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/* \
    && apt-get clean \
    && rm -rf /var/cache/debconf/*-old /var/lib/dpkg/*-old \
    && rm -f /var/lib/dpkg/status-old /var/lib/dpkg/status \
    && rm -f /var/lib/dpkg/info/perl-base.list \
    && rm -f /var/lib/apt/extended_states \
    && rm -f /etc/ld.so.cache \
    && rm -f /var/log/apt/eipp.log.xz \
    && rm -f /var/cache/debconf/config.dat


# Create the Libation directory and copy the settings file
#RUN mkdir -p /root/Libation
COPY Settings.json /defaults/Settings.json
COPY AccountsSettings.json /defaults/AccountsSettings.json
# Copy start script
COPY start.sh /start.sh
RUN chmod +x /start.sh

# Expose default ports (these can be overridden at runtime)
EXPOSE 5901 6080

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD pgrep Xvfb && pgrep openbox && pgrep libation && netstat -an | grep -q '5901\|6080'

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD netstat -an | grep 5901 > /dev/null; if [ 0 != $? ]; then exit 1; fi

HEALTHCHECK --interval=30s --timeout=30s --start-period=5s --retries=3 \
    CMD netstat -an | grep 6080 > /dev/null; if [ 0 != $? ]; then exit 1; fi



# Start the services
CMD ["/start.sh"]
