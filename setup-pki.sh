#!/bin/bash

set -e

apt update
apt install -y easy-rsa openvpn

EASYRSA_DIR="/etc/openvpn/easy-rsa"
PKI_DIR="$EASYRSA_DIR/pki"

# Inicializar estrutura do Easy-RSA
make-cadir "$EASYRSA_DIR"
cd "$EASYRSA_DIR"

./easyrsa init-pki

# Gerar CA (sem senha para automacao)
./easyrsa --batch build-ca nopass

# Gerar certificado do servidor
./easyrsa --batch build-server-full server nopass

# Gerar parametros Diffie-Hellman
./easyrsa gen-dh

# Gerar chave TLS-auth (protecao contra DoS e port scanning)
openvpn --genkey secret "$PKI_DIR/ta.key"

# Copiar para diretorio do OpenVPN
mkdir -p /etc/openvpn/server
cp "$PKI_DIR/ca.crt"              /etc/openvpn/server/
cp "$PKI_DIR/issued/server.crt"   /etc/openvpn/server/
cp "$PKI_DIR/private/server.key"  /etc/openvpn/server/
cp "$PKI_DIR/dh.pem"              /etc/openvpn/server/
cp "$PKI_DIR/ta.key"              /etc/openvpn/server/

echo ""
echo "PKI inicializada com sucesso."
echo "CA, certificado do servidor, DH e ta.key gerados."
