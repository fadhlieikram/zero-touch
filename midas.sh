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

echo "[+] Starting script..." >> ${log}
echo "[+] Log path: ${log}" 

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

echo "[+] Command received: ${0##*/} ${1} ${2} ${3} ${4}" >> ${log}

# Start chain of job
case $command in
  deploy)
    case $type in
      build)
        ;;
      nonbuild)
        ;;
      sql)
        ;;
    esac
  ;;
  rollback)
    case $type in
      build)
        ;;
      nonbuild)
        ;;
      sql)
        ;;
    esac
esac