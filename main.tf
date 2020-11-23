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

resource "digitalocean_kubernetes_cluster" "feednet" {
  name    = "feednet"
  region  = "sfo3"
  version = "1.19.3-do.0"

  node_pool {
    name       = "default"
    size       = "s-1vcpu-2gb"
    auto_scale = true
    min_nodes  = 3
    max_nodes  = 10
  }
}

resource "digitalocean_kubernetes_node_pool" "bar" {
  cluster_id = digitalocean_kubernetes_cluster.feednet.id
  name       = "default2"
  size       = "s-2vcpu-2gb"
  node_count = 2
  auto_scale = true
  min_nodes  = 1
  max_nodes  = 6
}

provider "kubernetes" {
  load_config_file = false
  host             = digitalocean_kubernetes_cluster.feednet.endpoint
  token            = digitalocean_kubernetes_cluster.feednet.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.feednet.kube_config[0].cluster_ca_certificate
  )
}

provider "kubernetes-alpha" {
  host  = digitalocean_kubernetes_cluster.feednet.endpoint
  token = digitalocean_kubernetes_cluster.feednet.kube_config[0].token
  cluster_ca_certificate = base64decode(
    digitalocean_kubernetes_cluster.feednet.kube_config[0].cluster_ca_certificate
  )
}

provider "helm" {
  kubernetes {
    load_config_file = false
    host             = digitalocean_kubernetes_cluster.feednet.endpoint
    token            = digitalocean_kubernetes_cluster.feednet.kube_config[0].token
    cluster_ca_certificate = base64decode(
      digitalocean_kubernetes_cluster.feednet.kube_config[0].cluster_ca_certificate
    )
  }
}
