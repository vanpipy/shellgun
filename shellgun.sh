#!/usr/bin/env bash

WHOAMI=$0
COMMANDER=/bin/bash

SOURCE="${BASH_SOURCE[0]}"
TARGET="$(readlink "$SOURCE")"
DIR="$(dirname "$TARGET")"
POCKET=pocket

vaildBullet=`ls $DIR/$POCKET`
bullet=$1

function main() {
    for each in $vaildBullet; do
        if [[ "$each" =~ $bullet ]]; then
            $COMMANDER $DIR/$POCKET/$each
            break
        fi
    done
}

main
