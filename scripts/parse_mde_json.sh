#!/bin/bash

##########################################################################################
#Script Name	: parse_mde_json.sh
#Description	: Parse Microsoft MDE real-time-protection statistics file
#Author       	: Jacob Pszonowsky
#Location     	: https://github.com/jakepez/utilities/blob/main/scripts/parse_mde_json.sh                                      
#                 Copyright (c) 2021
##########################################################################################

DEBUG_LOG=0
function debug() { ((DEBUG_LOG)) && echo "### $*"; }

function error() { printf '%s\n' "Error: $*"; exit 1; }
function help() { 
    printf '%s\n' "Parse MDE real-time-protection statistics"
    printf '%s\n' "Usage: $0 [options]"
    printf '%s\n' "  -f --file [name] : required"
    printf '%s\n' "  -c --csv [name] : required"
    printf '%s\n' "  -d --debug"
    printf '%s\n' "  -h --help"
    printf '%s\n' " "
    printf '%s\n' " Enable Real-time Protection Statistics:"
    printf '%s\n' "   Terminal (sudo/root)"
    printf '%s\n' "   mdatp config real-time-protection-statistics –-value enabled"
    printf '%s\n' " Note:  In Production channel"
    printf '%s\n' " Note 2:  Not needed in Dogfood and InsidersFast channels since its enabled by default."
    printf '%s\n' " "
    printf '%s\n' " Create JSON file:"
    printf '%s\n' "   mdatp diagnostic real-time-protection-statistics –output json > real_time_protection_logs"
    printf '%s\n' " "
    printf '%s\n' " Disable real-time-protection-statistics:"
    printf '%s\n' "   mdatp config real-time-protection-statistics –-value disabled"
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -f|--file)
      FILE="$2"
      shift # past argument
      shift # past value
      ;;
    -c|--csv)
      CSVFILE="$2"
      shift # past argument
      shift # past value
      ;;
    -d|--debug)
      DEBUG_LOG=1
      shift # past argument
      shift # past value
      ;;
    -h|--help)
      help ""
      exit 0
      ;;
    *)    # unknown option
      POSITIONAL+=("$1") # save it in an array for later
      shift # past argument
      ;;
esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if ! [ "$FILE" ]; then
    help
    error $(printf '%s\n' "-f required")
elif ! [ -a "$FILE" ]; then
    error $(printf '%s\n' "$FILE does not exist")
elif ! [ "$CSVFILE" ]; then
    help
    error $(printf '%s\n' "-c required")
fi
debug "$FILE"

CNT=0
RECORD=0

# print CSV file header
printf '%s\n' "ID,Process ID,Name,Path,Total files scanned,Scan time (ns),Status" > $CSVFILE

declare -a STATS
LINECNT=0

while IFS= read -r line; do
    #echo "$CNT : $RECORD"
    #debug "$line"
    if [ "$line" != "=====================================" ]; then 
        ((CNT++))
                debug "Count: $CNT Line: $line"
        case $CNT in
            1)
                ((RECORD++))
                ((LINECNT++))
                STATS[$CNT]=$(echo "$line" | cut -d ":" -f 2 | sed 's/^ *//g')
                ;;
            [2-6])
                STATS[$CNT]=$(echo "$line" | cut -d ":" -f 2 | sed 's/^ *//g')
                #PROCID=$(echo "$line" | cut -d ":" -f 2 | sed 's/^ *//g')
                ;;
            7)
                #CNT=0
                #printf '%s\n' "$RECORD,$PROCID,$NAME,$PROCPATH,$SCAN,$TIME,$STATUS" >> $CSVFILE
                ;;
            *)
                error "Count is off / empty"
                exit 1
                ;;
         esac
    fi
    if [ "$CNT" == "6" ]; then
        #printf '%s\n' "$RECORD,$PROCID,$NAME,$PROCPATH,$SCAN,$TIME,$STATUS" >> $CSVFILE
        printf '%s\n' "$RECORD,${STATS[1]},${STATS[2]},${STATS[3]},${STATS[4]},${STATS[5]},${STATS[6]}" >> $CSVFILE
        unset STATS
        CNT=0
    fi
    if [ "$LINECNT" == "100" ]; then
        printf '%s\n' "$RECORD records processed..."
        LINECNT=0
    fi
    

    #echo "Text read from file: $line"
done < "$FILE"
printf '%s\n' "$FILE : $RECORD records processed"

