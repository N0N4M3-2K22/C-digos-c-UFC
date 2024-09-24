#! /bin/bash


# ativando o firewall
iptables -P INPUT DROP
iptables -P OUTPUT DROP
iptables -P FORWARD DROP


# limpando regras
iptables -F
iptables -t nat -F


# liberando o firewall
iptables -P INPUT ACCEPT
iptables -P OUTPUT ACCEPT
iptables -P FORWARD ACCEPT


# firewall
# permitindo pacotes internos do firewall
iptables -A INPUT  -i lo -j ACCEPT
iptables -A OUTPUT -o lo -j ACCEPT

BRID="enp0s3"
HOST="enp0s8"


# permitindo ssh diretamente para o firewall
iptables -A INPUT  -i $BRID -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o $BRID -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# permitindo icmp diretamente para o firewall
iptables -A INPUT  -i $BRID -p icmp --icmp-type echo-request -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o $BRID -p icmp --icmp-type echo-reply -m conntrack --ctstate ESTABLISHED -j ACCEPT


# permitindo que o firewall faça consultas dns
iptables -A OUTPUT -o $BRID -p udp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o $BRID -p tcp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

iptables -A INPUT -i $BRID -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT
iptables -A INPUT -i $BRID -p tcp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT


# rede interna

iptables -t nat -F
iptables -t nat -A POSTROUTING -o $BRID -j MASQUERADE

# permitindo ICMP do cliente para a internet
iptables -A FORWARD -i $HOST -o $BRID -p icmp --icmp-type echo-request -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $BRID -o $HOST -p icmp --icmp-type echo-reply -m conntrack --ctstate ESTABLISHED -j ACCEPT

# permitindo novas conexões ssh, dns, smtp
iptables -A FORWARD -i $HOST -o $BRID -p tcp -m multiport --dport 22,53,587 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT

# permitindo respostas ssh, dns e smtp de conexões
# ja estabelecidas
iptables -A FORWARD -i $BRID -o $HOST -p tcp -m multiport --sport 22,53,587 -m conntrack --ctstate ESTABLISHED -j ACCEPT

# Permitir SMTP (porta 25)
iptables -A FORWARD -i $HOST -o $BRID -p tcp --dport 25 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $BRID -o $HOST -p tcp --sport 25 -m conntrack --ctstate ESTABLISHED -j ACCEPT


# permitindo dns (udp)
iptables -A FORWARD -i $HOST -o $BRID -p udp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $BRID -o $HOST -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT


# permitindo que o cliente faça requisições http e https
iptables -A FORWARD -i $HOST -o $BRID -p tcp -m multiport --dport 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $BRID -o $HOST -p tcp -m multiport --sport 80,442 -m conntrack --ctstate ESTABLISHED -j ACCEPT


# Permitir FTP para clientes
iptables -A FORWARD -i $HOST -o $BRID -p tcp --dport 21 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $BRID -o $HOST -p tcp --sport 21 -m conntrack --ctstate ESTABLISHED -j ACCEPT


# redirecionando http e https para o squid
iptables -t nat -A PREROUTING -i $HOST -p tcp --dport 80 -j REDIRECT --to-ports 3129
iptables -t nat -A PREROUTING -i $HOST -p tcp --dport 443 -j REDIRECT --to-ports 3130


# rede DMZ
DMZ_BRID="enp0s9"
FIREWALL_ADDRESS="192.168.1.8"
WEB_SERVER="192.168.57.5"

# permitindo encaminhamento da interface enp0s3 para enp0s9 para pacotes http e https
iptables -A FORWARD -i $BRID -o $DMZ_BRID -p tcp -m multiport --dport 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $DMZ_BRID -o $BRID -p tcp -m multiport --sport 80,443 -m conntrack --ctstate ESTABLISHED -j ACCEPT


# permitindo acesso ao servidor web vindo da internet
iptables -t nat -A PREROUTING -i $BRID -d $FIREWALL_ADDRESS -p tcp --dport 80 -j DNAT --to-destination $WEB_SERVER:80
iptables -t nat -A PREROUTING -i $BRID -d $FIREWALL_ADDRESS -p tcp --dport 443 -j DNAT --to-destination $WEB_SERVER:443


# permitinfo ping para o servidor web vindo da internet
iptables -A FORWARD -i $BRID -o $DMZ_BRID -d $WEB_SERVER -p icmp --icmp-type echo-request -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i $DMZ_BRID -o $BRID -s $WEB_SERVER -p icmp --icmp-type echo-reply -m conntrack --ctstate ESTABLISHED -j ACCEPT

