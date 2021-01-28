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
  trust_store   = {
    truststore = "./truststore.jks"
    password   = "somepass"
  }
  key_store     = {
    keystore   = "./keystore.jks"
    password   = "somepass"
  }
}
```

__IMPORTANT SECURITY INFORMATION__
> This module currently **enables** only mTLS-SSL
> between Kafka, Zookeeper or any connecting client apps.
> Operating and maintaining applications on Container Host is always
> your responsibility. This includes ensuring any security 
> measures are in place in case you need them.


## Requirements

| Name | Version |
|------|---------|
| hsdp | >= 0.9.4 |

## Providers

| Name | Version |
|------|---------|
| hsdp | >= 0.9.4 |
| random | n/a |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| bastion\_host | Bastion host to use for SSH connections | `string` | n/a | yes |
| enable\_exporter | Indicates whether jmx exporter is enabled or not | `bool` | `false` | no |
| host\_name | The middlename for your host default is a random number | `string` | `""` | no |
| image | The docker image to use | `string` | `"bitnami/zookeeper:latest"` | no |
| instance\_type | The instance type to use | `string` | `"t2.medium"` | no |
| key\_store | Key Store for SSL, same key used for all nodes | <pre>object(<br>    { keystore = string,<br>    password = string }<br>  )</pre> | n/a | yes |
| nodes | Number of nodes | `number` | `3` | no |
| private\_key | Private key for SSH access | `string` | n/a | yes |
| tld | The tld for your host default is a dev | `string` | `"dev"` | no |
| trust\_store | Trust store for SSL | <pre>object(<br>    { truststore = string,<br>    password = string }<br>  )</pre> | n/a | yes |
| user | LDAP user to use for connections | `string` | n/a | yes |
| user\_groups | User groups to assign to cluster | `list(string)` | `[]` | no |
| volume\_size | The volume size to use in GB | `number` | `20` | no |

## Key Store object
This object has two properties that needs to be filled
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| keystore | The path of the keystore file in JKS format| `string` | none | yes |
| password | The password to be used for the key store | `string` | none | yes |

## trust Store object
This object has two properties that needs to be filled
| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| truststore | The path of the truststore file in JKS format| `string` | none | yes |
| password | The password to be used for the trust store | `string` | none | yes |

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
