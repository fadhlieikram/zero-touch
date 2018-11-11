#!/bin/bash

#declare an array that holds all variables
declare -a build_var_array
declare -a nonbuild_var_array


while IFS='' read -r line; do
  if [ ! -z "$line" ] && [[ "$line" != \#* ]] && [[ "$line" != "" ]]; then
    echo "$line" | sed 's/=/="/g;s/$/"/g' >> $0.tmp
  fi
done < props.properties

chmod 775 $0.tmp 
source $0.tmp && rm $0.tmp

echo ${!dod*}
