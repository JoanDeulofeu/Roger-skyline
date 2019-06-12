#!/bin/sh
#
# firewall.sh

IPT="iptables"

# Réseau local
IFACE_LAN=enp0s8

# Remettre les compteurs à zéro
sudo $IPT -t filter -Z

# Supprimer toutes les règles actives et les chaînes personnalisées
sudo $IPT -t filter -F
sudo $IPT -t filter -X

# Politique par défaut
sudo $IPT -P INPUT REJECT
sudo $IPT -P FORWARD REJECT
sudo $IPT -P OUTPUT REJECT

# Protection DDOS
sudo $IPT -A FORWARD -p tcp --syn -m limit --limit 1/second -j ACCEPT

### 8: Limit connections per source IP ###
sudo $IPT -A INPUT -p tcp -m connlimit --connlimit-above 111 -j REJECT --reject-with tcp-reset

### 9: Limit RST packets ###
sudo $IPT -A INPUT -p tcp --tcp-flags RST RST -m limit --limit 2/s --limit-burst 2 -j ACCEPT
sudo $IPT -A INPUT -p tcp --tcp-flags RST RST -j REJECT

### 10: Limit new TCP connections per second per source IP ###
sudo $IPT -A INPUT -p tcp -m conntrack --ctstate NEW -m limit --limit 60/s --limit-burst 20 -j ACCEPT
sudo $IPT -A INPUT -p tcp -m conntrack --ctstate NEW -j REJECT

### 11: Use SYNPROXY on all ports (disables connection limiting rule) ###
#sudo $IPT -t raw -A PREROUTING -p tcp -m tcp --syn -j CT --notrack
#sudo $IPT -A INPUT -p tcp -m tcp -m conntrack --ctstate INVALID,UNTRACKED -j SYNPROXY --sack-perm --timestamp --wscale 7 --mss 1460
#sudo $IPT -A INPUT -m conntrack --ctstate INVALID -j REJECT

# Faire confiance à nous-mêmes ;o)
sudo $IPT -A INPUT -i lo -j ACCEPT
sudo $IPT -A OUTPUT -i lo -j ACCEPT

# Ping
sudo $IPT -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
sudo $IPT -A INPUT -p icmp --icmp-type time-exceeded -j ACCEPT
sudo $IPT -A INPUT -p icmp --icmp-type destination-unreachable -j ACCEPT

# Connexions établies
sudo $IPT -A INPUT -m state --state ESTABLISHED,RELATED  -j ACCEPT
sudo $IPT -A OUTPUT -m state --state ESTABLISHED,RELATED  -j ACCEPT

# SSH
sudo $IPT -A INPUT -p tcp -i $IFACE_LAN --dport 42 -j ACCEPT

# Enregistrer la configuration
#sudo service iptables save
sudo $IPT-save
