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

###################################
#Reglas de proteccion local
################################---

# 1. Permitir loopback
iptables -A INPUT -i lo -j ACCEPT

###################################
# Reglas de proteccion de red
###################################



# Logs para depurar
iptables -A INPUT -j LOG --log-prefix "IDH-INPUT: "
iptables -A OUTPUT -j LOG --log-prefix "IDH-OUTPUT: "
iptables -A FORWARD -j LOG --log-prefix "IDH-FORWARD: "
