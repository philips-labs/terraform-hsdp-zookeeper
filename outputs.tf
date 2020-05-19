output "private_ips" {
  description = "Private IP addresses of Zookeeper instances"
  value       = [hsdp_container_host.zookeeper.*.private_ip]
}
