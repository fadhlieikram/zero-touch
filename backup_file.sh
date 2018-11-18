#!/bin/bash

source=$1
target=$2

# Check if all variables are assigned
if [ -z ${source} ] || [ -z ${target} ]; then
  echo '[-] Error: Required parameter(s) not set.' >&2
  exit 1
fi

cp -p ${source} ${target}

if [ $? -ne 0 ]; then
  echo "[-] Error: Unable to backup file (${source})." >&2
  exit 1
fi

if [ ! -f  ${backupfile} ]; then
  echo "[-] Error: Attempt to backup file (${source}) failed." >&2
  exit 1
fi

exit 0
