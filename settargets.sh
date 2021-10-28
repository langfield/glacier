#!/bin/bash

# Path to valid targets file
valid_targets_path="$HOME/.glacier-valid-targets"
printf "Valid targets path: $valid_targets_path\n"
if [ ! -f $valid_targets_path ]; then
    echo "No '~/.glacier-valid-targets' file found."
    echo "Creating new file"
else
    echo "Found existing valid targets file at '$valid_targets_path'"
    echo "Predefined valid targets:"
    cat $valid_targets_path
fi
touch $valid_targets_path
sudo chmod 664 $valid_targets_path
