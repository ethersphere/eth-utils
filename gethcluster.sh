# !/bin/bash
# bash cluster <cluster_root> <number_of_nodes> <network_id> <runid> <local_IP> [[params]...]
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
mkdir -p $root/data
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

  echo "[" >> $root/nodes
  for ((i=0;i<N;++i)); do
    id=`printf "%02d" $i`
    if [ ! $ip_addr="" ]; then
      ip_addr="[::]"
    fi

    echo "getting enode for instance $id ($i/$N)"
    eth="$GETH --datadir $root/data/$id --port 303$id --networkid $network_id"
    cmd="$eth js <(echo 'console.log(admin.nodeInfo().NodeUrl); exit();') "
    echo $cmd
    bash -c "$cmd" 2>/dev/null |grep enode | perl -pe "s/\[\:\:\]/$ip_addr/g" | perl -pe "s/^/\"/; s/\s*$/\"/;" | tee >> $root/nodes
    if ((i<N-1)); then
      echo "," >> $root/nodes
    fi
  done
  echo "]" >> $root/nodes
fi

for ((i=0;i<N;++i)); do
  id=`printf "%02d" $i`
  echo "copy $root/data/$id/static-nodes.json"
  mkdir -p $root/data/$id
  cp $root/nodes $root/data/$id/static-nodes.json
  echo "launching node $i/$N ---> tail -f $root/$id.$run_id.log"
  GETH=$GETH bash ./gethup.sh $root $id $run_id --nodiscover --bzzport 86$id $* &
done



