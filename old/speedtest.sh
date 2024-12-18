#!/usr/bin/env bash

# References:
# https://github.com/ernisn/superspeed/blob/master/ServerList.md
# https://github.com/flyzy2005/superspeed/blob/master/superspeed.sh
# https://github.com/oooldking/script/blob/master/superbench.sh
# https://bench.im/hyperspeed
# https://www.infski.com/files/superspeed.sh

ARCH=$(uname -m)
# VERSION="1.1.1"
VERSION="1.2.0"

check_root() {
  if [[ "$USER" != 'root' ]]; then # [[ "$EUID" -ne 0 ]]
    danger "Please run this script as root!"; exit 1;
    # if [[ "$debug" != true ]]; then exit 1; fi
  fi
}
next() {
  printf "%-70s\n" "-" | sed 's/\s/-/g'
}
footer() {
  BLUE="\033[34m"; NC='\033[0m'
  printf "%b\n" " Supported by: ${BLUE}https://vps.dance${NC}"
  printf "%-37s\n" "-" | sed 's/\s/-/g'
}

check_speedtest() {
  # curl -Lo /usr/bin/speedtest-cli https://raw.githubusercontent.com/sivel/speedtest-cli/master/speedtest.py;chmod +x /usr/bin/speedtest-cli
  if [ -e "./speedtest-cli/speedtest" ]; then
    return;
  fi
  arch=""
  case $ARCH in
    i386 | i686)
      arch="i386"
    ;;
    armv8 | armv8l | aarch64 |arm64)
      arch="aarch64"
    ;;
    armv7 | armv7l)
      arch="armhf"
    ;;
    armv6)
      arch="armel"
    ;;
    *) # x86_64
    arch="$ARCH"
    ;;
  esac
  [ -z "${arch}" ] && _red "Error: Unsupported system architecture (${sysarch}).\n" && exit 1
  url1="https://install.speedtest.net/app/cli/ookla-speedtest-$VERSION-linux-$arch.tgz"
  # url2="https://raw.githubusercontent.com/VPSDance/files/main/speedtest/$VERSION/ookla-speedtest-$VERSION-linux-$arch.tgz"
  wget --no-check-certificate -q -T10 -O speedtest.tgz ${url1}
  if [ $? -ne 0 ]; then
    # wget --no-check-certificate -q -T10 -O speedtest.tgz ${url2}
    [ $? -ne 0 ] && _red "Error: Failed to download speedtest-cli.\n" && exit 1
  fi
  mkdir -p speedtest-cli && tar zxf speedtest.tgz -C ./speedtest-cli && chmod +x ./speedtest-cli/speedtest
  rm -f speedtest.tgz
}

speed_test() {
  local nodeName="$2"
  [ -z "$1" ] && ./speedtest-cli/speedtest --progress=no --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1 || \
  ./speedtest-cli/speedtest --progress=no --server-id=$1 --accept-license --accept-gdpr > ./speedtest-cli/speedtest.log 2>&1
  if [ $? -eq 0 ]; then
    local dl_speed=$(awk '/Download/{print $3" "$4}' ./speedtest-cli/speedtest.log)
    local up_speed=$(awk '/Upload/{print $3" "$4}' ./speedtest-cli/speedtest.log)
    local latency=$(awk '/Latency/{print $3" "$4}' ./speedtest-cli/speedtest.log)
    if [[ -n "${dl_speed}" && -n "${up_speed}" && -n "${latency}" ]]; then
      printf "\033[0;33m%-18s\033[0;32m%-18s\033[0;31m%-20s\033[0;36m%-12s\033[0m\n" " ${nodeName}" "${up_speed}" "${dl_speed}" "${latency}"
    fi
  fi
}

# https://www.speedtest.net/api/js/servers?search=China%20Telecom
# https://www.speedtest.net/api/js/servers?search=电信
# https://www.speedtest.net/api/js/servers?search=China%20Unicom
# https://www.speedtest.net/api/js/servers?search=联通
# https://www.speedtest.net/api/js/servers?search=China%20Mobile
# https://www.speedtest.net/api/js/servers?search=移动

runtest() {
  printf "%-18s%-18s%-20s%-12s\n" " Node Name" "Upload Speed" "Download Speed" "Latency"
  speed_test '3633' 'CT|Shanghai'
  # speed_test '28225' 'CT|Changsha 5G'
  speed_test '17145' 'CT|Hefei 5G'
  # speed_test '28225' 'CT|Nanjing 5G'

  speed_test '24447' 'CU|ShangHai 5G'
  speed_test '4870'  'CU|Changsha 5G'

  # speed_test '25637' 'CM|Shanghai 5G'
  # speed_test '28491' 'CM|Changsha 5G'
  # speed_test '26404' 'CM|Hefei 5G'
  speed_test '4575' 'CM|Chengdu'
  speed_test '54312' 'CM|Hangzhou'
  speed_test '29105' "CM|Xi'an"

  # speed_test '21541' 'Los Angeles, US'
  # speed_test '43860' 'Dallas, US'
  # speed_test '40879' 'Montreal, CA'
  # speed_test '24215' 'Paris, FR'
  # speed_test '28922' 'Amsterdam, NL'
  # speed_test '32155' 'Hongkong, CN'
  # speed_test '6527'  'Seoul, KR'
  # speed_test '7311'  'Singapore, SG'
  # speed_test '21569' 'Tokyo, JP'
}

check_root
check_speedtest
runtest
next
footer