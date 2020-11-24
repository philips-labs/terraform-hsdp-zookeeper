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
      -v jmx_exporter_version
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

create_volume() {
  docker volume rm zoocert
  docker volume create zoocert
}

start_zookeeper() {
  local index="$1"
  local nodes="$2"
  local image:"$3"
  local client_ks_pwd="$4"
  local client_ts_pwd="$5"

  servers="$(zoo_servers "$index" "$nodes")"
  echo ZOO_SERVERS="$servers"
  docker run -d -v zookeeper:/bitnami/zookeeper \
    --restart always \
    --name zookeeper \
    --env ZOO_SERVER_ID="$1" \
    --env ALLOW_ANONYMOUS_LOGIN=yes \
    --env ZOO_SERVERS="$servers"  \
    --env ZOO_TLS_CLIENT_ENABLE=true \
    --env ZOO_TLS_CLIENT_KEYSTORE_FILE="/opt/bitnami/kafka/conf/certs/zookeeper.keystore.jks" \
    --env ZOO_TLS_CLIENT_KEYSTORE_PASSWORD="$client_ks_pwd" \
    --env ZOO_TLS_CLIENT_TRUSTSTORE_FILE="/opt/bitnami/kafka/conf/certs/zookeeper.truststore.jks" \
    --env ZOO_TLS_CLIENT_TRUSTSTORE_PASSWORD="$client_ts_pwd" \
    --env ZOO_TLS_CLIENT_TRUSTSTORE_PASSWORD="$client_ts_pwd" \
    --env JVMFLAGS='-javaagent:/opt/bitnami/prometheus/jmx_export_agent.jar=10001:/opt/bitnami/prometheus/config.yml' \
    --env JMXPORT=5555 \
    -v jmx_exporter:/opt/bitnami/prometheus \
    -p 10000:3181 \
    -p 10001:10001 \
    -p 6066:2888 \
    -p 7077:3888 \
    -v 'zoocert:/opt/bitnami/kafka/conf/certs/' \
    "$image"
}

load_certificates_and_restart(){
  docker cp ./zookeeper.truststore.jks zookeeper:/opt/bitnami/kafka/conf/certs/
  docker cp ./zookeeper.keystore.jks zookeeper:/opt/bitnami/kafka/conf/certs/
  docker exec zookeeper ls -laR /opt/bitnami/kafka/conf/certs/
  docker restart zookeeper -t 10
}

download_jmx_agent(){
  local version="$1"
  echo "Download JMX Prometheus JavaAgent ${version}"
  mkdir -p jmx
  mv config.yml ./jmx
  cd jmx
  curl -s -o jmx_export_agent.jar "https://repo1.maven.org/maven2/io/prometheus/jmx/jmx_prometheus_javaagent/${version}/jmx_prometheus_javaagent-${version}.jar"
  docker volume create rm jmx_exporter
  docker volume create --driver local --name jmx_exporter --opt type=none --opt device=`pwd` --opt o=uid=root,gid=root --opt o=bind
  cd ..
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
        -v | --jmx-exporter-version ) shift
                                      jmx_exporter_version=$1
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

kill_zookeeper
create_volume
download_jmx_agent "$jmx_exporter_version"
start_zookeeper "$index" "$nodes" "$image" "$key_store_pwd" "$trust_store_pwd"
load_certificates_and_restart

