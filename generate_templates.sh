#!/usr/bin/env bash

CONF_DIR="./telegraf.d"
TEMPLATES_DIR="./templates"
VARS_DIR="./vars"
[[ ! -d "$CONF_DIR" ]] && mkdir "$CONF_DIR"
[[ ! -d "$TEMPLATES_DIR" ]] && mkdir "$TEMPLATES_DIR"
[[ ! -d "$VARS_DIR" ]] && mkdir "$VARS_DIR"

./split.awk plugins.conf

for file in "$CONF_DIR"/*; do
    ./templatize.awk "$file" 2>/dev/null
done
