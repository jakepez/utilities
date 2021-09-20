#!/bin/bash
## The first part filters the XML file on Apple's Update Server that iTunes checks with when looking for iOS and iPod software updates, filtering and displaying only the URLs and saving them to a text file in /var/tmp/firmwhere.txt

DEBUG_LOG=0
function debug() { ((DEBUG_LOG)) && echo "### $*"; }

function error() { printf '%s\n' "Error: $*"; exit 1; }
function help() { 
    printf '%s\n' "Check for iOS $VER"
    printf '%s\n' "Usage: $0 [options]"
    printf '%s\n' "  -v --version [#.#] : required"
    printf '%s\n' "  -d --debug"
    printf '%s\n' "  -h --help"
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -v|--version)
      VER="$2"
      VERCHECK=$(echo "$VER" |sed "s/\./\\\./g")
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

if ! [ "$VER" ]; then
    help
    error $(printf '%s\n' "-v required")
fi

CHECK=$(curl -s http://ax.phobos.apple.com.edgesuite.net/WebObjects/MZStore.woa/wa/com.apple.jingle.appserver.client.MZITunesClientCheck/version | grep ipsw | grep -v protected | grep -v Recovery | sort -u | sed 's/<string>//g' | awk '{$1=$1}1' | sed 's/<\/string>//g' |grep -i ipsw|grep -i "$VERCHECK")
CHECKSTATUS=$?

debug "$CHECK"
debug "$CHECKSTATUS"

if [ $CHECKSTATUS = "1" ]; then
    echo "iOS $VER not available"
else
    echo "iOS $VER available"
    afplay /System/Library/Sounds/Ping.aiff
fi


## If necessary, you can download *all* available software updates by uncommenting the command below. Make sure to change directory to the one you want to download to first or edit the command appropriately. It will just loop through the text file and using cURL, will download all iOS and iPod software updates. 

##If you have wget installed, uncomment the second line instead to use wget and it will skip any updates downloaded.  Again, change directory to the one you want to download to or edit the command. 

## Using cURL
## for i in `cat /var/tmp/firmwhere.txt`; do curl -O $i; done

## Using wget
## wget -m -nd -i /var/tmp/firmwhere.txt
