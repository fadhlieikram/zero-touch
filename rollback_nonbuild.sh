#!/bin/bash

source props.properties

# Initialize global variable
declare -a PARAM_ARR
ENTRY_FILE=
dodnumber=

set_nonbuild_var_array() {
  # Get all variables with name starts with NONBUILD_PATH
  local PARAMLIST=`echo ${!NONBUILD_PATH*}`
  local SORTEDLIST=
  local tmpfile=lst2.tmp

  for a in ${PARAMLIST}; do
    echo "${a}" >> ${tmpfile}
  done

  SORTEDLIST=$(sort -t_ -k3n ${tmpfile})
  
  if [ -f ${tmpfile} ]; then
    rm ${tmpfile}
  fi
  
  # Iterate the list and get only variable ends with _SOURCE
  index=0
  for p in ${SORTEDLIST}; do
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
  
  if [ -z ${filetorestore} ] || [ -z ${backupfile} ]; then
    echo '[-] Error: Required parameter(s) not set.' >&2
    exit 1
  fi

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
    
    cp -p ${backupfile} ${filetorestore}
    
    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to restore file." >&2
      return 1
    fi
    
    if [ ! -f ${filetorestore} ]; then
      echo "[-] Error: Attempt to restore file (${backupfile}) to (${filetorestore}) failed." >&2
      return 1
    fi
  fi

  return 0
}

delete_dir() {
  local reventry=

  if [ ! -f "${ENTRY_FILE}" ]; then
    echo "[+] Directory creation entry file doesn't exist. No directory to be deleted."
    return 0
  fi
  
  # Reverse order of file content
  reventry="${ENTRY_FILE}_rev"
  tac ${ENTRY_FILE} > ${reventry}
  
  while read -r dir; do
    echo "[+] Deleting directory:${dir}"

    rmdir "${dir}"

    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to delete directory." >&2
      return 1
    fi

  done < ${reventry}

  echo "[+] Deleting entry file:${ENTRY_FILE}"

  rm "${ENTRY_FILE}"
  rm "${reventry}"

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
export ENTRY_FILE

# Check if dod path exist
dodpath=${DOD_PATH}/${dodnumber}

if [ ! -d ${dodpath} ]; then
  echo "[-] Error: Dod path doesn't exist. Path:${dodpath}" >&2
  exit 1
fi

echo "[+] Dod directory found:${dodpath}."

set_nonbuild_var_array

# Iterate every nonbuild source path
for arr in "${PARAM_ARR[@]}"; do

  var_source=${arr}
  var_target=`echo ${arr} | sed s/SOURCE/TARGET/g`

  # Find file in source path
  dodsourcepath="${dodpath}${!var_source}"
  files=$(find "${dodsourcepath}" -type f -prune)

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
