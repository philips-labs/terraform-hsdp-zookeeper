variable "instance_type" {
  description = "The instance type to use"
  type        = string
  default     = "t2.medium"
}

variable "volume_size" {
  description = "The volume size to use in GB"
  type        = number
  default     = 20
}

variable "image" {
  description = "The docker image to use"
  type        = string
  default     = "bitnami/zookeeper:latest"
}

variable "nodes" {
  description = "Number of nodes"
  type        = number
  default     = 3
}

variable "user_groups" {
  description = "User groups to assign to cluster"
  type        = list(string)
  default     = []
}

variable "user" {
  description = "LDAP user to use for connections"
  type        = string
}

variable "bastion_host" {
  description = "Bastion host to use for SSH connections"
  type        = string
}

variable "private_key" {
  description = "Private key for SSH access"
  type        = string
}

variable "trust_store" {
  description = "Trust store for SSL"
  type        = object (
    { keystore  = string ,
      password  = string }
  )
}

variable "key_stores" {
  description = "A list of key stores one for each nore"
  type        = list(object(
    { keystore  = string ,
      password  = string }
  ) )
}
