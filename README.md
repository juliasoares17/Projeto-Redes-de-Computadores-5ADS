# Exercício de VPN

## Especificações
* O servidor VPN será executado em uma instância EC2 na AWS
* O servidor VPN será implementado usando OpenVPN
* O servidor VPN será configurado para a porta 1194/UDP
* A aplicação de chat será implementada em Python e será executada na mesma instância EC2 do servidor VPN
* A aplicação de chat permitirá que clientes conectados à VPN enviem mensagens entre si
* A aplicação de chat será executada na porta 8000/TCP


### Configuração do servidor
* O arquivo `server-conf.sh` contém a configuração do servidor OpenVPN. Ele gera uma chave secreta e cria o arquivo de configuração do servidor.
* O arquivo `server-config.sh` deve ser executado como root na instância EC2 para configurar o servidor OpenVPN.


### Configuração do cliente
* O arquivo `client-conf.sh` contém a configuração do cliente OpenVPN. Ele especifica


## Iniciar servidor
1. Crie uma instância EC2 com Ubuntu Server
2. Gere um par de chaves para acesso SSH e baixe a chave privada (por exemplo, `ssh-key.pem`)
3. Anote o endereço IP público da instância EC2 para uso posterior na configuração do cliente
4. Garanta que o grupo de segurança associado à instância EC2 permita tráfego de entrada na porta UDP 1194

5. Envie o script `server-conf.sh` para a instância EC2 usando SCP e defina as permissões apropriadas
```bash
scp -i ssh-key.pem server-conf.sh ubuntu@<public-id>:/home/ubuntu/server-conf.sh
scp -i ssh-key.pem -r ./cloud ubuntu@<public-id>:/home/ubuntu/cloud
ssh -i ssh-key.pem ubuntu@<public-id>
```

6. Após fazer login na instância EC2, ajuste as permissões do script `server-conf.sh` e execute-o como root
```bash
sudo su
chmod +x server-conf.sh
./server-conf.sh

chmod +x ./cloud/run_cloud.sh
./cloud/run_cloud.sh
docker compose -f ./cloud/docker-compose.yaml up --build -d
```

7. Verifique o status do servidor OpenVPN para garantir que está em execução corretamente
```bash
sudo systemctl status myvpn@server
```

8. Verifique se o NextCloud está em execução
```bash
docker inspect nextcloud --format '{{json .NetworkSettings.Ports}}'
```
o resultado deve ser algo como:
```bash
{"80/tcp":[{"HostIp":"10.0.0.1","HostPort":"8080"}]}
```

9. Disponibilizar chave VPN para o cliente
```bash
cp /etc/openvpn/vpn-key /home/ubuntu/
chown ubuntu:ubuntu /home/ubuntu/vpn-key
chmod 600 /home/ubuntu/vpn-key
```

## Iniciar cliente (VM local ou outra instância EC2)

1. No cliente, garanta que ele tenha a chave ssh privada (`ssh-key.pem`) para acessar a instância EC2 do servidor e o arquivo `client-conf.sh` para configurar o cliente OpenVPN.

2. Execute
```bash
scp -i ssh-key.pem ubuntu@<public-id>:/home/ubuntu/vpn-key .
mkdir -p /etc/openvpn/client
cp ./vpn-key /etc/openvpn/vpn-key
chmod 600 /etc/openvpn/vpn-key
```

3. Execute o script `client-conf.sh` para configurar o cliente OpenVPN
```bash
chmod +x client-conf.sh
sudo ./client-conf.sh
```

4. Verifique o status do cliente OpenVPN para garantir que está em execução corretamente
```bash
systemctl status openvpn-client@client
```
