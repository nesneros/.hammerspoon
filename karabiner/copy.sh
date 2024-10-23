#!/usr/bin/env bash

set -e

mkdir -p ~/.config/karabiner/assets/complex_modifications
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cp -v "$DIR/my-rules.json" ~/.config/karabiner/assets/complex_modifications
