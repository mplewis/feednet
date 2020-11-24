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

resource "helm_release" "mysql-operator" {
  name       = "mysql-operator"
  repository = "https://presslabs.github.io/charts"
  chart      = "mysql-operator"
  version    = "0.4.0"
}

module "letsencrypt-staging" {
  source = "./cluster-issuer"
  name   = "letsencrypt-staging"
  server = "https://acme-staging-v02.api.letsencrypt.org/directory"
}

module "letsencrypt" {
  source = "./cluster-issuer"
  name   = "letsencrypt"
  server = "https://acme-v02.api.letsencrypt.org/directory"
}

module "deployments" {
  source = "./deployments"
}

resource "kubernetes_manifest" "mysqlcluster_kesdev" {
  manifest = {
    apiVersion = "mysql.presslabs.org/v1alpha1"
    kind       = "MysqlCluster"
    metadata = {
      name = "kesdev"
    }
    spec = {
      replicas   = 1
      secretName = "mysql-root-password"
    }
  }
}

module "podinfo_exposure" {
  source           = "./exposure"
  name             = "podinfo"
  target_port      = 9898
  subdomain        = "podinfo"
  top_level_domain = "fdnt.me"
  cluster_issuer   = module.letsencrypt.name
}

# module "kesdev_exposure" {
#   source           = "./exposure"
#   name             = "kesdev"
#   target_port      = 2368
#   subdomain        = "kesdev"
#   top_level_domain = "fdnt.me"
#   cluster_issuer   = module.letsencrypt.name
# }
