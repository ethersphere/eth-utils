# !/bin/bash
# bash cluster <root> <network_id> <number_of_nodes>  <runid> <local_IP> [[params]...]
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
# - the nodes log into `<root>/<network_id>/00.<runid>.log`, `<root>/<network_id>/01.<runid>.log`, ...
# - The nodes launch in mining mode
# - the cluster can be killed with `killall geth` (FIXME: should record PIDs)
#   and restarted from the same state
# - if you want to interact with the nodes, use rpc
# - you can supply additional params on the command line which will be passed
#   to each node, for instance `-mine`


network_id=$1
shift
N=$1
shift

cmd="bash ./gethcluster.sh ~/leagues/swarm/ $network_id $N ''  --vmodule=netstore=6,depo=6,forwarding=6,hive=5,dpa=6,dpa=6,http=6,syncb=6,syncer=6,protocol=6,swap=6,chequebook=6 --verbosity=5  --vmdebug=false --maxpeers=20 --dev --shh=false --nodiscover --ipcexp"
echo $cmd
eval $cmd