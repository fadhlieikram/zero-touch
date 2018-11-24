#########################################################################
###   This program restores/delete build application file(s)          ###
###   if deployed and delete any created directory                    ###
#########################################################################
#!/bin/bash
source /tmp/rundeck_tmp/enotice/sg/envar.sh

# Initialize global variable
declare -a param_arr
entry_file=
dodnumber=
backupdir=

set_build_var_array() {
  # Get all variables with name starts with BUILD_PATH
  local paramlist=`echo ${!BUILD_PATH*}`
  local sortedlist=
  local tmpfile=lst2.tmp

  for a in ${paramlist}; do
    echo "${a}" >> ${tmpfile}
  done

  sortedlist=$(sort -t_ -k3n ${tmpfile})
  
  if [ -f ${tmpfile} ]; then
    rm ${tmpfile}
  fi
  
  # Iterate the list and get only variable ends with _SOURCE
  index=0
  for p in ${sortedlist}; do
    if [ ! -z "$p" ] && [[ "$p" = *_SOURCE ]]; then
      param_arr[index]="$p"
      index=$[index+1]
    fi
  done
}

restore_file() {
  local filetorestore=$1
  local bkdir="${backupdir}"
  local bkfile=
  
  if [ -z ${filetorestore} ]; then
    echo '[-] Error: Required parameter(s) not set.' >&2
    exit 1
  fi
  
  local fname=$(basename "${filetorestore}")
  bkfile="${bkdir}/${fname}"

  echo "[+] Restoring file:${filetorestore}"

  if [ ! -f "${bkfile}" ]; then
    echo "[-] Warning: Backup file doesn't exist. File:${bkfile}"
    echo "[-] Warning: Deleting file:${filetorestore}"
    
    rm ${filetorestore}
    
    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to delete file." >&2
      return 1
    fi 
  
  else
    
    cp -p ${bkfile} ${filetorestore}
    
    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to restore file." >&2
      return 1
    fi
    
    if [ ! -f ${filetorestore} ]; then
      echo "[-] Error: Attempt to restore file (${bkfile}) to (${filetorestore}) failed." >&2
      return 1
    fi
  fi

  return 0
}

delete_dir() {
  local reventry=
   
   echo "[+] Deleting created application directory(s)."
   
  if [ ! -f "${entry_file}" ]; then
    echo "[+] Directory creation entry file doesn't exist. No directory(s) to be deleted."
    return 0
  fi
  
  # Reverse order of file content
  reventry="${entry_file}_rev"
  tac ${entry_file} > ${reventry}
  
  while read -r dir; do
    echo "[+] Deleting directory:${dir}"

    rmdir "${dir}"

    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to delete directory." >&2
      return 1
    fi

  done < ${reventry}

  echo "[+] Deleting entry file:${entry_file}"

  rm "${entry_file}"
  rm "${reventry}"

  return 0
}

delete_backup_dir() {
  local bkdir="${backupdir}"
  
  echo "[+] Deleting backup directory:${bkdir}"
  
  # Remove dir and its content
  rm -rf "${bkdir}"
  if [ $? -ne 0 ]; then
    echo "[-] Error: Unable to delete directory." >&2
    return 1
  fi
  
  return 0
}


# Start
# Check if parameter is passed
if [ -z $1 ]; then
  echo "[-] Error: Please provide the dod number." >&2
  exit 1
fi

dodnumber=$1

# Check if dod path exist
dodpath=${DOD_PATH}/${dodnumber}

if [ ! -d ${dodpath} ]; then
  echo "[-] Error: Dod path doesn't exist. Path:${dodpath}" >&2
  exit 1
fi

echo "[+] Dod directory found:${dodpath}."

set_build_var_array

backupdir=${BACKUP_PATH}/${dodnumber}_bak

# Check if backup directory exist.
if [ ! -d "${backupdir}" ]; then
  # Abort deployment if backup directory does not exist, as deployment hasn't been conducted.
  echo "[-] Error: Backup directory does not found indicates package hasn't been deployed." >&2
  echo "[-] Error: Aborting rollback." >&2
  exit 1
fi

entry_file="${backupdir}/dir_entry"

# Iterate every nonbuild source path
for arr in "${param_arr[@]}"; do

  var_source=${arr}
  var_target=`echo ${arr} | sed s/SOURCE/TARGET/g`

  # Find file in source path
  dodsourcepath="${dodpath}${!var_source}"
  # Skip if path not exist
  if [ ! -d "${dodsourcepath}" ]; then
    break
  fi
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
delete_dir

#Delete backup directory
delete_backup_dir

if [ $? -ne 0 ]; then
  echo "[-] Application file(s) rollback failed!" >&2
  exit 1
fi

echo "[+] Application file(s) rollback complete."
exit 0
