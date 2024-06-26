#!/usr/bin/env bash
###
# File: install-pcsx2.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:26:25 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install PCSX2 during container startup.
#   This will also configure PCSX2 with some default options for Steam Headless.
#   It will also configure the PCSX2 AppImage as the default emulator for PS2 ROMs in ES-DE.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-pcsx2.sh" "${USER_HOME:?}/init.d/install-pcsx2.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="pcsx2"
package_description="Sony Playstation 2 Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/9a32ff36c65e8ba30915a21b7bd76506/32/24x24.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
print_package_name


# Check for a new version to install
__latest_registery_url=$(wget -O - -o /dev/null https://api.github.com/repos/PCSX2/pcsx2/releases | jq -r '.[0].url')
__registry_package_json=$(wget -O - -o /dev/null $(echo ${__latest_registery_url}))
__latest_package_version=$(echo ${__registry_package_json:?} | jq -r '.tag_name')
__latest_package_id=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.id')
__latest_package_url=$(echo ${__registry_package_json:?} | jq -r '.assets[] | select(.name | test("\\.appimage$"; "i"))' | jq -r '.browser_download_url')
print_step_header "Latest ${package_name:?} version: ${__latest_package_version:?}"
__installed_version=$(catalog -g ${package_name,,})


# Only install if the latest version does not already exist locally
if ([ ! -f "${package_executable:?}" ] || [ "${__installed_version:-X}" != "${__latest_package_version:?}" ]); then
    # Download Appimage to Applications directory
    print_step_header "Downloading ${package_name:?} version ${__latest_package_version:?}"
    fetch_appimage_and_make_executable "${__latest_package_url:?}"

    # Ensure this package has a start menu link (will create it if missing)
    print_step_header "Ensuring menu short is present for ${package_name:?}"
    rm -f "${USER_HOME:?}/.local/share/applications/${package_name:?}.desktop"
    ensure_menu_shortcut

    # Mark this version as installed
    catalog -s ${package_name,,} ${__latest_package_version:?}
else
    print_step_header "Latest version of ${package_name:?} version ${__latest_package_version:?} already installed"
fi

# Generate duckstation Emulation directory structure
__emulation_path="/mnt/games/Emulation"
mkdir -p \
    "${USER_HOME:?}"/.config/PCSX2/inis \
    "${__emulation_path:?}"/storage/pcsx2/{memcards,sstates,snaps,cheats,cache,covers,bios,patches,textures} \
    "${__emulation_path:?}"/roms/ps2

ensure_symlink "${__emulation_path:?}/storage/pcsx2/memcards" "${USER_HOME:?}/.config/PCSX2/memcards"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/sstates" "${USER_HOME:?}/.config/PCSX2/sstates"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/snaps" "${USER_HOME:?}/.config/PCSX2/snaps"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/cheats" "${USER_HOME:?}/.config/PCSX2/cheats"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/cache" "${USER_HOME:?}/.config/PCSX2/cache"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/covers" "${USER_HOME:?}/.config/PCSX2/covers"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/bios" "${USER_HOME:?}/.config/PCSX2/bios"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/patches" "${USER_HOME:?}/.config/PCSX2/patches"
ensure_symlink "${__emulation_path:?}/storage/pcsx2/textures" "${USER_HOME:?}/.config/PCSX2/textures"

# Create relative symlinks
ensure_symlink "../storage/pcsx2/bios" "${__emulation_path:?}/bios/pcsx2"

# Generate a default config if missing
# Currently need to run PCSX2 once to import the config, can't figure out how to bypass it
if [ ! -f "${USER_HOME:?}/.config/PCSX2/inis/PCSX2.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.config/PCSX2/inis/PCSX2.ini"
[UI]
SettingsVersion = 1
InhibitScreensaver = true
ConfirmShutdown = false
StartPaused = false
PauseOnFocusLoss = false
StartFullscreen = true
DoubleClickTogglesFullscreen = true
HideMouseCursor = true
RenderToSeparateWindow = false
HideMainWindowWhenRunning = false
DisableWindowResize = false
Theme = darkfusion
SetupWizardIncomplete = false


[Folders]
Bios = ${__emulation_path:?}/storage/pcsx2/bios
Snapshots = ${__emulation_path:?}/storage/pcsx2/snaps
SaveStates = ${__emulation_path:?}/storage/pcsx2/sstates
MemoryCards = ${__emulation_path:?}/storage/pcsx2/memcards
Logs = logs
Cheats = ${__emulation_path:?}/storage/pcsx2/cheats
Patches = ${__emulation_path:?}/storage/pcsx2/patches
Cache = ${__emulation_path:?}/storage/pcsx2/cache
Textures = ${__emulation_path:?}/storage/pcsx2/textures
InputProfiles = inputprofiles
Videos = videos
Covers = ${__emulation_path:?}/storage/pcsx2/covers


[Hotkeys]
ToggleFullscreen = SDL-3/Back & SDL-3/DPadLeft
CycleAspectRatio = Keyboard/F6
CycleInterlaceMode = Keyboard/F5
CycleMipmapMode = Keyboard/Insert
GSDumpMultiFrame = Keyboard/Control & Keyboard/Shift & Keyboard/F8
Screenshot = Keyboard/F8
GSDumpSingleFrame = Keyboard/Shift & Keyboard/F8
ToggleSoftwareRendering = Keyboard/F9
ZoomIn = Keyboard/Control & Keyboard/Plus
ZoomOut = Keyboard/Control & Keyboard/Minus
InputRecToggleMode = Keyboard/Shift & Keyboard/R
LoadStateFromSlot = Keyboard/F3
SaveStateToSlot = Keyboard/F1
NextSaveStateSlot = Keyboard/F2
PreviousSaveStateSlot = Keyboard/Shift & Keyboard/F2
OpenPauseMenu = SDL-3/Back & SDL-3/DPadUp
ToggleFrameLimit = Keyboard/F4
TogglePause = Keyboard/F9
ToggleSlowMotion = Keyboard/Shift & Keyboard/Backtab
ToggleTurbo = Keyboard/Tab
HoldTurbo = Keyboard/Period
SaveStateToSlot1 = SDL-3/Start & SDL-3/DPadUp
LoadStateFromSlot1 = SDL-3/Start & SDL-3/DPadDown
ShutdownVM = SDL-3/Back & SDL-3/DPadDown


[AutoUpdater]
CheckAtStartup = false


[GameList]
RecursivePaths = ${__emulation_path:?}/roms/ps2


[Pad1]
Up = SDL-3/DPadUp
Right = SDL-3/DPadRight
Down = SDL-3/DPadDown
Left = SDL-3/DPadLeft
Triangle = SDL-3/Y
Circle = SDL-3/B
Cross = SDL-3/A
Square = SDL-3/X
Select = SDL-3/Back
Start = SDL-3/Start
L1 = SDL-3/LeftShoulder
L2 = SDL-3/+LeftTrigger
R1 = SDL-3/RightShoulder
R2 = SDL-3/+RightTrigger
L3 = SDL-3/LeftStick
R3 = SDL-3/RightStick
Analog = SDL-3/Guide
LUp = SDL-3/-LeftY
LRight = SDL-3/+LeftX
LDown = SDL-3/+LeftY
LLeft = SDL-3/-LeftX
RUp = SDL-3/-RightY
RRight = SDL-3/+RightX
RDown = SDL-3/+RightY
RLeft = SDL-3/-RightX
LargeMotor = SDL-3/LargeMotor
SmallMotor = SDL-3/SmallMotor


[EmuCore/GS]
upscale_multiplier = 3


[EmuCore]
EnableWideScreenPatches = true
SaveStateOnShutdown = true
EOF
fi

ensure_esde_alternative_emulator_configured "ps2" "PCSX2 (Standalone)"

echo "DONE"
