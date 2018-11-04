#!/bin/bash

source setting.txt

dodnum=$1
dodpath=$2
marker=${dod_marker}


if [ -z ${dod_url} ] || [ -z ${dodnum} ] || [ -z ${dodpath} ]; then
  echo '[-] Error: Missing required parameter(s).' >&2
  exit 1
fi

# Construct download url
url=$(echo ${dod_url} | sed s/${marker}/${dodnum}/g)

if [ $? -ne 0 ]; then
  echo "[-] Error: Failed to construct download url." >&2
  exit 1
fi

# Check if link can be reach
echo "[+] wget --spider ${url}"
wget --spider ${url}

return=$?
if [ $return -ne 0 ]; then
  echo "[-] Error: ${return}. Url ${url} cant be reached." >&2
  exit 1
fi

# Perform download
echo "[+] Downloading..."
echo "[+] wget -v ${url} -O ${dodpath}/${dodnum}.html"
wget -v ${url} -O ${dodpath}/${dodnum}.htm

return=$?
if [ $return -ne 0 ]; then
  echo "[-] Error: ${return}. Failed to download from ${url}" >&2
  exit 1
fi

echo "[+] Download complete."
exit 0
