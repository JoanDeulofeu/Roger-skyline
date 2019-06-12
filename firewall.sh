sudo $IPT#!/bin/sh
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

## On flush iptables.
sudo iptables-restore < /etc/iptables.test.rules
sudo $IPT -F

## On supprime toutes les chaînes utilisateurs.
sudo $IPT -X

## On drop tout le trafic entrant.
sudo $IPT -t filter -P INPUT DROP

## On drop tout le trafic sortant.
sudo $IPT -t filter -P OUTPUT DROP

## On drop le forward.
sudo $IPT -t filter -P FORWARD DROP

## NULL-SCAN
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL NONE -j LOG \
--log-prefix "IPTABLES NULL-SCAN:"
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL NONE -j DROP

## XMAS-SCAN
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL ALL -j LOG \
--log-prefix "IPTABLES XMAS-SCAN:"
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL ALL -j DROP

## SYNFIN-SCAN
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL SYN,FIN -j LOG \
--log-prefix "IPTABLES SYNFIN-SCAN:"
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL SYN,FIN -j DROP

## NMAP-XMAS-SCAN
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL URG,PSH,FIN -j LOG \
--log-prefix "IPTABLES NMAP-XMAS-SCAN:"
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL URG,PSH,FIN -j DROP

## FIN-SCAN
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL FIN -j LOG \
--log-prefix "IPTABLES FIN-SCAN:"
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL FIN -j DROP

## NMAP-ID
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL URG,PSH,SYN,FIN -j LOG \
--log-prefix "IPTABLES NMAP-ID:"
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags ALL URG,PSH,SYN,FIN -j DROP

## SYN-RST
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j LOG \
--log-prefix "IPTABLES SYN-RST:"
sudo $IPT -t filter -A INPUT -p tcp --tcp-flags SYN,RST SYN,RST -j DROP

## SYN-FLOODING
sudo $IPT -t filter -N syn-flood
sudo $IPT -t filter -A INPUT -i eth0 -p tcp --syn -j syn-flood
sudo $IPT -t filter -A syn-flood -m limit --limit 1/sec --limit-burst 4 -j RETURN
sudo $IPT -t filter -A syn-flood -j LOG \
--log-prefix "IPTABLES SYN-FLOOD:"
sudo $IPT -t filter -A syn-flood -j DROP

## Make sure NEW tcp connections are SYN packets
sudo $IPT -t filter -A INPUT -i eth0 -p tcp ! --syn -m state --state NEW -j LOG  \
--log-prefix "IPTABLES SYN-FLOOD:"
sudo $IPT -t filter -A INPUT -i eth0 -p tcp ! --syn -m state --state NEW -j DROP

## port scaner
sudo $IPT -t filter -N port-scan
sudo $IPT -t filter -A INPUT -i eth0 -p tcp --tcp-flags SYN,ACK,FIN,RST RST -j port-scan
sudo $IPT -t filter -A port-scan -m limit --limit 1/s --limit-burst 4 -j RETURN
sudo $IPT -t filter -A port-scan -j LOG \
--log-prefix "IPTABLES PORT-SCAN:"
sudo $IPT -t filter -A port-scan -j DROP

## Permettre à une connexion ouverte de recevoir du trafic en entrée.
sudo $IPT -t filter -A INPUT -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

## Permettre à une connexion ouverte de recevoir du trafic en sortie.
sudo $IPT -t filter -A OUTPUT -m conntrack ! --ctstate INVALID -j ACCEPT

## On accepte ssh
sudo $IPT -t filter -A INPUT -p tcp -m state --state NEW --dport 42 -j LOG --log-prefix "Un Script Kiddies Test SSH "
sudo $IPT -t filter -A INPUT -p tcp --dport 42 -m recent --rcheck --seconds 160 --hitcount 2 --name SSH -j LOG --log-prefix "Script Kiddies Attaque SSH "
sudo $IPT -t filter -A INPUT -p tcp --dport 42 -m recent --update --seconds 160 --hitcount 2 --name SSH -j DROP
sudo $IPT -t filter -A INPUT -p tcp --dport 42 -m state --state NEW -m recent --set --name SSH -j ACCEPT

#sudo $IPT -t filter -A INPUT -p tcp --dport 42 -j ACCEPT

## On accepte la boucle locale en entrée.
sudo $IPT -t filter -I INPUT -i lo -j ACCEPT

## On LOG ICMP
sudo $IPT -t filter -A INPUT -p icmp -j LOG --log-prefix "Icmp Drop "

## On log les paquets en entrée.
sudo $IPT -t filter -A INPUT -i eth0 ! -s 0.0.0.0 ! -p icmp -j LOG --log-prefix "Attaques "

## On log les paquets forward.
sudo $IPT -t filter -A FORWARD -j LOG --log-prefix "Forward "

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
