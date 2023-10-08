#!/usr/bin/env bash
###
# File: install-xenia-canary.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:26:27 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="Xenia-Canary"
package_description="Xbox360 Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/420c841038c492fed4d19999a813009d/32/32x32.png"
package_executable="${__emulation_path:?}/storage/xenia/xenia_canary.exe"
package_category="Game"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/xenia-canary/xenia-canary/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_url=$(echo ${__registry_package_json:?} | jq -r '.assets[]' | jq -r '.browser_download_url')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"
__installed_version=$(catalog -g ${package_name,,})


# Only install if the latest version does not already exist locally
if ([ ! -f "${package_executable:?}" ] || [ ${__installed_version} != ${__latest_package_version:?} ]); then
    __install_dir="${__emulation_path:?}/storage/xenia"
    # Download zip & extract
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    mkdir -p \
        "${__install_dir:?}" \
        "${USER_HOME:?}/.local/bin/xenia" # just for ES-DE
    wget -O "${__install_dir:?}/${package_name,,}.zip" \
        --quiet -o /dev/null \
        --no-verbose --show-progress \
        --progress=bar:force:noscroll \
        "${__latest_package_url:?}"

    pushd "${__install_dir:?}" &> /dev/null || { echo "Error: Failed to push directory to ${__install_dir:?}"; exit 1; }
    unzip -x "${__install_dir:?}/${package_name,,}.zip"
    chmod +x "${__install_dir:?}/xenia_canary.exe"
    # create link so ES-DE auto finds executable
    ln -snf "${__install_dir:?}/xenia_canary.exe" "${USER_HOME:?}/.local/bin/xenia/xenia_canary.exe"
    # pull latest patches for camptability
    #if ([ -d "${__install_dir:?}/patches" ]); then
    #    rm -rf "${__install_dir:?}/patches" 
    #fi
    #git clone "https://github.com/xenia-canary/game-patches.git" "${__install_dir:?}"
    popd &> /dev/null || { echo "Error: Failed to pop directory out of ${__install_dir:?}"; exit 1; }

    # Ensure this package has a start menu link (will create it if missing)
    # print_step_header "Ensuring menu short is present for ${package_name:?}"
    # rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    # ensure_menu_shortcut

    # Mark this version as installed
    catalog -s ${package_name,,} ${__latest_package_version:?}
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

# Generate xenia Emulation directory structure
__emulation_path="/mnt/games/Emulation"
mkdir -p \
    "${__emulation_path:?}"/storage/xenia \
    "${__emulation_path:?}"/roms/xbox360

#ensure_symlink "${__emulation_path:?}/storage/rpcs3/home" "${USER_HOME:?}/.config/rpcs3/dev_hdd0/home"

# Generate a default config if missing
if [ ! -f "${__emulation_path:?}/storage/xenia/xenia-canary.config.toml" ]; then
    cat << EOF > "${__emulation_path:?}/storage/xenia/xenia-canary.config.toml"
[Display]
fullscreen = true

[GPU]
gpu = "vulkan"
EOF
fi

if [ ! -f "${__emulation_path:?}/storage/xenia/portable.txt" ]; then
    touch "${__emulation_path:?}/storage/xenia/portable.txt"
fi

# ensure_esde_alternative_emulator_configured "xbox360" "xenia (Proton)"

echo "DONE"