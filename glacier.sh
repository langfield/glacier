#!/bin/bash
#
# THIS SCRIPT RUNS AS ROOT
#
# %glacier ALL=(ALL) NOPASSWD: /usr/local/bin/glacier

# ------------------------------------------------------------------------------
#  User configurable values
# ------------------------------------------------------------------------------

# Path to root password file
rootpass_path="/usr/local/etc/glacier_rootpass"

# Delay in seconds
delay=3600

########################################################################
# Here we go

#####################
# vvv FUNCTIONS vvv #
#####################

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
# Function to print cmdline usage string
print_usage() {
  printf "Usage: glacier (displays rootpass) | glacier -a <URL> (append URL to /etc/hosts)\n"
}

#####################
# ^^^ FUNCTIONS ^^^ #
#####################

# Reset PATH to known quantity
export PATH=/usr/local/bin:/bin:/usr/bin

# Force the script to run with sudo
[[ $(id -u) != 0 ]] && exec sudo "$0" "$@"

########### ALL LOGIC SHOULD BE BELOW THIS POINT ###########

home=$(eval echo ~$SUDO_USER)

a_flag=''

# Parse flags
while getopts 'a:' flag; do
  case "${flag}" in
    a) a_flag='true' ;;
    *) print_usage
       printf "bad cmdline flag\n"
       exit 1 ;;
  esac
done

# Append a line to the hosts file.
if [[ "$a_flag" == "true" ]] ; then
  printf "appending URL: $2\n"
  echo "127.0.0.1 $2" >> /etc/hosts
  tail /etc/hosts
  exit 0
fi

# Handle root password query and then exit
printf "Expected rootpass path: $rootpass_path\n"
if [ ! -f $rootpass_path ]; then
    echo "No '$rootpass_path' file found."
    echo "Run 'make rootpass' to generate this file."
    exit 1
fi
time_delay
printf "ROOT PASSWORD:\n"
cat $rootpass_path
exit 0
