#!/bin/bash

source props.properties

# Initialize global variable
declare -a PARAM_ARR
dodnumber=

create_app_dir(){
  # Get all variables with name starts with APP_PATH*
  local PARAMLIST=`echo ${!APP_PATH*}`
  local SORTEDLIST=
  local tmpfile=lst1.tmp

  for a in ${PARAMLIST}; do
    echo "${a}" >> ${tmpfile}
  done

  SORTEDLIST=$(sort -t_ -k3n ${tmpfile})
  
  if [ -f ${tmpfile} ]; then
    rm ${tmpfile}
  fi
  
  # Iterate the list and create dir if doesn't exist
  for p in ${SORTEDLIST}; do
    if [[ "${p}" = *_TARGET ]] && [ ! -d "${!p}" ]; then
      
      echo "[+] Creating application directory:${!p}"
        ./make_dir.sh "${!p}"
        
        if [ $? -ne 0 ]; then
          echo "[-] Error: Unable to create dir." >&2
          return 1
        fi
    fi
  done
}

set_build_var_array() {
  # Get all variables with name starts with BUILD_PATH
  local PARAMLIST=`echo ${!BUILD_PATH*}`
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

backup_file() {
  local filetobackup=$1
  local dodnum=${dodnumber}
  local newfile=${filetobackup}_${dodnumber}

  if [ -z ${filetobackup} ] || [ -z ${newfile} ]; then
    echo '[-] Error: Required parameter(s) not set.' >&2
    exit 1
  fi

  echo "[+] Performing file backup (${filetobackup}) to (${newfile})"

  if [ -f "${newfile}" ]; then
    echo "[-] Error: Backup file has already exist. File:${newfile}" >&2
    return 1
  fi

  cp -p ${filetobackup} ${newfile}

  if [ $? -ne 0 ]; then
    echo "[-] Error: Unable to backup file (${filetobackup})." >&2
    return 1
  fi
  
  if [ ! -f  "${newfile}" ]; then
    echo "[-] Error: Attempt to create backup file (${newfile}) failed." >&2
    return 1
  fi

  return 0
}

deploy_file() {
  local source=$1
  local target=$2

  echo "[+] Deploying file (${source}) to (${target})."

  # Create dir if doesnt exist
  local target_dir=$(dirname "${target}")

  if [ ! -z  "${target_dir}" ] && [ ! -d  "${target_dir}" ] ;then

    echo "[+] Creating new dir:${target_dir}"
    ./make_dir.sh "${target_dir}"

    if [ $? -ne 0 ]; then
      echo "[-] Error: Failed to create dir:${target_dir}"
      return 1
    fi

    chmod ${NONBUILD_CHMOD} "${target_dir}"
  fi
  
  cp -p ${source} ${target}

  if [ $? -ne 0 ]; then
    echo "[-] Error: Unable to copy file:${source}" >&2
    return 1
  fi
  
  if [ ! -f ${target} ]; then
    echo "[-] Error: Attempt to copy file (${source}) to (${target}) failed." >&2
    return 1
  fi

  chmod ${NONBUILD_CHMOD} ${target}
  echo "[+] File deployed. File:${target}"
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

create_app_dir

if [ $? -ne 0 ]; then
  echo "[-] App dir creation failed." >&2
  exit 1
fi


set_build_var_array

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
    echo "[+] File found:${file}"
    sourcefile="${file}"
    filename=$(basename "${file}")
    targetfile="${!var_target}/${filename}"

    # Check if file exist in target directory, and do backup
    if [ -f  "${targetfile}" ]; then
      # If file exist in target dir, do backup first, then copy and replace file
      
      backup_file $targetfile

      if [ $? -ne 0 ]; then
         echo "[-] File backup failed." >&2
         exit 1
      fi
    fi

    deploy_file ${sourcefile} ${targetfile}
    
    if [ $? -ne 0 ]; then
       echo "[-] File deployment failed." >&2
       exit 1
    fi
  done
done

echo "[+] Application file(s) deployment complete."
exit 0
