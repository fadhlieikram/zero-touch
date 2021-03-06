#!/bin/bash

source=$1
target=$2

# Check if all variables are assigned
if [ -z ${source} ] || [ -z ${target} ]; then
  echo '[-] Error: Required parameter(s) are not set.' >&2
  exit 1
fi
    
echo "[+] Deploying file ($source)."
echo "[+] cp -p ${source} ${target}"
cp -p ${source} ${target}

if [ $? -ne 0 ]; then
  echo "[-] Error: Unable to deploy file (${source})." >&2
  exit 1
fi

if [ ! -f ${target} ]; then
  echo "[-] Error: Attempt to deploy file (${source}) to (${target}) failed." >&2
  exit 1
fi

exit 0
