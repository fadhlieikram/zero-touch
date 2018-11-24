#!/bin/bash
source /tmp/rundeck_tmp/enotice/sg/envar.sh

# Initialize variable
logpath="${LOG_PATH}"
log=

##########################################
# Usage info
##########################################
show_help()
{
echo ""
cat << EOF
Usage: ${0##*/} [command] [type] <dod>
Auto deployment script for batch application. Takes command with type, and <package>.

command:
  deploy      Runs file deployment based on [type] and <package number>.
  rollback    Rollback changes made based on [type] and <package number>.

type:
  build       application jar file.
  nonbuild    other non-build application file(s).
  sql         sql scripts.

EOF
}

##########################################
# Validating and assigning input parameters
##########################################

if [[ $1 = --help ]]; then
  show_help
  exit 1
elif [ $# -ne 3 ]; then
  show_help
  exit 1
fi

# Assigning passed in parameters.
if [[ -z "${3}" ]]; then
  echo "[-] Invalid package format: zero" | tee -a ${log}
  show_help
  exit 1
fi

if [[ ${#3} -ne 6 ]]; then
  echo "[-] Invalid package format: not 6" | tee -a ${log}
  echo ""
  show_help
  exit 1
fi

command=$1
type=$2
dod_no=$3

##########################################
# Creating log file
##########################################
if [ ! -d "${logpath}" ];then
  echo "mkdir -p ${logpath}"
  mkdir -p ${logpath}
  
  echo "chmod -R 755 ${logpath}"
  chmod -R 755 ${logpath}
fi
log="${logpath}/${command}_${type}.log"
############################################
# Available jobs
############################################

#### deploy build #####
deploy_build() {
  bash "${SCRIPT_PATH}"/build_job.sh deploy ${dod_no}
  
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  return 0
}

#### deploy nonbuild #####
deploy_nonbuild() {
  bash "${SCRIPT_PATH}"/nonbuild_job.sh deploy ${dod_no}
  
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  return 0
}

### deploy sql #####
deploy_sql() {
  bash "${SCRIPT_PATH}"/sql_job.sh deploy ${dod_no}
  
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  return 0
}

#### rollback build #####
rollback_build() {
#Rollback jar
  bash "${SCRIPT_PATH}"/build_job.sh rollback ${dod_no}
  
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  return 0
}

### rollback nonbuild #####
rollback_nonbuild() {
  bash "${SCRIPT_PATH}"/nonbuild_job.sh rollback ${dod_no}
  
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  return 0
}

#### rollback sql #####
rollback_sql() {
  bash "${SCRIPT_PATH}"/sql_job.sh rollback ${dod_no}
  
  if [ $? -ne 0 ]; then
    return 1
  fi
  
  return 0
}

#################################
# Start the deploy/rollback job
#################################

echo "[+] Start to run [${command}] [${type}] with package ${dod_no}." > ${log}
echo "[+] Log path: ${log}" | tee -a ${log}

case ${command} in
  deploy)
    case ${type} in
      build)
        echo "[+] Execute deploy_build ${package}" | tee -a ${log}
        deploy_build | tee -a ${log} 2>&1
        ;;
      nonbuild)
        echo "[+] Execute deploy_nonbuild ${package}" | tee -a ${log}
        deploy_nonbuild | tee -a ${log} 2>&1
        ;;
      sql)
        echo "[+] Execute deploy_sql ${package}" | tee -a ${log}
        deploy_sql | tee -a ${log} 2>&1
        ;;
    esac
    ;;
  rollback)
    case ${type} in
      build)
        echo "[+] Execute rollback_build ${package}" | tee -a ${log}
        rollback_build | tee -a ${log} 2>&1
        ;;
      nonbuild)
        echo "[+] Execute rollback_nonbuild ${package}" | tee -a ${log}
        rollback_nonbuild | tee -a ${log} 2>&1
        ;;
      sql)
        echo "[+] Execute rollback_sql ${package}" | tee -a ${log}
        rollback_sql | tee -a ${log} 2>&1
        ;;
    esac
    ;;
esac

# Use bash PIPESTATUS to catch rollback/deply return code to avoid 
# getting 'tee' success return code
if [ ${PIPESTATUS[0]} -ne 0 ]; then
  echo "[-] Job failed." | tee -a ${log}
  gzip -c ${log} > ${log}_`date '+%y%m%d%H%M%S'`.gz
  rm ${log}
  exit 1
fi

echo "[+] Job completed." | tee -a ${log}
gzip -c ${log} > ${log}_`date '+%y%m%d%H%M%S'`.gz
rm ${log}
exit 0