#!/usr/bin/env bash

# # bash <(curl -Lso- https://sh.vps.dance/autoBestTrace.sh)
# https://github.com/nyjx/autoBestTrace
# https://github.com/flyzy2005/shell

# besttrace -q1 -T -g cn # 探测数据包数1, TCP, CN

bin="/usr/bin/besttrace"

OSARCH=$(uname -m)
case $OSARCH in 
  x86_64)
    BINTAG=""
    ;;
  i*86)
    BINTAG="32"
    ;;
  arm64|aarch64)
    BINTAG="arm"
    ;;
  *)
    echo "unsupported OSARCH: $OSARCH"
    exit 1
    ;;
esac

# clean faild file
if [ -f "$bin" ]; then
  if [[ ! $($bin -V) ]]; then
    rm -rf $bin;
  fi
fi

# install besttrace
if [ ! -f "$bin" ]; then
  # https://github.com/nyjx/autoBestTrace/raw/main/besttrace4linux/besttrace
  wget -q -O $bin "https://sh.vps.dance/raw/nyjx/autoBestTrace/main/besttrace4linux/besttrace${BINTAG}"
  chmod +x $bin
fi

## start to use besttrace

next() {
  printf "%-70s\n" "-" | sed 's/\s/-/g'
}

clear
next

ipv4="$(curl -m 5 -fsL4 http://ipv4.ip.sb)"
ipv6="$(curl -m 5 -fsL6 http://ipv6.ip.sb)"

# gd.189.cn, gd.10086.cn
ip_list=(14.215.116.1 202.96.209.133 117.28.254.129 221.5.88.88 119.6.6.6 120.204.197.126 183.221.253.100 211.139.145.129 202.112.14.151)
ip_addr=(广东电信 上海电信 厦门电信 广东联通 成都联通 上海移动 成都移动 广东移动 成都教育网)

if [ -z "$ipv4" ]; then
  echo "ipv6 is not supported"
  exit 1
fi

# ip_len=${#ip_list[@]}

for i in "${!ip_addr[@]}"; do
  echo ${ip_addr[$i]}
  besttrace -q1 -g cn -T ${ip_list[$i]}
  next
done
