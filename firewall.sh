#!/bin/bash
sudo su

# Liberando qualquer tráfego para interface de loopback no firewall
iptables -t filter -A INPUT -i lo -j ACCEPT
iptables -t filter -A OUTPUT -o lo -j ACCEPT

# Estabelecendo a política DROP (restritiva) para as chains INPUT e FORward da tabela filter
iptables -t filter -P INPUT DROP
iptables -t filter -P FORWARD DROP  

# Possibilitando que usuários da rede interna possam acessar o serviço WWW, tanto na porta (TCP) 80 como na 443.
iptables -t filter -A FORWARD -i eno0 -o eno2 -p tcp --dport 80 -j ACCEPT
iptables -t filter -A FORWARD -i eno0 -o eno2 -p tcp --dport 443 -j ACCEPT
iptables -t filter -A FORWARD -i eno2 -o eno0 -p tcp --dport 80 -j ACCEPT
iptables -t filter -A FORWARD -i eno2 -o eno0 -p tcp --dport 443 -j ACCEPT

iptables -t nat -A POUSTROUTING -S 10.1.1.0/24 -o eno2 -j MASQUERADE

# Fazendo LOG e o bloqueio do acesso de qualquer site que contenha a palavra "games"
iptables -t filter -I FORWARD -o eno2 -p tcp --dport 80 -m string --algo bm --string "games" -j LOG
iptables -t filter -I FORWARD -o eno2 -p tcp --dport 80 -m string --algo bm --string "games" -j DROP

# Bloqueando o acesso para qualquer usuário ao site www.jogosonline.com.br, exceto para seu chefe, que possui o endereço IP 10.1.1.100.
iptables -t filter -I FORWARD -o eno2 -s 10.1.1.100 -d www.jogosonline.com.br -p tcp --dport 80 -j ACCEPT
iptables -t filter -I FORWARD -o eno2 -s 10.1.1.0/24 -d www.jogosonline.com.br -p tcp --dport 80 -j DROP

# Permitindo que o firewall receba pacotes do tipo ICMP echo-request (ping), porém, limite a 5 pacotes por segundo.
iptables -t filter -I INPUT -p icmp -- icmp-type -echo-request -m limit --limit 5/s -j ACCEPT

# Permitindo que tanto a rede interna como a DMZ possam realizar consultas ao DNS externo, bem como, receber os resultados das mesmas 
iptables -t filter -I FORWARD -o eno2 -p udp --dport 53 -j ACCEPT
iptables -t filter -I FORWARD -i eno2 -p udp --sport 53 -j ACCEPT

# Permitindo o tráfego TCP destinado à máquina 192.168.1.100 (DMZ) na porta 80, vindo de qualquer rede (Interna ou Externa)
iptables -t filter -I FORWARD -d 192.168.1.100 -p tcp --dport 80 -j ACCEPT


# Redirecionando pacotes TCP destinados ao IP 200.20.5.1 porta 80, para a máquina 192.168.1.100 que está localizado na DMZ
iptables -t nat -A PREROUTING -i eno2 -d 200.20.5.1 -p tcp --dport 80 -j DNAT --to 192.168.1.100

# Fazendo com que a máquina 192.168.1.100 consiga responder os pacotes TCP recebidos na porta 80 corretamente.
iptables -t filter -I FORWARD -s 192.138.1.100 -p tcp --sport 80 -j ACCEPT

