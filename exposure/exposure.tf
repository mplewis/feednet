variable "name" {
  type        = string
  description = "The name of the resources to be created"
}
variable "target_port" {
  type        = number
  description = "The service port number to send traffic to"
}
variable "subdomain" {
  type        = string
  description = "The subdomain to configure with DNS and TLS (e.g. myapp)"
}
variable "top_level_domain" {
  type        = string
  description = "The top-level domain to configure with DNS (e.g. fdnt.me)"
}
variable "cluster_issuer" {
  type        = string
  description = "The name of the Cluster Issuer to use for issuing the TLS cert"
}

locals {
  host = var.subdomain == "@" ? var.top_level_domain : "${var.subdomain}.${var.top_level_domain}"
}

data "kubernetes_service" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "kubernetes_service" "service" {
  metadata {
    name = var.name
  }
  spec {
    selector = {
      app = var.name
    }
    port {
      port        = 80
      target_port = var.target_port
    }
  }
}

resource "digitalocean_record" "record" {
  domain = var.top_level_domain
  type   = "A"
  name   = var.name
  value  = data.kubernetes_service.traefik.load_balancer_ingress.0.ip
}

resource "kubernetes_ingress" "ingress" {
  metadata {
    name = var.name
    annotations = {
      "cert-manager.io/cluster-issuer" = var.cluster_issuer
    }
  }
  spec {
    rule {
      host = local.host
      http {
        path {
          path = "/"
          backend {
            service_name = var.name
            service_port = 80
          }
        }
      }
    }
    tls {
      secret_name = "${var.name}-cert"
      hosts       = [local.host]
    }
  }
}
