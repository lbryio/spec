#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

$DIR/bin/mmark-linux-amd64 -head "$DIR/head.html" -html "$DIR/index.md" > "$DIR/index.html"
$DIR/bin/toc.sh "$DIR/index.html" "$DIR/index.md"