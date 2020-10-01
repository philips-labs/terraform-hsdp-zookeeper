output "zookeeper_nodes" {
  description = "Container Host Zookeeper instances"
  value       = hsdp_container_host.zookeeper.*.private_ip
}

output "zookeeper_name_nodes" {
  description = "Container Host Zookeeper instance names"
  value       = hsdp_container_host.zookeeper.*.name
}

output "zookeeper_port" {
  description = "Zookeeper port"
  value       = "10000"
}
