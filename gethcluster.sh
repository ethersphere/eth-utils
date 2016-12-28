# !/bin/bash
# bash cluster <root> <network_id> <number_of_nodes> <local_IP> [[params]...]
# https://github.com/ethereum/go-ethereum/wiki/Setting-up-monitoring-on-local-cluster

# Defaults for our two optional parameters
DFLT_BASE_PORT=311
DFLT_BASE_RPCPORT=82

# Other args if not named based
other=""


usage() {
  echo "Usage: $0 <root> <network_id> <number_of_nodex> <local_IP> [ base_port=xx ] [ base_rpcport=yy ] [[params] ...]"
  echo "  Bring up a local ethereum network cluster of nodes."
  echo "  killall -q geth can be used to kill them, obviously be careful :)"
  echo ""
  echo " Two required parameters:"
  echo "   root is root directory of the cluster nodes are setup"
  echo "        with data_dir=<root>/<network_id/00, <root>/<network_id>/01, .."
  echo "   nework_id is an identifier unique for this network"
  echo "   number_of_nodes is the number of nodes to creeate"
  echo "   local_IP is the IP address of for this computer"
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
  echo ""
  echo "  \[\[params\] ...] are additional parameters passed to gethup.sh such as --miner --minerthreads 2"
}

if (( $# == 0 )); then
    usage
    exit 1
fi

root=$1
shift
network_id=$1
data_dir=$root/$network_id
mkdir -p $data_dir/data
mkdir -p $data_dir/log
shift
N=$1
shift
ip_addr=$1
shift

# Declare an array of named arguments
declare -A args

function print_args() {
  echo "root=$root"
  echo "network_id=$network_id"
  echo "N=$N"
  echo "ip_addr=$ip_addr"

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


# GETH=geth

if [ ! -f "$data_dir/nodes"  ]; then

  echo "[" >> $data_dir/nodes
  for ((i=0;i<N;++i)); do
    id=`printf "%02d" $i`
    if [ ! $ip_addr="" ]; then
      ip_addr="[::]"
    fi

    echo "getting enode for instance $id ($i/$N)"
    eth="$GETH --datadir $data_dir/data/$id --port ${args[base_port]}${id} --networkid $network_id"
    cmd="$eth js <(echo 'console.log(admin.nodeInfo.enode); exit();') "
    echo $cmd
    bash -c "$cmd" 2>/dev/null |grep enode | perl -pe "s/\[\:\:\]/$ip_addr/g" | perl -pe "s/^/\"/; s/\s*$/\"/;" | tee >> $data_dir/nodes
    if ((i<N-1)); then
      echo "," >> $data_dir/nodes
    fi
  done
  echo "]" >> $data_dir/nodes
fi

for ((i=0;i<N;++i)); do
  id=`printf "%02d" $i`
  # echo "copy $data_dir/data/$id/static-nodes.json"
  mkdir -p $data_dir/data/$id
  # cp $data_dir/nodes $data_dir/data/$id/static-nodes.json
  echo "launching node $i/$N ---> tail-f $data_dir/log/$id.log"
  echo "GETH=$GETH bash ./gethup.sh $data_dir $id base_port=${args[base_port]} base_rpcport=${args[base_rpcport]} --networkid $network_id $other"
  GETH=$GETH bash ./gethup.sh $data_dir $id base_port=${args[base_port]} base_rpcport=${args[base_rpcport]} --networkid $network_id $other
done
