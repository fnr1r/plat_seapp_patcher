#!/data/adb/ksu/bin/busybox ash
# shellcheck shell=sh

mkdir_if_not_exist() {
    if ! [ -d "$1" ]; then
        mkdir -pv "$1"
    elif [ -f "$1/placeholder" ]; then
        rm -v "$1/placeholder"
    fi
}

mkdir_if_not_exist "${MODPATH}/system/etc/selinux"
