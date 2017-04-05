# !/bin/bash
# bash intelligence <destination_app_json_path> <number_of_clusters> <name_prefix> <ws_server> <ws_secret>
# you can also set the values as environment variables in upper case
# - NUMBER_OF_CLUSTERS, NAME_PREFIX, WS_SERVER, WS_SECRET

# sets up a eth-net-intelligence app.json for a local ethereum network cluster of nodes
# - <number_of_clusters> is the number of clusters
# - <name_prefix> is a prefix for the node names as will appear in the listing
# - <ws_server> is the eth-netstats server
# - <ws_secret> is the eth-netstats secret
#

# open http://localhost:3301

: ${NUMBER_OF_CLUSTERS:=$1}
: ${NAME_PREFIX:=$2}
: ${WS_SERVER:=$3}
: ${WS_SECRET:=$4}

echo -e "["

for ((i=0;i<NUMBER_OF_CLUSTERS;++i)); do
    id=`printf "%02d" $i`
    single_template="  {\n    \"name\"        : \"$NAME_PREFIX-$i\",\n    \"cwd\"         : \".\",\n    \"script\"      : \"app.js\",\n    \"log_date_format\"   : \"YYYY-MM-DD HH:mm Z\",\n    \"merge_logs\"    : false,\n    \"watch\"       : false,\n    \"exec_interpreter\"  : \"node\",\n    \"exec_mode\"     : \"fork_mode\",\n    \"env\":\n    {\n      \"NODE_ENV\"    : \"production\",\n      \"RPC_HOST\"    : \"localhost\",\n      \"RPC_PORT\"    : \"81$id\",\n      \"INSTANCE_NAME\"   : \"$NAME_PREFIX-$i\",\n      \"WS_SERVER\"     : \"$WS_SERVER\",\n      \"WS_SECRET\"     : \"$WS_SECRET\",\n    }\n  }"

    endline=""
    if [ "$i" -ne "$NUMBER_OF_CLUSTERS" ]; then
        endline=","
    fi
    echo -e "$single_template$endline"
done

echo "]"
