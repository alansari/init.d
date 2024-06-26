#!/usr/bin/env bash
###
# File: install-duckstation.sh
# Project: scripts
# File Created: Sunday, 27th August 2023 8:28:04 am
# Author: Josh.5 (jsunnex@gmail.com)
# -----
# Last Modified: Sunday, 17th September 2023 4:26:23 pm
# Modified By: Josh.5 (jsunnex@gmail.com)
###
#
# About:
#   Install Duckstation during container startup.
#   This will also configure duckstation with some default options for Steam Headless.
#   It will also configure the duckstation AppImage as the default emulator for GBA ROMs in ES-DE.
#
# Guide:
#   Add this script to your startup scripts by running:
#       $ ln -sf "./scripts/install-duckstation.sh" "${USER_HOME:?}/init.d/install-duckstation.sh"
#
###

set -euo pipefail


# Import helpers
source "${USER_HOME:?}/init.d/helpers/functions.sh"
source "${USER_HOME:?}/init.d/helpers/functions-es-de-config.sh"


# Ensure this script is being executed as the default user
exec_script_as_default_user


# Config
package_name="duckstation-qt"
package_description="Playstation Emulator"
package_icon_url="https://cdn2.steamgriddb.com/file/sgdb-cdn/icon/e1f581b9f9af4ca9be996aa40da6759e/32/24x24.png"
package_executable="${USER_HOME:?}/Applications/${package_name:?}.AppImage"
package_category="Game"
print_package_name


# Check for a new version to install
__registry_package_json=$(wget -O - -o /dev/null https://api.github.com/repos/stenzek/duckstation/releases/latest)
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
    "${USER_HOME:?}"/.local/share/duckstation \
    "${__emulation_path:?}"/roms/psx \
    "${__emulation_path:?}"/storage/duckstation/{states,memcards,bios,screenshots,covers,cache,cheats,dump,gamesettings,inputprofiles,states,screenshots,shaders,textures} 

# Create relative symlinks
ensure_symlink "../storage/duckstation/bios" "${__emulation_path:?}/bios/duckstation"

# Generate a default config if missing
if [ ! -f "${USER_HOME:?}/.local/share/duckstation/settings.ini" ]; then
    cat << EOF > "${USER_HOME:?}/.local/share/duckstation/settings.ini"
[Main]
SettingsVersion = 3
EmulationSpeed = 1
FastForwardSpeed = 0
TurboSpeed = 0
SyncToHostRefreshRate = false
IncreaseTimerResolution = true
InhibitScreensaver = true
StartPaused = false
StartFullscreen = true
PauseOnFocusLoss = false
PauseOnMenu = true
SaveStateOnExit = true
CreateSaveStateBackups = true
CompressSaveStates = true
ConfirmPowerOff = false
LoadDevicesFromSaveStates = false
ApplyCompatibilitySettings = true
ApplyGameSettings = true
AutoLoadCheats = true
DisableAllEnhancements = false
RewindEnable = false
RewindFrequency = 10
RewindSaveSlots = 10
RunaheadFrameCount = 0
EnableDiscordPresence = false


[ControllerPorts]
ControllerSettingsMigrated = true
MultitapMode = Disabled
PointerXScale = 8
PointerYScale = 8
PointerXInvert = false
PointerYInvert = false


[Console]
Region = Auto
Enable8MBRAM = false


[CPU]
ExecutionMode = Recompiler
OverclockEnable = false
OverclockNumerator = 1
OverclockDenominator = 1
RecompilerMemoryExceptions = false
RecompilerBlockLinking = true
RecompilerICache = false
FastmemMode = MMap


[GPU]
Renderer = Vulkan
Adapter = 
ResolutionScale = 5
Multisamples = 1
UseDebugDevice = false
PerSampleShading = false
UseThread = true
ThreadedPresentation = true
UseSoftwareRendererForReadbacks = false
TrueColor = true
ScaledDithering = true
TextureFilter = xBR
DownsampleMode = Disabled
DisableInterlacing = true
ForceNTSCTimings = false
WidescreenHack = false
ChromaSmoothing24Bit = false
PGXPEnable = true
PGXPCulling = true
PGXPTextureCorrection = true
PGXPColorCorrection = false
PGXPVertexCache = false
PGXPCPU = false
PGXPPreserveProjFP = false
PGXPTolerance = -1
PGXPDepthBuffer = false
PGXPDepthClearThreshold = 300


[Display]
CropMode = Overscan
ActiveStartOffset = 0
ActiveEndOffset = 0
LineStartOffset = 0
LineEndOffset = 0
Force4_3For24Bit = false
AspectRatio = Auto (Game Native)
Alignment = Center
CustomAspectRatioNumerator = 0
LinearFiltering = true
IntegerScaling = false
Stretch = false
PostProcessing = false
ShowOSDMessages = true
ShowFPS = false
ShowSpeed = false
ShowResolution = false
ShowCPU = false
ShowGPU = false
ShowFrameTimes = false
ShowStatusIndicators = true
ShowInputs = false
ShowEnhancements = false
DisplayAllFrames = false
InternalResolutionScreenshots = false
StretchVertically = false
VSync = false
MaxFPS = 0
OSDScale = 100


[CDROM]
ReadaheadSectors = 8
RegionCheck = false
LoadImageToRAM = false
LoadImagePatches = false
MuteCDAudio = false
ReadSpeedup = 1
SeekSpeedup = 1


[Audio]
Backend = Cubeb
Driver = 
OutputDevice = 
StretchMode = TimeStretch
BufferMS = 50
OutputLatencyMS = 20
OutputVolume = 100
FastForwardVolume = 100
OutputMuted = false
DumpOnBoot = false


[Hacks]
UseOldMDECRoutines = false
DMAMaxSliceTicks = 1000
DMAHaltTicks = 100
GPUFIFOSize = 16
GPUMaxRunAhead = 128


[PCDrv]
Enabled = false
EnableWrites = false
Root = 


[BIOS]
PatchTTYEnable = false
PatchFastBoot = false
SearchDirectory = ${__emulation_path:?}/storage/duckstation/bios


[MemoryCards]
Card1Type = PerGameTitle
Card2Type = None
UsePlaylistTitle = true
Directory = ${__emulation_path:?}/storage/duckstation/memcards
Card2Path = ${__emulation_path:?}/storage/duckstation/memcards/shared_card_2.mcd
Card1Path = ${__emulation_path:?}/storage/duckstation/memcards/shared_card_1.mcd


[Cheevos]
Enabled = false
TestMode = false
UnofficialTestMode = false
UseFirstDiscFromPlaylist = true
RichPresence = true
ChallengeMode = false
Leaderboards = true
Notifications = true
SoundEffects = true
PrimedIndicators = true


[Logging]
LogLevel = Info
LogFilter = 
LogToConsole = true
LogToDebug = false
LogToWindow = false
LogToFile = false


[Debug]
ShowVRAM = false
DumpCPUToVRAMCopies = false
DumpVRAMToCPUCopies = false
ShowGPUState = false
ShowCDROMState = false
ShowSPUState = false
ShowTimersState = false
ShowMDECState = false
ShowDMAState = false


[TextureReplacements]
EnableVRAMWriteReplacements = false
PreloadTextures = false
DumpVRAMWrites = false
DumpVRAMWriteForceAlphaChannel = true
DumpVRAMWriteWidthThreshold = 128
DumpVRAMWriteHeightThreshold = 128


[Folders]
Cache = ${__emulation_path:?}/storage/duckstation/cache
Cheats = ${__emulation_path:?}/storage/duckstation/cheats
Covers = ${__emulation_path:?}/storage/duckstation/covers
Dumps = ${__emulation_path:?}/storage/duckstation/dump
GameSettings = ${__emulation_path:?}/storage/duckstation/gamesettings
InputProfiles = ${__emulation_path:?}/storage/duckstation/inputprofiles
SaveStates = ${__emulation_path:?}/storage/duckstation/states
Screenshots = ${__emulation_path:?}/storage/duckstation/screenshots
Shaders = ${__emulation_path:?}/storage/duckstation/shaders
Textures = ${__emulation_path:?}/storage/duckstation/textures


[InputSources]
SDL = true
SDLControllerEnhancedMode = false
Evdev = false
XInput = false
RawInput = false


[Pad1]
Type = AnalogController
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
R1 = SDL-3/RightShoulder
L2 = SDL-3/+LeftTrigger
R2 = SDL-3/+RightTrigger
L3 = SDL-3/LeftStick
R3 = SDL-3/RightStick
LLeft = SDL-3/-LeftX
LRight = SDL-3/+LeftX
LDown = SDL-3/+LeftY
LUp = SDL-3/-LeftY
RLeft = SDL-3/-RightX
RRight = SDL-3/+RightX
RDown = SDL-3/+RightY
RUp = SDL-3/-RightY
Analog = SDL-3/Guide
SmallMotor = SDL-3/SmallMotor
LargeMotor = SDL-3/LargeMotor


[Pad2]
Type = None


[Pad3]
Type = None


[Pad4]
Type = None


[Pad5]
Type = None


[Pad6]
Type = None


[Pad7]
Type = None


[Pad8]
Type = None


[Hotkeys]
FastForward = Keyboard/Tab
TogglePause = Keyboard/F9
Screenshot = SDL-3/Start & SDL-3/DPadRight
ToggleFullscreen = SDL-3/Start & SDL-3/DPadLeft
OpenPauseMenu = SDL-3/Back & SDL-3/DPadUp
LoadSelectedSaveState = Keyboard/F1
SaveSelectedSaveState = Keyboard/F2
SelectPreviousSaveStateSlot = Keyboard/F3
SelectNextSaveStateSlot = Keyboard/F4
PowerOff = SDL-3/Back & SDL-3/DPadDown
LoadGlobalState1 = SDL-3/Start & SDL-3/DPadDown
SaveGlobalState1 = SDL-3/Start & SDL-3/DPadUp


[GameList]
RecursivePaths = ${__emulation_path:?}/roms/psx


[UI]
MainWindowGeometry = AdnQywADAAAAAARWAAABhwAAB38AAAQ3AAAEWwAAAaQAAAd6AAAEMgAAAAAAAAAAB4AAAARbAAABpAAAB3oAAAQy
EOF
fi

ensure_esde_alternative_emulator_configured "psx" "DuckStation (Standalone)"

echo "DONE"
