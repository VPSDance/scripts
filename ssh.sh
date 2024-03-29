#!/usr/bin/env bash

# Usage:
# # bash <(curl -Lso- https://sh.vps.dance/ssh.sh) [key|port|pwd]

# DISTRO=$( ([[ -e "/usr/bin/yum" ]] && echo 'CentOS') || ([[ -e "/usr/bin/apt" ]] && echo 'Debian') || echo 'unknown' )
# Colors
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[0;33m'; BLUE='\033[34m'; CYAN='\033[0;36m'; PURPLE='\033[35m'; BOLD='\033[1m'; NC='\033[0m';
success() { printf "${GREEN}%b${NC} ${@:2}\n" "$1"; }
info() { printf "${CYAN}%b${NC} ${@:2}\n" "$1"; }
danger() { printf "\n${RED}[x] %b${NC}\n" "$@"; }
warn() { printf "${YELLOW}%b${NC}\n" "$@"; }
promptYn () {
  default=${2:-Y}
  while true; do
    read -p "${1:-"Please answer"} ([Y]es, [N]o), default [$default] " yn
    case "${yn:-$default}" in
      [Yy]* ) return 0;;
      [Nn]* ) return 1;;
      * ) clear; echo "Please answer [y] yes or [n] no.";;
    esac
  done
}
name=$( tr '[:upper:]' '[:lower:]' <<<"$1" )

# Set up SSH public key authentication
# mkdir -m 700 ~/.ssh; chmod 600 ~/.ssh/authorized_keys >> ~/.ssh/authorized_keys
ssh_key () {
  # for home in /root /home/*; do { if [[ ! -e "$home" ]]; then continue; fi; echo $home; }; done
  for home in /root /home/*;
  do
    if [[ ! -e "$home" ]]; then continue; fi;
    mkdir -p "${home}/.ssh"; chmod 700 "${home}/.ssh";
    if [[ ! -f "${home}/.ssh/authorized_keys" ]]; then echo '' >> "${home}/.ssh/authorized_keys"; fi
    chmod 600 "${home}/.ssh/authorized_keys"
  done
  echo "Paste your SSH public key (~/.ssh/id_rsa.pub):"
  IFS= read -d '' -n 1 text
  while IFS= read -d '' -n 1 -t 2 c
  do
    text+=$c
  done
  text=$(echo "$text" | sed '/^$/d')
  # echo "public key=$text"
  # echo "$text" >> "${HOME}/.ssh/authorized_keys"
  # for line in $text; do echo "$line"; sed -i "/$line/d" test; done
  # echo "$text" >> test

  enable_pubkey
  for home in /root /home/*;
  do
    if [[ ! -e "$home" ]]; then continue; fi;
    # echo $home;
    echo "$text" >> "${home}/.ssh/authorized_keys"
    # remove-duplicates
    # sed -nr 'G;/^([^\n]+\n)([^\n]+\n)*\1/!{P;h}'
    # awk '!seen[$0]++'
    sed -i "/^$/d" "${home}/.ssh/authorized_keys"
    sed -i -nr 'G;/^([^\n]+\n)([^\n]+\n)*\1/!{P;h}' "${home}/.ssh/authorized_keys"
  done
  success "[*] SSH public key has been added."
  warn "\nEnable or Disable Password login:"
  info " bash <(curl -Lso- https://sh.vps.dance/ssh.sh) pwd\n"
}

enable_pubkey() {
  sed -i 's/^#\?\(PubkeyAuthentication[[:space:]]\+\).*$/\1yes/' /etc/ssh/sshd_config
  systemctl restart sshd;
}
enable_pwd() {
  sed -i 's/^#\?\(PasswordAuthentication[[:space:]]\+\).*$/\1yes/' /etc/ssh/sshd_config
  systemctl restart sshd;
  success "[*] SSH PasswordAuthentication has been enabled."
}
disable_pwd() {
  sed -i 's/^#\?\(PasswordAuthentication[[:space:]]\+\).*$/\1no/' /etc/ssh/sshd_config
  systemctl restart sshd;
  success "[*] SSH PasswordAuthentication has been disabled."
}
ssh_pwd() {
  local AR=(
    [1]="Enable PasswordAuthentication"
    [2]="Disable PasswordAuthentication"
    [3]="Exit"
  )
  info "Enable or Disable Password login:"
  for i in "${!AR[@]}"; do
    success "$i." "${AR[i]}"
  done
  while :; do
    read -p "Please enter a number: " num
    [[ $num =~ ^[0-9]+$ ]] || { danger "invalid number"; continue; }
    break
  done
  case $num in
    1)
      enable_pwd
    ;;
    2)
      disable_pwd
    ;;
    *)
      exit
    ;;
  esac
}

iptables_persistence() { # Debian/Ubuntu
cat > /etc/network/if-pre-up.d/iptables << EOF
#!/bin/sh
iptables-restore < /etc/iptables.rules
exit 0
EOF
chmod +x /etc/network/if-pre-up.d/iptables
# iptables-save > /etc/iptables.rules # save current iptables rules
}

ssh_port() {
  # local port=$(( ${RANDOM:0:4} + 10000 )) # random 10000-20000
  # local port=$(shuf -i 10001-60000 -n 1); # echo $port
  local port='35653';
  read -p "Please enter the SSH port [default=$port]: " _p && [ -n "$_p" ] && SSH_PORT=$_p || SSH_PORT=$port;
  sed -i "s/#\?.*\Port\s*.*$/Port $SSH_PORT/" /etc/ssh/sshd_config;
  # echo "Port $SSH_PORT" >> /etc/ssh/sshd_config;
  systemctl restart sshd;
  info "[*] /etc/ssh/sshd_config has been modified."
  if [ -e /etc/sysconfig/firewalld ]; then # CentOS
    if [[ $( firewall-cmd --zone=public --query-port=${SSH_PORT}/tcp ) == 'no' ]]; then
      firewall-cmd --permanent --zone=public --add-port=${SSH_PORT}/tcp
      firewall-cmd --reload
    fi
  elif [ -e /etc/ufw/before.rules ]; then # Debian/Ubuntu
    ufw allow $SSH_PORT/tcp
    ufw reload
  elif [ -e /etc/sysconfig/iptables ]; then # CentOS
    iptables -I INPUT -p tcp --dport $SSH_PORT -j ACCEPT
    service iptables save
    service iptables restart
  elif [ -e /etc/iptables.rules ]; then # Debian/Ubuntu
    iptables -I INPUT -p tcp --dport $SSH_PORT -j ACCEPT
    iptables-save > /etc/iptables.rules
  fi
  local ip=`curl -4Ls ip.sb || curl -6Ls ip.sb || echo 'localhost'`;
  warn "[*] 请勿退出当前ssh, 新开终端测试 \"ssh root@$ip -p $SSH_PORT\" 是否能登录"
  warn "[*] 如不能登录, 重新执行本命令, 改回默认的 22 端口"
}
main() {
  case "$name" in
    key)
      ssh_key
    ;;
    port)
      ssh_port
    ;;
    pwd)
      ssh_pwd
    ;;
    *)
      ssh_key
      # warn "Please specify name (key|port|pwd)";
      exit
    ;;
  esac
}
main
