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
scp -i ssh-key.pem -r /chat ubuntu@<public-id>:/home/ubuntu/chat
ssh -i ssh-key.pem ubuntu@<public-id>
```

6. Após fazer login na instância EC2, ajuste as permissões do script `server-conf.sh` e execute-o como root
```bash
chmod +x server-conf.sh
sudo su
./server-conf.sh
```

7. Verifique o status do servidor OpenVPN para garantir que está em execução corretamente
```bash
sudo systemctl status myvpn@server
```

8. Bloquear o acesso à porta 8000 para conexões que não venham da interface tun0 (VPN)
```bash
iptables -A INPUT -p tcp --dport 8000 ! -i tun0 -j DROP
```

---

## Iniciar cliente
```bash
./client-conf.sh --server <public-ip>
```





## Container Docker SSH

```bash
docker build -t ssh-client -f Dockerfile .
```

```bash
docker run -it `
  -v "$($PWD.Path)\ssh-key.pem:/ssh-key.pem" `
  -v "$($PWD.Path)\server-conf.sh:/server-conf.sh" `
  ssh-client bash
```

```bash
docker run -d `
  --name vpn-client `
  --device /dev/net/tun `
  --cap-add NET_ADMIN `
  -v "$($PWD.Path)\vpn-key:/etc/openvpn/vpn-key" `
  vpn-client ./client-conf.sh --server <public-ip>
```