#!/bin/bash

apt update

apt install -y iproute2 iputils-ping net-tools openvpn

openvpn --genkey secret /etc/openvpn/vpn-key

cat > /etc/openvpn/server.conf <<EOF
dev tun
ifconfig 10.0.0.1 10.0.0.2 
secret /etc/openvpn/vpn-key
port 1194 # 1194
proto udp # tcp
comp-lzo
verb 4
keepalive 10 120
persist-key
persist-tun
float
cipher AES-256-CBC
EOF


echo 1 > /proc/sys/net/ipv4/ip_forward

# openvpn --config /etc/openvpn/server.conf

mkdir -p /etc/openvpn/server
cp /etc/openvpn/server.conf /etc/openvpn/server/
cp /etc/openvpn/vpn-key /etc/openvpn/server/

systemctl start openvpn-server@server
systemctl enable openvpn-server@server

ln -s /usr/lib/systemd/system/openvpn-server@.service \
           /etc/systemd/system/myvpn@.service

systemctl daemon-reload

# systemctl status myvpn@server

iptables -D DOCKER-USER -i tun0 -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
iptables -D DOCKER-USER -p tcp --dport 8080 -j DROP 2>/dev/null || true

netstat -unlp
