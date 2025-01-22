#!/bin/bash

# Update the system
apt-get update
apt-get upgrade -y

# Install necessary packages
apt-get install -y curl wget libssl-dev jq

# Install ShadowSocks from the official repository
apt-get install -y shadowsocks-libev

# Determine the latest version of Cloak
CLOAK_VERSION=$(curl -s https://api.github.com/repos/cbeuw/Cloak/releases/latest | jq -r .tag_name | sed 's/v//')
if [ -z "$CLOAK_VERSION" ]; then
  echo "Unable to determine the latest version of Cloak. Using version 2.10.0."
  CLOAK_VERSION="2.10.0"
fi

# Download Cloak files
wget -q https://github.com/cbeuw/Cloak/releases/download/v${CLOAK_VERSION}/ck-server-linux-amd64-v${CLOAK_VERSION} -O /usr/local/bin/ck-server

# Check if the download was successful
if [ ! -f /usr/local/bin/ck-server ]; then
    echo "Error downloading Cloak files."
    exit 1
fi

# Install Cloak
chmod +x /usr/local/bin/ck-server

# Generate keys for Cloak
KEY_OUTPUT=$(/usr/local/bin/ck-server -k)

# Extract PublicKey and PrivateKey
PUBLIC_KEY=$(echo "$KEY_OUTPUT" | awk -F',' '{print $1}')
PRIVATE_KEY=$(echo "$KEY_OUTPUT" | awk -F',' '{print $2}')

# Check if keys were generated successfully
if [ -z "$PUBLIC_KEY" ] || [ -z "$PRIVATE_KEY" ]; then
  echo "Error generating keys for Cloak."
  exit 1
fi

# Generate AdminUID
ADMIN_UID=$(/usr/local/bin/ck-server -u)

# Check if AdminUID was generated successfully
if [ -z "$ADMIN_UID" ]; then
  echo "Error generating AdminUID for Cloak."
  exit 1
fi

# Generate password for ShadowSocks
SHADOWSOCKS_PASSWORD=$(head -c 16 /dev/urandom | base64)

# Create configuration file for Cloak
mkdir -p /etc/cloak
cat <<EOF > /etc/cloak/config.json
{
    "ProxyBook": {
        "shadowsocks": ["tcp", "127.0.0.1:8388"]
    },
    "BindAddr": [":443"],
    "BypassUID": [],
    "RedirAddr": "www.bing.com",
    "PrivateKey": "$PRIVATE_KEY",
    "AdminUID": "$ADMIN_UID",
    "DatabasePath": "/etc/cloak/userinfo.db"
}
EOF

# Check if the configuration file was created successfully
if [ $? -ne 0 ]; then
  echo "Error creating the Cloak configuration file."
  exit 1
fi

# Create a service for Cloak
cat <<EOF > /etc/systemd/system/cloak.service
[Unit]
Description=Cloak Server
After=network.target

[Service]
ExecStart=/usr/local/bin/ck-server -c /etc/cloak/config.json
Restart=always

[Install]
WantedBy=multi-user.target
EOF

# Reload systemd and enable the Cloak service
systemctl daemon-reload
systemctl enable --now cloak

# Check if the Cloak service is running
if ! systemctl is-active --quiet cloak; then
  echo "Error: Cloak service is not running. Check the logs:"
  journalctl -u cloak.service
  exit 1
fi

# Configure ShadowSocks
cat <<EOF > /etc/shadowsocks-libev/config.json
{
    "server":"0.0.0.0",
    "server_port":8388,
    "password":"$SHADOWSOCKS_PASSWORD",
    "method":"aes-256-gcm",
    "timeout":300,
    "fast_open":false
}
EOF

# Restart and enable the ShadowSocks service
systemctl restart shadowsocks-libev
systemctl enable shadowsocks-libev

# Check if the ShadowSocks service is running
if ! systemctl is-active --quiet shadowsocks-libev; then
  echo "Error: ShadowSocks service is not running."
  exit 1
fi

# Get the external IP address of the server
SERVER_IP=$(curl -s --max-time 10 https://api.ipify.org)
if [ -z "$SERVER_IP" ]; then
  echo "Unable to automatically determine the external IP address of the server."
  read -p "Enter the external IP address of the server manually: " SERVER_IP
fi

# Encode the ShadowSocks parameters in base64
SHADOWSOCKS_BASE64=$(echo -n "aes-256-gcm:$SHADOWSOCKS_PASSWORD" | base64)

# Form the Cloak plugin parameters
CLOAK_PLUGIN="ck-client;UID=$ADMIN_UID;ProxyMethod=shadowsocks;PublicKey=$PUBLIC_KEY;EncryptionMethod=plain;ServerName=www.bing.com"
CLOAK_PLUGIN_URLENCODED=$(echo -n "$CLOAK_PLUGIN" | jq -sRr @uri)

# Form the client link
CLIENT_LINK="ss://$SHADOWSOCKS_BASE64@$SERVER_IP:443?plugin=$CLOAK_PLUGIN_URLENCODED"

# Summary
echo "Installation completed!"
echo "AdminUID: $ADMIN_UID"
echo "PrivateKey: $PRIVATE_KEY"
echo "PublicKey: $PUBLIC_KEY"
echo "ShadowSocks Password: $SHADOWSOCKS_PASSWORD"
echo "Client link: $CLIENT_LINK"