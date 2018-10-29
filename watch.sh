#!/bin/bash

./bin/reflex --decoration=none --start-service=true --inverse-regex='index\.html' -- sh -c "make"
