#!/bin/sh
#
# firewall.sh

IPT="iptables"

# Réseau local
IFACE_LAN=enp0s8

# Tout accepter
sudo $IPT -t filter -P INPUT ACCEPT
sudo $IPT -t filter -P FORWARD ACCEPT
sudo $IPT -t filter -P OUTPUT ACCEPT
sudo $IPT -t nat -P PREROUTING ACCEPT
sudo $IPT -t nat -P POSTROUTING ACCEPT
sudo $IPT -t nat -P OUTPUT ACCEPT
sudo $IPT -t mangle -P PREROUTING ACCEPT
sudo $IPT -t mangle -P INPUT ACCEPT
sudo $IPT -t mangle -P FORWARD ACCEPT
sudo $IPT -t mangle -P OUTPUT ACCEPT
sudo $IPT -t mangle -P POSTROUTING ACCEPT

# Remettre les compteurs à zéro
sudo $IPT -t filter -Z
sudo $IPT -t nat -Z
sudo $IPT -t mangle -Z

# Supprimer toutes les règles actives et les chaînes personnalisées
sudo $IPT -t filter -F
sudo $IPT -t filter -X
sudo $IPT -t nat -F
sudo $IPT -t nat -X
sudo $IPT -t mangle -F
sudo $IPT -t mangle -X

# Politique par défaut
sudo $IPT -P INPUT DROP
sudo $IPT -P FORWARD DROP
sudo $IPT -P OUTPUT ACCEPT

# Faire confiance à nous-mêmes ;o)
sudo $IPT -A INPUT -i lo -j ACCEPT


# Ping
sudo $IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
sudo $IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
sudo $IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT

# Connexions établies
sudo $IPT -A INPUT -m state --state ESTABLISHED -j ACCEPT

# SSH
sudo $IPT -A INPUT -p tcp -i $IFACE_LAN --dport 42 -j ACCEPT

# Protection DDOS
sudo $IPT -A FORWARD -p tcp --syn -m limit --limit 1/second -j ACCEPT

### 1: Drop invalid packets ###
sudo $IPT -t mangle -A PREROUTING -m conntrack --ctstate INVALID -j DROP

### 2: Drop TCP packets that are new and are not SYN ###
sudo $IPT -t mangle -A PREROUTING -p tcp ! --syn -m conntrack --ctstate NEW -j DROP

### 3: Drop SYN packets with suspicious MSS value ###
sudo $IPT -t mangle -A PREROUTING -p tcp -m conntrack --ctstate NEW -m tcpmss ! --mss 536:65535 -j DROP

### 4: Block packets with bogus TCP flags ###
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN,RST,PSH,ACK,URG NONE -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags FIN,SYN FIN,SYN -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags SYN,RST SYN,RST -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags SYN,FIN SYN,FIN -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags FIN,RST FIN,RST -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags FIN,ACK FIN -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags ACK,URG URG -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags ACK,FIN FIN -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags ACK,PSH PSH -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL ALL -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL NONE -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL FIN,PSH,URG -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,FIN,PSH,URG -j DROP
sudo $IPT -t mangle -A PREROUTING -p tcp --tcp-flags ALL SYN,RST,ACK,FIN,URG -j DROP

### 5: Block spoofed packets ###
sudo $IPT -t mangle -A PREROUTING -s 224.0.0.0/3 -j DROP
sudo $IPT -t mangle -A PREROUTING -s 169.254.0.0/16 -j DROP
sudo $IPT -t mangle -A PREROUTING -s 172.16.0.0/12 -j DROP
sudo $IPT -t mangle -A PREROUTING -s 192.0.2.0/24 -j DROP
sudo $IPT -t mangle -A PREROUTING -s 192.168.0.0/16 -j DROP
sudo $IPT -t mangle -A PREROUTING -s 10.0.0.0/8 -j DROP
sudo $IPT -t mangle -A PREROUTING -s 0.0.0.0/8 -j DROP
sudo $IPT -t mangle -A PREROUTING -s 240.0.0.0/5 -j DROP
sudo $IPT -t mangle -A PREROUTING -s 127.0.0.0/8 ! -i lo -j DROP

### 6: Drop ICMP (you usually don't need this protocol) ###
sudo $IPT -t mangle -A PREROUTING -p icmp -j DROP

### 7: Drop fragments in all chains ###
sudo $IPT -t mangle -A PREROUTING -f -j DROP

### 8: Limit connections per source IP ###
sudo $IPT -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset

### 9: Limit RST packets ###
sudo $IPT -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
sudo $IPT -A INPUT -p tcp --tcp-flags RST RST -j DROP

### 10: Limit new TCP connections per second per source IP ###
sudo $IPT -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
sudo $IPT -A INPUT -p tcp -m conntrack --ctstate NEW -j DROP

### 11: Use SYNPROXY on all ports (disables connection limiting rule) ###
#sudo $IPT -t raw -A PREROUTING -p tcp -m tcp --syn -j CT --notrack
#sudo $IPT -A INPUT -p tcp -m tcp -m conntrack --ctstate INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460
#sudo $IPT -A INPUT -m conntrack --ctstate INVALID -j DROP

# Enregistrer la configuration
#sudo service iptables save
sudo $IPT-save
