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

resource "digitalocean_kubernetes_cluster" "feednet" {
  name         = "feednet"
  region       = "sfo3"
  version      = data.digitalocean_kubernetes_versions.example.latest_version
  auto_upgrade = true

  node_pool {
    name       = "default"
    size       = "s-1vcpu-2gb"
    auto_scale = true
    min_nodes  = 3
    max_nodes  = 10
  }
}

provider "kubernetes" {
  load_config_file = false
  host             = digitalocean_kubernetes_cluster.feednet.endpoint
  token            = digitalocean_kubernetes_cluster.feednet.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.feednet.kube_config[0].cluster_ca_certificate
  )
}
