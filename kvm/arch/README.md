# Install ArchLinux (UEFI)

## Create VM

create ArchLinux VM using Cockpit.
DO NOT START VM YET!

## Change Configuration

CPU: 1 vCPU -> 4 vCPU
Firmware: BIOS -> UEFI

## Dump Configuration

$ virsh dumpxml ArchLinux > ArchLinux.xml

or

$ sh build.sh dumpxml

## Fix Configuration

$ sh build.sh modify

## Undefine VM

$ virsh undefine ArchLinux

## define VM

$ virsh define ArchLinux.xml

## install from ISO image

press "install" button on Cockpit





