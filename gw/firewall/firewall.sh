#!/bin/bash
# activar ip forwarding
set -ex
sysctl -w net.ipv4.ip_forward=1

#limpiar reglas existentes
iptables -F
iptables -t nat -F
iptables -Z
iptables -t nat -Z

# ANTI-LOCK RULE regla para que nunca nos falle el acceso ssh
iptables -A INPUT -i eth0 -p tcp --dport 22 -j ACCEPT 
iptables -A OUTPUT -o eth0 -p tcp --sport 22 -j ACCEPT

#Politicas por defecto
iptables -P INPUT DROP
iptables -P FORWARD DROP
iptables -P OUTPUT DROP

################################---
#Reglas de proteccion local
################################---

# L1. Permitir loopback
iptables -A OUTPUT -o lo -j ACCEPT
iptables -A INPUT -i lo -j ACCEPT

#L2. Permitir ping a cualquiero maquina interna o externa
iptables -A OUTPUT -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -p icmp --icmp-type echo-reply -j ACCEPT

#L3. Permitir que me hagan ping desde LAN y DMZ
iptables -A INPUT -i eth2 -s 172.1.3.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A INPUT -i eth3 -s 172.1.4.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A OUTPUT -o eth2 -d 172.1.3.1 -p icmp --icmp-type echo-reply -j ACCEPT
iptables -A OUTPUT -o eth3 -d 172.2.3.1 -p icmp --icmp-type echo-reply -j ACCEPT

#L4. Permitir consultas DNS
iptables -A OUTPUT -o eth0 -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A INPUT -i eth0 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT 

#L.5 Permitir el http/https para actulizar y navegar por internet
iptables -A OUTPUT -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth0 -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A INPUT -i eth0 -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#L6. Permitir que se puedan conectar a mi desde adminpc
iptables -A INPUT -i eth3 -s 172.1.3.10 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth3 -d 172.1.3.110 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT



################################---
# Reglas de proteccion de red
################################---

#R1. Se debe de hacer NAT del trafico saliente 
iptables -t nat -A POSTROUTING -s 172.2.3.0/24 -o eth0 -j MASQUERADE

#R4. Permitir salir trafico de la LAN
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.3.0/24 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2





# Logs para depurar
iptables -A INPUT -j LOG --log-prefix "IDH-INPUT: "
iptables -A OUTPUT -j LOG --log-prefix "IDH-OUTPUT: "
iptables -A FORWARD -j LOG --log-prefix "IDH-FORWARD: "
