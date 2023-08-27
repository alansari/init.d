#!/usr/bin/env bash
###
# File: install-mgba.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Monday, 28th August 2023 11:10:59 am
# Modified By: Josh.5 (jsunnex@gmail.com)
###


# Config
package_name="mGBA"
package_description="Gameboy Advance Emulator"
package_icon_url="https://raw.githubusercontent.com/mgba-emu/mgba/master/res/mgba-512.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
package_icon="${USER_HOME:?}/.cache/init.d/package_icons/${package_name:?}-icon.png"


[ -f "${USER_HOME:?}/init.d/helpers/setup-directories.sh" ] && source "${USER_HOME:?}/init.d/helpers/setup-directories.sh"
[ -f "${USER_HOME:?}/init.d/helpers/functions.sh" ] && source "${USER_HOME:?}/init.d/helpers/functions.sh"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/mgba-emu/mgba/releases/latest)
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.id')
__latest_package_url=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.browser_download_url')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"


# Only install if the latest version does not already exist locally
if [ ! -f "${package_executable:?}" ] || [ ! -f "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}" ]; then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    touch "${USER_HOME:?}/.cache/init.d/installed_packages/.${package_name:?}-${__latest_package_version:?}"
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi


# Generate mGBA Emulation directory structure
romsPath="/mnt/games/Emulation/roms"
biosPath="/mnt/games/Emulation/bios"
savesPath="/mnt/games/Emulation/saves"
storagePath="/mnt/games/Emulation/storage"
mkdir -p \
    "${USER_HOME:?}"/.config/mgba \
    "${savesPath:?}"/mgba/states \
    "${savesPath:?}"/mgba/saves \
    "${storagePath:?}"/mgba/cheats \
    "${storagePath:?}"/mgba/screenshots \
    "${storagePath:?}"/mgba/patches \
    "${romsPath:?}"/gba

# Generate a default config if missing
if [ ! -f "${USER_HOME:?}/.config/mgba/config.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/mgba/config.ini"
[gba.input.SDLB]
keyRight=-1
keyDown=-1
axisUpValue=-12288
hat0Up=6
tiltAxisY=3
device0=030000005e0400008e02000010010000
axisLeftAxis=-0
gyroAxisZ=-1
gyroSensitivity=2.2e+09
gyroAxisX=0
axisLeftValue=-12288
axisRightAxis=+0
keyR=5
keyL=4
hat0Right=4
hat0Left=5
tiltAxisX=2
keyB=1
keyUp=-1
gyroAxisY=1
keySelect=6
keyLeft=-1
axisRightValue=12288
keyA=0
hat0Down=7
axisDownValue=12288
keyStart=7
axisUpAxis=-1
axisDownAxis=+1

[gba.input-profile.Xbox 360 Controller]
keyRight=-1
keyDown=-1
axisUpValue=-12288
hat0Up=6
axisLeftAxis=-0
axisLeftValue=-12288
axisRightAxis=+0
keyR=5
keyL=4
hat0Right=4
hat0Left=5
keyB=1
keyUp=-1
keySelect=6
keyLeft=-1
axisRightValue=12288
keyA=0
hat0Down=7
axisDownValue=12288
keyStart=7
axisUpAxis=-1
axisDownAxis=+1

[ports.qt]
width=863
height=641
gb.pal[0]=8953928
gb.pal[1]=4745264
gb.pal[2]=2637856
gb.pal[3]=1583112
gb.pal[4]=8953928
gb.pal[5]=4745264
gb.pal[6]=2637856
gb.pal[7]=1583112
gb.pal[8]=8953928
gb.pal[9]=4745264
gb.pal[10]=2637856
gb.pal[11]=1583112
hwaccelVideo=1
rewindBufferCapacity=1000
savestatePath=${savesPath:?}/mgba/states
cheatsPath=${storagePath:?}/mgba/cheats
screenshotPath=${storagePath:?}/mgba/screenshots
savegamePath=${savesPath:?}/mgba/saves
patchPath=${storagePath:?}/mgba/patches
showLibrary=1
videoScale=5
updateAutoCheck=0
rewindEnable=1
fpsTarget=59.72750056960583
libraryStyle=1

EOF
fi
if [ ! -f "${USER_HOME:?}/.config/mgba/qt.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/mgba/qt.ini"
[shortcutButton]
quit=2

[shortcutProfileAxis.Xbox%20360%20Controller]
quit=@String(\0-1)

[shortcutProfileButton.Xbox%20360%20Controller]
quit=2

EOF
fi

# Configure EmulationStation DE
cat << 'EOF' > "${romsPath:?}/gba/systeminfo.txt"
System name:
gba

Full system name:
Nintendo Game Boy Advance

Supported file extensions:
.agb .AGB .bin .BIN .cgb .CGB .dmg .DMG .gb .GB .gba .GBA .gbc .GBC .sgb .SGB .7z .7Z .zip .ZIP

Launch command:
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/mgba_libretro.so %ROM%

Alternative launch commands:
%EMULATOR_MGBA% -f %ROM%
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/vbam_libretro.so %ROM%
%EMULATOR_VBA-M% -f %ROM%
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/vba_next_libretro.so %ROM%
%EMULATOR_RETROARCH% -L %CORE_RETROARCH%/gpsp_libretro.so %ROM%

Platform (for scraping):
gba

Theme folder:
gba
EOF
if ! grep -ri "gba:" "${romsPath:?}/systems.txt" &>/dev/null; then
    print_step_header "Adding 'gba' path to '${romsPath:?}/systems.txt'"
    echo "gba: " >> "${romsPath:?}/systems.txt"
    chown -R ${PUID:?}:${PGID:?} "${romsPath:?}/systems.txt"
fi
sed -i 's|^gba:.*$|gba: Nintendo Game Boy Advance|' "${romsPath:?}/systems.txt"

# Set correct ownership of created paths
chown -R ${PUID:?}:${PGID:?} \
    "${USER_HOME:?}"/.config/mgba \
    "${savesPath:?}"/mgba \
    "${storagePath:?}"/mgba \
    "${romsPath:?}"/gba

echo "DONE"
