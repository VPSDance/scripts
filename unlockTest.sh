#!/usr/bin/env bash

# bash <(curl -L -s check.unlock.media)
# https://github.com/lmc999/RegionRestrictionCheck

url="lmc999/RegionRestrictionCheck/main/check.sh"

url="https://sh.vps.dance/raw/$url"
main() {
  bash <(
    curl -L -s $url \
    | sed '/^[ \t]*echo\( -e\)\? "[-]*"\(.*\)\?$/d' \
    | sed '/^[ \t]*echo\( -e\)\? "[=]*"\(.*\)\?$/d' \
    | sed 's/ CheckV6().*$/&\n printf "%-39s\\n" \| sed "s\/\\s\/-\/g"/' \
    | sed 's/ Goodbye().*$/&\n printf "%-39s\\n" \| sed "s\/\\s\/-\/g"/' \
    | sed '/echo\( -e\)\? ""\(.*\)\?$/d'
  )
}
main
