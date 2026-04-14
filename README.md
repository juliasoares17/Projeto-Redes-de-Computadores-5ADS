# Exercício de VPN

## Especificações
* O servidor VPN será executado em uma instância EC2 na AWS
* O servidor VPN será implementado usando OpenVPN com autenticação por certificados (Easy-RSA)
* O servidor VPN será configurado para a porta 1194/UDP
* A aplicação de chat será implementada em Python e será executada na mesma instância EC2 do servidor VPN
* A aplicação de chat permitirá que clientes conectados à VPN enviem mensagens entre si
* A aplicação de chat será executada na porta 8000/TCP


### Configuração do servidor
* O arquivo `setup-pki.sh` inicializa a PKI com Easy-RSA, gera a CA, o certificado do servidor, parâmetros DH e a chave TLS-auth
* O arquivo `server-conf.sh` contém a configuração do servidor OpenVPN em modo TLS
* O arquivo `gen-client.sh` gera certificados individuais para cada cliente

### Configuração do cliente
* O arquivo `client-conf.sh` contém a configuração do cliente OpenVPN. Recebe o nome do cliente como parâmetro


## Iniciar servidor
1. Crie uma instância EC2 com Ubuntu Server
2. Gere um par de chaves para acesso SSH e baixe a chave privada (por exemplo, `ssh-key.pem`)
3. Anote o endereço IP público da instância EC2 para uso posterior na configuração do cliente
4. Garanta que o grupo de segurança associado à instância EC2 permita tráfego de entrada na porta UDP 1194

5. Envie os scripts para a instância EC2 usando SCP
```bash
scp -i ssh-key.pem setup-pki.sh server-conf.sh gen-client.sh ubuntu@<ip-do-servidor>:/home/ubuntu/
scp -i ssh-key.pem -r ./cloud ubuntu@<ip-do-servidor>:/home/ubuntu/cloud
ssh -i ssh-key.pem ubuntu@<ip-do-servidor>
```

6. Após fazer login na instância EC2, execute os scripts como root
```bash
sudo su
chmod +x setup-pki.sh server-conf.sh gen-client.sh
```

7. Inicializar a PKI e gerar certificados do servidor
```bash
./setup-pki.sh
```

8. Gerar certificado para um cliente
```bash
./gen-client.sh client1
```

9. Configurar e iniciar o servidor OpenVPN
```bash
./server-conf.sh
```

10. Iniciar os serviços cloud (copie o `.env.example` para `.env` e preencha as variáveis antes)
```bash
cp ./cloud/.env.example ./cloud/.env
# edite ./cloud/.env com as credenciais desejadas
chmod +x ./cloud/run_cloud.sh
./cloud/run_cloud.sh
docker compose -f ./cloud/docker-compose.yaml up --build -d
```

11. Aplicar regras de firewall (NextCloud acessível apenas pela VPN)
```bash
iptables -D DOCKER-USER -i tun0 -p tcp --dport 8080 -j ACCEPT 2>/dev/null || true
iptables -D DOCKER-USER -p tcp --dport 8080 -j DROP 2>/dev/null || true
iptables -A DOCKER-USER -i tun0 -p tcp --dport 8080 -j ACCEPT
iptables -A DOCKER-USER -p tcp --dport 8080 -j DROP
```

12. Verifique o status do servidor OpenVPN para garantir que está em execução corretamente
```bash
sudo systemctl status myvpn@server
```

13. Verifique se o NextCloud está em execução
```bash
docker inspect nextcloud --format '{{json .NetworkSettings.Ports}}'
```
o resultado deve ser algo como:
```bash
{"80/tcp":[{"HostIp":"10.0.0.1","HostPort":"8080"}]}
```

## Iniciar cliente (VM local ou outra instância EC2)

1. No cliente, garanta que ele tenha a chave ssh privada (`ssh-key.pem`) para acessar a instância EC2 do servidor e o arquivo `client-conf.sh`.

2. Copiar os certificados do cliente a partir do servidor
```bash
scp -i ssh-key.pem -r ubuntu@<ip-do-servidor>:/home/ubuntu/client-keys/client1/ .
mkdir -p /etc/openvpn/client
cp client1/ca.crt client1/client1.crt client1/client1.key client1/ta.key /etc/openvpn/client/
chmod 600 /etc/openvpn/client/*.key
```

3. Execute o script `client-conf.sh` para configurar o cliente OpenVPN
```bash
chmod +x client-conf.sh
sudo ./client-conf.sh client1
```

4. Verifique o status do cliente OpenVPN para garantir que está em execução corretamente
```bash
systemctl status openvpn-client@client
```

## Revogar acesso de um cliente

Para revogar o certificado de um cliente (bloquear o acesso):
```bash
cd /etc/openvpn/easy-rsa
./easyrsa revoke client1
./easyrsa gen-crl
cp pki/crl.pem /etc/openvpn/server/
```
Depois descomente a linha `crl-verify` no arquivo `/etc/openvpn/server/server.conf` e reinicie o serviço:
```bash
systemctl restart openvpn-server@server
```
