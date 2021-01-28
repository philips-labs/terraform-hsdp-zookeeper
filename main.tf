resource "random_id" "id" {
  byte_length = 8
}

resource "hsdp_container_host" "zookeeper" {
  count         = var.nodes
  name          = var.host_name == "" ? "zookeeper-${random_id.id.hex}-${count.index}.dev" : "zookeeper-${var.host_name}-${count.index}.${var.tld}"
  volumes       = 1
  volume_size   = var.volume_size
  instance_type = var.instance_type

  user_groups     = var.user_groups
  security_groups = ["analytics"]

  lifecycle {
    ignore_changes = [
      volumes,
      volume_size,
      instance_type,
      iops
    ]
  }

  bastion_host = var.bastion_host
  user         = var.user
  private_key  = var.private_key

  commands = [
    "docker volume create zookeeper"
  ]
}

resource "hsdp_container_host_exec" "cluster" {
  count = var.nodes

  triggers = {
    cluster_instance_ids = join(",", hsdp_container_host.zookeeper.*.id)
    bash                 = file("${path.module}/scripts/bootstrap-cluster.sh")
  }

  bastion_host = var.bastion_host
  host         = element(hsdp_container_host.zookeeper.*.private_ip, count.index)
  user         = var.user
  private_key  = var.private_key

  file {
    source      = "${path.module}/scripts/bootstrap-cluster.sh"
    destination = "/home/${var.user}/bootstrap-cluster.sh"
  }
  
  file {
    source      = "${path.module}/scripts/jmxconfig.yml.tmpl"
    destination = "/home/${var.user}/jmxconfig.yml.tmpl"
  }

  file {
    source      = var.trust_store.truststore
    destination = "/home/${var.user}/zookeeper.truststore.jks"
  }

  file {
    source      = var.key_store.keystore
    destination = "/home/${var.user}/zookeeper.keystore.jks"
  }

  commands = [
    "chmod +x /home/${var.user}/bootstrap-cluster.sh",
    "chmod 755 /home/${var.user}/jmxconfig.yml.tmpl",
    "/home/${var.user}/bootstrap-cluster.sh -n ${join(",", hsdp_container_host.zookeeper.*.private_ip)} -c ${random_id.id.hex} -d ${var.image} -i ${count.index + 1} -t ${var.trust_store.password} -k ${var.key_store.password} -e ${var.enable_exporter}"
  ]
}
