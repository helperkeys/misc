#!/bin/bash
# Assumes the cloudflared is running with metrics server
# Example: cloudflared tunnel --url 'http://localhost:32400' --metrics 'localhost:33400'

PreferencesPath='/home/ubuntu/plex/config/Library/Application Support/Plex Media Server/Preferences.xml'
PlexOnlineToken='https://plex.tv/api/resources?X-Plex-Token='$(grep -oP 'PlexOnlineToken="\K[^"]*' "${PreferencesPath}")

PlexAPIcustomConnections=$(curl -s $PlexOnlineToken | grep -oP 'address="\K[^"]*\.trycloudflare\.com' | head -n1)
ArgoURL=$(curl -s http://localhost:33400/metrics | grep -oP 'userHostname="https://\K[^"]*\.trycloudflare\.com' | head -n1)

[ -z $ArgoURL ] && exit
[ -z $PlexAPIcustomConnections ] && exit

if [[ $ArgoURL != $PlexAPIcustomConnections ]]; then
    docker container stop plex
    PreferencesValue="https://${ArgoURL}:443,http://${ArgoURL}:80"
    # Set new Argo URL
    sed -i "s|customConnections=\".*\"|customConnections\=\"${PreferencesValue}\"|" "${PreferencesPath}"
    # Disable Plex Relay Servers
    sed -i "s|RelayEnabled=\"1\"|RelayEnabled=\"0\"|" "${PreferencesPath}"
    # Disable Plex Remote Access Methods
    sed -i "s|PublishServerOnPlexOnlineKey=\"1\"|PublishServerOnPlexOnlineKey=\"0\"|" "${PreferencesPath}"
    docker container restart plex
fi
