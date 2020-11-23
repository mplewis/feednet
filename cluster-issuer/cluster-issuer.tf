variable "name" {
  type        = string
  description = "The name of the cluster issuer and its associated secret"
}
variable "server" {
  type        = string
  description = "The URL of the ACME server directory"
}

resource "kubernetes_manifest" "clusterissuer" {
  provider = kubernetes-alpha
  manifest = {
    apiVersion = "cert-manager.io/v1"
    kind       = "ClusterIssuer"
    metadata = {
      name = var.name
    }
    spec = {
      acme = {
        email  = "matt@mplewis.com"
        server = var.server
        privateKeySecretRef = {
          name = var.name
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

output "name" {
  value = var.name
}
