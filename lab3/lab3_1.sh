#!bin/bash

#Script

cat grep_data/access_log |  grep -oE "\b([0-9]{1,3}\.){3}[0-9]{1,3}\b" | sort -u | head -10

