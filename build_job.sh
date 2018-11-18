#!/bin/bash

source props.properties

# Initialize global variable
package=
job=

download_package() {
    local dloadpath=${DOD_PATH}

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

    chmod ${dod_chmod} ${dloadpath}/${dodnum}.zip
    return 0
}

upzip_package() {
    local zipfile=${DOD_PATH}/${package}.zip
    local unzipdir=${DOD_PATH}/${package}/

    echo "[+] Unzip package to ${unzipdir}"
    unzip ${zipfile} -d ${unzipdir}

    if [ $? -ne 0 ]; then
      echo "[-] Error: Failed to unzip ${zipfile} to ${unzipdir}." >&2
      return 1
    fi

    chmod -R 775 ${unzipdir}
    return 0
}

deploy_package() {

  ./deploy_build.sh ${package}

  if [ $? -ne 0 ]; then
      echo "[-] Error: Build file(s) deployment failed." >&2
      return 1
  fi

  return 0
}

rollback_package() {

  ./rollback_build.sh ${package}

  if [ $? -ne 0 ]; then
      echo "[-] Error: Build file(s) rollback failed." >&2
      return 1
  fi

  echo "[+] Rollback package complete."
  return 0
}


# Start
# Capture the script parameter
job=$1
package=$2

if [ -z "${job}" ] [ -z "${package}" ]; then
  echo "[-] Error: Invalid paramters." >&2
  exit 1
fi

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

# Deploy or rollback
case $job in
  deploy)
    deploy_package

    if [ $? -ne 0 ]; then
    echo "[-] Error: ${0##*/} failed." >2&
    exit 1
    fi
    ;;
  rollback)
    rollback_package

    if [ $? -ne 0 ]; then
    echo "[-] Error: ${0##*/} failed." >2&
    exit 1
    fi
    ;;
esac


echo "[+] ${0##*/} complete."
exit 0
