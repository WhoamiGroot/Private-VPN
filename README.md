When you have a spare laptop or desktop or a raspberri pi left which you can a server on it then here i will explain how to run your own VPN server for more privace and security.
I will also add a script to install wireguard automatic. (Instructions at bottom of the readme file).

So let's start:

Setting up your own VPN server involves several steps, including choosing the right server, installing the VPN software, and configuring security settings. Below is a step-by-step guide to setting up your own VPN server.

Step 1: Choose Your Server

You need a server to run your VPN. You have two main options:

1.    Self-Hosted Server – You can use your own computer, Raspberry Pi, or a dedicated server.
2.    Cloud VPS – Renting a VPS from providers like AWS, DigitalOcean, Linode, or Vultr.

For security and reliability, a cloud VPS is usually recommended.

Step 2: Choose a VPN Software

Popular open-source VPN software includes:

    WireGuard (lightweight, fast, and secure)
    OpenVPN (widely used, highly configurable)
    SoftEther VPN (multi-protocol support)
    Pritunl (enterprise-grade, based on OpenVPN)

For simplicity and performance, WireGuard is a great choice.



Step 3: Set Up Your VPN Server
Option 1: WireGuard Setup

1.Install WireGuard
    On Ubuntu/Debian-based systems:

```
sudo apt update && sudo apt install wireguard -y
```
On CentOS:
```
sudo yum install epel-release -y
sudo yum install wireguard-tools -y
```
2.Generate Keys
```
wg genkey | tee privatekey | wg pubkey > publickey
```
3.Configure WireGuard Edit the configuration file:
```
sudo nano /etc/wireguard/wg0.conf
```
Add the following configuration:
```
[Interface]
Address = 10.0.0.1/24
PrivateKey = <server_private_key>
ListenPort = 51820
PostUp = iptables -A FORWARD -i wg0 -j ACCEPT; iptables -A FORWARD -o wg0 -j ACCEPT; iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE
PostDown = iptables -D FORWARD -i wg0 -j ACCEPT; iptables -D FORWARD -o wg0 -j ACCEPT; iptables -t nat -D POSTROUTING -o eth0 -j MASQUERADE

[Peer]
PublicKey = <client_public_key>
AllowedIPs = 10.0.0.2/32
```
4.Enable and Start WireGuard
```
sudo systemctl enable wg-quick@wg0
sudo systemctl start wg-quick@wg0
```

--------------------------------------------------------------------------------

Option 2: OpenVPN Setup

1.Install OpenVPN
```
sudo apt update
sudo apt install openvpn easy-rsa -y
```
2.Set Up Certificate Authority
```
make-cadir ~/openvpn-ca
cd ~/openvpn-ca
source vars
./clean-all
./build-ca
```
3.Generate Server Keys and Certificates
```
./build-key-server server
./build-dh
openvpn --genkey --secret keys/ta.key
```
4.Configure OpenVPN
```
sudo nano /etc/openvpn/server.conf
```

Example configuration:
```
port 1194
proto udp
dev tun
ca /etc/openvpn/ca.crt
cert /etc/openvpn/server.crt
key /etc/openvpn/server.key
dh /etc/openvpn/dh.pem
```

5.Enable and Start OpenVPN
```
sudo systemctl start openvpn@server
sudo systemctl enable openvpn@server
```
--------------------------------------------------------------------------------

Step 4: Configure Firewall

For WireGuard:
```
sudo ufw allow 51820/udp
sudo ufw enable
```

For OpenVPN:
```
sudo ufw allow 1194/udp

```

Enable IP Forwarding:
```
echo "net.ipv4.ip_forward=1" | sudo tee -a /etc/sysctl.conf
sudo sysctl -p
```
````````````````````````````````````````````````````````````````````````````````
Step 5: Set Up VPN Clients

1.For WireGuard
Install WireGuard on the client and add a configuration:
```
[Interface]
PrivateKey = <client_private_key>
Address = 10.0.0.2/24
DNS = 1.1.1.1

[Peer]
PublicKey = <server_public_key>
Endpoint = <server_ip>:51820
AllowedIPs = 0.0.0.0/0
PersistentKeepalive = 25
```

2.For OpenVPN
Generate client configurations and distribute them securely.
--------------------------------------------------------------------------------
Step 6: Test Your VPN

Connect using the client.
Verify IP address changes with:
```
curl ifconfig.me
```
Check connectivity with ping 10.0.0.1 (WireGuard) or ping server (OpenVPN).
--------------------------------------------------------------------------------
Now you have a working VPN server! For better security, consider:

    Using a firewall like UFW or iptables.
    Enabling fail2ban to prevent brute-force attacks.
    Keeping your VPN software updated.
--------------------------------------------------------------------------------


# WireGuard VPN Auto-Install Script
This script will:

    Install WireGuard
    Generate server keys and configuration
    Set up firewall rules
    Generate a client configuration file
    
```
nano install-wireguard.sh
```

Make the script executeable:
```
chmod +x install-wireguard.sh
```
Run the script:
```
sudo ./install-wireguard.sh
```

What This Script Does

    Installs WireGuard.
    Enables IP forwarding for VPN traffic.
    Generates server and client keys.
    Configures server and client VPN settings.
    Sets up firewall rules using ufw.
    Starts and enables the WireGuard service.
    
How to Use the VPN

    On the Client
        Copy the client1.conf file to your device.
        Install WireGuard on the client device (Windows, macOS, Linux, Android, iOS).
        Import client1.conf into the WireGuard app.
        Connect to the VPN!
