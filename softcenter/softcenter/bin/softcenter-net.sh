#!/bin/sh

# Copyright (C) 2021 MerlinRdev

ACTION=$1

for i in $(find /jffs/softcenter/init.d/ -name 'N*' | sort) ;
do
    case "$i" in
        *.sh )
            # Source shell script for speed.
            trap "" INT QUIT TSTP EXIT
            #set $1
            logger -t "SOFTCENTER" "plugin_net_start_1 $i"
            if [ -r "$i" ]; then
            $i $ACTION
            fi
            ;;
        *)
            # No sh extension, so fork subprocess.
            logger -t "SOFTCENTER" "plugin_net_start_2 $i"
            . $i $ACTION
            ;;
    esac
done

