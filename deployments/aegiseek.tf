resource "kubernetes_deployment" "aegiseek" {
  metadata {
    name = "aegiseek"
    labels = {
      app = "aegiseek"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "aegiseek"
      }
    }

    template {
      metadata {
        labels = {
          app = "aegiseek"
        }
      }

      spec {
        container {
          name  = "aegiseek"
          image = "mplewis/aegiseek:1.0.2"
          env {
            name = "AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = "aegiseek-bot-token"
                key  = "aegiseek"
              }
            }
          }
          resources {
            requests {
              cpu    = "100m"
              memory = "64Mi"
            }
            limits {
              cpu    = "1"
              memory = "256Mi"
            }
          }
        }
      }
    }
  }
}
