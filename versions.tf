terraform {
  required_providers {
    hsdp = {
      source  = "philips-software/hsdp"
      version = ">= 0.14.8"
    }
    ssh = {
      source  = "loafoe/ssh"
      version = ">= 2.1.0"
    }

  }
}
