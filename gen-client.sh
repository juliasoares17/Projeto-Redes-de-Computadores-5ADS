#!/bin/bash

set -e

if [ -z "$1" ]; then
    echo "Uso: $0 <nome-do-cliente>"
    exit 1
fi

CLIENT_NAME="$1"
EASYRSA_DIR="/etc/openvpn/easy-rsa"
PKI_DIR="$EASYRSA_DIR/pki"
CLIENT_DIR="/home/ubuntu/client-keys/$CLIENT_NAME"

cd "$EASYRSA_DIR"

# Gerar certificado do cliente
./easyrsa --batch build-client-full "$CLIENT_NAME" nopass

# Disponibilizar arquivos para transferencia
mkdir -p "$CLIENT_DIR"
cp "$PKI_DIR/ca.crt"                       "$CLIENT_DIR/"
cp "$PKI_DIR/issued/${CLIENT_NAME}.crt"    "$CLIENT_DIR/"
cp "$PKI_DIR/private/${CLIENT_NAME}.key"   "$CLIENT_DIR/"
cp "$PKI_DIR/ta.key"                       "$CLIENT_DIR/"
chown -R ubuntu:ubuntu "$CLIENT_DIR"
chmod 600 "$CLIENT_DIR"/*.key

echo ""
echo "Certificado gerado para: $CLIENT_NAME"
echo "Arquivos em: $CLIENT_DIR"
