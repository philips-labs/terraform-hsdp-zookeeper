#!/bin/bash

usage() {
    cat <<-EOF
usage: bootstrap-cluster.sh
      -n node1,node2,...
      -c cluster
      -i index
      -d docker
EOF
}

kill_zookeeper() {
  docker kill zookeeper
  docker rm zookeeper
}

zoo_servers() {
  local index=$1
  local nodes=$2
  local servers=""

  IFS=','
  read -ra SERVERS <<< "$nodes"
  count=1

  for i in "${SERVERS[@]}";do
    current=$i:6066:7077
    if ((index == count)); then
      current=0.0.0.0:2888:3888
    fi
    if [ "$servers" == "" ]; then
      servers=$current
    else
      servers=$servers,$current
    fi
    ((count+=1))
  done

  echo "$servers"
}

start_zookeeper() {
  local index="$1"
  local nodes="$2"

  servers="$(zoo_servers "$index" "$nodes")"
  echo ZOO_SERVERS="$servers"
  docker run -d -v zookeeper:/bitnami/zookeeper \
    --restart always \
    --name zookeeper \
    --env ZOO_SERVER_ID="$1" \
    --env ZOO_ENABLE_PROMETHEUS_METRICS=yes \
    --env ZOO_PROMETHEUS_METRICS_PORT_NUMBER=18080 \
    --env ALLOW_ANONYMOUS_LOGIN=yes \
    --env ZOO_SERVERS="$servers"  \
    -p 2181:2181 \
    -p 18080:18080 \
    -p 6066:2888 \
    -p 7077:3888 \
    "$3"
}

##### Main

nodes=
cluster=
image=
index=

while [ "$1" != "" ]; do
    case $1 in
        -n | --nodes )          shift
                                nodes=$1
                                ;;
        -c | --cluster )        shift
                                cluster=$1
                                ;;
        -d | --docker )        shift
                                image=$1
                                ;;
        -i | --index )        shift
                                index=$1
                                ;;
        -h | --help )           usage
                                exit
                                ;;
        * )                     usage
                                exit 1
    esac
    shift
done

echo Bootstrapping node "$index" in cluster "$cluster" with image "$image"

kill_zookeeper
start_zookeeper "$index" "$nodes" "$image"

