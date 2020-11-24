resource "random_id" "id" {
  byte_length = 8
}

resource "hsdp_container_host" "zookeeper" {
  count         = var.nodes
  name          = "zookeeper-${random_id.id.hex}-${count.index}.dev"
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

  connection {
    bastion_host = var.bastion_host
    host         = self.private_ip
    user         = var.user
    private_key  = var.private_key
    script_path  = "/home/${var.user}/bootstrap.bash"
  }

  provisioner "remote-exec" {
    inline = [
      "docker volume create zookeeper",
    ]
  }
}

//resource "null_resource" "container_exporter" {
//  count = var.prometheus_metrics ? var.nodes : 0
//
//  triggers = {
//    cluster_instance_ids = join(",", hsdp_container_host.zookeeper.*.id)
//  }
//
//  connection {
//    bastion_host = var.bastion_host
//    host         = element(hsdp_container_host.zookeeper.*.private_ip, count.index)
//    user         = var.user
//    private_key  = var.private_key
//    script_path  = "/home/${var.user}/cluster.bash"
//  }
//
//  provisioner "file" {
//    source      = "${path.module}/scripts/container_exporter.sh"
//    destination = "/home/${var.user}/container_exporter.sh"
//  }
//
//  provisioner "remote-exec" {
//    # Deploy container exporter for nodes
//    inline = [
//      "chmod +x /home/${var.user}/container_exporter.sh",
//      "/home/${var.user}/container_exporter.sh"
//    ]
//  }
//}

resource "null_resource" "cluster" {
  count = var.nodes

  triggers = {
    cluster_instance_ids = join(",", hsdp_container_host.zookeeper.*.id)
  }

  connection {
    bastion_host = var.bastion_host
    host         = element(hsdp_container_host.zookeeper.*.private_ip, count.index)
    user         = var.user
    private_key  = var.private_key
    script_path  = "/home/${var.user}/cluster.bash"
  }

  provisioner "file" {
    source      = "${path.module}/scripts/bootstrap-cluster.sh"
    destination = "/home/${var.user}/bootstrap-cluster.sh"
  }
  provisioner "file" {
    source      = var.trust_store.truststore
    destination = "/home/${var.user}/zookeeper.truststore.jks"
  }

  provisioner "file" {
    source      = var.key_store.keystore
    destination = "/home/${var.user}/zookeeper.keystore.jks"
  }

  provisioner "remote-exec" {
    # Bootstrap script called with private_ip of each node in the cluster
    inline = [
      "chmod +x /home/${var.user}/bootstrap-cluster.sh",
      "/home/${var.user}/bootstrap-cluster.sh -n ${join(",", hsdp_container_host.zookeeper.*.private_ip)} -c ${random_id.id.hex} -d ${var.image} -i ${count.index + 1} -t ${var.trust_store.password} -k ${var.key_store.password}"
    ]
  }
}
