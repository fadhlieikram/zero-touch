#!/bin/bash

./props_parser.sh

# Initialize global variable
package=

download_package() {
    local dloadpath=${dod_path}

    echo "[+] Fetching package ${package} to path:${dloadpath}..."
    
    # Check if download path exist
    if [ ! -d $dloadpath ]; then
      echo "[-] Error: Path ${dloadpath} doesnt exist." >&2
      return 1
    fi
    
    # Plug in the dod download script
    ./download_dod.sh ${package} ${dloadpath}
    
    if [ $? -ne 0 ]; then
      echo "[-] Error: Failed to download package ${package}." >&2
      return 1
    fi

    echo "[+] Perform: chmod ${dod_chmod} ${dloadpath}/${dodnum}.zip"
    chmod ${dod_chmod} ${dloadpath}/${dodnum}.zip
    echo "[+] Package download complete."
    return 0
}

upzip_package() {
    local zipfile=${dod_path}/${package}.zip
    local unzipdir=${dod_path}/${package}/

    unzip ${zipfile} -d ${unzipdir}

    if [ $? -ne 0 ]; then
      echo "[-] Error: Failed to unzip ${zipfile} to ${unzipdir}." >&2
      return 1
    fi

    echo "[+] Perform: chmod -R 775 ${unzipdir}"
    chmod -R 775 ${unzipdir}
    echo "[+] Unzip complete."
    return 0
}

deploy_package() {
  ./deploy_jar.sh ${package}

  if [ $? -ne 0 ]; then
      echo "[-] Error: deploy_jar failed." >&2
      exit 1
  fi

  echo "[+] Deploy package complete."
  return 0
}



# Start
# Capture the script parameter
package=

if [ -z $1 ]; then
  echo "[-] Error: Please provide the package number." >&2
  exit 1
fi

package=$1

# Download the package
download_package

if [ $? -ne 0 ]; then
  echo "[-] Error: ${0##*/} failed." >2&
  exit 1
fi

# Unzip the package
unzip_package

if [ $? -ne 0 ]; then
  echo "[-] Error: ${0##*/} failed." >2&
  exit 1
fi

# Backup and deploy
deploy_package

if [ $? -ne 0 ]; then
  echo "[-] Error: ${0##*/} failed." >2&
  exit 1
fi

echo "[+] ${0##*/} complete."
exit 0
