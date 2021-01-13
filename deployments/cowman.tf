resource "kubernetes_deployment" "cowman" {
  metadata {
    name = "cowman"
    labels = {
      app = "cowman"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "cowman"
      }
    }

    template {
      metadata {
        labels = {
          app = "cowman"
        }
      }

      spec {
        container {
          name  = "cowman"
          image = "mplewis/cowman:1.0.0"
          env {
            name = "AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = "cowman-bot-token"
                key  = "cowman"
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
