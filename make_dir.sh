#!/bin/bash

source props.properties

# Initialize variables
dod="$PACKAGE"
dir_entry_file="$DIR_ENTRY_PATH"
dir_entry_chmod="$DIR_ENTRY_CHMOD"
dir=
tmp_file=


dir=$1

# Check if all variables are assigned
if [ -z "$dir" ]; then
  echo '[-] Error: Directory path is not set.' >&2
  exit 1
fi

if [ -z "$dir_entry_file" ] || [ -z "$dir_entry_chmod" ] || [ -z "$dod" ]; then
  echo '[-] Error: Directory creation entry details are not set.' >&2
  exit 1
fi


tmp_file=${dir_entry_file}_${dod}

# Create temporary entry file
if [ ! -f "$tmp_file" ]; then
  echo "[+] Creating directory creation entry file: ${tmp_file}."
  
  touch ${tmp_file}
  
  if [ $? -ne 0 ]; then
    echo "[-] Error: Unable to create file: ${tmp_file}." >&2
    exit 1
  fi
  
  chmod ${dir_entry_chmod} ${tmp_file}
fi

echo "[+] Creating directory: ${dir}."
mkdir ${dir}

if [ $? -ne 0 ]; then
  echo "[-] Error: Unable to create directory: ${dir}." >&2
  exit 1
fi

echo "${dir}" >> ${tmp_file}

exit 0
