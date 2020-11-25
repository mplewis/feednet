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

resource "digitalocean_record" "inca" {
  type   = "CNAME"
  domain = "fdnt.me"
  name   = "inca"
  value  = "mplewis.my.to"
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

module "podinfo_exposure" {
  source           = "./exposure"
  name             = "podinfo"
  target_port      = 9898
  subdomain        = "podinfo"
  top_level_domain = "fdnt.me"
  cluster_issuer   = module.letsencrypt.name
}

module "kesdev_exposure" {
  source           = "./exposure"
  name             = "kesdev"
  target_port      = 2368
  subdomain        = "kesdev"
  top_level_domain = "fdnt.me"
  cluster_issuer   = module.letsencrypt.name
}
