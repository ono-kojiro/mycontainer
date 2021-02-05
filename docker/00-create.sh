#!/bin/sh

sudo debootstrap bionic mybaseimage
sudo tar -C mybaseimage -c . | docker import - mybaseimage


