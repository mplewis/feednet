terraform {
  required_providers {
    digitalocean = {
      source = "digitalocean/digitalocean"
    }

    kubernetes-alpha = {
      source  = "hashicorp/kubernetes-alpha"
      version = "0.2.1"
    }
  }
  required_version = ">= 0.13"
}
