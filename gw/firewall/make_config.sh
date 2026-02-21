#!/bin/bash
# Primer argumento: identificador del cliente
CLIENTE=$1
KEY_DIR=/etc/openvpn/client/keys
OUTPUT_DIR=/etc/openvpn/client/files
BASE_CONFIG=/etc/openvpn/client/client.conf
cat ${BASE_CONFIG} > ${OUTPUT_DIR}/${CLIENTE}.ovpn
echo -e '<ca>' >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
cat ${KEY_DIR}/ca.crt >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
echo -e '</ca>\n<cert>' >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
cat ${KEY_DIR}/${CLIENTE}.crt >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
echo -e '</cert>\n<key>' >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
cat ${KEY_DIR}/${CLIENTE}.key >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
echo -e '</key>\n<tls-crypt>' >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
cat ${KEY_DIR}/ta.key >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
echo -e '</tls-crypt>' >> ${OUTPUT_DIR}/${CLIENTE}.ovpn
