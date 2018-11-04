#!/bin/bash

# Usage info
show_help() {
  echo ""
  cat << EOF
Usage: ${0##*/} [command] [type] [-p <package>]
Auto deployment script for batch application. Takes command and type with <package> code.

command:
  deploy      Runs file deployment based on [type] and <packgae number>.
  rollback    Rollback changes made based on [type] and <package number>.

type:
  build       application jar file.
  nonbuild    other non-build application file(s).
  sql         sql scripts.

Example:./midas.sh deploy build -p 653721

EOF
}

# Initialize global variable.
command=
type=
package=

# Set log
logpath=$(pwd)
log="${logpath}/${0##*/}.log"

# Assigning passed in parameters.
while :; do

  case $1 in
    deploy|rollback)
      command=$1
      ;;
    build|nonbuild|sql)
      type=$1
      ;;
    -p)
      if [ "$2" ]; then
        invalid=
        case $2 in
          '' | *[!0-9]*) # Invalid digit
            invalid=1
        esac
        if [ ${#2} -ne 6 ] || [ "$invalid" ]; then
          echo '[-] Error: Package must be 6 digits of integer.' >&2
          exit 1
        fi
        package=$2
        shift
      else
        echo '[-] Error: "-p" requires a non-empty option argument.' >&2
        exit 1
      fi
      ;;
    --help|-\?)
      show_help
      exit 0
      ;;
    *)
      break
  esac

  shift
done

# Check if all variables are assigned
if [ -z ${command} ] || [ -z ${type} ] || [ -z ${package} ]; then
  echo '[-] Error: Missing required parameter(s).' >&2
  exit 1
fi

echo "[+] Starting script..." | tee -a ${log}
echo "[+] Log path: ${log}" | tee -a ${log} 
echo "[+] Command received: ${0##*/} ${command} ${type} -p ${package}" | tee -a ${log}

# Start chain of job
case $command in
  deploy)
    case $type in
      build)
        echo "[+] Run deploy_build ${package}" | tee -a ${log}
        ;;
      nonbuild)
        echo "[+] Run deploy_nonbuild ${package}" | tee -a ${log}
        ;;
      sql)
        echo "[+] Run deploy_sql ${package}" | tee -a ${log}
        ;;
    esac
  ;;
  rollback)
    case $type in
      build)
        echo "[+] Run rollback_build ${package}" | tee -a ${log}
        ;;
      nonbuild)
        echo "[+] Run rollback_nonbuild ${package}" | tee -a ${log}
        ;;
      sql)
        echo "[+] Run rollback_sql ${package}" | tee -a ${log}
        ;;
    esac
esac
