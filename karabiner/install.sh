#!/usr/bin/env bash

set -e

mkdir -p ~/.config/karabiner/assets/complex_modifications
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

jsonnet "$DIR/my-rules.jsonnet" > "$DIR/my-rules.json"

cp -v "$DIR/my-rules.json" ~/.config/karabiner/assets/complex_modifications
cp -v "$DIR/my-rules.json" ~/.config/karabiner/karabiner.json
# /Library/Application\ Support/org.pqrs/Karabiner-Elements/bin/karabiner_cli --reload-karabiner-json
