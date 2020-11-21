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

provider "kubernetes" {
  load_config_file = false
  host             = digitalocean_kubernetes_cluster.feednet.endpoint
  token            = digitalocean_kubernetes_cluster.feednet.kube_config[0].token
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

resource "kubernetes_service" "inbound" {
  metadata {
    name = "inbound"
  }
  spec {
    type = "LoadBalancer"
  }
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://kubernetes-charts.storage.googleapis.com/"
  chart      = "traefik"
  version    = "1.78.4"

  values = [file("helm/traefik.yaml")]
  set {
    type  = "string"
    name  = "loadBalancerIP"
    value = kubernetes_service.inbound.load_balancer_ingress[0].ip
  }
}

resource "kubernetes_deployment" "podinfo" {
  metadata {
    name = "podinfo"
    labels = {
      app = "podinfo"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "podinfo"
      }
    }

    template {
      metadata {
        labels = {
          app = "podinfo"
        }
      }

      spec {
        container {
          image = "stefanprodan/podinfo:latest"
          name  = "podinfo"

          resources {
            limits {
              cpu    = "0.5"
              memory = "512Mi"
            }
            requests {
              cpu    = "250m"
              memory = "50Mi"
            }
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "podinfo_lb" {
  metadata {
    name = "podinfo_lb"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = "podinfo"
    }
    port {
      port        = 80
      target_port = 9898
    }
  }
}

resource "kubernetes_service" "podinfo" {
  metadata {
    name = "podinfo"
  }
  spec {
    type = "LoadBalancer"
    selector = {
      app = "podinfo"
    }
    port {
      port        = 80
      target_port = 9898
    }
  }
}

resource "kubernetes_ingress" "podinfo" {
  metadata {
    name = "podinfo"
  }
  spec {
    backend {
      service_name = "podinfo"
      service_port = 80
    }
  }
}
