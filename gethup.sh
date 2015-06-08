#!/bin/bash
# Usage:
# bash /path/to/eth-utils/gethup.sh

root=$1  # base directory to use for datadir and logs
shift
dd=$1  # double digit instance id like 00 01 02
shift
r=$1  # run, tag to identify subsequents runs of the same instance
shift

# TODO: use this if GETH not set
# GETH=geth

# geth CLI params       e.g., (dd=04, run=09)
datadir=$root/$dd        # /tmp/eth/04
log=$root/$dd.$r.log     # /tmp/eth/04.09.log
glog=$root/$dd.$r.glog     # /tmp/eth/04.09.glog
password=$dd            # 04
port=303$dd              # 30304
rpcport=81$dd            # 8104

mkdir -p $root
# if we do not have a primary account, create one
# will not prompt for password, we use the double digit instance id as passwd
# NEVER EVER USE THESE ACCOUNTS FOR INTERACTING WITH A LIVE CHAIN
# the programmatic
if [ ! -d "$root/keystore/$dd" ]; then
  echo create primary account with password $dd [DO NOT EVER USE THIS ON LIVE]
  mkdir -p $root/keystore/$dd
  # create account with password 00, 01, ...
  # note that the primary account key will be stored also separately outside
  # datadir
  # this way you can safely clear the data directory and still keep your key
  # under `<rootdir>/keystore/dd
  $GETH --datadir $datadir --password <(echo -n $dd) account new
  cp -R $datadir/keystore $root/keystore/$dd
fi

# bring up node `dd` (double digit)
# - using <rootdir>/<dd>
# - listening on port 303dd, (like 30300, 30301, ...)
# - with primary account unlocked
# - launching json-rpc server on port 81dd (like 8100, 8101, 8102, ...)
echo "$GETH --datadir $datadir \
  --port $port \
  --unlock primary \
  --password <(echo -n $dd) \
  --logfile $log --logtostderr --verbosity 6  \
  --rpc --rpcport $rpcport --rpccorsdomain '*' $* \
  2>> $glog  # comment out if you pipe it to a tty etc.\
"
$GETH -datadir $datadir \
  --port $port \
  --unlock primary \
  --password <(echo -n $dd) \
  --logfile $log --logtostderr --verbosity 6  \
  --rpc --rpcport $rpcport --rpccorsdomain '*' $* \
  2>> "$glog" # comment out if you pipe it to a tty etc.

# to bring up logs, uncomment
# tail -f $glog
