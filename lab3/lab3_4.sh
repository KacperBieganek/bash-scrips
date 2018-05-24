#!/bin/bash

./grep_data/fakaping.sh 2>&1 | grep -i '^permission\ denied' | sort -u | tee denied.log
