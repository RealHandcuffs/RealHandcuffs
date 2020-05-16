#!/bin/bash

# this script compiles all papyrus files from the package folder
# into a matching folder structure in the build folder

# make sure we clean up on exit
ORIGINAL_DIR=$(pwd)
function clean_up {
  cd "$ORIGINAL_DIR"
}
trap clean_up EXIT
set -e

# check arguments
QUIET=0
for VAR in "$@"
do
  case "$VAR" in
    "-q" )
      QUIET=1;;
    "--quiet" )
      QUIET=1;;
    * )
      if [[ "$VAR" != "-h" && "$VAR" != "--help" ]]
      then
        echo "Invalid argument: $VAR"
      fi
      echo "Usage: $(basename "$0") [-q|--quiet]"
      exit -1;;
  esac
done

# switch to base directory of repo
SCRIPTS_DIR=$(dirname "$(realpath "${BASH_SOURCE[0]}")")
BASE_DIR=$(realpath "$SCRIPTS_DIR/..")
cd "$BASE_DIR"

# find tools and set env variables pointing to them
echo "#!/bin/bash" > build/setenv.sh
scripts/find_tools.sh -g >> build/setenv.sh
. build/setenv.sh

# find base source directory for papyrus compiler (installed with creation kit)
SOURCE_BASE="$DIR_FALLOUT4CREATIONKIT/Data/Scripts/Source/Base"
if [[ ! -f "$SOURCE_BASE/Institute_Papyrus_Flags.flg" ]]
then
    SOURCE_BASE="$DIR_FALLOUT4/Data/Scripts/Source/Base"
    if [[ ! -f "$SOURCE_BASE/Institute_Papyrus_Flags.flg" ]]
    then
      >&2 echo "ERROR: Unable to find papyrus base source dir."
      exit -1
    fi
fi
SOURCE_BASE=$(echo "$SOURCE_BASE" | sed -e 's/\///' -e 's/\//:\\/' -e 's/\//\\/g')

# find F4SE scripts source directory for papyrus compiler
SOURCE_F4SE="$DIR_FALLOUT4CREATIONKIT/Data/Scripts/Source/User"
if [[ ! -f "$SOURCE_F4SE/F4SE.psc" ]]
then
    SOURCE_F4SE="$DIR_FALLOUT4/Data/Scripts/Source/User"
    if [[ ! -f "$SOURCE_F4SE/F4SE.psc" ]]
    then
      >&2 echo "ERROR: Unable to find papyrus F4SE source dir."
      exit -1
    fi
fi
SOURCE_F4SE=$(echo "$SOURCE_F4SE" | sed -e 's/\///' -e 's/\//:\\/' -e 's/\//\\/g')

# set up a function to compile all scripts in a folder using parallel execution
# $1: input folder (must be inside "package" folder and contain 'Source/User' folder)
# $2: additional imports
function compile_folder() { # $1: folder, $2: additional imports
  cd "$BASE_DIR/package/$1/Source/User"
  if [[ $QUIET == 0 ]]
  then
    echo "Compiling: $1"
  fi
  files=()
  pids=()
  # the for loops works because the folders (which correspond to namespaces) have no whitespace
  for f in $(find . -name '*.psc' |  sed -e 's/.\///' -e 's/\//\\/g')
  do
    files+=( "$f" )
    if [[ "$f" =~ "Debug" ]]
    then
      options="-final -optimize -quiet"
    else
      options="-release -final -optimize -quiet"
    fi
    "$DIR_FALLOUT4CREATIONKIT/Papyrus Compiler/PapyrusCompiler.exe" "$f" $options -flags="$SOURCE_BASE\\Institute_Papyrus_Flags.flg" -import="$SOURCE_F4SE;$SOURCE_BASE;$2" -output="$(echo "$BASE_DIR/build/$1" | sed -e 's/\///' -e 's/\//:\\/' -e 's/\//\\/g')" &
    pids+=( "$!" )
  done
  failures=()
  for index in ${!pids[*]}
  do 
    wait ${pids[$index]} || failures+=( "${files[$index]}" )
  done
  if [[ ${#failures[@]} > 0 ]]
  then
    for file in "${failures[@]}"
    do
      echo "ERROR: Compilation failed for: package/$1/Source/User/$(echo $file | sed 's/\\/\//g')."
    done
    exit -1
  else
    if [[ $QUIET == 0 ]]
    then
      echo "  Compiled ${#pids[@]} files."
    fi
  fi
  cd "$BASE_DIR"
}

# call the function for the package/0_Common folder, using LL_FourPlay as dependency
SOURCE_LL_FOURPLAY=$(echo "$BASE_DIR/package/5_ThirdParty/LL FourPlay community F4SE plugin/Scripts/Source/User" | sed -e 's/\///' -e 's/\//:\\/' -e 's/\//\\/g')
compile_folder "0_Common/Scripts" "$SOURCE_LL_FOURPLAY"

# call the function for all other script folders, using 0_Common as dependency (but skip 5_ThirdParty)
SOURCE_RH_COMMON=$(echo "$BASE_DIR/package/0_Common/Scripts/Source/User" | sed -e 's/\///' -e 's/\//:\\/' -e 's/\//\\/g')
find package -name '*.psc' ! -path 'package/0_Common/*' ! -path 'package/5_ThirdParty/*' | sed -rn 's/package\/(.*)\/Source\/User\/.*\.psc/\1/p' | sort -u |\
while read -r i
do
  compile_folder "$i" "$SOURCE_RH_COMMON"
done  
