#!/bin/bash

if [ "$EUID" = 0 ]
  then echo "Please do not run as root"
  exit
fi

mkdir -p $HOME/.local/share/applications
cp applications/* $HOME/.local/share/applications
