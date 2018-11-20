#########################################################################
###   This program download dod package, to a specified directory.    ###
###                                                                   ###
#########################################################################
#!/bin/bash

source props.properties

dodnum=$1
dodpath=$2
marker=${DOD_MARKER}

# Program starts here
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
echo "[+] Checking url..."
wget --spider ${url}

return=$?
if [ $return -ne 0 ]; then
  echo "[-] Error: ${return}. Url ${url} cant be reached." >&2
  exit 1
fi

# Perform download
echo "[+] Downloading package..."
wget -v ${url} -O ${dodpath}/${dodnum}.htm

return=$?
if [ $return -ne 0 ]; then
  echo "[-] Error: ${return}. Failed to download from ${url}" >&2
  exit 1
fi

echo "[+] Download complete."
exit 0
