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
iptables -A INPUT -i eth3 -s 172.2.3.10 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth3 -d 172.2.3.10 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT



################################---
# Reglas de proteccion de red
################################---

# R1. Se debe hacer NAT del tráfico saliente
iptables -t nat -A POSTROUTING -s 172.2.3.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 172.1.3.0/24 -o eth0 -j MASQUERADE
# R2. Permitir acceso desde la WAN a www a través del 80 haciendo port forwading
iptables -A FORWARD -i eth0 -o eth2 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


# R3.a. Usuarios de la LAN pueden acceder a 80 y 443 de www
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.3.0/24 -d 172.1.3.3 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.3.3 -d 172.2.3.0/24 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# R3.b. Adminpc debe poder acceder por ssh a cualquier máquina de DMZ
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.3.10 -d 172.1.3.0/24 -p tcp --dport 22 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.3.0/24 -d 172.2.3.10 -p tcp --sport 22 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


# R4.v2. Permitir salir tráfico procedente de la LAN
# ----------------------------------------------------
# R4.v2.1. Tráfico web saliente ha de pasar por el proxy
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.3.0/24 -d 172.1.3.2 -p tcp --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.3.2 -d 172.2.3.0/24 -p tcp --sport 3128 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# R4.v2.2. Permitir consultas DNS directas (sin proxy) tanto UDP (rápidas) como TCP (consultas grandes / DNSSEC )
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.3.0/24 -p udp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.3.0/24 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.3.0/24 -p tcp --dport 53 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.3.0/24 -p tcp --sport 53 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# R4.v2.3. Permitir consultas NTP (reloj)
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.3.0/24 -p udp --dport 123 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.3.0/24 -p udp --sport 123 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# R4.v2.4. permitimos pings salientes para depuración
iptables -A FORWARD -i eth3 -o eth0 -s 172.2.3.0/24 -p icmp --icmp-type echo-request -j ACCEPT
iptables -A FORWARD -i eth0 -o eth3 -d 172.2.3.0/24 -p icmp --icmp-type echo-reply -j ACCEPT

iptables -A INPUT -i eth1 -p udp --dport 1194 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A OUTPUT -o eth1 -p udp --sport 1194 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -o eth3 -d 172.2.3.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -s 172.2.3.2 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -i tun0 -o eth2 -s 172.3.3.0/24 -d 172.1.3.3 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o tun0 -s 172.1.3.3 -d 172.3.3.0/24 -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

iptables -A FORWARD -i tun0 -o eth3 -s 172.3.3.0/24 -d 172.2.3.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -o tun0 -s 172.2.3.2 -d 172.3.3.0/24 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# R5. Permitir salir tráfico de la DMZ (sólo http/https/dns/ntp)
                        # Permitir tráfico HTTP desde la DMZ
#  iptables -A FORWARD -i eth2 -o eth0 -p tcp --dport 80 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
#  iptables -A FORWARD -i eth0 -o eth2 -p tcp --sport 80 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
# #                         # Permitir tráfico HTTPS desde la DMZ
#  iptables -A FORWARD -i eth2 -o eth0 -p tcp --dport 443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
#  iptables -A FORWARD -i eth0 -o eth2 -p tcp --sport 443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT
                        # Permitir consultas DNS desde la DMZ
iptables -A FORWARD -i eth2 -o eth0 -p udp --dport 53 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -p udp --sport 53 -m conntrack --ctstate ESTABLISHED -j ACCEPT
                        # Permitir tráfico NTP desde la DMZ
iptables -A FORWARD -i eth2 -o eth0 -p udp --dport 123 -m conntrack --ctstate NEW -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -p udp --sport 123 -m conntrack --ctstate ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth0 -p icmp --icmp-type echo-request -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -p icmp --icmp-type echo-reply -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#P6. Permitir trafico a ldap desde dmz
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.3.0/24 -d 172.2.3.2 -p tcp --dport 389 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.3.2 -d 172.1.3.0/24 -p tcp --sport 389 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

# Regla P6. Permitir acceso del proxy a Internet
iptables -A FORWARD -i eth2 -o eth0 -s 172.1.3.2 -p tcp -m multiport --dports 80,443 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth0 -o eth2 -d 172.1.3.2 -p tcp -m multiport --sports 80,443 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT

#Reglas para squid
iptables -A FORWARD -i eth3 -o eth2 -s 172.2.3.0/24 -d 172.1.3.2 -p tcp --dport 3128 -m conntrack --ctstate NEW,ESTABLISHED -j ACCEPT
iptables -A FORWARD -i eth2 -o eth3 -s 172.1.3.2 -d 172.2.3.0/24 -p tcp --sport 3128 -m conntrack --ctstate ESTABLISHED,RELATED -j ACCEPT


# Logs para depurar
iptables -A INPUT -j LOG --log-prefix "IDH-INPUT: "
iptables -A OUTPUT -j LOG --log-prefix "IDH-OUTPUT: "
iptables -A FORWARD -j LOG --log-prefix "IDH-FORWARD: "