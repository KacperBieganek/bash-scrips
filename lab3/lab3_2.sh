#!/bin/bash

cat grep_data/yolo.csv | grep  'gov'  | grep -P '^\d*[02468]\b'
