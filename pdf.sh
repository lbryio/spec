#!/bin/bash
google-chrome --headless --no-margins --run-all-compositor-stages-before-draw --virtual-time-budget=2000 --print-to-pdf=lbry-spec.pdf http://127.0.0.1:4000
