docker rm -fv cadvisor_exporter
docker rm -fv node_exporter

docker run -d --name=cadvisor_exporter --device=/dev/kmsg -p 9102:8080 \
-v /:/rootfs:ro -v /var/run:/var/run:ro -v /sys:/sys:ro \
-v /var/lib/docker/:/var/lib/docker:ro -v /dev/disk/:/dev/disk:ro \
gcr.io/cadvisor/cadvisor:v0.38.1

docker stop zookeeper || echo "Zookeeper doesn't exist"
docker run -d --name node_exporter -p 9101:9100 bitnami/node-exporter:latest
docker start zookeeper || echo "Zookeeper doesn't exist"