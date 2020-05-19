# HSDP Zookeeper module

Module to create an Apache Zookeeper ensemble cluster deployed
on the HSDP Container Host infrastructure. This module serves as a 
blueprint for future HSDP Container Host modules. Consider it experimental / broken as we refine the internals.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 0.12 |

## Providers

| Name | Version |
|------|---------|
| hsdp | n/a |
| null | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bastion\_host | Bastion host ot use for connections | `string` | n/a | yes |
| image | The docker image to use | `string` | `"bitnami/zookeeper:latest"` | no |
| instance\_type | The instance type to use | `string` | `"t2.medium"` | no |
| nodes | Number of nodes | `number` | `3` | no |
| private\_key | Private key for SSH access | `string` | n/a | yes |
| user | LDAP user to use for connections | `string` | n/a | yes |
| user\_groups | User groups to assign to cluster | `list(string)` | `[]` | no |
| volume\_size | The volume size to use in GB | `number` | `20` | no |

## Outputs

| Name | Description |
|------|-------------|
| private\_ips | Private IP addresses of Zookeeper instances |

# Contact / Getting help

Andy Lo-A-Foe <andy.lo-a-foe@philips.com>

# License

License is MIT
