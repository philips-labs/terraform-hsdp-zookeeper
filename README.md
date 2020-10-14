<img src="https://cdn.rawgit.com/hashicorp/terraform-website/master/content/source/assets/images/logo-hashicorp.svg" width="500px">

# HSDP Zookeeper module

Module to create an Apache Zookeeper ensemble cluster deployed
on the HSDP Container Host infrastructure. This module serves as a 
blueprint for future HSDP Container Host modules. Example usage

```hcl
module "zookeeper" {
  source = "github.com/philips-labs/terraform-hsdp-zookeeper"

  nodes        = 5
  bastion_host = "bastion.host"
  user         = "ronswanson"
  private_key  = file("~/.ssh/dec.key")
  user_groups  = ["ronswanson", "poc"]
}
```

__IMPORTANT SECURITY INFORMATION__
> This module currently **does not offer or enable security features** like
> Kerberos or mTLS between Kafka, Zookeeper or any connecting client apps.
> Operating and maintaining applications on Container Host is always
> your responsibility. This includes ensuring above mentioned security 
> measures are in place in case you need them.


## Requirements

| Name | Version |
|------|---------|
| hsdp | >= 0.6.1 |

## Providers

| Name | Version |
|------|---------|
| hsdp | >= 0.6.1 |
| null | n/a |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bastion\_host | Bastion host to use for SSH connections | `string` | n/a | yes |
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
| zookeeper\_name\_nodes | Container Host Zookeeper instance names |
| zookeeper\_nodes | Container Host Zookeeper instances |
| zookeeper\_port | Zookeeper port |

# Contact / Getting help

Andy Lo-A-Foe <andy.lo-a-foe@philips.com>

# License

License is MIT
