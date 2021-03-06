#!/bin/bash

##
# created by bastelfreak
# based on a script by Bluewind
##

# this allows us to set different configs via env vars:
# CONFIG_BUILD=config_build_rackmonkey.sh CONFIG_LIVE=config_live_rackmonkey.sh ./rebuild_and_copy.sh
config_build=${CONFIG_BUILD:-config_build.sh}
config_live=${CONFIG_LIVE:-config_live.sh}

for file in "$config_build" "$config_live"; do
  if [ ! -e "$file" ]; then
    echo "Error: ${file} file isn't available"
    exit 1
  fi
done

# shellcheck disable=SC1090
. "$config_build"

# we need to place the set under the exit
# it would ignore it because it's in an if/fi statement
set -e
umask 022

# copy the config because we need it later during build inside of the ISO
cp "$config_build" airootfs/root/config_build.sh

# copy the config, needed after booting the ISO
rsync -a ext_scripts/ scripts/ airootfs/usr/local/bin/
rsync -a "${config_live}" airootfs/usr/local/bin/config_live.sh
chmod +x airootfs/usr/local/bin/*

# clean builddir, build the ISO, clean it again
rm -rf work
./build.sh -v
rm -rf work

# determine the name of the latest ISO
unset -v latest
for file in out/archlinux-*.iso; do
	[[ $file -nt $latest ]] && latest=$file
done

# copy and extract the ISO
rsync -tP "$latest" -e ssh "${DHCP_USER}@${DHCP_SERVER}:${DHCP_PATH}"
# shellcheck disable=SC2029
ssh "${DHCP_USER}@${DHCP_SERVER}" "${DHCP_EXTRACT} ${DHCP_PATH}${latest##*/}"
