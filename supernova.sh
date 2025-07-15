#!/bin/bash
#
# Setup multiple udp based proxies

export LANG=en_US.UTF-8
####################### Color pallete
CYAN="\033[36m\033[01m"
BLUE="\033[34m\033[01m"
PINK="\033[95m\033[01m"
GREEN="\033[32m\033[01m"
PLAIN="\033[0m"
RESET="\033[0m"
RED="\033[31m\033[01m"
YELLOW="\033[33m\033[01m"

cyan() { echo -e "\033[36m\033[01m$1\033[0m"; }
blue() { echo -e "\033[34m\033[01m$1\033[0m"; }
pink() { echo -e "\033[95m\033[01m$1\033[0m"; }
red() { echo -e "\033[31m\033[01m$1\033[0m"; }
green() { echo -e "\033[32m\033[01m$1\033[0m"; }
yellow() { echo -e "\033[33m\033[01m$1\033[0m"; }
magenta() { echo -e "\033[35m\033[01m$1\033[0m"; }
#######################

clients(){
# ... (unchanged, keep as in your original script)
echo -e "${BLUE}========================================================${PLAIN}"
echo -e "${RED}Recommended clients${PLAIN}"
echo
echo -e "${GREEN}Android${PLAIN}":
echo -e "${YELLOW}https://github.com/MatsuriDayo/NekoBoxForAndroid/releases${PLAIN}"
echo
echo -e "${GREEN}Windows/Linux/Macos${PLAIN}":
echo -e "${YELLOW}https://github.com/MatsuriDayo/nekoray/releases${PLAIN}"
echo
echo -e "${GREEN}Brook${PLAIN}":
echo -e "${YELLOW}https://www.txthinking.com/brook.html${PLAIN}"
echo
echo -e "${GREEN}Mieru (Sagernet + Mieru plugin)${PLAIN}":
echo -e "${YELLOW}https://github.com/SagerNet/SagerNet/releases/download/0.8.1-rc03/SN-0.8.1-rc03-arm64-v8a.apk${PLAIN}"
echo -e "${YELLOW}https://github.com/SagerNet/SagerNet/releases/download/mieru-plugin-1.15.1/mieru-plugin-1.15.1-arm64-v8a.apk${PLAIN}"
echo
echo -e "${GREEN}Naive (Naive plugin for Nekobox)${PLAIN}":
echo -e "${YELLOW}https://github.com/SagerNet/SagerNet/releases/download/naive-plugin-116.0.5845.92-2/naive-plugin-116.0.5845.92-2-arm64-v8a.apk${PLAIN}"
echo
echo -e "${GREEN}Juicity (Juicity plugin for Nekobox)${PLAIN}":
echo -e "${YELLOW}https://github.com/MatsuriDayo/plugins/releases/download/juicity-v0.3.0/juicity-plugin-v0.3.0-arm64-v8a.apk${PLAIN}"
echo -e "${BLUE}========================================================${PLAIN}"
}

# ... All functions unchanged, except where read is used in install_hysteria and menu

install_hysteria() {
rm temp/hy.txt
clear
if [ $( docker ps -a | grep hysteria | wc -l ) -gt 0 ]; then
  hy_reinstall="Y"
  if [[ -z "$hy_reinstall" || $hy_reinstall = "Y" || $hy_reinstall = "y" ]]; then 
    uninstall_hysteria
  else
    exit 0
  fi
fi
install_dependencies
get_cert
rm hysteria/config.yaml
auth_pass=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 30 ; echo '')
server_ip=$(curl api.ipify.org)
ipv6=$(curl -s6m8 ip.sb -k)
clear
hy_port=443
[ $(lsof -i :$hy_port | grep :$hy_port | wc -l) -gt 0 ] && red "Port $hy_port is occupied. Please try another port" && exit 1

cat <<EOF > hysteria/config.yaml
listen: :$hy_port
tls:
  cert: /etc/hysteria/certs/cert.crt
  key: /etc/hysteria/certs/private.key
auth:
  type: password
  password: $auth_pass
quic:
  initStreamReceiveWindow: 8388608
  maxStreamReceiveWindow: 8388608
  initConnReceiveWindow: 20971520
  maxConnReceiveWindow: 20971520
  maxIdleTimeout: 60s
  maxIncomingStreams: 1024
  disablePathMTUDiscovery: false
bandwidth:
  up: 1 gbps
  down: 1 gbps
ignoreClientBandwidth: true
disableUDP: false
udpIdleTimeout: 60s
resolver:
  type: https
  https:
    addr: 1.1.1.1:443
    timeout: 10s
    sni: cloudflare-dns.com
    insecure: false
acl:
  inline: 
    - reject(*.ir)
    - reject(all, udp/443)
    - reject(geoip:ir)
EOF

enable_obfs="Y"
if [[ -z "$enable_obfs" || $enable_obfs = "Y" || $enable_obfs = "y" ]]; then 
obfs_pass=$(tr -dc A-Za-z0-9 </dev/urandom | head -c 30 ; echo '')
echo "obfs:
  type: salamander
  salamander:
    password: $obfs_pass" >> hysteria/config.yaml
fi

enable_masq="Y"
if [[ -z "$enable_masq" || $enable_masq = "Y" || $enable_masq = "y" ]]; then 
  masq_addr="vipofilm.com"
echo "masquerade:
  type: proxy
  proxy:
    url: https://$masq_addr
    rewriteHost: true 
  listenHTTP: :80 
  listenHTTPS: :443 
  forceHTTPS: true
" >> hysteria/config.yaml
fi

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
    sysctl -w net.core.rmem_max=16777216
    sysctl -w net.core.wmem_max=16777216
elif [[ "$OSTYPE" == "darwin"* ]]; then
    sysctl -w kern.ipc.maxsockbuf=20971520
    sysctl -w net.inet.udp.recvspace=16777216
fi

(cd hysteria && docker compose up -d)
clear
clients

country_code=$(curl ipinfo.io | jq -r '.country')

if [ -z "$obfs_pass" ]; then 
blue "
hy2://$auth_pass@$server_ip:$hy_port/?insecure=1&sni=google.com#Hysteria%20($country_code)
"
if [ ! -z "$ipv6" ]; then
yellow "Irancell (Ipv6) : 
hy2://$auth_pass@[$ipv6]:$hy_port/?insecure=1&sni=google.com#Hysteria%20($country_code)
"
fi

qrencode -m 2 -t utf8 <<< "hy2://$auth_pass@$server_ip:$hy_port/?insecure=1&sni=google.com#Hysteria%20($country_code)"

cat <<EOF > temp/hy.txt
hy2://$auth_pass@$server_ip:$hy_port/?insecure=1&sni=google.com#Hysteria%20($country_code)

Irancell (Ipv6) : 
hy2://$auth_pass@[$ipv6]:$hy_port/?insecure=1&sni=google.com#Hysteria%20($country_code)
EOF
else
blue "
hy2://$auth_pass@$server_ip:$hy_port/?insecure=1&sni=google.com&obfs-password=$obfs_pass#Hysteria%20%2B%20Obfs%20($country_code)
"
if [ ! -z "$ipv6" ]; then
yellow "Irancell (Ipv6) : 
hy2://$auth_pass@[$ipv6]:$hy_port/?insecure=1&sni=google.com#Hysteria%20($country_code)
"
fi
qrencode -m 2 -t utf8 <<< "hy2://$auth_pass@$server_ip:$hy_port/?insecure=1&sni=google.com&obfs-password=$obfs_pass#Hysteria%20%2B%20Obfs%20($country_code)"
fi

cat <<EOF > temp/hy.txt
hy2://$auth_pass@$server_ip:$hy_port/?insecure=1&sni=google.com&obfs-password=$obfs_pass#Hysteria%20%2B%20Obfs%20($country_code)

Irancell (Ipv6) : 
hy2://$auth_pass@[$ipv6]:$hy_port/?insecure=1&sni=google.com#Hysteria%20($country_code)
EOF
}

# ... rest of your functions unchanged

menu() {
    install_hysteria
}

menu
