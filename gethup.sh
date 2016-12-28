#!/bin/bash
# Usage:
# bash /path/to/eth-utils/gethup.sh <datadir> <instance_name> <base_port=xx> <base_rpcport=yyy>

# Defaults for our two optional parameters
DFLT_BASE_PORT=311
DFLT_BASE_RPCPORT=82
other=""


usage() {
  echo "Usage: $0 datadir instance_name [ base_port=xx ] [ base_rpcport=yy ]"
  echo "  Bring up an eth node"
  echo ""
  echo " Two required parameters:"
  echo "   datadir is the data directory"
  echo "   instance_name is the node instance name"
  echo ""
  echo " Two optional parameters:"
  echo "   base_port=yy default is ${DFLT_BASE_PORT}"
  echo "                Where the rpcport will be concatonated with to xx"
  echo "                so base_rpcport=${DFLT_BASE_PORT} and instance_name is 03"
  echo "                port == ${DFLT_PORT}03"
  echo "   base_rpcport=yy default is ${DFLT_BASE_RPCPORT}"
  echo "                Where the rpcport will be concatonated with to yy"
  echo "                so base_rpcport=${DFLT_BASE_RPCPORT} and instance_name is 03"
  echo "                port == ${DFLT_BASE_RPCPORT}03"
}

if (( $# == 0 )); then
    usage
    exit 1
fi

root=$1  # base directory to use for datadir and logs
shift
dd=$1  # double digit instance id like 00 01 02
shift

# Declare an array of named arguments
declare -A args

function print_args() {
  echo "root=$root"
  echo "dd=$dd"
  echo "base_port=${args[base_port]}"
  echo "base_rpcport=${args[base_rpcport]}"
  echo "other=${other}"
}

# Default values for named parameters
args[base_port]=$DFLT_BASE_PORT
args[base_rpcport]=$DFLT_BASE_RPCPORT

# Parse the named arguments
function parse_named_args() {
  for a in $*
  do
    #echo "a=$a"
    case $a in
      base_port=*)
        local $a
        args[base_port]="$base_port"
        ;;
      base_rpcport=*)
        local $a
        args[base_rpcport]="$base_rpcport"
        ;;
      *)
        [[ "$other" == "" ]] && other=$a || other="$other $a"
        ;;
    esac
  done
}

parse_named_args $*

#print_args

# logs are output to a date-tagged file for each run , while a link is
# created to the latest, so that monitoring be easier with the same filename
# TODO: use this if GETH not set
# GETH=geth

# geth CLI params       e.g., (dd=04, run=09)
datetag=`date "+%c%y%m%d-%H%M%S"|cut -d ' ' -f 5`
datadir=$root/data/$dd        # /tmp/eth/04
log=$root/log/$dd.$datetag.log     # /tmp/eth/04.09.log
linklog=$root/log/$dd.current.log     # /tmp/eth/04.09.log
stablelog=$root/log/$dd.log     # /tmp/eth/04.09.log
password=$dd            # 04
port=${args[base_port]}${dd}              # 31104
rpcport=${args[base_rpcport]}${dd}            # 8204

mkdir -p $root/data
mkdir -p $root/log
ln -sf "$log" "$linklog"
# if we do not have an account, create one
# will not prompt for password, we use the double digit instance id as passwd
# NEVER EVER USE THESE ACCOUNTS FOR INTERACTING WITH A LIVE CHAIN
if [ ! -d "$root/keystore/$dd" ]; then
  echo create an account with password $dd [DO NOT EVER USE THIS ON LIVE]
  mkdir -p $root/keystore/$dd
  $GETH --datadir $datadir --password <(echo -n $dd) account new
# create account with password 00, 01, ...
  # note that the account key will be stored also separately outside
  # datadir
  # this way you can safely clear the data directory and still keep your key
  # under `<rootdir>/keystore/dd

  cp -R "$datadir/keystore" $root/keystore/$dd
fi

# echo "copying keys $root/keystore/$dd $datadir/keystore"
# ls $root/keystore/$dd/keystore/ $datadir/keystore

# mkdir -p $datadir/keystore
# if [ ! -d "$datadir/keystore" ]; then
echo "copying keys $root/keystore/$dd $datadir/keystore"
cp -R $root/keystore/$dd/keystore/ $datadir/keystore/
# fi

# bring up node `dd` (double digit)
# - using <rootdir>/<dd>
# - listening on port <base_port>dd, (like 31100, 31101, ...)
# - with the account unlocked
# - launching json-rpc server on port <base_rpcport>dd (like 8200, 8201, 8202, ...)
echo "$GETH --datadir=$datadir \
  --identity="$dd" \
  --port $port \
  --password <(echo -n $dd) \
  --rpc --rpcport=$rpcport --rpccorsdomain='*' $other \
  2>&1 | tee "$stablelog" > "$log" &  # comment out if you pipe it to a tty etc.
"

$GETH --datadir=$datadir \
  --identity "$dd" \
  --port $port \
  --password=<(echo -n $dd) \
  --rpc --rpcport $rpcport --rpccorsdomain '*' $other \
   2>&1 | tee "$stablelog" > "$log" &  # comment out if you pipe it to a tty etc.

# to bring up logs, uncomment
# tail -f $log
