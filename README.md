## eth-utils

ethereum utilities, dev tools, scripts, etc

* `gethup.sh`: primitive wrapper to [geth](https://github.com/ethereum/go-ethereum)
* `gethcluster.sh`: launch local clusters non-interactively (https://github.com/ethereum/go-ethereum/wiki/Setting-up-private-network-or-local-cluster)
* `netstatconf.sh`: auto-generate the json config of your local cluster for netstat (https://github.com/ethereum/go-ethereum/wiki/Setting-up-monitoring-on-local-cluster)

##  Usage

### Launch an instance 

```
GETH=./geth bash /path/to/eth-utils/gethup.sh <rootdir> <dd> <run> <params>...
```

This will
- if it does not exist yet, then create an account with password _dd_ [NEVER USE THIS LIVE]
- bring up a node with instance id _dd_ (double digit)
- using _rootdir/dd_ as data directory (where blockchain etc. are stored)
- listening on port _303dd_, (like 30300, 30301, ...)
- with the account unlocked
- launching json-rpc server on port _81dd_ (like 8100, 8101, 8102, ...)
- extra params are passed to `geth` 

```
$ GETH=./geth bash ~/eth-utils/gethup.sh ~/tmp/eth/ 04 09 --mine console 
Welcome to the FRONTIER
> eth.getBalance(eth.coinbase)
'198400000000001'
>
```

### Launch a cluster 
Running a cluster of 8 instances under dir `tmp/eth/` isolated on local eth network (id 3301), launch 05. Give external IP and pass extra param `--mine`.

```
GETH=./geth bash gethcluster.sh <root> <n> <network_id> <runid> <IP> [[params]...]
```

This will set up a local cluster of nodes
- `<n>` is the number of clusters
- `<root>` is the root directory for the cluster, the nodes are set up 
  with datadir `<root>/00`, `<root>/01`, ...
- new accounts are created for each node
- they listening on port _303dd_ (like 30300, 30301, ...)
- json-rpc server is launched on port _81dd_ (like 8100, 8101, ...)
- by collecting the nodes' node-urls, they get connected to each other
- if enode has no IP, `<IP>` is substituted
- if `<network_id>` is not 0, they will not connect to a default client,
  resulting in a private isolated network
- the nodes log into `<root>/00.<runid>.log`, `<root>/01.<runid>.log`, ...
- `<runid>` is just an arbitrary tag or index you can use to log multiple 
  subsequent launches of the same cluster, I recommend sequential double digit ids
- the cluster can be killed with `killall -QUIT geth` (FIXME: should record PIDs)
- the nodes can be restarted from the same state individually using the `gethup.sh` script
- if you want to interact with the nodes, use a json-rpc client
- you can supply additional params on the command line which will be passed 
  to `gethup.sh` and eventually to `geth` for each node, for instance `-vmodule=http=6 -mine -minerthreads=8` is a good one.

```
GETH=./geth bash gethcluster.sh ./leagues/3301/cicada 2 3301 05 77.160.58.3 -mine 
launching node 0/2 ---> tail -f ./leagues/3301/cicada/00.05.log
Welcome to the FRONTIER
launching node 1/2 ---> tail -f ./leagues/3301/cicada/01.05.log
Welcome to the FRONTIER
```

fill create:
```
./leagues/3301/cicada/
./leagues/3301/cicada/3301/
./leagues/3301/cicada/3301/00/
./leagues/3301/cicada/3301/00.05.log
./leagues/3301/cicada/3301/00.05.glog
./leagues/3301/cicada/3301/01/
./leagues/3301/cicada/3301/01.05.log
./leagues/3301/cicada/3301/01.05.glog
./leagues/3301/cicada/3301/
```

You can kill and restart individual nodes or the entire cluster safely, by using different runid you can separate logs for the individual runs in a neat way.

```
killall -QUIT geth
```

Using the `-QUIT` signal is very useful because it dumps the stacktrace into the glog file which you can attach to any bugreport or issue. 

### Monitor your local cluster:


#### Installing the eth-netstats monitor

```
git clone https://github.com/cubedro/eth-netstats
cd eth-netstats
npm install
```

####Configuring netstat for your cluster

```
bash /path/to/eth-utils/netstatconf.sh <number_of_clusters> <name_prefix> <ws_server> <ws_secret> 
```

- will output resulting app.json to stdout
- `number_of_clusters` is the number of nodes in the cluster.
- `name_prefix` is a prefix for the node names as will appear in the listing.
- `ws_server` is the eth-netstats server. Make sure you write the full URL, for example: http://localhost:3000.
- `ws_secret` is the eth-netstats secret.

For example:

```
git clone https://github.com/ethersphere/eth-utils
cd eth-utils
bash ./netstatconfig.sh 8 cicada http://localhost:3301 kscc > ~/leagues/3301/cicada.json
```

####Installing eth-net-intelligence-api

```
git clone https://github.com/cubedro/eth-net-intelligence-api
cd eth-net-intelligence-api
npm install
sudo npm install -g pm2
```

#### Starting the eth-net-intelligence-api

to start the eth-net-intelligence-api client for your cluster

```
cd eth-net-intelligence-api
pm2 start ~/leagues/3301/cicada.json
[PM2] Process launched
[PM2] Process launched
┌──────────┬────┬──────┬───────┬────────┬─────────┬────────┬─────────────┬──────────┐
│ App name │ id │ mode │ pid   │ status │ restart │ uptime │ memory      │ watching │
├──────────┼────┼──────┼───────┼────────┼─────────┼────────┼─────────────┼──────────┤
│ cicada-0 │ 1  │ fork │ 93855 │ online │ 0       │ 0s     │ 10.289 MB   │ disabled │
│ cicada-1 │ 2  │ fork │ 93858 │ online │ 0       │ 0s     │ 10.563 MB   │ disabled │
└──────────┴────┴──────┴───────┴────────┴─────────┴────────┴─────────────┴──────────┘
 Use `pm2 show <id|name>` to get more details about an app
```


####Starting the monitor 

Use your own eth-netstat server to monitor a league on a port corresponding to a league

```
cd eth-netstat
PORT=3301 WS_SECRET=kscc npm start &
```

and enjoy:
```
open http://localhost:3301
```
