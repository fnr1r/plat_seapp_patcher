#!/data/adb/ksu/bin/busybox ash
# shellcheck shell=sh
MODPATH="${0%/*}"
MODNAME="$(basename "$MODPATH")"
SEAPP_FILE="/system/etc/selinux/plat_seapp_contexts"
SEAPP_TEMP="$MODPATH/plat_seapp_contexts"

exec >"/data/local/tmp/$MODNAME/post-fs-data.log" 2>&1
set -xe

# https://github.com/chenxiaolong/MSD/blob/f405bf848422ad47750ba191a13c82ab4b474d4f/app/module/post-fs-data.sh#L6
# toybox's `mountpoint` command only works for directories, but bind mounts can
# be files too.
has_mountpoint() {
    local mnt=${1}

    awk -v "mnt=${mnt}" \
        'BEGIN { ret=1 } $5 == mnt { ret=0; exit } END { exit ret }' \
        /proc/self/mountinfo
}

patch_kernelsu() {
    MOD_SEAPP_FILE="$MODPATH$SEAPP_FILE"
    MOD_SEAPP_DIR="$(dirname "$MOD_SEAPP_FILE")"
    if ! [ -d "$MOD_SEAPP_DIR" ]; then
        mkdir -p "$MOD_SEAPP_DIR"
    fi
    if [ -f "$MOD_SEAPP_FILE" ]; then
        rm "$MOD_SEAPP_FILE"
    fi
    mv "$SEAPP_TEMP" "$MOD_SEAPP_FILE"
    /system/bin/touch -r "$SEAPP_FILE" "$MOD_SEAPP_FILE"
}

patch_magisk() {
    /system/bin/touch -r "$SEAPP_FILE" "$SEAPP_TEMP"

    while has_mountpoint "${SEAPP_FILE}"; do
        umount -l "${SEAPP_FILE}"
    done

    nsenter --mount=/proc/1/ns/mnt -- \
        mount -o ro,bind "${SEAPP_TEMP}" "${SEAPP_FILE}"
}

if [ -f "$SEAPP_TEMP" ]; then
    rm "$SEAPP_TEMP"
fi
/system/bin/cp --preserve=timestamps "$SEAPP_FILE" "$SEAPP_TEMP"

for module in /data/adb/modules/*; do
    PATCHER="$module/patch-plat_seapp_contexts.sh"
    echo "$module"
    if [ -f "$PATCHER" ]; then
        busybox ash "$PATCHER" "$SEAPP_TEMP"
    fi
done

if [ "$KSU" = true ]; then
    patch_kernelsu
else
    patch_magisk
fi
