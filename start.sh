#!/bin/bash


# Create config and log directories if they don't exist
mkdir -p /root/Libation/Logs
mkdir -p /root/Libation/Config

# Check if Settings.json exists, if not, create a blank one
if [ ! -f /root/Libation/Config/Settings.json ]; then
    cp /defaults/Settings.json /root/Libation/Config/Settings.json
    echo "Settings.json installed"
fi

# Check if AccountsSettings.json exists, if not, create a blank one
if [ ! -f /root/Libation/Config/AccountsSettings.json ]; then
    cp /defaults/AccountsSettings.json /root/Libation/Config/AccountsSettings.json
    echo "AccountsSettings.json installed"
fi


# Symlink Settings.json if it's not already a link
if [ ! -L /root/Libation/Settings.json ]; then
    ln -s /root/Libation/Config/Settings.json /root/Libation/Settings.json
    echo "Settings.json now in Config"
fi

# Symlink AccountsSettings.json if it's not already a link
if [ ! -L /root/Libation/AccountsSettings.json ]; then
    ln -s /root/Libation/Config/AccountsSettings.json /root/Libation/AccountsSettings.json
    echo "AccountsSettings.json now in Config"
fi


# Set default ports if not provided
VNC_PORT=${VNC_PORT:-5901}
WEBSOCKIFY_PORT=${WEBSOCKIFY_PORT:-6080}

# Direct logs to the Logs directory
OPENBOX_LOG_PATH="/root/Libation/Logs/openbox.log"
X11VNC_LOG_PATH="/root/Libation/Logs/x11vnc.log"
WEBSOCKIFY_LOG_PATH="/root/Libation/Logs/websockify.log"
LIBATION_LOG_PATH="/root/Libation/Logs/libation_run.log"

# Configure dconf to use a dummy backend to avoid dbus issues
#export DC_CONFIG_HOME=/root/Libation/dconf
#mkdir -p $DC_CONFIG_HOME
#echo "[user]" > $DC_CONFIG_HOME/user
#dconf update


# Function to create directory if it doesn't exist
create_dir_if_not_exists() {
    if [ ! -d "$1" ]; then
        mkdir -p "$1"
        echo "Created directory: $1"
    else
        echo "Directory already exists: $1"
    fi
}

# Create necessary directories
mkdir -p $(dirname "$OPENBOX_LOG_PATH") 

#if [ ! -e /var/run/dbus/system_bus_socket ]; then
#    dbus-daemon --system --fork
#    echo "D-Bus system daemon started"
#fi


# Remove the X server lock file to avoid issues when starting Xvfb
rm -f /tmp/.X99-lock

# Export DISPLAY environment variable before starting Xvfb
export DISPLAY=:99

# Start virtual framebuffer
Xvfb :99 -screen 0 1280x720x16 &
echo "Xvfb started on $DISPLAY"

# Warte kurz, damit Xvfb starten kann
sleep 1

# Setze die Hintergrundfarbe auf Grau
xsetroot -solid grey -display :99

# Start window manager
openbox &> "$OPENBOX_LOG_PATH" &
echo "Openbox window manager started"

# Start x11vnc server on the specified port
x11vnc -display :99 -forever -nopw -shared -rfbport $VNC_PORT &> "$X11VNC_LOG_PATH" &
echo "x11vnc started on port $VNC_PORT"

xsetroot -solid "gray" -display :99 &


# Create a symlink to vnc_lite.html as index.html if it does not already exist
NOVNC_INDEX="/usr/share/novnc/index.html"
if [ ! -f "$NOVNC_INDEX" ]; then
    ln -s /usr/share/novnc/vnc_lite.html $NOVNC_INDEX
    echo "Created symlink for noVNC index.html"
else
    echo "Symlink for noVNC index.html already exists"
fi

#dbus-monitor --system &
# Start websockify server and proxy to the new VNC port
websockify --web /usr/share/novnc/ $WEBSOCKIFY_PORT localhost:$VNC_PORT &> "$WEBSOCKIFY_LOG_PATH" &
echo "Websockify started on port $WEBSOCKIFY_PORT"

# Start Libation
#dbus-launch libation
#echo "Libation started"

# Keep starting Libation in an infinite loop
while true; do
    #dbus-launch 
    libation &> "$LIBATION_LOG_PATH"
    echo "Libation exited, restarting in 10 sec..."
    sleep 10  # Optional: Delay before restart to avoid rapid loops on fast failures
done
