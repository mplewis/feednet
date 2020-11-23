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

module "cluster" {
  source = "./cluster"
}

provider "kubernetes" {
  load_config_file       = false
  host                   = module.cluster.host
  token                  = module.cluster.token
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
}

provider "kubernetes-alpha" {
  host                   = module.cluster.host
  token                  = module.cluster.token
  cluster_ca_certificate = module.cluster.cluster_ca_certificate
}

provider "helm" {
  kubernetes {
    load_config_file       = false
    host                   = module.cluster.host
    token                  = module.cluster.token
    cluster_ca_certificate = module.cluster.cluster_ca_certificate
  }
}

resource "helm_release" "traefik" {
  name       = "traefik"
  repository = "https://kubernetes-charts.storage.googleapis.com/"
  chart      = "traefik"
  version    = "1.78.4"
  values     = [file("helm/traefik.yaml")]
}

data "kubernetes_service" "traefik" {
  metadata {
    name = "traefik"
  }
}

resource "helm_release" "cert-manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = "v1.0.4"
  set {
    name  = "installCRDs"
    value = "true"
  }
}

resource "kubernetes_manifest" "clusterissuer_letsencrypt_staging" {
  provider = kubernetes-alpha
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt-staging"
    }
    spec = {
      acme = {
        email  = "matt@mplewis.com"
        server = "https://acme-staging-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt-staging"
        }
        solvers = [
          {
            dns01 = {
              digitalocean = {
                tokenSecretRef = {
                  name = "digitalocean-api-key"
                  key  = "api-key"
                }
              }
            }
          }
        ]
      }
    }
  }
}

resource "kubernetes_manifest" "clusterissuer_letsencrypt" {
  provider = kubernetes-alpha
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = "letsencrypt"
    }
    spec = {
      acme = {
        email  = "matt@mplewis.com"
        server = "https://acme-v02.api.letsencrypt.org/directory"
        privateKeySecretRef = {
          name = "letsencrypt"
        }
        solvers = [
          {
            dns01 = {
              digitalocean = {
                tokenSecretRef = {
                  name = "digitalocean-api-key"
                  key  = "api-key"
                }
              }
            }
          }
        ]
      }
    }
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

resource "kubernetes_service" "podinfo" {
  metadata {
    name = "podinfo"
  }
  spec {
    selector = {
      app = "podinfo"
    }
    port {
      port        = 80
      target_port = 9898
    }
  }
}

resource "digitalocean_record" "podinfo" {
  domain = "fdnt.me"
  type   = "A"
  name   = "podinfo"
  value  = data.kubernetes_service.traefik.load_balancer_ingress.0.ip
}

resource "kubernetes_ingress" "podinfo" {
  metadata {
    name = "podinfo"
    annotations = {
      "cert-manager.io/cluster-issuer" = "letsencrypt"
    }
  }
  spec {
    rule {
      host = "podinfo.fdnt.me"
      http {
        path {
          path = "/"
          backend {
            service_name = "podinfo"
            service_port = 80
          }
        }
      }
    }
    tls {
      secret_name = "podinfo-cert"
      hosts       = ["podinfo.fdnt.me"]
    }
  }
}
