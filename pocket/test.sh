#!/usr/bin/env sh

read -p 'Are you sure?' yesOrno

if [ $yesOrno = "yes" ]; then
    echo $yesOrno
fi
