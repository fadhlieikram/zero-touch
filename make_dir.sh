#!/bin/bash

local dod="$package"
local dir_entry_file="$dir_creation_entry"
local dir_entry_chmod="$dir_entry_chmod"
local dir=$1
local tmp_file=

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

# Create
if [ ! -f "$tmp_file" ]; then
  echo "[+] Creating directory creation entry file: ${tmp_file}."
  
  touch ${tmp_file}
  
  if [ $? -ne 0 ]; then
    echo '[-] Error: Unable to create file: ${tmp_file}.' >&2
    exit 1
  fi
  
  chmod ${dir_entry_chmod} ${tmp_file}
fi

echo "[+] Creating directory: ${dir}."

mkdir ${dir}

if [ $? -ne 0 ]; then
  echo '[-] Error: Unable to create directory: ${dir}.' >&2
  exit 1
fi

echo "${dir}" >> ${tmp_file}

exit 0
