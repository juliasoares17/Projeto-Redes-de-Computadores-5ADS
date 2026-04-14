#!/bin/bash

if [ -z "$1" ]; then
    echo "Uso: $0 <nome-do-cliente>"
    exit 1
fi

CLIENT_NAME="$1"

apt update
apt install -y openvpn iproute2 iputils-ping net-tools

cat > /etc/openvpn/client/client.conf <<EOF
client
dev tun
proto udp
remote <ip-do-servidor> 1194

# Certificados e chaves
ca   /etc/openvpn/client/ca.crt
cert /etc/openvpn/client/${CLIENT_NAME}.crt
key  /etc/openvpn/client/${CLIENT_NAME}.key

# Chave TLS-auth (direcao 1 no cliente, 0 no servidor)
tls-auth /etc/openvpn/client/ta.key 1
remote-cert-tls server

keepalive 10 120
persist-key
persist-tun

cipher AES-256-GCM
auth SHA256

compress lz4-v2

verb 4
resolv-retry infinite
nobind
EOF

systemctl enable --now openvpn-client@client

ip a show tun0
ping -c 3 10.0.0.1
