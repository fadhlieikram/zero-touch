#########################################################################
###     This program sets db instance, finds and runs rollback        ###
###     script from the dod package.                                  ###
#########################################################################
#!/bin/bash

source props.properties

# Initialize global variable
declare -a param_arr
dodnumber=

set_sql_var_array() {
  # Get all variables with name starts with SQL_SCRIPT_
  local paramlist=`echo ${!SQL_SCRIPT_*}`
  local sortedlist=
  local tmpfile=lst2.tmp

  # Place all variables in a temporary file to be sorted
  for a in ${paramlist}; do
    echo "${a}" >> ${tmpfile}
  done

  #Sort the variable at 'column' 3 based on '_' as delimeter
  sortedlist=$(sort -t_ -k3n ${tmpfile})
  
  # Remove temporary file
  if [ -f ${tmpfile} ]; then
    rm ${tmpfile}
  fi
  
  # Iterate the list and get only variable ends with *_PATH
  local index=0
  for p in ${sortedlist}; do
    if [ ! -z "$p" ] && [[ "$p" = *_PATH ]]; then
      param_arr[index]="$p"
      index=$[index+1]
    fi
  done
}


# Program starts here
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

set_sql_var_array

# Iterate every source path
for arr in "${param_arr[@]}"; do

  var_source=${arr}
  var_instance=`echo ${arr} | sed s/PATH/INST/g`
  dbinst=${!var_instance}
  
  echo "[+] Set db instance:${dbinst}"

  # Find file(s) in source path
  dodsourcepath="${dodpath}${!var_source}"
  files=$(find "${dodsourcepath}" -type f -prune)

  if [ -z "${files}" ]; then
    echo "[-] Warning: Source path is empty. Path:${!var_source}"
    break
  fi
  
  # Remove file ends with _DEPLOY.sql
  tmpfile=sql.tmp
  for f in ${files}; do
    if [[ "${f}" = *_ROLLBACK.sql ]]; then
      echo "${f}" >> ${tmpfile}
    fi
  done

  # Sort the sequence at 'column' 2 and 3 based on '_' as delimeter.
  # File with name *_(n)_DDL_DEPLOY.sql preceeds *_(n)_DML_DEPLOY.sql
  # (n) is a non negative numerical value sorted ascending from 1 .. n
  sortedlist=$(sort -t_ -k3,3 -k2n,2 ${tmpfile})
  
  rm ${tmpfile}

  # Iterate every found script and execute
  for file in ${sortedlist}; do
    filename=$(basename ${file})
    echo "[+] Executing script:${filename}"
    sourcefile="${file}"
    
    eval "${dbinst}"
    eval "db2 -tvf ${file}"
    
    if [ $? -ne 0 ]; then
       echo "[-] Sql execution has failed." >&2
       exit 1
    fi
  done
done

echo "[+] Sql deployment complete."
exit 0
