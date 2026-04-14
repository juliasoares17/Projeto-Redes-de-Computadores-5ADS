#!/bin/bash

apt update

apt install -y iproute2 iputils-ping net-tools openvpn

cat > /etc/openvpn/server.conf <<EOF
port 1194
proto udp
dev tun

# Certificados e chaves
ca   /etc/openvpn/server/ca.crt
cert /etc/openvpn/server/server.crt
key  /etc/openvpn/server/server.key
dh   /etc/openvpn/server/dh.pem

# Chave TLS-auth (direcao 0 no servidor, 1 no cliente)
tls-auth /etc/openvpn/server/ta.key 0

# Rede VPN - subnet permite multiplos clientes
server 10.0.0.0 255.255.255.0

# Manter registro de IPs atribuidos
ifconfig-pool-persist /etc/openvpn/server/ipp.txt

# Permitir comunicacao entre clientes
client-to-client

keepalive 10 120
persist-key
persist-tun

cipher AES-256-GCM
auth SHA256

compress lz4-v2
push "compress lz4-v2"

verb 4
status /var/log/openvpn-status.log
log-append /var/log/openvpn.log

# Descomente apos gerar a CRL para revogar certificados
# crl-verify /etc/openvpn/server/crl.pem
EOF


echo 1 > /proc/sys/net/ipv4/ip_forward
sed -i 's/^#*net.ipv4.ip_forward.*/net.ipv4.ip_forward = 1/' /etc/sysctl.conf
grep -q 'net.ipv4.ip_forward' /etc/sysctl.conf || echo 'net.ipv4.ip_forward = 1' >> /etc/sysctl.conf

# openvpn --config /etc/openvpn/server.conf

mkdir -p /etc/openvpn/server
cp /etc/openvpn/server.conf /etc/openvpn/server/

systemctl start openvpn-server@server
systemctl enable openvpn-server@server

ln -sf /usr/lib/systemd/system/openvpn-server@.service \
           /etc/systemd/system/myvpn@.service

systemctl daemon-reload

# systemctl status myvpn@server

netstat -unlp
