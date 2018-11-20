#########################################################################
###   This program create directory, and an entry file which          ###
###   records the path of created directory.                          ###
#########################################################################

#!/bin/bash

source props.properties

# Initialize variables
# var entry_file is coming from deploy_*.sh
tmp_file="$entry_file"
dir_entry_chmod="$DIR_ENTRY_CHMOD"


# Program starts here
dir=$1

# Check if all variables are assigned
if [ -z "$dir" ]; then
  echo '[-] Error: Directory path is not set.' >&2
  exit 1
fi

if [ -z "$tmp_file" ] || [ -z "$dir_entry_chmod" ]; then
  echo '[-] Error: Directory creation entry details are not set.' >&2
  exit 1
fi

# Create temporary entry file
if [ ! -f "$tmp_file" ]; then
  echo "[+] Creating entry file for directory creation:${tmp_file}."
  
  touch ${tmp_file}

  if [ $? -ne 0 ]; then
    echo "[-] Error: Unable to create file:${tmp_file}." >&2
    exit 1
  fi
  
  chmod ${dir_entry_chmod} ${tmp_file}
fi

mkdir ${dir}

if [ $? -ne 0 ]; then
  echo "[-] Error: Unable to create directory:${dir}." >&2
  exit 1
fi

echo "${dir}" >> ${tmp_file}

exit 0
