#!/usr/bin/env bash

# Usage:
# bash <(curl -Lso- https://sh.vps.dance/paste.sh) [poster]

echo "Paste your content:"
IFS= read -d '' -n 1 text
while IFS= read -d '' -n 1 -t 2 c
do
  text+=$c
done

# text=$(cat <<- 'EOF'
# ~text~
# EOF
# );

# echo "poster=$1"
# echo "content=$text"

curl -w "URL: %{redirect_url}\n" -o /dev/null -s "https://paste.ubuntu.com" --data-urlencode "content=$text" -d "poster=$1" -d "syntax=bash"
