#!/bin/bash

# Verify that script is run as root
if [ "$EUID" != 0 ]
  then echo "!!! Please run as root !!!"
  exit
fi

echo "[org.gnome.desktop.interface]" > /usr/share/glib-2.0/schemas/99_hdpi.gschema.override
echo "scaling-factor=2" >> /usr/share/glib-2.0/schemas/99_hdpi.gschema.override

glib-compile-schemas /usr/share/glib-2.0/schemas/
