
#!/usr/bin/env bash
# curl https://sh.vps.dance/tuning.sh | bash

# Reference:
# https://www.cnblogs.com/tolimit/p/5065761.html
# https://cloud.google.com/architecture/tcp-optimization-for-network-performance-in-gcp-and-hybrid?hl=zh-cn
# [LFN网络下TCP性能的优化](https://github.com/acacia233/Project-Smalltrick/wiki/)
# https://github.com/ylx2016/Linux-NetSpeed/blob/master/tcp.sh
# bash <(curl -Lso- http://sh.nekoneko.cloud/tools.sh)

pam_limits="/etc/pam.d/common-session"
limits_conf="/etc/security/limits.conf"
sysctl_conf="/etc/sysctl.conf"
allusers=$( cat /etc/passwd | grep -vE "(/bin/false|/sbin/nologin|/bin/sync|guest-)" | cut -d: -f1 )
# allusers=$(awk -F':' '$2 ~ "\\$" {print $1}' /etc/shadow)

CURR_USER="$(whoami)"
with_sudo() {
  if ! command -v sudo >/dev/null 2>&1; then
    warn "Error: sudo command not found"
    return 1
  fi

  local cmd
  if [[ "$(type -t "$1")" == "function" ]]; then
    local declare_vars="$(declare -p CURR_USER pam_limits limits_conf sysctl_conf allusers RED GREEN YELLOW BLUE CYAN PURPLE BOLD NC 2>/dev/null)"
    local declare_funcs="$(declare -f)"
    cmd="$declare_vars; $declare_funcs; $1 "'"${@:2}"'
  else
    cmd="$1 "'"${@:2}"'
  fi

  if [[ $EUID -ne 0 ]]; then
    sudo bash -c "$cmd" -- "$@" < /dev/tty
  else
    bash -c "$cmd" -- "$@"
  fi
}

reload_sysctl() { sysctl -q -p && sysctl --system; }
check_sysctl() {
  if [ ! -f "$sysctl_conf" ]; then touch "$sysctl_conf"; fi
}

ulimited_tuning() {
  check_sysctl
  # enable 'session required pam_limits.so'
  if ! grep -q 'pam_limits.so' "$pam_limits"; then
    sed -i '/required.* pam_limits.so/d' "$pam_limits"
    echo 'session required pam_limits.so' >> "$pam_limits"
  fi
  # max open files
  if [ -w /proc/sys/fs/file-max ]; then
    sed -i '/fs.file-max/d' "$sysctl_conf"
    echo 'fs.file-max=102400' >> "$sysctl_conf"
  fi
  # watch limit
  if [ -w /proc/sys/fs/inotify/max_user_instances ]; then
    sed -i '/inotify.max_user_instances/d' "$sysctl_conf"
    echo 'fs.inotify.max_user_instances=999' >> "$sysctl_conf"
    sed -i '/inotify.max_user_watches/d' "$sysctl_conf"
    echo 'fs.inotify.max_user_watches=81920' >> "$sysctl_conf"
  fi
  # max user processes
  for usr in $allusers '\*'; do
    usr="${usr/\\/}"
    sed -i "/${usr}.*\(nproc\|nofile\|memlock\)/d" "$limits_conf"
    echo "${usr} soft    nproc    65536" >> "$limits_conf"
    echo "${usr} hard    nproc    65536" >> "$limits_conf"
    echo "${usr} soft    nofile   65535" >> "$limits_conf"
    echo "${usr} hard    nofile   65535" >> "$limits_conf"
    echo "${usr} soft    memlock  unlimited" >> "$limits_conf"
    echo "${usr} hard    memlock  unlimited" >> "$limits_conf"
  done
  if ! grep -q "ulimit" /etc/profile; then
    sed -i '/ulimit -SHn/d' /etc/profile
    echo "ulimit -SHn 65535" >> /etc/profile
  fi
  ulimit -SHn 65535 && ulimit -c unlimited
  # reload_sysctl
}

# sysctl -a | grep mem
tcp_tuning() {
  check_sysctl
  # incoming connections
  sed -i '/net.core.somaxconn/d' "$sysctl_conf"
  echo 'net.core.somaxconn=65535' >> "$sysctl_conf"
  # 保持time_wait套接字的最大数
  sed -i '/net.ipv4.tcp_max_tw_buckets/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_max_tw_buckets=8192' >> "$sysctl_conf"
  # 端口随机分配的范围
  sed -i '/net.ipv4.ip_local_port_range/d' "$sysctl_conf"
  echo 'net.ipv4.ip_local_port_range=10240 65000' >> "$sysctl_conf"
  # TCP内存自动调整
  sed -i '/net.ipv4.tcp_moderate_rcvbuf/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_moderate_rcvbuf=1' >> "$sysctl_conf"
  # TCP窗口大小缩放
  sed -i '/net.ipv4.tcp_window_scaling/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_window_scaling=1' >> "$sysctl_conf"
  # TCP缓冲区
  BDP='16777216' # 26214400
  if [ -w /proc/sys/net/core/rmem_max ]; then
    # sed -i '/net.ipv4.tcp_rmem/d' "$sysctl_conf"
    # sed -i '/net.ipv4.tcp_wmem/d' "$sysctl_conf"
    # echo "net.ipv4.tcp_rmem=4096 131072 $BDP" >> "$sysctl_conf"
    # echo "net.ipv4.tcp_wmem=4096 16384 $BDP" >> "$sysctl_conf"
    sed -i '/net.core.rmem_max/d' "$sysctl_conf"
    sed -i '/net.core.wmem_max/d' "$sysctl_conf"
    echo "net.core.rmem_max=$BDP" >> "$sysctl_conf"
    echo "net.core.wmem_max=$BDP" >> "$sysctl_conf"
    sed -i '/net.core.rmem_default/d' "$sysctl_conf"
    echo "net.core.rmem_default=$BDP" >> "$sysctl_conf" # 212992, `$BDP / 2`
  fi
  # TCP Fast Open
  sed -i '/net.ipv4.tcp_fastopen/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_fastopen=1' >> "$sysctl_conf"
  if [ -w /proc/sys/net/core/netdev_max_backlog ]; then
    # 网卡设备将请求放入队列的最大长度(默认值1000)
    sed -i '/net.core.netdev_max_backlog/d' "$sysctl_conf"
    echo 'net.core.netdev_max_backlog=32768' >> "$sysctl_conf"
  fi
  # 接受SYN同步包的最大客户端数量(默认值128)
  sed -i '/net.ipv4.tcp_max_syn_backlog/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_max_syn_backlog=8192' >> "$sysctl_conf"
  # SYN洪水攻击保护, 可防范少量SYN攻击 (在syn_backlog队列满了之后才会触发)
  sed -i '/net.ipv4.tcp_syncookies/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_syncookies=1' >> "$sysctl_conf"
  # TCP失败重传次数(默认值15), 重传15次才彻底放弃, 适当改小,尽早释放资源
  sed -i '/net.ipv4.tcp_retries2/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_retries2=8' >> "$sysctl_conf"
  # 放弃建立连接之前发送SYN包的数量(默认值6) 负载大且网络状况好的情况下建议更小
  sed -i '/net.ipv4.tcp_syn_retries/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_syn_retries=3' >> "$sysctl_conf"
  # 放弃连接之前所送出的 SYN+ACK 数目(默认值5)
  sed -i '/net.ipv4.tcp_synack_retries/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_synack_retries=3' >> "$sysctl_conf"
  # 如果套接字由本端要求关闭, 保持FIN-WAIT-2状态的时间(默认值60)
  sed -i '/net.ipv4.tcp_fin_timeout/d' "$sysctl_conf"
  echo 'net.ipv4.tcp_fin_timeout=30' >> "$sysctl_conf"
  # reload_sysctl
}
with_sudo ulimited_tuning
with_sudo tcp_tuning
with_sudo reload_sysctl
