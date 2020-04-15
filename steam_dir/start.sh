#!/usr/bin/env bash

set -e

# These envvars should've been set by the Dockerfile
# If they're not set then something went wrong during the build
: "${STEAM_DIR:?'ERROR: STEAM_DIR IS NOT SET!'}"
: "${STEAMCMD_DIR:?'ERROR: STEAMCMD_DIR IS NOT SET!'}"
: "${CSGO_APP_ID:?'ERROR: CSGO_APP_ID IS NOT SET!'}"
: "${CSGO_DIR:?'ERROR: CSGO_DIR IS NOT SET!'}"

export SERVER_HOSTNAME="${SERVER_HOSTNAME:-Counter-Strike: Global Offensive Dedicated Server}"
export SERVER_PASSWORD="${SERVER_PASSWORD:-}"
export RCON_PASSWORD="${RCON_PASSWORD:-changeme}"
export STEAM_ACCOUNT="${STEAM_ACCOUNT:-changeme}"
export AUTHKEY="${AUTHKEY:-changeme}"
export IP="${IP:-0.0.0.0}"
export PORT="${PORT:-27015}"
export TV_PORT="${TV_PORT:-27020}"
export TICKRATE="${TICKRATE:-128}"
export FPS_MAX="${FPS_MAX:-300}"
export GAME_TYPE="${GAME_TYPE:-0}"
export GAME_MODE="${GAME_MODE:-1}"
export MAP="${MAP:-de_dust2}"
export MAPGROUP="${MAPGROUP:-mg_active}"
export MAXPLAYERS="${MAXPLAYERS:-12}"
export TV_ENABLE="${TV_ENABLE:-1}"
export LAN="${LAN:-0}"
export SOURCEMOD_ADMINS="${SOURCEMOD_ADMINS:-}"
export RETAKES="${RETAKES:-0}"

# Attempt to update CSGO before starting the server
"$STEAMCMD_DIR/steamcmd.sh" +login anonymous +force_install_dir "$CSGO_DIR" +app_update "$CSGO_APP_ID" +quit

# Create dynamic autoexec config
cat << AUTOEXECCFG > "$CSGO_DIR/csgo/cfg/autoexec.cfg"
log on
hostname "$SERVER_HOSTNAME"
rcon_password "$RCON_PASSWORD"
sv_password "$SERVER_PASSWORD"
sv_cheats 0
sv_downloadurl "$FAST_DOWNLOAD_URL"
sv_allowdownload ${ALLOW_FAST_DOWNLOAD:-0}
exec banned_user.cfg
exec banned_ip.cfg
AUTOEXECCFG

# Create dynamic server config
cat << SERVERCFG > "$CSGO_DIR/csgo/cfg/server.cfg"
tv_enable $TV_ENABLE
tv_delaymapchange 1
tv_delay 30
tv_deltacache 2
tv_dispatchmode 1
tv_maxclients 10
tv_maxrate 0
tv_overridemaster 0
tv_relayvoice 1
tv_snapshotrate 64
tv_timeout 60
tv_transmitall 1
writeid
writeip
SERVERCFG

# Install and configure plugins & extensions
"$BASH" "$STEAM_DIR/manage_plugins.sh"

# Update csgo dir
rsync -r "$STEAM_DIR/csgo_sync/" "$CSGO_DIR/"

# Make configs from templates
find "$STEAM_DIR/csgo_templates" -type f -exec sh -c 'FILE=$(echo {} | sed "s|$STEAM_DIR/csgo_templates/||"); ( echo "cat <<EOF"; cat "$STEAM_DIR/csgo_templates/$FILE"; echo "EOF" ) | sh > "$STEAM_DIR/csgo/$FILE"' \;

# Start the server
exec "$BASH" "$CSGO_DIR/srcds_run" \
        -console \
        -usercon \
        -game csgo \
        -autoupdate \
        -authkey "$AUTHKEY" \
        -steam_dir "$STEAMCMD_DIR" \
        -steamcmd_script "$STEAM_DIR/autoupdate_script.txt" \
        -tickrate "$TICKRATE" \
        -port "$PORT" \
        -net_port_try 1 \
        -ip "$IP" \
        -maxplayers_override "$MAXPLAYERS" \
        +fps_max "$FPS_MAX" \
        +game_type "$GAME_TYPE" \
        +game_mode "$GAME_MODE" \
        +mapgroup "$MAPGROUP" \
        +map "$MAP" \
        +sv_setsteamaccount "$STEAM_ACCOUNT" \
        +sv_lan "$LAN" \
        +tv_port "$TV_PORT"
