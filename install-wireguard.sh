#!/bin/bash

# WireGuard VPN Auto-Installer for Ubuntu/Debian

# Variables
SERVER_IP=$(curl -s ifconfig.me)  # Automatically detects the server's public IP
WG_PORT=51820
WG_INTERFACE="wg0"
WG_DIR="/etc/wireguard"
WG_CONFIG="$WG_DIR/$WG_INTERFACE.conf"
CLIENT_NAME="client1"
CLIENT_CONFIG="$WG_DIR/$CLIENT_NAME.conf"
CLIENT_DIR="$HOME/$CLIENT_NAME"

# Install WireGuard
echo "[+] Installing WireGuard..."
sudo apt update -y && sudo apt install wireguard -y

# Enable IP forwarding
echo "[+] Enabling IP forwarding..."
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Generate server keys
echo "[+] Generating server keys..."
mkdir -p $WG_DIR
umask 077
wg genkey | tee $WG_DIR/privatekey | wg pubkey > $WG_DIR/publickey
SERVER_PRIVATE_KEY=$(cat $WG_DIR/privatekey)
SERVER_PUBLIC_KEY=$(cat $WG_DIR/publickey)

# Generate client keys
echo "[+] Generating client keys..."
wg genkey | tee $WG_DIR/$CLIENT_NAME-privatekey | wg pubkey > $WG_DIR/$CLIENT_NAME-publickey
CLIENT_PRIVATE_KEY=$(cat $WG_DIR/$CLIENT_NAME-privatekey)
CLIENT_PUBLIC_KEY=$(cat $WG_DIR/$CLIENT_NAME-publickey)

# Configure WireGuard server
echo "[+] Configuring WireGuard server..."
cat <<EOF | sudo tee $WG_CONFIG
[Interface]
Address = 10.0.0.1/24
PrivateKey = $SERVER_PRIVATE_KEY
ListenPort = $WG_PORT
PostUp = iptables -A FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -A FORWARD -o $WG_INTERFACE -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i $WG_INTERFACE -j ACCEPT; iptables -D FORWARD -o $WG_INTERFACE -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = $CLIENT_PUBLIC_KEY
AllowedIPs = 10.0.0.2/32
EOF

# Configure client
echo "[+] Creating client configuration..."
mkdir -p $CLIENT_DIR
cat <<EOF | tee $CLIENT_CONFIG
[Interface]
PrivateKey = $CLIENT_PRIVATE_KEY
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = $SERVER_PUBLIC_KEY
Endpoint = $SERVER_IP:$WG_PORT
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
EOF

# Set up firewall rules
echo "[+] Configuring firewall..."
ufw allow $WG_PORT/udp
ufw enable

# Enable and start WireGuard
echo "[+] Starting WireGuard service..."
sudo systemctl enable wg-quick@$WG_INTERFACE
sudo systemctl start wg-quick@$WG_INTERFACE

echo "[+] WireGuard VPN installation complete!"
echo "[+] Client config saved to: $CLIENT_CONFIG"
echo "[+] Transfer it to your client device and import it into WireGuard."

