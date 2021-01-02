#!/usr/bin/env bash
#
# by Siddharth Dushantha
#

# Colored log indicators
GOOD="\033[92;1m[✔]\033[0m"
BAD="\033[91;1m[✘]\033[0m"
INFO="\033[94;1m[I]\033[0m"
RUNNING="\033[37;1m[~]\033[0m"
NOTICE="\033[93;1m[!]\033[0m"

SERIAL="$1"
SNAPS_DIRECTORY="snaps_$SERIAL"

usage(){
cat <<EOF
usage: snaprecovery [SERIAL]

The serial number of the device can be found by running 'adb devices'
EOF
    exit 1
}

[ $# -eq 0 ] || [ "$1" = "" ] && usage

while [ "$1" ] ; do
    case $1 in
        -h|--help) usage ;;
    esac
    shift
done

for DEPENDENCY in curl adb; do
    if ! command -v "$DEPENDENCY" >/dev/null 2>&1; then
        printf "$BAD %b\n" "Could not find '$DEPENDENCY', is it installed?"
        exit 1
    fi
done

if ! PRODUCT_MODEL=$(adb -s "$SERIAL" shell getprop ro.product.model 2> /dev/null);then
    printf "$BAD %b\n" "Looks like '$SERIAL' is an invalid device"
    exit 1
fi

printf "$INFO %b\n" "Target device: $SERIAL ($PRODUCT_MODEL)"

# Restart adb as root. Root access is needed in order to access the files
adb -s "$SERIAL" root > /dev/null 2>&1

if ! adb -s "$SERIAL" pull /data/user/0/com.snapchat.android/files/file_manager/chat_snap/ .tmp > /dev/null 2>&1; then
    printf "$BAD %b\n" "This device is not rooted!"
    exit 1
fi

mkdir -p "$SNAPS_DIRECTORY"
TOTAL_FILES=$(find .tmp | wc -l | xargs)
COUNT=1

for SNAP in .tmp/*; do
    EXTENSION=$(file --mime-type -b "$SNAP" | sed 's/.*\///g')
    NEW_FILENAME=$(echo "$SNAP" | sed "s/chat_snap\.0/$EXTENSION/g")

    # \r            Move cursor to the start of the current line
    # \e[<NUM>K     Move cursor up N lines   
    printf "\r\e[2K$RUNNING %b" "Recovering [$COUNT/$TOTAL_FILES]: $NEW_FILENAME"
    mv "$SNAP" "$NEW_FILENAME"
    COUNT=$((COUNT + 1))
done

printf "\r\e[2K$GOOD %b\n" "Recoverd $TOTAL_FILES snaps"
printf "$NOTICE %b\n" "The recovered snaps can be found in '$SNAPS_DIRECTORY'"

mv .tmp/* "$SNAPS_DIRECTORY"
rm -rf .tmp/

