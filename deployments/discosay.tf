resource "kubernetes_config_map" "discosay-config" {
  metadata {
    name = "discosay-config"
    labels = {
      app = "discosay"
    }
  }

  data = {
    "discosay.yaml" = file("${path.module}/discosay.config.yaml")
  }
}

resource "kubernetes_deployment" "discosay" {
  metadata {
    name = "discosay"
    labels = {
      app = "discosay"
    }
  }

  spec {
    replicas = 1

    selector {
      match_labels = {
        app = "discosay"
      }
    }

    template {
      metadata {
        labels = {
          app = "discosay"
        }
      }

      spec {
        volume {
          name = "config"
          config_map {
            name = "discosay-config"
          }
        }

        container {
          name  = "discosay"
          image = "mplewis/discosay:1.0.0"

          volume_mount {
            name       = "config"
            mount_path = "/config"
          }

          env {
            name  = "CONFIG_PATH"
            value = "/config/discosay.yaml"
          }
          env {
            name = "RETF_AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = "discosay-bot-tokens"
                key  = "retf"
              }
            }
          }
          env {
            name = "GOPHER_AUTH_TOKEN"
            value_from {
              secret_key_ref {
                name = "discosay-bot-tokens"
                key  = "retf"
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
