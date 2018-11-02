#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null && pwd )"

(
  cd "$DIR"
  ./bin/reflex --decoration=none --start-service=true --glob='*' --inverse-regex='index\.html' -- sh -c "./build.sh"
)
