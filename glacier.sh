#!/bin/bash
#
# THIS SCRIPT RUNS AS ROOT
#
# %glacier ALL=(ALL) NOPASSWD: /usr/local/bin/glacier
########################################################################

# User configurable values

# Path to root password file
rootpass_path="/home/mal/pkgs/glacier/rootpass"

# Files we allow to be edited with this script
valid_targets=("/etc/hosts" "$rootpass_path")

# Delay in seconds
delay=5

########################################################################
# Here we go

#####################
# vvv FUNCTIONS vvv #
#####################

# Function to check if a variable is contained in an array
contains() {
        typeset _x;
        typeset -n _A="$1"
        for _x in "${_A[@]}" ; do
                [ "$_x" = "$2" ] && return 0
        done
        return 1
}

# Function to print cmdline usage string
print_usage() {
  printf "Usage: glacier -r (displays rootpass) | glacier <path> (opens frozen file for reading) | glacier -w <path> (opens frozen file for writing)\n"
}

# Function to sleep while printing time remaining
time_delay() {
    echo "Delay: $delay"
    for i in $(seq 1 $delay);
    do
        printf 'Waiting %d seconds...\r' $(($delay - $i))
        sleep 1
    done
    printf '\n'
}

#####################
# ^^^ FUNCTIONS ^^^ #
#####################

# This variable expansion gets the basename of the path to this file
progName="${0##*/}"

# Reset PATH to known quantity
export PATH=/usr/local/bin:/bin:/usr/bin

# Force the script to run with sudo
[[ $(id -u) != 0 ]] && exec sudo "$0" "$@"

########### ALL LOGIC SHOULD BE BELOW THIS POINT ###########

# Make sure the valid_targets are files that actually exist
for valid_target in "${valid_targets[@]}"
do
    if [ ! -f $valid_target ]; then
        echo "Target not found: $valid_target"
        exit 1
    fi
done

# Flag to indicate root password query
r_flag=''

# Flag to indicate we want to edit a file
w_flag=''


# Parse flags
while getopts 'rw:' flag; do
  case "${flag}" in
    r) r_flag='true' ;;
    w) w_flag='true' ;;
    *) print_usage
       printf "getopts is angry\n"
       exit 1 ;;
  esac
done

# Handle root password query and then exit
if [[ "$r_flag" == "true" ]] ; then
    time_delay
    printf "ROOT PASSWORD:\n"
    cat $rootpass_path
    exit 0
fi

# Make sure we have at least one argument
if [ $# -eq 0 ]
  then
    echo "No arguments supplied"
    print_usage
    exit 0
fi

# Get abspath of the target
if [[ "$w_flag" == "true" ]] ; then
    target=`realpath $2`
else
    target=`realpath $1`
fi

# Check if the argument is a valid target
if contains valid_targets "$target" ; then
    echo "Good target: $target"
else
    echo "Bad target: $target (valid targets: ${valid_targets[@]})"
    exit 1
fi

# Handle read query and then exit
if [[ "$w_flag" == "" ]] ; then
    time_delay
    cat $target
    exit 0
fi

umask 0022
tmpf=$(mktemp "/tmp/${progName}_XXXXXXXXXX")
cp -f "$target" "$tmpf"

# Revert to the original user account to edit the temporary file
chown "$SUDO_USER" "$tmpf"
sudo -u "$SUDO_USER" "${EDITOR:-vi}" "$tmpf"


printf "############################### OLD VERS: '%s' ###############################\n\n" $target
cat $target
printf "\n############################### NEW VERS: '%s' ###############################\n\n" $target
cat $tmpf
printf "\n############################### EDITS TO: '%s' ###############################\n\n" $target
diff --new-file $target $tmpf
printf "\n############################### --------: '%s' ###############################\n\n" $target

# Make the user wait
time_delay

read -t 60 -p "Are you sure you still want to edit '$target' (y/N)? " YN
[[ "${YN,,}" =~ ^(y|yes)$ ]] || exit 1

# If the copy of the file we edited ($tmpf) exists and we made nontrivial changes, apply them
if [[ -f "$tmpf" ]] && ! cmp -s "$target" "$tmpf" ; then
    echo 'Applying changes'

    # Backup the target and then replace it with our edited version
    [ ! -f "$target" ] && printf "Not making backup. Target '$target' does not exist\n"
    [ -f "$target" ] && cp -pf "$target" "$target.old"
    cp -f "$tmpf" "$target"
else
    printf "No changes\n"
fi

# All done
echo 'Done'
rm -f "$tmpf"
exit 0
