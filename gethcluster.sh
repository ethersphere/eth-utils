# !/bin/bash
# Usage: GETH=geth bash /path/to/eth-utils/gethcluster.sh <root> <number_of_nodes> <network_id> <runid> <IP> <params>

# https://github.com/ethereum/go-ethereum/wiki/Setting-up-monitoring-on-local-cluster

# sets up a local ethereum network cluster of nodes
# - <number_of_nodes> is the number of nodes in cluster
# - <root> is the root directory for the cluster, the nodes are set up
#   with datadir `<root>/<network_id>/00`, `<root>/ <network_id>/01`, ...
# - new accounts are created for each node
# - they launch on port 30300, 30301, ...
# - they star rpc on port 8100, 8101, ...
# - by collecting the nodes nodeUrl, they get connected to each other
# - if enode has no IP, `<local_IP>` is substituted
# - if `<network_id>` is not 0, they will not connect to a default client,
#   resulting in a private isolated network
# - the nodes log into `<root>/00.<runid>.log`, `<root>/01.<runid>.log`, ...
# - The nodes launch in mining mode
# - the cluster can be killed with `killall geth` (FIXME: should record PIDs)
#   and restarted from the same state
# - if you want to interact with the nodes, use rpc
# - you can supply additional params on the command line which will be passed
#   to each node, for instance `-mine`


root=$1
shift
N=$1
shift
network_id=$1
dir=$root/$network_id
mkdir -p $dir/data
mkdir -p $dir/log
shift
run_id=$1
shift
ip_addr=$1
shift

# GETH=geth

if [ ! -f "$dir/nodes"  ]; then
  
  echo "[" >> $dir/nodes
  for ((i=0;i<N;++i)); do
    id=`printf "%02d" $i`
    if [ ! $ip_addr="" ]; then
      ip_addr="[::]"
    fi

    echo "getting enode for instance $id ($((i+1))/$N)"
    eth="$GETH --datadir $dir/data/$id --port 303$id --networkid $network_id"
    cmd="$eth js <(echo 'console.log(admin.nodeInfo.enode); exit();') "
    echo $cmd
    bash -c "$cmd" 2>/dev/null | grep enode | perl -pe "s/\[\:\:\]/$ip_addr/g" | perl -pe "s/^/\"/; s/\s*$/\"/;" | tee >> $dir/nodes
    if ((i<N-1)); then
      echo "," >> $dir/nodes
    fi
  done
  echo "]" >> $dir/nodes
fi

for ((i=0;i<N;++i)); do
  id=`printf "%02d" $i`
  # echo "copy $dir/data/$id/static-nodes.json"
  mkdir -p $dir/data/$id
  # cp $dir/nodes $dir/data/$id/static-nodes.json
  echo "launching node $((i+1))/$N ---> tail-f $dir/log/$id.log"
  echo GETH=$GETH bash ./gethup.sh $dir $id --networkid $network_id $*
  GETH=$GETH bash ./gethup.sh $dir $id --networkid $network_id $*
done