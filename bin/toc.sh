#!/bin/bash

set -euo pipefail
# set -x

HTML=${1:-}
MARKDOWN=${2:-}
if [ -z "$HTML" -o -z "$MARKDOWN" ]; then
  echo "Usage: $0 HTML MARKDOWN"
  exit 1
fi

if [ ! -f "${HTML}" ]; then
  echo "HTML file not found"
  exit 1
fi
if [ ! -f "${MARKDOWN}" ]; then
  echo "MARKDOWN file not found"
  exit 1
fi

regex='<h([2-6]) id="([^"]+)">([^<]+)</h'

toc=''

while read line; do
  if [[ $line =~ $regex ]]; then
    level="${BASH_REMATCH[1]}"
    id="${BASH_REMATCH[2]}"
    header="${BASH_REMATCH[3]}"
    [ -n "$toc" ] && printf -v toc "$toc\n"
    for ((i=$level-2; i>0; i--)); do toc="${toc}   "; done
    toc="${toc}* [${header}](#${id})"
  fi
done < "${HTML}"


# fix sed on mac
sed='sed -i'
if [[ "$(uname)" == "Darwin" ]]; then
    sed='sed -i ""'
fi

ts="<\!--ts-->"
te="<\!--te-->"


tmp="$(mktemp)"
function finish {
  rm "$tmp"
}
trap finish EXIT

echo "${toc}" > "${tmp}"

# clear old toc
$sed "/${ts}/,/${te}/{//!d;}" "$MARKDOWN"
# insert toc
$sed "/${ts}/r ${tmp}" "$MARKDOWN"