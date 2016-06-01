#!/usr/bin/env sh

read -p 'Are you sure to echo a `yes`?' yesOrno

if [ $yesOrno = "yes" ]; then
    echo $yesOrno
fi
