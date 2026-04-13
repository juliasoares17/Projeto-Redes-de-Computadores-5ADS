#!/bin/bash

apt update
apt install -y openvpn iproute2 iputils-ping net-tools

cat > /etc/openvpn/client/client.conf <<EOF
dev tun
ifconfig 10.0.0.2 10.0.0.1
remote <ip_do_servidor>
secret /etc/openvpn/vpn-key
port 1194
proto udp
comp-lzo
verb 4
keepalive 10 120
persist-key
persist-tun
float
cipher AES-256-CBC
EOF

systemctl enable --now openvpn-client@client

ip a show tun0
ping -c 3 10.0.0.1
