#!/bin/bash

./props_parser.sh

# Initialize global variable
dodnumber=

backup_file() {
    local filetobackup=$1
    local dodnum=${dodnumber}

    ./backup_file.sh ${filetobackup} ${filetobackup}_${dodnumber}
    
    if [ $? -ne 0 ]; then
      echo "[-] Error: Unable to backup file (${filetobackup})." >&2
      return 1
    fi

    echo "[+] Back up file (${filetobackup}) complete."
    return 0
}

deploy_file() {
    local source=$1
    local target=$2
    
    ./deploy_file.sh ${source} ${target}

    if [ $? -ne 0 ]; then
      echo "[-] Error: Failed to deploy (${source})." >&2
      return 1
    fi

    chmod ${jar_chmod} ${target}
    echo "[+] File (${source}) deployed."
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
dodpath=${dod_path}/${dodnumber}/

if [ ! -d ${dodpath} ]; then
  echo "[-] Error: Dod path (${dodpath}) doesn't exist." >&2
  exit 1
fi

echo "[+] Checking file(s) in ${dodpath}"

# Check if jar file(s) exist in source dir
jar_files=$(find ${dodpath} -name ${jar_path_source})

if [ -z ${jar_files} ]; then
  echo "[-] Error: Jar source (${dodpath}) is empty." >&2
  exit 1
fi

# Iterate over file found in source
for file in $jar_files; do
  echo "[+] Found file(s) ${file}"
  
  sourcefile=${file}
  targetfilename=$(basename ${sourcefile})
  targetfile=${jar_path_target}/${targetfilename}

  # Check if file exist in target dir
  if [ -f  ${targetfile} ]; then
    # If file exist in target dir, do backup first, then copy and replace file
    echo "[+] Backup existing file (${targetfile})."
    
    backup_file $targetfile

    if [ $? -ne 0 ]; then
       echo "[-] Backup failed for file (${targetfile})" >&2
       exit 1
    fi

    deploy_file ${sourcefile} ${targetfile}

    if [ $? -ne 0 ]; then
       echo "[-} Deployment failed for file (${sourcefile})" >&2
       exit 1
    fi
  
  else
    # If file is new and doesn't exist in target dir, deploy
    echo "[+] File (${sourcefile}) is new."

    deploy_file ${sourcefile} ${targetfile}

    if [ $? -ne 0 ]; then
       echo "[-} Deployment failed for file (${sourcefile})" >&2
       exit 1
    fi

  fi

echo "[+] Jar deployment complete."
exit 0

done
