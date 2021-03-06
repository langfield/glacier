#!/bin/bash
target="/usr/local/etc/glacier_rootpass"

# This variable expansion gets the basename of the path to this file
progname="${0##*/}"

# Reset PATH to known quantity
export PATH=/usr/local/bin:/bin:/usr/bin

# Force the script to run with sudo
[[ $(id -u) != 0 ]] && exec sudo "$0" "$@"

printf "This script is for changing your root password and storing it in a file with 600 octal permissions owned by root.\n"
printf "In order to view this file, you must be (1) root, or (2) using a successfully-installed glacier executable.\n"
printf "You will be prompted with an editor in which to enter your new password.\n"
printf "If a password was previously set with this script, you will be prompted to edit the existing file.\n"
read -t 60 -p " Continue (y/N)? " YN
[[ "${YN,,}" =~ ^(y|yes)$ ]] || exit 1

# Create a temporary file which will become ``/usr/local/etc/glacier_rootpass``
tmpf=$(mktemp "/tmp/${progname}_XXXXXXXXXX")
if [[ -f "$target" ]] ; then
    cp -f "$target" "$tmpf"
else
    printf "Target '$target' does not exist. Creating new file\n"
fi

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

# If the copy of the file we edited ($tmpf) exists and we made nontrivial changes, apply them
if [[ -f "$tmpf" ]] && ! cmp -s "$target" "$tmpf" ; then
    echo 'Applying changes'

    # Backup the target and then replace it with our edited version
    [ ! -f "$target" ] && printf "Not making backup. Target '$target' does not exist\n"
    [ -f "$target" ] && cp -pf "$target" "$target.old"
    cp -f "$tmpf" "$target"
    chmod 600 $target
else
    printf "No changes\n"
fi

# All done
echo 'Done'
rm -f "$tmpf"

password=`sudo cat $target`
echo "New password: $password"
echo "root:$password" | sudo chpasswd
