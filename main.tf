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
  value  = "mplewis.my.to."
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
  subdomain        = "@"
  top_level_domain = "kesdev.com"
  cluster_issuer   = module.letsencrypt.name
}

resource "kubernetes_cron_job" "kesdev-db-backup" {
  metadata {
    name = "kesdev-db-backup"
  }
  spec {
    schedule = "0 10 * * *"
    job_template {
      spec {
        template {
          spec {
            restart_policy = "Never"
            container {
              name  = "mysql-backup"
              image = "databack/mysql-backup:a7f39c710fe48354a49d15f8fa575bb98f577c48"
              env {
                name  = "DB_DUMP_TARGET"
                value = "s3://mplewis-db-backups/kesdev-db"
              }
              env {
                name  = "DB_SERVER"
                value = "kesdev-db"
              }
              env {
                name  = "DB_USER"
                value = "root"
              }
              env {
                name  = "DB_PASS"
                value = "superuser"
              }
              env {
                name  = "RUN_ONCE"
                value = "true"
              }
              env {
                name  = "AWS_DEFAULT_REGION"
                value = "us-west-2"
              }
              env {
                name = "AWS_S3_ACCESS_KEY_ID"
                value_from {
                  secret_key_ref {
                    name = "aws-s3-creds"
                    key  = "access-key-id"
                  }
                }
              }
              env {
                name = "AWS_S3_SECRET_ACCESS_KEY"
                value_from {
                  secret_key_ref {
                    name = "aws-s3-creds"
                    key  = "secret-access-key"
                  }
                }
              }
            }
          }
        }
      }
    }
  }
}
