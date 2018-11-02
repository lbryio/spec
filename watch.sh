#!/bin/bash

./bin/reflex --decoration=none --start-service=true --glob='*' --inverse-regex='index\.html' -- sh -c "make"
