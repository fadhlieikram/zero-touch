#!/bin/bash

./props_parser.sh

# Initialize global variable
dodnumber=

rollback_file() {
    local source=$1
    local target=$2
    
    ./deploy_file.sh ${source} ${target}

    if [ $? -ne 0 ]; then
      echo "[-] Error: Failed to rollback (${source})." >&2
      return 1
    fi

    echo "[+] File (${source}) rollback complete."
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

# Check if jar file(s) exist in source dir.
# We need to know what has been deployed and need to rollback.
jar_files=$(find ${dodpath} -name ${jar_path_source})

if [ -z ${jar_files} ]; then
  echo "[-] Error: Jar source (${dodpath}) is empty. Rollback failed." >&2
  exit 1
fi

# Iterate over file found in source
for file in $jar_files; do
  echo "[+] Found file(s) ${file}"
  
  sourcefile=${file}
  targetfilename=$(basename ${sourcefile})
  overwritefile=${jar_path_target}/${targetfilename}
  backupfile=${jar_path_target}/${targetfilename}_${dodnumber}

  # Check if backup file exist in target dir
  if [ -f  ${backupfile} ]; then
    # If backup file exist in target dir, proceed with file rollback
    echo "[+] Backup file (${targetfile}) found."


  else
    # If file doesn't exist in target dir, terminate
    echo "[-] Error: File (${targetfile}) doesn't exist." >&2

    deploy_file ${sourcefile} ${targetfile}

    if [ $? -ne 0 ]; then
       echo "[-} Deployment failed for file (${sourcefile})" >&2
       exit 1
    fi

  fi

echo "[+] Jar deployment complete."
exit 0

done
