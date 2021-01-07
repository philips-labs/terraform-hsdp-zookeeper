#!/bin/bash

usage() {
    cat <<-EOF
usage: bootstrap-cluster.sh
      -n node1,node2,...
      -c cluster
      -i index
      -d docker
      -k key-store-pwd
      -t trust-store-pwd
EOF
}

kill_zookeeper() {
  docker kill $zookeeper_name
  docker rm $zookeeper_name
}

kill_monitoring() {
  echo Killing monitoring tools...
  docker kill jmx_exporter 2&>1
  docker rm -f jmx_exporter 2&>1
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

create_network() {
  docker network rm $zookeeper_network 2&>1
  docker network create $zookeeper_network
}

create_volume() {
  docker volume rm zoocert
  docker volume create zoocert
}

start_zookeeper() {
  local index="$1"
  local nodes="$2"
  local image="$3"
  local client_ks_pwd="$4"
  local client_ts_pwd="$5"

  servers="$(zoo_servers "$index" "$nodes")"
  echo ZOO_SERVERS="$servers"
  docker run -d -v $zookeeper_name:/bitnami/zookeeper \
    --restart always \
    --name $zookeeper_name \
    --network $zookeeper_network \
    --env ZOO_SERVER_ID="$1" \
    --env ALLOW_ANONYMOUS_LOGIN=yes \
    --env ZOO_SERVERS="$servers"  \
    --env ZOO_TLS_CLIENT_ENABLE=true \
    --env ZOO_TLS_CLIENT_KEYSTORE_FILE="/opt/bitnami/kafka/conf/certs/zookeeper.keystore.jks" \
    --env ZOO_TLS_CLIENT_KEYSTORE_PASSWORD="$client_ks_pwd" \
    --env ZOO_TLS_CLIENT_TRUSTSTORE_FILE="/opt/bitnami/kafka/conf/certs/zookeeper.truststore.jks" \
    --env ZOO_TLS_CLIENT_TRUSTSTORE_PASSWORD="$client_ts_pwd" \
    --env JMXPORT=5555 \
    -p 10000:3181 \
    -p 6066:2888 \
    -p 7077:3888 \
    -v 'zoocert:/opt/bitnami/kafka/conf/certs/' \
    "$image"
}

load_certificates_and_restart(){
  docker cp ./zookeeper.truststore.jks $zookeeper_name:/opt/bitnami/kafka/conf/certs/
  docker cp ./zookeeper.keystore.jks $zookeeper_name:/opt/bitnami/kafka/conf/certs/
  docker exec $zookeeper_name ls -laR /opt/bitnami/kafka/conf/certs/
  docker restart $zookeeper_name -t 10
}

start_jmx_exporter(){
  # create dir to contain jmx config file
  mkdir -p jmx

  # remove any left-over volume(s)
  docker rm -fv jmx_exporter
  docker volume rm jmx_config_volume

  # Substitute container name in jmx config and move it
  export container_name=$zookeeper_name
  envsubst < jmxconfig.yml.tmpl > ./jmx/config.yml
  
  # create jmx volume mapping the jmx config file
  docker volume create --driver local --name jmx_config_volume --opt type=none --opt device=`pwd`/jmx --opt o=uid=root,gid=root --opt o=bind

  # start jmx exporter
  docker run -d -p 10001:5556 \
  --name jmx_exporter \
  --network $zookeeper_network \
  -v jmx_config_volume:/opt/bitnami/jmx-exporter/example_configs \
  bitnami/jmx-exporter:latest 5556 example_configs/config.yml
}

##### Main

nodes=
cluster=
image=
index=
trust_store_pwd=
key_store_pwd=
jmx_exporter_version=

while [ "$1" != "" ]; do
    case $1 in
        -n | --nodes )                shift
                                      nodes=$1
                                      ;;
        -c | --cluster )              shift
                                      cluster=$1
                                      ;;
        -d | --docker )               shift
                                      image=$1
                                      ;;
        -i | --index )                shift
                                      index=$1
                                      ;;
        -t | --trust-store-pwd )      shift
                                      trust_store_pwd=$1
                                      ;;
        -k | --key-store-pwd )        shift
                                      key_store_pwd=$1
                                      ;;
        -h | --help )                 usage
                                      exit
                                      ;;
        * )                           usage
                                      exit 1
    esac
    shift
done

echo Bootstrapping node "$index" in cluster "$cluster" with image "$image"
zookeeper_name="zookeeper-${index}"
zookeeper_network="zookeeper-${index}-network"

kill_monitoring
kill_zookeeper
create_volume
create_network
start_zookeeper "$index" "$nodes" "$image" "$key_store_pwd" "$trust_store_pwd"
load_certificates_and_restart
start_jmx_exporter
