#!/bin/bash
source /tmp/rundeck_tmp/enotice/sg/envar.sh

# Initialize global variable
package=
unzipped_package=
job=

download_package() {
    local dloadpath=${DOD_PATH}

    echo "[+] Fetching package ${package} to path:${dloadpath}..."
    
    # Check if download path exist
    if [ ! -d "${dloadpath}" ]; then
      echo "[-] Error: Path ${dloadpath} doesnt exist." >&2
      return 1
    fi
    
    # Check if package exist and delete
    local file="${dloadpath}/${package}.zip"
    if [ -f "${file}" ]; then
      echo "[+] Deleting existing package:${file}"
      
      rm "${file}"
      
      if [ $? -ne 0 ]; then
        echo "[-] Error: Failed to delete package." >&2
        return 1
      fi
    fi
    
    # Plug in the dod download script
    bash "${SCRIPT_PATH}"/download_dod.sh ${package} ${dloadpath}
    
    if [ $? -ne 0 ]; then
      echo "[-] Error: Failed to download package ${package}." >&2
      return 1
    fi

    chmod ${dod_chmod} ${dloadpath}/${dodnum}.zip
    return 0
}

unzip_package() {
    local zipfile=${DOD_PATH}/${package}.zip
    local unzipdir=${unzipped_package}/

    echo "[+] Unzip package to ${unzipdir}"
    
    if [ ! -f "${zipfile}" ]; then
      echo "[-] Error: Unable to find package:${zipfile}" >&2
      return 1
    fi
    
    unzip -o ${zipfile} -d ${unzipdir}

    if [ $? -ne 0 ]; then
      echo "[-] Error: Failed to unzip ${zipfile} to ${unzipdir}." >&2
      return 1
    fi

    chmod -R 775 ${unzipdir}
    return 0
}

deploy_package() {

  bash "${SCRIPT_PATH}"/deploy_build.sh ${package}

  if [ $? -ne 0 ]; then
      echo "[-] Error: Build file(s) deployment failed." >&2
      return 1
  fi

  echo "[+] Deployment complete."
  return 0
}

rollback_package() {

  bash "${SCRIPT_PATH}"/rollback_build.sh ${package}

  if [ $? -ne 0 ]; then
      echo "[-] Error: Build file(s) rollback failed." >&2
      return 1
  fi

  echo "[+] Rollback complete."
  return 0
}


# Program starts here
# Capture the script parameter
job=$1
package=$2

if [ -z "${job}" ] || [ -z "${package}" ]; then
  echo "[-] Error: Invalid paramters." >&2
  exit 1
fi

# Download the package
download_package

if [ $? -ne 0 ]; then
  echo "[-] Error: ${0##*/} failed." >&2
  exit 1
fi

unzipped_package=${DOD_PATH}/${package}

# Unzip the package
unzip_package

if [ $? -ne 0 ]; then
  echo "[-] Error: ${0##*/} failed." >&2
  exit 1
fi

# Deploy or rollback
case $job in
  deploy)
    deploy_package

    if [ $? -ne 0 ]; then
      echo "[-] Error: ${0##*/} failed." >&2
      exit 1
    fi
    ;;
  rollback)
    rollback_package

    if [ $? -ne 0 ]; then
      echo "[-] Error: ${0##*/} failed." >&2
      exit 1
    fi
    ;;
esac

# Remove unzipped package
echo "[+] Removing unzipped package."

rm -rf "${unzipped_package}"

if [ $? -ne 0 ]; then
  echo "[-] Failed to remove ${unzipped_package}" >&2
  exit 1
fi


echo "[+] ${0##*/} complete."
exit 0
