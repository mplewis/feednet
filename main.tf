variable "digitalocean_token" {}

terraform {
  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "mplewis"

    workspaces {
      name = "feednet"
    }
  }
}

provider "digitalocean" {
  token = var.digitalocean_token
}

resource "digitalocean_container_registry" "chiba" {
  name                   = "chiba"
  subscription_tier_slug = "starter"
}

data "digitalocean_kubernetes_versions" "versions" {}

resource "digitalocean_kubernetes_cluster" "feednet" {
  name         = "feednet"
  region       = "sfo3"
  version      = data.digitalocean_kubernetes_versions.versions.latest_version
  auto_upgrade = true

  node_pool {
    name       = "default"
    size       = "s-2vcpu-2gb"
    auto_scale = true
    min_nodes  = 2
    max_nodes  = 6
  }
}
