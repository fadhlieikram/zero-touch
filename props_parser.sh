#!/bin/bash

sed -e 's/=/="/g;s/$/"/g' props.txt >> $0.tmp

chmod 755 $0.tmp
source $0.tmp && rm $0.tmp

echo $jar_path_source
echo $dod_path
