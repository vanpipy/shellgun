#!/usr/bin/env sh

DIR=$1

if [ -z $DIR ]; then
    echo "The directory is empty and can not do anything."
    exit 0
fi

read -p "Are you sure to remove all file under $DIR - yes or no?" yesOrno
if [ "$yesOrno" = 'yes' ]; then
    rm $DIR/*
else
    echo "Clear canceled."
fi
