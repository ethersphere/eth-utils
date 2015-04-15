# !/bin/bash
# bash cluster <cluster_root> <number_of_clusters> <network_id> <runid> <local_IP> [[params]...]
# https://github.com/ethereum/go-ethereum/wiki/Setting-up-monitoring-on-local-cluster

# sets up a local ethereum network cluster of nodes
# - <n> is the number of clusters
# - <root> is the root directory for the cluster, the nodes are set up
#   with datadir `<root>/00`, `<root>/01`, ...
# - new accounts are created for each node
# - they launch on port 30300, 30301, ...
# - they star rpc on port 8100, 8101, ...
# - by collecting the nodes nodeUrl, they get connected to each other
# - if enode has no IP, `<local_IP>` is substituted
# - if `<network_id>` is not 0, they will not connect to a default client,
#   resulting in a private isolated network
# - the nodes log into `<root>/00.<runid>.log`, `<root>/01.<runid>.log`, ...
# - `<runid>` is just an arbitrary tag or index you can use to log multiple
#   subsequent launches of the same cluster
# - The nodes launch in mining mode
# - the cluster can be killed with `killall geth` (FIXME: should record PIDs)
#   and restarted from the same state
# - if you want to interact with the nodes, use rpc
# - you can supply additional params on the command line which will be passed
#   to each node, for instance `-mine`

root=$1
mkdir -p $root
shift
N=$1
shift
network_id=$1
shift
run_id=$1
shift
ip_addr=$1
shift

# GETH=geth

if [ ! -f "$root/nodes"  ]; then
  for ((i=0;i<N;++i)); do
    id=`printf "%02d" $i`

    echo "getting enode for instance $id ($i/$N)"
    eth="$GETH -datadir $root/$id -logfile /dev/null -port 303$id -networkid $network_id"
    cmd="$eth js <(echo 'console.log(admin.nodeInfo().NodeUrl)') "
    echo $cmd
    bash -c "$cmd" 2>/dev/null |grep enode >> $root/nodes

  done
fi

if [ ! $ip_addr="" ]; then
  bootnodes=`cat $root/nodes|tr '\n' ' '|perl -pe "s/\[\:\:\]/$ip_addr/g"`
else
  bootnodes=`cat $root/nodes|tr '\n' ' '`
fi

for ((i=0;i<N;++i)); do
  id=`printf "%02d" $i`
  echo "launching node $i/$N ---> tail -f $root/$id.$run_id.log"
  GETH=$GETH bash ./gethup.sh $root $id $run_id -bootnodes="\"$bootnodes\"" &
done



