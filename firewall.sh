#!/bin/sh
#
# firewall.sh

IPT=iptables
SERVICE=service

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

# Enregistrer la configuration
sudo $SERVICE iptables save
