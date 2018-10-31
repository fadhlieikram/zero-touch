#!/bin/sh

# Usage info
show_help() {
    cat << EOF
Usage: ${0##*/} [command] [type] <package> <ccode>
Auto deployment script for batch application. Takes command with type, <package>
and <ccode>.

command:
  deploy      Runs file deployment based on [type] and <packgae number>.
  rollback    Rollback changes made based on [type] and <package number>.

type:
  build       application jar file.
  nonbuild    other non-build application file(s).
  sql         sql scripts.

<package>     6 digits of integer number of delivery package.
<ccode>       2 characters representation of country code.
EOF
}

# Initialize global variable.
command=
type=
package=
country=

# Set log
logpath=$(pwd)
log="${logpath}/${0##*/}.log"

# Assigning passed in parameters.
while :; do

  case $1 in
    deploy|rollback)
      command=$1
      ;;
    --help|-\?|*)
      show_help
      exit
      ;;
  esac

  case $2 in
    build|nonbuild|sql)
      type=$2
      ;;
    *)
      show_help
      exit
      ;;
  esac

  if [ -z $3 || ${#3} != 6 ]; then
    show_help
    exit
  fi
  
  package=$3

  if [ -z $4 || ${#4} != 2 ]; then
    show_help
    exit
  fi

  country=$4
done

echo "[+] Starting script..." | tee -a ${log}
echo "[+] Log path: ${log}" | tee -a ${log} 
echo "[+] Command received: ${0##*/} ${command} ${type} ${package} ${country}" | tee -a ${log}

# Start chain of job
case $command in
  deploy)
    case $type in
      build)
        echo "[+] Command received: Run deploy_build ${package}" | tee -a ${log}
        ;;
      nonbuild)
        echo "[+] Command received: Run deploy_nonbuild ${package}" | tee -a ${log}
        ;;
      sql)
        echo "[+] Command received: Run deploy_sql ${package}" | tee -a ${log}
        ;;
    esac
  ;;
  rollback)
    case $type in
      build)
        echo "[+] Command received: Run rollback_build ${package}" | tee -a ${log}
        ;;
      nonbuild)
        echo "[+] Command received: Run rollback_nonbuild ${package}" | tee -a ${log}
        ;;
      sql)
        echo "[+] Command received: Run rollback_sql ${package}" | tee -a ${log}
        ;;
    esac
esac