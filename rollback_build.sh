#!/bin/bash

source props.properties

# Initialize global variable
declare -a PARAM_ARR
ENTRY_FILE=
dodnumber=

set_build_var_array() {
  # Get all variables with name starts with NONBUILD_PATH
  PARAMLIST=`echo ${!BUILD_PATH*}`
  
  # Iterate the list and get only variable ends with _SOURCE
  index=0
  for p in ${PARAMLIST}; do
    if [ ! -z "$p" ] && [[ "$p" = *_SOURCE ]]; then
      PARAM_ARR[index]="$p"
      index=$[index+1]
    fi
  done
}

restore_file() {
  local filetorestore=$1
  local dodnum=${dodnumber}
  local backupfile=${filetorestore}_${dodnumber}

  echo "[+] Restoring file (${backupfile}) to (${filetorestore})"

  if [ ! -f "${backupfile}" ]; then
    echo "[-] Warning: Backup file doesn't exist."
    echo "[-] Warning: Deleting file:${filetorestore}"

    rm ${filetorestore}

    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to delete file." >&2
      return 1
    fi 
  
  else
    ./copy_file.sh ${backupfile} ${filetorestore}
    
    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to restore file." >&2
      return 1
    fi 
  fi

  return 0
}

delete_dir() {

  if [ ! -f "${ENTRY_FILE}" ]; then
    echo "Directory creation entry file doesn't exist!:${ENTRY_FILE}"
    return 1
  fi
  
  while read -r dir; do
    echo "[+] Deleting directory:${dir}"

    rmdir "${dir}"

    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to delete directory." >&2
      return 1
    fi

  done <<< $(tac "${ENTRY_FILE}")

  echo "[+] Deleting entry file:${ENTRY_FILE}"

  rm "${ENTRY_FILE}"

  return 0
}


# Start
# Check if parameter is passed
if [ -z $1 ]; then
  echo "[-] Error: Please provide the dod number." >&2
  exit 1
fi

dodnumber=$1
ENTRY_FILE="${DIR_ENTRY_PATH}_${dodnumber}"

# Check if dod path exist
dodpath=${DOD_PATH}/${dodnumber}

if [ ! -d ${dodpath} ]; then
  echo "[-] Error: Dod path doesn't exist. Path:${dodpath}" >&2
  exit 1
fi

echo "[+] Dod directory found:${dodpath}."

set_build_var_array

# Iterate every nonbuild source path
for arr in "${PARAM_ARR[@]}"; do

  var_source=${arr}
  var_target=`echo ${arr} | sed s/SOURCE/TARGET/g`

  # Find file in source path
  dodsourcepath="${dodpath}${!var_source}"
  files=$(find "${dodsourcepath}" -type f)

  if [ -z "${files}" ]; then
    echo "[-] Warning: Source path is empty. Path:${!var_source}"
    break
  fi

  for file in ${files}; do
    filename=$(basename "${file}")
    targetfile="${!var_target}/${filename}"

    echo "[+] Deployed file found:${file}"
 
    restore_file ${targetfile}
    
    if [ $? -ne 0 ]; then
       echo "[-] File rollback failed." >&2
       exit 1
    fi
  done
done

#Delete any created directories
echo "[+] Deleting created directory(s)."
delete_dir

if [ $? -ne 0 ]; then
  echo "[-] Application file(s) rollback failed!" >&2
  exit 1
fi

echo "[+] Application file(s) rollback complete."
exit 0
