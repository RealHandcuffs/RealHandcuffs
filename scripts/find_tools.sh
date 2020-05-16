#!/bin/bash

# this script looks for the required tools:
# - TOOL_7ZIP points to 7z.exe
# - DIR_FALLOUT4 points to the Fallout 4 directory
# - DIR_FALLOUT4CREATIONKIT points to the Fallout 4 Creation Kit directory (usually the same as DIR_FALLOUT4)
# if the -g argument is passed, it will output the above variables in format KEY="VALUE"
# if not, it will just check for presence of the tools and print human-readable messages

# make sure we clean up on exit
ORIGINAL_DIR=$(pwd)
function clean_up {
  cd "$ORIGINAL_DIR"
}
trap clean_up EXIT
set -e

# check arguments
GENERATE=0
for var in "$@"
do
  case "$var" in
    "-g" )
      GENERATE=1;;
    "--generate" )
      GENERATE=1;;
    * )
      if [[ "$var" != "-h" && "$var" != "--help" ]]
      then
        echo "Invalid argument: $var"
      fi
      echo "Usage: $(basename "$0") [-g|--generate]"
      exit -1;;
  esac
done

# switch to base directory of repo
SCRIPTS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
BASE_DIR=$(realpath "$SCRIPTS_DIR/..")
cd "$BASE_DIR"

# search for 7zip
# if 7z.exe (or symlink to it) is in tools directory, this is used
# otherwise try to find the install location in the registry
if [[ -f "tools/7z.exe" ]]
then
  [[ $GENERATE == 0 ]] && echo "7-Zip: In tools directory."
  TOOL_7ZIP="$(realpath "$BASE_DIR/tools/7z.exe")"
  if [[ "$TOOL_7ZIP" != "$BASE_DIR/tools/7z.exe" ]]
  then
    [[ $GENERATE == 0 ]] && echo "  Resolved to: $TOOL_7ZIP"
  fi
else
  REGISTRY=$(reg query "HKLM\SOFTWARE\7-Zip") || { >&2 echo "ERROR: Unable to find 7-Zip registry key."; exit 1; }
  PATH_7ZIP=$(echo "$REGISTRY" | sed -rn "s/\s*Path64\s+REG_SZ\s+(.*)/\1/p" | sed 's/\\/\//g' | sed 's/://')
  PATH_7ZIP="/${PATH_7ZIP%/}"
  if [[ -f "$PATH_7ZIP/7z.exe" ]]
  then
    TOOL_7ZIP="$PATH_7ZIP/7z.exe"
    [[ $GENERATE == 0 ]] && echo "7-Zip: $TOOL_7ZIP"
  fi
fi

if [[ -z "$TOOL_7ZIP" ]]
then
  >&2 echo "ERROR: Unable to find 7-Zip."
  exit 1
fi

# search for Fallout 4
# if "Fallout 4" folder is in tools directory (probably symlink), this is used
# otherwise try to find the install location in the registry
if [[ -d "tools/Fallout 4" ]]
then
  [[ $GENERATE == 0 ]] && echo "Fallout 4: In tools directory."
  DIR_FALLOUT4="$(realpath "$BASE_DIR/tools/Fallout 4")"
  if [[ "$DIR_FALLOUT4" != "$BASE_DIR/tools/Fallout 4" ]]
  then
    [[ $GENERATE == 0 ]] && echo "  Resolved to: $DIR_FALLOUT4"
  fi
else
  REGISTRY=$(reg query "HKLM\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\Steam App 377160") || { >&2 echo "ERROR: Unable to find Fallout 4 registry key."; exit 2; }
  PATH_FALLOUT4=$(echo "$REGISTRY" | sed -rn "s/\s*InstallLocation\s+REG_SZ\s+(.*)/\1/p" | sed -e 's/\\/\//g' -e 's/://')
  PATH_FALLOUT4="/${PATH_FALLOUT4%/}"
  if [[ -d "$PATH_FALLOUT4" ]]
  then
    DIR_FALLOUT4="$PATH_FALLOUT4"
    [[ $GENERATE == 0 ]] && echo "Fallout 4: $DIR_FALLOUT4"
  fi
fi

if [[ -z "$DIR_FALLOUT4" ]]
then
  >&2 echo "ERROR: Unable to find Fallout 4."
  exit 2
fi

# search for Fallout 4 Creation Kit
# if "Fallout 4 Creation Kit" folder is in tools directory (probably symlink), this is used
# otherwise try to find it in the same folder as Fallout 4
if [[ -d "tools/Fallout 4 Creation Kit" ]]
then
  [[ $GENERATE == 0 ]] && echo "Fallout 4 Creation Kit: In tools directory."
  DIR_FALLOUT4CREATIONKIT="$(realpath "$BASE_DIR/tools/Fallout 4 Creation Kit")"
  if [[ "$DIR_FALLOUT4CREATIONKIT" != "$BASE_DIR/tools/Fallout 4 Creation Kit" ]]
  then
    [[ $GENERATE == 0 ]] && echo "  Resolved to: $DIR_FALLOUT4CREATIONKIT"
  fi
else
  if [[ -f "$DIR_FALLOUT4/CreationKit.exe" ]]
  then
    DIR_FALLOUT4CREATIONKIT="$DIR_FALLOUT4"
    [[ $GENERATE == 0 ]] && echo "Fallout 4 Creation Kit: In Fallout 4 directory."
  fi
fi

if [[ -z "$DIR_FALLOUT4CREATIONKIT" ]]
then
  >&2 echo "ERROR: Unable to find Fallout 4 Creation Kit."
  exit 3
fi

# done, echo commands to set environment variables if requested to do so 
if [[ $GENERATE == 1 ]]
then
    echo TOOL_7ZIP=\"$TOOL_7ZIP\"
    echo DIR_FALLOUT4=\"$DIR_FALLOUT4\"
    echo DIR_FALLOUT4CREATIONKIT=\"$DIR_FALLOUT4CREATIONKIT\"
fi